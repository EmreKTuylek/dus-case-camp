import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/interactive_models.dart';

class AiEvaluationService {
  // TODO: Move to secure storage or remote config in production
  static const String _apiKey = 'API_KEY_HERE';

  /// Evaluates a student's answer using Gemini 1.5 Flash in Strict Mode.
  /// Falls back to heuristic [evaluateAnswerLegacy] if API fails or key is missing.
  static Future<InteractiveAnswer> evaluateAnswer({
    required InteractiveStep step,
    required String studentAnswer,
    required String studentId,
    required String caseId,
  }) async {
    if (_apiKey == 'API_KEY_HERE') {
      debugPrint('AI Service: No API key provided, using legacy heuristic.');
      return evaluateAnswerLegacy(
          step: step,
          studentAnswer: studentAnswer,
          studentId: studentId,
          caseId: caseId);
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.0, // Zero temperature for deterministic/strict output
        ),
      );

      final prompt = '''
You are a strict automated evaluation system for dental education.
Your job is to compare a Student Answer to a Teacher Answer Key and Keywords.

DATA:
[Teacher Answer Key]: "${step.correctAnswerText}"
[Keywords]: ${step.requiredKeywords.join(', ')}
[Student Answer]: "$studentAnswer"

RULES:
1. STRICTLY closed-loop evaluation. Do NOT use external medical knowledge.
2. If the user mentions concepts found in the [Teacher Answer Key] or [Keywords], give credit.
3. If the user mentions relevant medical facts NOT in the inputs, ignore them. Do not give credit, do not penalize unless it contradicts the Key.
4. Output specific JSON.

OUTPUT JSON FORMAT:
{
  "match_score": <float 0.0 to 1.0>,
  "feedback_text": "<string, concise feedback based ONLY on missing/matching keys>",
  "is_passing": <bool, true if score >= 0.7>
}
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        String cleanedText = response.text!;
        // Strip Markdown code fences if present
        if (cleanedText.startsWith('```json')) {
          cleanedText = cleanedText
              .replaceAll(RegExp(r'^```json\s*'), '')
              .replaceAll(RegExp(r'\s*```$'), '');
        } else if (cleanedText.startsWith('```')) {
          cleanedText = cleanedText
              .replaceAll(RegExp(r'^```\s*'), '')
              .replaceAll(RegExp(r'\s*```$'), '');
        }

        final json = jsonDecode(cleanedText) as Map<String, dynamic>;
        final double score = (json['match_score'] as num).toDouble() * 100;
        final String feedback = json['feedback_text'] as String;
        // final bool isPassing = json['is_passing'] as bool; // Can use if needed later

        return InteractiveAnswer(
          id: '${step.id}_$studentId',
          caseId: caseId,
          stepId: step.id,
          studentId: studentId,
          answerText: studentAnswer,
          aiScore: score,
          aiFeedback: feedback,
          status: InteractiveAnswerStatus.evaluated,
          submittedAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('AI Evaluation Failed: $e');
    }

    // Fallback
    return evaluateAnswerLegacy(
        step: step,
        studentAnswer: studentAnswer,
        studentId: studentId,
        caseId: caseId);
  }

  /// Original heuristic-based evaluation (Legacy)
  static InteractiveAnswer evaluateAnswerLegacy({
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

    // Scoring Logic:
    // Required keywords account for 60% of the score
    // Bonus keywords account for 20%
    // Length/Effort heuristic accounts for 20%

    double score = 0.0;

    if (step.requiredKeywords.isNotEmpty) {
      final reqScore = (requiredParamsHit / step.requiredKeywords.length) * 60;
      score += reqScore;
    } else {
      score += 60;
    }

    if (step.bonusKeywords.isNotEmpty) {
      final bonusPart = (bonusHits / step.bonusKeywords.length) * 20;
      score += bonusPart;
    }

    if (studentAnswer.length > 20) {
      score += 10;
    }
    if (studentAnswer.length > 50) {
      score += 10;
    }

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
      id: '${step.id}_$studentId',
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
