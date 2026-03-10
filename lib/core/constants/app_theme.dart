import 'package:flutter/material.dart';

import '../../utils/dark_theme.dart';
import '../../utils/light_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => lightTheme;
  static ThemeData dark() => darkTheme;
}
