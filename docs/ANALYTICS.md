# Student Progress Analytics

## Overview
The Analytics Engine tracks student performance over time, providing insights into their strengths, weaknesses, and engagement consistency.

## Data Pipeline
1. **Trigger**: Firestore `onDocumentUpdated` for `submissions/{id}` (when status becomes `scored` or score changes).
2. **Aggregation**: `analytics` Cloud Function is triggered.
3. **Execution**:
   - Fetches all scored submissions for the student.
   - Cross-references with `cases` collection for Specialty and Week info.
   - Aggregates metrics (Total Score, Per-Specialty Average, Per-Week Total).
4. **Storage**: Writes aggregated result to `userAnalytics/{studentId}`.
5. **Visualization**: Flutter app (`ProgressScreen`) visualizes this data using charts.

## Metrics Defined
- **Total Completed Cases**: Count of submissions with `status: scored`.
- **Total Score**: Sum of `totalPointsAwarded`.
- **Weekly Performance**: Bar chart showing total points earned in each Week.
- **Specialty Strengths**: Average score per specialty.
- **Activity Heatmap**: Active submission days.

## Data Model
**User Analytics Document (`userAnalytics/{studentId}`)**:
```json
{
  "totalCompletedCases": 15,
  "totalScore": 750,
  "weeklyPerformance": [
    { "week": "week_1", "points": 80 },
    { "week": "week_2", "points": 90 }
  ],
  "specialtyPerformance": [
    { "specialty": "Endodontics", "average": 78.5 },
    { "specialty": "Surgery", "average": 92.0 }
  ],
  "activityHeatmap": {
    "2025-01-01": 1,
    "2025-01-02": 2
  }
}
```

## Future Improvements
- Comparison with cohort average.
- Detailed radar charts (Spider web) for specialty balance.
