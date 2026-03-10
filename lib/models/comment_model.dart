import 'user_model.dart';

class CommentModel {
  final int id;
  final int commentableId;
  final String comment;
  final int repliesCount;
  final DateTime createdAt;
  final UserModel user;

  CommentModel({
    required this.id,
    required this.commentableId,
    required this.comment,
    required this.repliesCount,
    required this.createdAt,
    required this.user,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: int.parse(json['id'].toString()),
      commentableId: int.parse(json['commentable_id'].toString()),
      comment: json['comment'] ?? '',
      repliesCount: int.parse(json['replies_count'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      user: UserModel.fromJson(json['user']),
    );
  }
}