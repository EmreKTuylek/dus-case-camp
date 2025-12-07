# Video Transcoding Pipeline

## Overview
The Video Transcoding Pipeline ensures that all student video submissions are optimized for playback across different devices and network conditions. It automatically generates multiple resolutions (1080p, 720p, 480p) from the original upload.

## Pipeline Architecture
1. **Trigger**: Video uploaded to Firebase Storage (`videoSubmissions/{id}`).
2. **Processing**: `transcoding` Cloud Function triggered.
3. **Filtering**: Checks if file is video and not already in `transcoded/` folder.
4. **Transcoding**: Spawns FFmpeg processes to resize video to:
   - 1080p
   - 720p
   - 480p
5. **Storage**: Uploads results to `videoSubmissions/{id}/transcoded/{resolution}.mp4`.
6. **Metadata**: Updates `submissions` Firestore document with `transcodedSizes`, `transcodedPaths`, and `transcodingStatus`.
7. **Playback**: Flutter app (`AdaptiveVideoPlayer` widget) consumes these paths to offer quality selection.

## Configuration
- **Cloud Functions**: Node.js 18 runtime.
- **Dependencies**: `fluent-ffmpeg`, `ffmpeg-static`.
- **Resources**: 2GB Memory / 2 CPU allocated for high performance value.

## Data Model
**Submission Document (`submissions/{id}`)**:
```json
{
  "transcodingStatus": "completed" | "error",
  "transcodedSizes": ["1080p", "720p", "480p"],
  "transcodedPaths": {
    "1080p": "videoSubmissions/123/transcoded/1080p.mp4",
    "720p": "videoSubmissions/123/transcoded/720p.mp4"
  },
  "originalSize": 10485760
}
```

## Monitoring
- **Logs**: Viewable in Firebase Console -> Functions -> Logs.
- **Errors**: Stored in `transcodingError` field in Firestore.
