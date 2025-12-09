import 'package:cloud_firestore/cloud_firestore.dart';
import 'interactive_models.dart';
import 'dental_specialities.dart';

enum CaseLevel { easy, medium, hard }

enum CaseVideoType { vod, live, vodWithLiveQa, youtube }

class Chapter {
  final String label;
  final int timestampSeconds;

  Chapter({required this.label, required this.timestampSeconds});

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      label: json['label'] as String,
      timestampSeconds: json['timestampSeconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'timestampSeconds': timestampSeconds,
    };
  }
}

class CaseSubtitle {
  final String language; // e.g. 'en', 'tr'
  final String label; // e.g. 'English', 'Türkçe'
  final String url;

  CaseSubtitle({
    required this.language,
    required this.label,
    required this.url,
  });

  factory CaseSubtitle.fromJson(Map<String, dynamic> json) {
    return CaseSubtitle(
      language: json['language'] as String? ?? 'en',
      label: json['label'] as String? ?? 'English',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'label': label,
      'url': url,
    };
  }
}

class CaseModel {
  final String id;
  final String weekId;
  final String title;
  final String description;
  final String specialtyKey; // Standardized Key (e.g. "endodontics")
  final CaseLevel level;
  final List<String> mediaUrls;
  final String createdBy;
  final DateTime createdAt;
  final String? teaser;
  final List<String>? preparationMaterials; // Legacy string list

  // New fields for Unified Player
  final CaseVideoType videoType;
  final String? videoUrl; // For VOD
  final String? thumbnailUrl; // For Video Thumbnail
  final String? liveStreamUrl; // For Live
  final DateTime? liveSessionStart;
  final DateTime? liveSessionEnd;
  final List<Chapter> chapters;

  // Admin & Interactive AI Fields
  final List<PrepMaterial> prepMaterials;
  final List<InteractiveStep> interactiveSteps;
  final List<CaseSubtitle> subtitles;

  CaseModel({
    required this.id,
    required this.weekId,
    required this.title,
    required this.description,
    required this.specialtyKey,
    required this.level,
    required this.mediaUrls,
    required this.createdBy,
    required this.createdAt,
    this.teaser,
    this.preparationMaterials,
    this.videoType = CaseVideoType.vod,
    this.videoUrl,
    this.thumbnailUrl,
    this.liveStreamUrl,
    this.liveSessionStart,
    this.liveSessionEnd,
    this.chapters = const [],
    this.prepMaterials = const [],
    this.interactiveSteps = const [],
    this.subtitles = const [],
  });

  // Helper to get localized label
  String get specialityLabel => DentalSpecialtyConfig.getLabel(
      DentalSpecialtyConfig.fromKey(specialtyKey),
      lang: 'tr');

  // Legacy getter alias to minimize breaking changes in UI access
  String get speciality => specialityLabel;

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    // 1. Try new standard key
    String? key = json['specialtyKey'];

    // 2. Fallback to old field
    if (key == null || key.isEmpty) {
      final oldText = json['speciality'] as String? ?? '';
      if (oldText.isNotEmpty) {
        key = DentalSpecialtyConfig.guessFromText(oldText).name;
      } else {
        key = DentalSpecialty.other.name;
      }
    }

    return CaseModel(
      id: json['id'] as String,
      weekId: json['weekId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      specialtyKey: key,
      level: CaseLevel.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => CaseLevel.medium,
      ),
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdBy: json['createdBy'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      teaser: json['teaser'] as String?,
      preparationMaterials: (json['preparationMaterials'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      videoType: CaseVideoType.values.firstWhere(
        (e) => e.name == (json['videoType'] ?? 'vod'),
        orElse: () => CaseVideoType.vod,
      ),
      videoUrl: json['videoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      liveStreamUrl: json['liveStreamUrl'] as String?,
      liveSessionStart: (json['liveSessionStart'] as Timestamp?)?.toDate(),
      liveSessionEnd: (json['liveSessionEnd'] as Timestamp?)?.toDate(),
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((e) => Chapter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      prepMaterials: (json['prepMaterials'] as List<dynamic>?)
              ?.map((e) => PrepMaterial.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      interactiveSteps: (json['interactiveSteps'] as List<dynamic>?)
              ?.map((e) => InteractiveStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subtitles: (json['subtitles'] as List<dynamic>?)
              ?.map((e) => CaseSubtitle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekId': weekId,
      'title': title,
      'description': description,
      'specialtyKey': specialtyKey, // New Standard
      'speciality':
          specialityLabel, // Keep for legacy read-only listeners if any
      'level': level.name,
      'mediaUrls': mediaUrls,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'teaser': teaser,
      'preparationMaterials': preparationMaterials,
      'videoType': videoType.name,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'liveStreamUrl': liveStreamUrl,
      'liveSessionStart': liveSessionStart != null
          ? Timestamp.fromDate(liveSessionStart!)
          : null,
      'liveSessionEnd':
          liveSessionEnd != null ? Timestamp.fromDate(liveSessionEnd!) : null,
      'chapters': chapters.map((e) => e.toJson()).toList(),
      'prepMaterials': prepMaterials.map((e) => e.toJson()).toList(),
      'interactiveSteps': interactiveSteps.map((e) => e.toJson()).toList(),
      'subtitles': subtitles.map((e) => e.toJson()).toList(),
    };
  }
}
