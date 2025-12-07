class PrepMaterial {
  final String id;
  final String type; // 'pdf', 'link'
  final String title;
  final String url;

  PrepMaterial({
    required this.id,
    required this.type,
    required this.title,
    required this.url,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'url': url,
      };

  factory PrepMaterial.fromJson(Map<String, dynamic> json) {
    return PrepMaterial(
      id: json['id'] ?? '',
      type: json['type'] ?? 'link',
      title: json['title'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class InteractiveStep {
  final String id;
  final int pauseAtSeconds;
  final String questionText;
  final String correctAnswerText;
  final List<String> requiredKeywords;
  final List<String> bonusKeywords;

  InteractiveStep({
    required this.id,
    required this.pauseAtSeconds,
    required this.questionText,
    required this.correctAnswerText,
    required this.requiredKeywords,
    required this.bonusKeywords,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pauseAtSeconds': pauseAtSeconds,
        'questionText': questionText,
        'correctAnswerText': correctAnswerText,
        'requiredKeywords': requiredKeywords,
        'bonusKeywords': bonusKeywords,
      };

  factory InteractiveStep.fromJson(Map<String, dynamic> json) {
    return InteractiveStep(
      id: json['id'] ?? '',
      pauseAtSeconds: json['pauseAtSeconds'] ?? 0,
      questionText: json['questionText'] ?? '',
      correctAnswerText: json['correctAnswerText'] ?? '',
      requiredKeywords: List<String>.from(json['requiredKeywords'] ?? []),
      bonusKeywords: List<String>.from(json['bonusKeywords'] ?? []),
    );
  }
}

enum InteractiveAnswerStatus { pending, evaluated, overridden }

class InteractiveAnswer {
  final String id;
  final String caseId;
  final String stepId;
  final String studentId;
  final String answerText;
  final double? aiScore;
  final String? aiFeedback;
  final double? teacherScore;
  final InteractiveAnswerStatus status;
  final DateTime submittedAt;

  InteractiveAnswer({
    required this.id,
    required this.caseId,
    required this.stepId,
    required this.studentId,
    required this.answerText,
    this.aiScore,
    this.aiFeedback,
    this.teacherScore,
    required this.status,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'caseId': caseId,
        'stepId': stepId,
        'studentId': studentId,
        'answerText': answerText,
        'aiScore': aiScore,
        'aiFeedback': aiFeedback,
        'teacherScore': teacherScore,
        'status': status.name,
        'submittedAt': submittedAt.toIso8601String(),
      };

  factory InteractiveAnswer.fromJson(Map<String, dynamic> json) {
    return InteractiveAnswer(
      id: json['id'] ?? '',
      caseId: json['caseId'] ?? '',
      stepId: json['stepId'] ?? '',
      studentId: json['studentId'] ?? '',
      answerText: json['answerText'] ?? '',
      aiScore: (json['aiScore'] as num?)?.toDouble(),
      aiFeedback: json['aiFeedback'],
      teacherScore: (json['teacherScore'] as num?)?.toDouble(),
      status: InteractiveAnswerStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InteractiveAnswerStatus.pending,
      ),
      submittedAt: DateTime.parse(
          json['submittedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
