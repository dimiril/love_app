import 'category_model.dart';
import 'message_model.dart';

class MessageWithCategoryModel extends MessageModel {
  final CategoryModel category;

  MessageWithCategoryModel({
    required super.id,
    required super.categoryId,
    required super.isFavorite,
    required super.content,
    required this.category,
  });

  factory MessageWithCategoryModel.fromMap(Map<String, dynamic> map) {
    return MessageWithCategoryModel(
      id: map['id'],
      categoryId: map['category_id'],
      isFavorite: map['is_favorite'] == 1,
      content: map['content'],
      category: CategoryModel.fromMap(map['category']),
    );
  }
}
