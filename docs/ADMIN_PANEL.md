# DUS Case Camp - Teacher & Admin Panel

This guide explains how to use the Admin Panel to manage weeks, cases, and score student submissions.

## Accessing the Admin Panel

Only users with the role `teacher` or `admin` can access the panel.
1.  Log in to the app.
2.  Go to the **Profile** tab.
3.  If you have the correct role, you will see an **Admin Panel** button.

### How to set a user as Teacher/Admin
Currently, this must be done via the Firebase Console or the seeding script.
1.  Go to Firestore Console -> `users` collection.
2.  Find the user document.
3.  Change the `role` field to `teacher` or `admin`.

## Features

### 1. Dashboard
Provides an overview of the system (currently a placeholder).

### 2. Manage Weeks
- **List Weeks**: See all weeks and their active status.
- **Create Week**: Click the `+` button to create a new week with a title and date range.
- **Activate Week**: Click "Activate" on a week to make it the current active week. This will deactivate all other weeks.
- **Manage Cases**: Click the "Edit Note" icon to view and manage cases for a specific week.

### 3. Manage Cases
- **List Cases**: See all cases for the selected week.
- **Create Case**: Click `+` to add a new case. You need to provide:
    - Title
    - Description
    - Speciality
    - Difficulty Level
- **Delete Case**: Click the trash icon to delete a case.

### 4. Review Submissions
- **Filter**: Use the chips at the top to filter by status (Pending, Scored, Rejected).
- **Review**:
    - Watch the student's uploaded video.
    - Enter a Score (0-100).
    - Enter Feedback (optional).
    - Click **Save Score** or **Reject**.
- **Scoring Logic**:
    - Saving a score will automatically update the student's `totalPoints` and the leaderboards via Cloud Functions.
