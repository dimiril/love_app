import 'user_model.dart';

class VideoModel {
  final String id;
  final String title;
  final String videoUrl;
  final String thumbnail;
  int viewsCount;
  int likesCount;
  final DateTime createdAt;
  final UserModel user;

  VideoModel({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.thumbnail,
    required this.viewsCount,
    required this.likesCount,
    required this.createdAt,
    required this.user,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      videoUrl: json['video_url'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      viewsCount: int.tryParse(json['views_count']?.toString() ?? '0') ?? 0,
      likesCount: int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }
}
