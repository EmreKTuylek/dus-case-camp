const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const db = admin.firestore();

exports.updateStudentAnalytics = onDocumentUpdated("submissions/{submissionId}", async (event) => {
    const newData = event.data.after.data();
    const oldData = event.data.before.data();

    // Trigger only if totalPointsAwarded changes or status becomes scored
    const wasScored = oldData.status === 'scored';
    const isScored = newData.status === 'scored';
    const scoreChanged = newData.totalPointsAwarded !== oldData.totalPointsAwarded;

    if (!isScored && !wasScored) return; // Not relevant
    if (isScored && !scoreChanged && wasScored) return; // No change in score

    const studentId = newData.studentId;
    console.log(`Updating analytics for student: ${studentId}`);

    // 1. Fetch all scored submissions for this student
    const submissionsSnapshot = await db.collection("submissions")
        .where("studentId", "==", studentId)
        .where("status", "==", "scored")
        .get();

    if (submissionsSnapshot.empty) return;

    // 2. We need Case metadata (Specialty, Week) for each submission
    // Optimization: Fetch all cases relevant to these submissions
    const caseIds = new Set();
    submissionsSnapshot.forEach(doc => caseIds.add(doc.data().caseId));

    // Fetch cases (batching if necessary, but assuming reasonable count)
    // If > 10, better to fetch all cases or use field masking?
    // For now, let's fetch individual cases or use a map if we have a way.
    // We'll just Promise.all get calls (up to limits) or use `getAll` if available on admin SDK.
    const refs = Array.from(caseIds).map(id => db.collection("cases").doc(id));

    // Firestore supports getting up to 100 documents? 
    // We'll map caseId -> caseData
    const caseMap = {};
    if (refs.length > 0) {
        // getAll supports varargs, so use spread
        // But spread might be too large.
        // Let's do chunks of 10 for safety
        for (let i = 0; i < refs.length; i += 10) {
            const chunk = refs.slice(i, i + 10);
            const caseDocs = await db.getAll(...chunk);
            caseDocs.forEach(d => {
                if (d.exists) caseMap[d.id] = d.data();
            });
        }
    }

    // 3. Compute Analytics
    let totalScore = 0;
    let totalMaxPossible = 0; // Estimation
    const weeklyPoints = {}; // weekId -> points
    const specialtyStats = {}; // specialty -> { points, count }
    const activityHeatmap = {}; // 'YYYY-MM-DD' -> count
    const trendData = []; // { date, score }

    submissionsSnapshot.forEach(doc => {
        const sub = doc.data();
        const caseData = caseMap[sub.caseId];

        if (!caseData) return;

        const points = sub.totalPointsAwarded || 0;
        totalScore += points;

        // Weekly
        const weekId = caseData.weekId || 'unknown';
        weeklyPoints[weekId] = (weeklyPoints[weekId] || 0) + points;

        // Specialty
        const specialty = caseData.speciality || 'General';
        if (!specialtyStats[specialty]) {
            specialtyStats[specialty] = { points: 0, count: 0 };
        }
        specialtyStats[specialty].points += points;
        specialtyStats[specialty].count += 1;

        // Activity Heatmap
        if (sub.submittedAt) {
            const date = sub.submittedAt.toDate().toISOString().split('T')[0];
            activityHeatmap[date] = (activityHeatmap[date] || 0) + 1;
            trendData.push({ date: sub.submittedAt.toDate(), score: points });
        }
    });

    // Formatting for Chart Consumption
    const specialtyChartData = Object.entries(specialtyStats).map(([key, val]) => ({
        specialty: key,
        average: val.points / val.count
    }));

    const weeklyChartData = Object.entries(weeklyPoints).map(([key, val]) => ({
        week: key,
        points: val
    }));

    // 4. Save to userAnalytics
    await db.collection("userAnalytics").doc(studentId).set({
        totalCompletedCases: submissionsSnapshot.size,
        totalScore: totalScore,
        weeklyPerformance: weeklyChartData,
        specialtyPerformance: specialtyChartData,
        activityHeatmap: activityHeatmap,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    console.log("Analytics updated.");
});
