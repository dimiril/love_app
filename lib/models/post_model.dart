import 'user_model.dart';

class PostModel {
  final int id;
  final String content;
  final String? image;
  int likesCount; // ✅ إزالة final لتمكين التعديل التفاؤلي (Optimistic UI)
  final int commentsCount;
  final int viewsCount;
  final DateTime createdAt;
  final UserModel user;
  bool isLiked;

  PostModel({
    required this.id,
    required this.content,
    this.image,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    required this.createdAt,
    required this.user,
    this.isLiked = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    int safeInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return PostModel(
      id: safeInt(json['id']),
      content: json['content'] ?? '',
      image: json['image'],
      likesCount: safeInt(json['likes_count']),
      commentsCount: safeInt(json['comments_count']),
      viewsCount: safeInt(json['views_count']),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isLiked: json['is_liked'] == 1 || json['is_liked'] == true,
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }

  PostModel copyWith({bool? isLiked, int? likesCount, int? commentsCount}) {
    return PostModel(
      id: id,
      content: content,
      image: image,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount,
      createdAt: createdAt,
      user: user,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
