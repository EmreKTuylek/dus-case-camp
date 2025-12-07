const { onObjectFinalized } = require("firebase-functions/v2/storage");
const admin = require("firebase-admin");
const path = require("path");
const os = require("os");
const fs = require("fs");
const ffmpeg = require("fluent-ffmpeg");
const ffmpegPath = require("ffmpeg-static");
const { SpeechClient } = require("@google-cloud/speech");
const { VertexAI } = require("@google-cloud/vertexai");

ffmpeg.setFfmpegPath(ffmpegPath);

const db = admin.firestore();
const speechClient = new SpeechClient();

// Initialize Vertex AI
// Note: Location might need configuration or dynamic detection. Defaulting to us-central1.
const project = process.env.GCLOUD_PROJECT;
const location = 'us-central1';
const vertexAI = new VertexAI({ project: project, location: location });

/**
 * Triggered when a new video is uploaded to 'videoSubmissions/{submissionId}/{filename}'
 * or 'videoSubmissions/{submissionId}.mp4'
 */
exports.generateAiFeedback = onObjectFinalized({
    cpu: 2,
    memory: "2GiB", // Transcoding/Extraction needs memory
    timeoutSeconds: 540 // Long timeout for video processing
}, async (event) => {
    const fileBucket = event.data.bucket;
    const filePath = event.data.name;
    const contentType = event.data.contentType;

    // 1. Validation: Check if it's a video and in the right path
    if (!contentType.startsWith("video/")) {
        console.log("Not a video file, skipping.");
        return;
    }

    // Support path structure: videoSubmissions/{submissionId}/... or videoSubmissions/{submissionId}.mp4
    // We want to avoid loops if we upload transcoded files to the same folder triggers
    if (filePath.includes("/transcoded/")) {
        console.log("Skipping transcoded file.");
        return;
    }

    // Parse submissionId
    // Assuming format: videoSubmissions/SUBMISSION_ID/original.mp4
    const parts = filePath.split("/");
    let submissionId;
    if (parts.length >= 3 && parts[0] === "videoSubmissions") {
        submissionId = parts[1];
    } else if (parts.length === 2 && parts[0] === "videoSubmissions") {
        // videoSubmissions/SUBMISSION_ID.mp4
        submissionId = path.basename(filePath, path.extname(filePath));
    } else {
        console.log("File path does not match expected structure for submission.");
        return;
    }

    console.log(`Processing submission: ${submissionId}`);

    // Create temp paths
    const fileName = path.basename(filePath);
    const tempFilePath = path.join(os.tmpdir(), fileName);
    const tempAudioPath = path.join(os.tmpdir(), `${submissionId}.wav`); // Mono wav for STT

    const bucket = admin.storage().bucket(fileBucket);

    try {
        // 2. Download video
        await bucket.file(filePath).download({ destination: tempFilePath });
        console.log("Video downloaded.");

        // 3. Extract Audio
        await new Promise((resolve, reject) => {
            ffmpeg(tempFilePath)
                .toFormat("wav")
                .audioChannels(1) // Mono
                .audioFrequency(16000) // 16kHz recommended for STT
                .on("end", resolve)
                .on("error", reject)
                .save(tempAudioPath);
        });
        console.log("Audio extracted.");

        // 4. Speech to Text
        const audioBytes = fs.readFileSync(tempAudioPath).toString("base64");
        const audio = { content: audioBytes };
        const config = {
            encoding: "LINEAR16",
            sampleRateHertz: 16000,
            languageCode: "tr-TR", // Assuming Turkish based on "DUS Case Camp" context
        };
        const request = {
            audio: audio,
            config: config,
        };

        const [response] = await speechClient.recognize(request);
        const transcription = response.results
            .map(result => result.alternatives[0].transcript)
            .join("\n");

        console.log("Transcription complete:", transcription.substring(0, 50) + "...");

        // 5. Generate AI Feedback
        const model = vertexAI.preview.getGenerativeModel({
            model: 'gemini-pro',
        });

        const prompt = `
        You are an expert dental professor evaluating a student's case presentation.
        Analyze the following student transcript:
        "${transcription}"
        
        Provide feedback in the following JSON format structure (do not use markdown code blocks, just raw JSON or plain text parsing):
        {
          "summary": "Brief summary of what the student said",
          "missing_points": ["List of key clinical points missed"],
          "reasoning": "Analysis of their reasoning path",
          "advice": "Constructive advice for improvement"
        }
        Return ONLY valid JSON.
        `;

        const result = await model.generateContent(prompt);
        const responseText = result.response.candidates[0].content.parts[0].text;

        // Clean markdown code blocks if present
        const jsonStr = responseText.replace(/```json/g, '').replace(/```/g, '').trim();
        let feedbackData;
        try {
            feedbackData = JSON.parse(jsonStr);
        } catch (e) {
            console.error("Failed to parse JSON from AI", responseText);
            feedbackData = {
                summary: "Could not parse AI response.",
                raw_response: responseText
            };
        }

        // 6. Save to Firestore
        // Using 'submissions' collection as the main record
        await db.collection("submissions").doc(submissionId).set({
            autoFeedback: feedbackData,
            aiStatus: 'completed',
            transcription: transcription
        }, { merge: true });

        console.log("Feedback saved to Firestore.");

    } catch (error) {
        console.error("Error in AI pipeline:", error);
        await db.collection("submissions").doc(submissionId).set({
            aiStatus: 'error',
            aiError: error.message
        }, { merge: true });
    } finally {
        // Cleanup
        if (fs.existsSync(tempFilePath)) fs.unlinkSync(tempFilePath);
        if (fs.existsSync(tempAudioPath)) fs.unlinkSync(tempAudioPath);
    }
});
