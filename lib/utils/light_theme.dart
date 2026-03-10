import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.bgLight,
  fontFamily: 'Kaff',
  appBarTheme: const AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.bgLight,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    backgroundColor: AppColors.appBarLight,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 2,
    centerTitle: false,
    elevation: 2,
    shadowColor: Color(0xfffafafa),
    shape: Border(
      bottom: BorderSide(color: Color(0xffd4d4d6), width: .5),
    ),
    iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
    titleTextStyle: TextStyle(color: AppColors.textPrimaryLight, fontFamily: 'Kaff-Black', fontSize: 16),
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardLight,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: AppColors.textPrimaryLight),
    bodyMedium: TextStyle(color: AppColors.textSecondaryLight),
  ),
);
