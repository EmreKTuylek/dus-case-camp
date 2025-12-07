# Firestore Schema

This document defines the Firestore data model for DUS Case Camp.

## Collections

### `users`
Stores user profiles (students, teachers, admins).

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String | User ID (same as Auth UID) |
| `fullName` | String | Full name of the user |
| `email` | String | Email address |
| `role` | String | `student`, `teacher`, or `admin` |
| `school` | String? | University/School name (optional) |
| `yearOfStudy` | Number? | Year of study (optional) |
| `totalPoints` | Number | Cumulative total points |
| `createdAt` | Timestamp | Account creation time |
| `updatedAt` | Timestamp | Last update time |

### `weeks`
Represents a weekly campaign of cases.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Auto-generated ID |
| `title` | String | Title of the week (e.g., "Week 1 - Endodontics") |
| `startDate` | Timestamp | Start of the week |
| `endDate` | Timestamp | End of the week |
| `isActive` | Boolean | Whether the week is currently active |
| `caseCount` | Number | Number of cases in this week |

### `cases`
Individual clinical cases belonging to a week.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Auto-generated ID |
| `weekId` | String | Reference to `weeks` document ID |
| `title` | String | Case title |
| `description` | String | Clinical story/description |
| `speciality` | String | e.g., "Endodontics", "Periodontology" |
| `level` | String | `easy`, `medium`, `hard` |
| `mediaUrls` | Array<String> | List of URLs for images/PDFs |
| `createdBy` | String | Teacher ID who created the case |
| `createdAt` | Timestamp | Creation time |

### `submissions`
Video answers uploaded by students.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Auto-generated ID |
| `caseId` | String | Reference to `cases` document ID |
| `studentId` | String | Reference to `users` document ID |
| `videoUrl` | String | URL of the uploaded video in Storage |
| `durationSeconds` | Number? | Length of the video |
| `submittedAt` | Timestamp | Submission time |
| `status` | String | `pending_review`, `scored`, `rejected` |
| `teacherScore` | Number? | Score given by teacher (0-100) |
| `teacherFeedback` | String? | Feedback text from teacher |
| `totalPointsAwarded` | Number | Final points awarded for this submission |

### `weekly_leaderboards`
Weekly ranking of students.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Composite ID (e.g., `weekId_studentId`) or Auto ID |
| `weekId` | String | Reference to `weeks` document ID |
| `studentId` | String | Reference to `users` document ID |
| `totalPoints` | Number | Points earned in this week |
| `rank` | Number | Rank in the leaderboard |

### `global_leaderboards`
Overall ranking of students.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Same as `studentId` |
| `studentId` | String | Reference to `users` document ID |
| `totalPoints` | Number | Total points accumulated |
| `rank` | Number | Global rank |
