class BannerModel {
  final String id;
  final String imageUrl;
  final String? title;
  final String? link;
  final String type; // e.g., 'case', 'announcement', 'external'
  final bool isActive;
  final int order;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.title,
    this.link,
    required this.type,
    required this.isActive,
    required this.order,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      title: json['title'] as String?,
      link: json['link'] as String?,
      type: json['type'] as String? ?? 'announcement',
      isActive: json['isActive'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'title': title,
      'link': link,
      'type': type,
      'isActive': isActive,
      'order': order,
    };
  }
}
