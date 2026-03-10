class CategoryModel {
  final int id;
  final int totalMsg;
  final int newMsg;
  final String name;
  final String? img;
  final String? colors;

  const CategoryModel({
    required this.id,
    required this.totalMsg,
    required this.newMsg,
    required this.name,
    this.img,
    this.colors,
  });

  CategoryModel copyWith({
    int? id,
    int? totalMsg,
    int? newMsg,
    String? name,
    String? img,
    String? colors,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      totalMsg: totalMsg ?? this.totalMsg,
      newMsg: newMsg ?? this.newMsg,
      name: name ?? this.name,
      img: img ?? this.img,
      colors: colors ?? this.colors,
    );
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      totalMsg: map['total_msg'],
      newMsg: map['new_msg'],
      name: map['name'],
      img: map['img'],
      colors: map['colors'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_msg': totalMsg,
      'new_msg': newMsg,
      'name': name,
      'img': img,
      'colors': colors,
    };
  }
}
