const { onObjectFinalized } = require("firebase-functions/v2/storage");
const admin = require("firebase-admin");
const path = require("path");
const os = require("os");
const fs = require("fs");
const ffmpeg = require("fluent-ffmpeg");
const ffmpegPath = require("ffmpeg-static");

ffmpeg.setFfmpegPath(ffmpegPath);
const db = admin.firestore();

exports.transcodeVideo = onObjectFinalized({
    cpu: 2,
    memory: "2GiB",
    timeoutSeconds: 540
}, async (event) => {
    const fileBucket = event.data.bucket;
    const filePath = event.data.name;
    const contentType = event.data.contentType;

    // 1. Check if video and not already transcoded
    if (!contentType.startsWith("video/")) return;
    if (filePath.includes("/transcoded/")) return;

    // Parse submissionId
    const parts = filePath.split("/");
    let submissionId;
    if (parts.length >= 3 && parts[0] === "videoSubmissions") {
        submissionId = parts[1];
    } else if (parts.length === 2 && parts[0] === "videoSubmissions") {
        submissionId = path.basename(filePath, path.extname(filePath));
    } else {
        console.log("File path does not match expected structure for submission.");
        return; // Or process anyway? Better safe.
    }

    console.log(`Transcoding submission: ${submissionId}`);

    const bucket = admin.storage().bucket(fileBucket);
    const fileName = path.basename(filePath);
    const tempFilePath = path.join(os.tmpdir(), fileName);

    const resolutions = [
        { name: '1080p', height: 1080 },
        { name: '720p', height: 720 },
        { name: '480p', height: 480 }
    ];

    try {
        await bucket.file(filePath).download({ destination: tempFilePath });
        console.log("Video downloaded.");

        const completedSizes = [];
        const transcodedUrls = {};

        // 2. Transcode
        for (const res of resolutions) {
            const outputFileName = `${res.name}.mp4`;
            const outputFilePath = path.join(os.tmpdir(), outputFileName);
            // Construct target storage path: videoSubmissions/{id}/transcoded/1080p.mp4
            // Assuming structure videoSubmissions/{id}/...
            // If original was videoSubmissions/{id}.mp4, we create a folder videoSubmissions/{id}/transcoded/
            const targetStoragePath = `videoSubmissions/${submissionId}/transcoded/${outputFileName}`;

            console.log(`Transcoding to ${res.name}...`);
            await new Promise((resolve, reject) => {
                ffmpeg(tempFilePath)
                    .output(outputFilePath)
                    .videoCodec('libx264')
                    .size(`?x${res.height}`) // Maintain aspect ratio
                    .on('end', resolve)
                    .on('error', reject)
                    .run();
            });

            console.log(`Uploading ${res.name}...`);
            await bucket.upload(outputFilePath, {
                destination: targetStoragePath,
                metadata: {
                    contentType: 'video/mp4',
                }
            });

            completedSizes.push(res.name);
            // Construct Public URL or Storage Path (Client can fetch URL via SDK)
            // We'll store the storage path or a signed URL pattern (but signed URLs expire).
            // Storing the full path is better.
            transcodedUrls[res.name] = targetStoragePath;

            // Cleanup temp output
            fs.unlinkSync(outputFilePath);
        }

        // 3. Update Firestore
        await db.collection("submissions").doc(submissionId).set({
            transcodingStatus: 'completed',
            transcodedSizes: completedSizes,
            transcodedPaths: transcodedUrls, // Helper for client
            originalSize: fs.statSync(tempFilePath).size,
            lastTranscodedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });

        console.log("Transcoding complete.");

    } catch (error) {
        console.error("Transcoding failed:", error);
        await db.collection("submissions").doc(submissionId).set({
            transcodingStatus: 'error',
            transcodingError: error.message
        }, { merge: true });
    } finally {
        if (fs.existsSync(tempFilePath)) fs.unlinkSync(tempFilePath);
    }
});
