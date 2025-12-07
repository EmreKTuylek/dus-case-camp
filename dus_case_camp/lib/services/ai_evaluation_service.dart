import '../models/interactive_models.dart';

class AiEvaluationService {
  /// Evaluates a student's answer against the strict criteria.
  /// Returns an [InteractiveAnswer] with score and feedback.
  static InteractiveAnswer evaluateAnswer({
    required InteractiveStep step,
    required String studentAnswer,
    required String studentId,
    required String caseId,
  }) {
    final lowerAnswer = studentAnswer.toLowerCase();

    // 1. Keyword Matching
    int requiredParamsHit = 0;
    List<String> missingRequired = [];

    for (final kw in step.requiredKeywords) {
      if (lowerAnswer.contains(kw.toLowerCase())) {
        requiredParamsHit++;
      } else {
        missingRequired.add(kw);
      }
    }

    int bonusHits = 0;
    List<String> hitBonus = [];
    for (final kw in step.bonusKeywords) {
      if (lowerAnswer.contains(kw.toLowerCase())) {
        bonusHits++;
        hitBonus.add(kw);
      }
    }

    // Scoring Logic
    // Required keywords account for 60% of the score (if all present)
    // Bonus keywords account for 20%
    // Semantic similarity (simulated by length/coverage here) accounts for 20%

    double score = 0.0;

    if (step.requiredKeywords.isNotEmpty) {
      final reqScore = (requiredParamsHit / step.requiredKeywords.length) * 60;
      score += reqScore;
    } else {
      score += 60; // No required keywords -> free points? Or judge differently.
    }

    if (step.bonusKeywords.isNotEmpty) {
      final bonusPart = (bonusHits / step.bonusKeywords.length) * 20;
      score += bonusPart;
    }

    // Length/Effort heuristic for "Semantic" placeholder
    if (studentAnswer.length > 20) {
      score += 10;
    }
    if (studentAnswer.length > 50) {
      score += 10;
    }

    // Cap score at 100
    if (score > 100) score = 100;

    // Generate Feedback
    final feedbackBuffer = StringBuffer();
    if (score == 100) {
      feedbackBuffer.writeln("Excellent! Perfect match.");
    } else if (score > 80) {
      feedbackBuffer.writeln("Great answer.");
    } else {
      feedbackBuffer.writeln("Good effort, but some key points were missing.");
    }

    if (missingRequired.isNotEmpty) {
      feedbackBuffer.writeln(
          "\nMissing essential concepts: ${missingRequired.join(', ')}");
    }

    if (hitBonus.isNotEmpty) {
      feedbackBuffer
          .writeln("\nBonus points for identifying: ${hitBonus.join(', ')}");
    }

    return InteractiveAnswer(
      id: '${step.id}_$studentId', // Simple ID generation
      caseId: caseId,
      stepId: step.id,
      studentId: studentId,
      answerText: studentAnswer,
      aiScore: score,
      aiFeedback: feedbackBuffer.toString(),
      status: InteractiveAnswerStatus.evaluated,
      submittedAt: DateTime.now(),
    );
  }
}
