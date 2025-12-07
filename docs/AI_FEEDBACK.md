# AI-Assisted Feedback System

## Overview
The Automated Feedback System analyzes student video submissions to provide immediate, constructive feedback. It uses **Google Cloud Speech-to-Text** for transcription and **Vertex AI (Gemini Pro)** for clinical reasoning analysis.

## Pipeline Architecture
1. **Trigger**: Video uploaded to Firebase Storage (`videoSubmissions/{id}`).
2. **Audio Extraction**: `ai_feedback` Cloud Function downloads video and extracts audio using `ffmpeg`.
3. **Transcription**: Audio sent to Google Cloud Speech API (Turkish, `tr-TR`).
4. **Analysis**: Transcript sent to Vertex AI with a system prompt to evaluate:
   - Summary
   - Missing Clinical Points
   - Reasoning Path
   - Advice
5. **Storage**: Result is saved to the Firestore submission document (`submissions/{id}`) in the `autoFeedback` field.
6. **Display**: Flutter app detects `aiStatus: completed` and renders the feedback via `CaseDetailScreen`.

## Configuration
### Requirements
- **Google Cloud Project** with enabled APIs:
  - `speech.googleapis.com`
  - `aiplatform.googleapis.com` (Vertex AI)
- **Firebase Functions** linked to the project.
- **Service Account** with permissions to access Storage and Vertex AI.

### Environment Variables
- `GCLOUD_PROJECT`: Project ID (automated in keyless envs).

## Data Model
**Submission Document (`submissions/{id}`)**:
```json
{
  "aiStatus": "completed" | "processing" | "error",
  "autoFeedback": {
    "summary": "...",
    "missing_points": ["...", "..."],
    "reasoning": "...",
    "advice": "..."
  },
  "transcription": "..."
}
```

## Error Handling
- Invalid video format -> Skipped.
- AI API failure -> `aiStatus: error`, generic message shown in App.

## Billing Considerations
- **Storage**: Temporary storage for video/audio processing.
- **Cloud Functions**: CPU/Memory usage during FFmpeg processing (2GB RAM allocated).
- **Speech-to-Text**: By second pricing.
- **Vertex AI**: By character/token pricing.
