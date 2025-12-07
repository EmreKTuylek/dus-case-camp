# Gamification & Recommendations System

## A) Point / XP System

### 1. Point Events
Users earn XP for engaging with the platform.
*   **Action**: Reading Prep Material -> **10 XP**
*   **Action**: Attending Live Session -> **50 XP**
*   **Action**: Submitting Correct Answer (Interactive Case) -> **20 XP**
*   **Action**: Completing a Case (All steps + Threshold video watched) -> **100 XP**

### 2. Data Model
**Collection**: `userPointsEvents`
*   `id`: string (auto-id)
*   `userId`: string
*   `eventType`: string ("prep_read", "live_attend", "case_complete", "interactive_answer")
*   `caseId`: string? (optional)
*   `points`: number
*   `createdAt`: timestamp

**Collection**: `users` (Update)
*   `totalPoints`: number (Cumulative XP)

### 3. Logic
*   **Triggers**: Client-side services will write to `userPointsEvents` and increment `users.totalPoints` using a Firestore transaction to ensure consistency.

## B) Badges

### 1. Badge Types
*   **"Endo Starter"**: Solved 1 Endodontic Case.
*   **"Endo Master"**: Solved 10 Endodontic Cases.
*   **"Live Enthusiast"**: Attended 5 Live Sessions.
*   **"Top 10"**: Reached top 10 on a weekly leaderboard.

### 2. Data Model
**Collection**: `userBadges` (Subcollection of `users` or root collection)
*   `id`: badgeId_userId
*   `userId`: string
*   `badgeId`: string (e.g., "endo_starter")
*   `earnedAt`: timestamp

**Config**: `badges` (Hardcoded in App or remote config)
*   `id`: string
*   `name`: string
*   `icon`: string (asset path)
*   `description`: string

## C) Certificates

### 1. Completed Cases
**Collection**: `userCompletedCases`
*   `userId`: string
*   `caseId`: string
*   `completedAt`: timestamp
*   `score`: number?

### 2. Certificates
Generate certificates for milestones (e.g., "Basic Module Completed").
**Collection**: `userCertificates`
*   `id`: string
*   `title`: string
*   `description`: string
*   `issuedAt`: timestamp
*   `pdfUrl`: string?

## D) Leaderboards

### 1. Scopes
*   **Global**: All time total points.
*   **Monthly**: Points earned in the current month (e.g., `2025-12`).
*   **Weekly**: Points earned in the current week (ISO week).

## E) Smart Recommendations ("Fill Your Gaps")

### 1. Goal
Suggest content where the user is weak or lacks activity.

### 2. Analytics
Track `userSpecialtyStats/{userId}__{specialty}`:
*   `specialty`: string
*   `casesSolved`: number
*   `averageScore`: number

### 3. Logic
1.  Fetch user's stats for all specialties.
2.  Identify specialties with:
    *   Low `casesSolved` (Exposure gap).
    *   Low `averageScore` (Performance gap).
3.  Query `cases` collection for active cases in those specialties that the user *has not* completed.
4.  Display top 3 suggestions on Home Screen.
