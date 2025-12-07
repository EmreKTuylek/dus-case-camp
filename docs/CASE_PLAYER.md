# Case Player & Live Chat Specification

## A) Unified Case Player

### 1. Video Types
The system will support three primary modes for a case:
- **VOD (Video on Demand)**: Standard pre-recorded playback.
- **LIVE**: A real-time live stream.
- **VOD_WITH_LIVE_QA**: Pre-recorded video content with a specific time window for live Q&A chat.

### 2. Behavior
- **VOD**: Shows standard playback controls (play/pause, timeline, volume).
- **LIVE**: Shows "LIVE" badge. Scrubbing might be disabled or limited to DVR window.
- **VOD_WITH_LIVE_QA**: Plays VOD but enables/disables the Chat panel based on server time vs. scheduled timestamps.

## B) Timestamps / Chapter Markers

### 1. Data Structure
Each case can have a list of chapters:
```dart
class Chapter {
  final String label;
  final int timestampSeconds;
}
```

### 2. User Interface
- **Chapter List**: displayed below the player or in a side panel.
- **Interaction**: Clicking a chapter seeks the player to `timestampSeconds`.
- **Active State**: The current chapter highlights as playback progresses (optional/nice-to-have).

## C) Live Chat (Time-Bounded)

### 1. Logic
Chat is "Active" if:
1.  Video Type is `LIVE`.
2.  OR Video Type is `VOD_WITH_LIVE_QA` AND `current_time` is between `liveSessionStart` and `liveSessionEnd`.

### 2. Firestore Data Model
**Collection**: `caseLiveChatMessages`
- `id`: Auto ID
- `caseId`: String
- `senderId`: String
- `senderName`: String (Display purposes)
- `messageText`: String
- `createdAt`: Timestamp
- `isDeleted`: Boolean (for moderation)

### 3. UI Layout
- **Mobile**: Chat in a tab or bottom sheet.
- **Desktop/Tablet**: Split view (Player Left, Chat Right).

### 4. Moderation
- Teachers can delete messages (mark `isDeleted: true`).
