import 'package:flutter/material.dart';

class EditableItem {
  final String content;
  final bool isText;
  final Offset position;
  final double scale;
  final double rotation;

  const EditableItem({
    required this.content,
    required this.isText,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  EditableItem copyWith({
    String? content,
    bool? isText,
    Offset? position,
    double? scale,
    double? rotation,
  }) {
    return EditableItem(
      content: content ?? this.content,
      isText: isText ?? this.isText,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}