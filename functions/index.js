const { onDocumentWritten, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();
const messaging = admin.messaging();

// Scoring Constants
const POINTS_BASE = 10;
const POINTS_EARLY_24H = 10;
const POINTS_EARLY_48H = 5;
const TEACHER_SCORE_MULTIPLIER = 0.5;

exports.calculateScores = onDocumentWritten("submissions/{submissionId}", async (event) => {
  // ... (Existing calculateScores logic - kept as is, just ensuring it's in the file)
  // For brevity in this tool call, I will assume the previous content is preserved if I use 'replace' or I need to rewrite the whole file.
  // Since I'm using write_to_file with Overwrite: true, I MUST include the previous logic.

  const submissionId = event.params.submissionId;
  const oldData = event.data.before.exists ? event.data.before.data() : null;
  const newData = event.data.after.exists ? event.data.after.data() : null;

  if (!newData) return; // Deletion

  const oldTotal = oldData ? oldData.totalPointsAwarded || 0 : 0;
  const currentTotal = newData.totalPointsAwarded || 0;

  const caseId = newData.caseId;
  const studentId = newData.studentId;

  const caseDoc = await db.collection("cases").doc(caseId).get();
  if (!caseDoc.exists) return;
  const caseData = caseDoc.data();

  const weekDoc = await db.collection("weeks").doc(caseData.weekId).get();
  if (!weekDoc.exists) return;
  const weekData = weekDoc.data();

  let calculatedPoints = 0;
  calculatedPoints += POINTS_BASE;

  const submittedAt = newData.submittedAt.toDate();
  const weekStart = weekData.startDate.toDate();
  const diffHours = (submittedAt - weekStart) / (1000 * 60 * 60);

  if (diffHours <= 24) calculatedPoints += POINTS_EARLY_24H;
  else if (diffHours <= 48) calculatedPoints += POINTS_EARLY_48H;

  if (newData.status === 'scored' && newData.teacherScore) {
    calculatedPoints += Math.round(newData.teacherScore * TEACHER_SCORE_MULTIPLIER);
  }

  if (calculatedPoints !== currentTotal) {
    const pointsDiff = calculatedPoints - currentTotal;
    await db.runTransaction(async (t) => {
      t.update(event.data.after.ref, { totalPointsAwarded: calculatedPoints });
      const userRef = db.collection("users").doc(studentId);
      t.update(userRef, { totalPoints: admin.firestore.FieldValue.increment(pointsDiff) });
      const globalRef = db.collection("global_leaderboards").doc(studentId);
      t.set(globalRef, { studentId: studentId, totalPoints: admin.firestore.FieldValue.increment(pointsDiff), rank: 0 }, { merge: true });
      const weeklyRef = db.collection("weekly_leaderboards").doc(`${caseData.weekId}_${studentId}`);
      t.set(weeklyRef, { weekId: caseData.weekId, studentId: studentId, totalPoints: admin.firestore.FieldValue.increment(pointsDiff), rank: 0 }, { merge: true });
    });
  }
});

// --- NOTIFICATION TRIGGERS ---

exports.onWeekActivated = onDocumentUpdated("weeks/{weekId}", async (event) => {
  const newData = event.data.after.data();
  const oldData = event.data.before.data();

  if (newData.isActive && !oldData.isActive) {
    const message = {
      notification: {
        title: 'New Week Started!',
        body: `${newData.title} is now active. Check out the new cases!`,
      },
      topic: 'new_weeks',
    };

    try {
      await messaging.send(message);
      logger.info('New week notification sent');
    } catch (e) {
      logger.error('Error sending notification', e);
    }
  }
});

exports.onSubmissionScored = onDocumentUpdated("submissions/{submissionId}", async (event) => {
  const newData = event.data.after.data();
  const oldData = event.data.before.data();

  // Check if status changed to 'scored'
  if (newData.status === 'scored' && oldData.status !== 'scored') {
    const studentId = newData.studentId;

    // Get user tokens
    const userDoc = await db.collection("users").doc(studentId).get();
    if (!userDoc.exists) return;

    const tokens = userDoc.data().fcmTokens;
    if (!tokens || tokens.length === 0) return;

    const message = {
      notification: {
        title: 'Submission Scored',
        body: `Your submission has been scored! You got ${newData.teacherScore} points from the teacher.`,
      },
      tokens: tokens,
    };

    try {
      await messaging.sendMulticast(message);
      logger.info(`Score notification sent to student ${studentId}`);
    } catch (e) {
      logger.error('Error sending score notification', e);
    }
  }
});

const { generateAiFeedback } = require("./ai_feedback");
exports.generateAiFeedback = generateAiFeedback;

const { transcodeVideo } = require("./transcoding");
exports.transcodeVideo = transcodeVideo;

const { updateStudentAnalytics } = require("./analytics");
exports.updateStudentAnalytics = updateStudentAnalytics;
