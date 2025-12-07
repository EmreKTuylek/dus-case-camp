# Admin Panel & Closed-Loop AI Evaluation (Strict Mode)

## Overview
This document outlines the implementation of an advanced Admin Panel for content management and a strict, closed-loop AI evaluation system for interactive video cases.

## A. Admin Panel Features

### 1. Video & Live Session Management
- **Video Upload**: VOD URL input or file upload.
- **Live Configuration**:
    - Toggle `isLive`.
    - Set `liveSessionStart` and `liveSessionEnd`.

### 2. Preparation Materials
- Manage a list of resources (`PrepMaterial`):
    - `type`: 'pdf' | 'link'
    - `title`: Display name
    - `url`: Resource link

### 3. Interactive AI Steps (The "Answer Key")
Admin inputs for each interruption point in the video:
- `pauseAtSeconds`: Timestamp to pause video.
- `questionText`: The question to ask the student.
- `correctAnswerText`: The "Gold Standard" answer.
- `requiredKeywords`: List of words MUST be present.
- `bonusKeywords`: List of words that add extra score.

### 4. Student Answer Review
- View answers for a specific step.
- See AI-generated analysis (Score + Feedback).
- **Teacher Override**: Manually correct the score/status.

## B. Student Flow (Interactive Mode)

1. **Playback**: Video plays normally.
2. **Interruption**: At `pauseAtSeconds`, video pauses.
3. **Modal**: Question appears. video controls locked/hidden.
4. **Submission**: Student types answer -> Submit.
5. **Resume**:
    - Answer sent to backend.
    - Video resumes (or waits for feedback depending on UX choice - we will resume and notify later to keep flow).

## C. Closed-Loop AI Evaluation Logic (Strict Mode)

The evaluation Logic must **NOT** use external knowledge.

### Formula
1. **Keyword Match (40%)**:
    - `(Matches / TotalRequired) * 40`.
    - If `Matches < TotalRequired`, significant penalty or cap.
2. **Bonus Match (20%)**:
    - Points for optional keywords.
3. **Semantic Similarity (40%)**:
    - Comparison between `studentAnswer` and `correctAnswerText` using local NLP or constrained LLM prompt.

### "Strict Mode" LLM Prompt
If using an LLM (e.g., Vertex AI / Gemini API), the system instruction must be:
> "You are an automated grading assistant. You have NO medical knowledge. You can ONLY compare the Student Answer against the Reference Answer. Do not use your own training data. If the student mentions concepts not in the Reference Answer, ignore them. Grade based on semantic coverage of the Reference Answer."

## D. Data Models

### 1. PrepMaterial
```dart
class PrepMaterial {
  String id;
  String type; // 'pdf', 'link'
  String title;
  String url;
}
```

### 2. InteractiveStep
```dart
class InteractiveStep {
  String id;
  int pauseAtSeconds;
  String questionText;
  String correctAnswerText;
  List<String> requiredKeywords;
  List<String> bonusKeywords;
}
```

### 3. InteractiveAnswer
```dart
class InteractiveAnswer {
  String id;
  String caseId;
  String stepId;
  String studentId;
  String answerText;
  double? aiScore;
  String? aiFeedback;
  double? teacherScore;
  String status; // 'pending', 'evaluated'
}
```
