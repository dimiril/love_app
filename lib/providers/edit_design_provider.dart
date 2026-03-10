import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/edit_design_state.dart';
import '../utils/editable_item.dart';

class EditDesignProvider with ChangeNotifier {
  EditDesignState _state = const EditDesignState();

  EditDesignState get state => _state;

  void init(String content) {
    _state = const EditDesignState().copyWith(
      content: content,
      position: Offset.zero,
      scale: 1.0,
      rotation: 0.0,
      overlays: [],
      fontSize: 20.0,
      textColor: Colors.white,
      bgColor: Colors.black,
      isGradient: false,
      bgOpacity: 1.0,
      fontWeight: FontWeight.normal,
      fontStyle: FontStyle.normal,
    );
    notifyListeners();
  }

  void _emit(EditDesignState newState) {
    _state = newState;
    notifyListeners();
  }

  // --- أدوات النص الأساسي ---
  void setContent(String value) => _emit(_state.copyWith(content: value));
  void setFontSize(double v) => _emit(_state.copyWith(fontSize: v));
  void setTextColor(Color v) => _emit(_state.copyWith(textColor: v));
  void setBgColor(Color v) => _emit(_state.copyWith(bgColor: v, isGradient: false, bgImage: null));
  void setBgImage(File? v) => _emit(_state.copyWith(bgImage: v, bgOpacity: 0.5, isGradient: false));
  void setTextAlign(TextAlign v) => _emit(_state.copyWith(textAlign: v));
  void updatePosition(Offset delta) => _emit(_state.copyWith(position: _state.position + delta));
  void updateScale(double factor) => _emit(_state.copyWith(scale: (_state.scale * factor).clamp(0.5, 5.0)));
  void updateRotation(double angle) => _emit(_state.copyWith(rotation: _state.rotation + angle));
  
  void toggleShadow() => _emit(_state.copyWith(hasShadow: !_state.hasShadow));
  void setShadowColor(Color v) => _emit(_state.copyWith(shadowColor: v));
  void setShadowBlurRadius(double v) => _emit(_state.copyWith(shadowBlurRadius: v));
  void setShadowOffset(Offset v) => _emit(_state.copyWith(shadowOffset: v));
  
  void toggleBold() {
    final next = _state.fontWeight == FontWeight.bold ? FontWeight.normal : FontWeight.bold;
    _emit(_state.copyWith(fontWeight: next));
  }

  void toggleItalic() {
    final next = _state.fontStyle == FontStyle.italic ? FontStyle.normal : FontStyle.italic;
    _emit(_state.copyWith(fontStyle: next));
  }

  void setBorderRadius(double v) => _emit(_state.copyWith(borderRadius: v));
  void setLineHeight(double v) => _emit(_state.copyWith(lineHeight: v));
  void setBgOpacity(double v) => _emit(_state.copyWith(bgOpacity: v));
  void setBorderWidth(double v) => _emit(_state.copyWith(borderWidth: v));
  void setBorderColor(Color v) => _emit(_state.copyWith(borderColor: v));
  void setSelectedFont(String v) => _emit(_state.copyWith(selectedFont: v));

  void resetTransform() {
    _emit(_state.copyWith(position: Offset.zero, scale: 1.0, rotation: 0.0));
  }

  // --- أدوات التدرج اللوني (Gradient) ---
  void setGradient(List<Color> colors) {
    _emit(_state.copyWith(gradientColors: colors, isGradient: true, bgImage: null));
  }

  void toggleGradient() => _emit(_state.copyWith(isGradient: !_state.isGradient));

  // --- أدوات الملصقات (Overlays) ---
  void addOverlay(String content, bool isText) {
    final updated = List<EditableItem>.from(_state.overlays)
      ..add(EditableItem(content: content, isText: isText, position: const Offset(150, 150)));
    _emit(_state.copyWith(overlays: updated));
  }

  void removeOverlay(EditableItem item) {
    final updated = List<EditableItem>.from(_state.overlays)..remove(item);
    _emit(_state.copyWith(overlays: updated));
  }

  void updateOverlayTransform(int index, Offset positionDelta, double scaleFactor, double rotationDelta) {
    if (index >= 0 && index < _state.overlays.length) {
      final updatedList = List<EditableItem>.from(_state.overlays);
      final item = updatedList[index];
      updatedList[index] = item.copyWith(
        position: item.position + positionDelta,
        scale: (item.scale * scaleFactor).clamp(0.3, 4.0),
        rotation: item.rotation + rotationDelta,
      );
      _emit(_state.copyWith(overlays: updatedList));
    }
  }

  void updateOverlay() => notifyListeners();
}
