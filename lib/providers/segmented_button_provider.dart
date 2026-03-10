import 'package:flutter/material.dart';

class SegmentedButtonProvider with ChangeNotifier {
  int _currentIndex = 0;
  bool _isVisible = true;

  int get currentIndex => _currentIndex;
  bool get isVisible => _isVisible;

  set currentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }


  void show() {
    if (!_isVisible) {
      _isVisible = true;
      notifyListeners();
    }
  }

  void hide() {
    if (_isVisible) {
      _isVisible = false;
      notifyListeners();
    }
  }
}
