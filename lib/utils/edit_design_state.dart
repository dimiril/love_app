import 'dart:io';
import 'package:flutter/material.dart';

import 'editable_item.dart';

@immutable
class EditDesignState {
  final String content;
  final double fontSize;
  final Color textColor;
  final Color bgColor;
  final File? bgImage;
  final TextAlign textAlign;
  final bool hasShadow;

  final Offset position;
  final double scale;
  final double rotation;

  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;

  final FontWeight fontWeight;
  final FontStyle fontStyle; // ✅ إضافة FontStyle
  final double borderRadius;
  final double lineHeight;
  final double bgOpacity;
  final double borderWidth;
  final Color borderColor;
  final String selectedFont;

  final List<EditableItem> overlays;

  // Gradient properties
  final bool isGradient;
  final List<Color> gradientColors;
  final Alignment gradientBegin;
  final Alignment gradientEnd;

  const EditDesignState({
    this.content = "",
    this.fontSize = 22,
    this.textColor = Colors.white,
    this.bgColor = Colors.black,
    this.bgImage,
    this.textAlign = TextAlign.center,
    this.hasShadow = false,
    this.position = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.shadowColor = Colors.black45,
    this.shadowBlurRadius = 10,
    this.shadowOffset = const Offset(2, 2),
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal, // ✅ افتراضي عادي
    this.borderRadius = 16,
    this.lineHeight = 1.4,
    this.bgOpacity = 1.0,
    this.borderWidth = 0.0,
    this.borderColor = Colors.transparent,
    this.selectedFont = 'Kaff',
    this.overlays = const [],
    this.isGradient = false,
    this.gradientColors = const [Colors.blue, Colors.purple],
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
  });

  EditDesignState copyWith({
    String? content,
    double? fontSize,
    Color? textColor,
    Color? bgColor,
    File? bgImage,
    TextAlign? textAlign,
    bool? hasShadow,
    Offset? position,
    double? scale,
    double? rotation,
    Color? shadowColor,
    double? shadowBlurRadius,
    Offset? shadowOffset,
    FontWeight? fontWeight,
    FontStyle? fontStyle, // ✅ إضافة هنا
    double? borderRadius,
    double? lineHeight,
    double? bgOpacity,
    double? borderWidth,
    Color? borderColor,
    String? selectedFont,
    List<EditableItem>? overlays,
    bool? isGradient,
    List<Color>? gradientColors,
    Alignment? gradientBegin,
    Alignment? gradientEnd,
  }) {
    return EditDesignState(
      content: content ?? this.content,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      bgColor: bgColor ?? this.bgColor,
      bgImage: bgImage ?? this.bgImage,
      textAlign: textAlign ?? this.textAlign,
      hasShadow: hasShadow ?? this.hasShadow,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle, // ✅ إضافة هنا
      borderRadius: borderRadius ?? this.borderRadius,
      lineHeight: lineHeight ?? this.lineHeight,
      bgOpacity: bgOpacity ?? this.bgOpacity,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      selectedFont: selectedFont ?? this.selectedFont,
      overlays: overlays ?? this.overlays,
      isGradient: isGradient ?? this.isGradient,
      gradientColors: gradientColors ?? this.gradientColors,
      gradientBegin: gradientBegin ?? this.gradientBegin,
      gradientEnd: gradientEnd ?? this.gradientEnd,
    );
  }
}
