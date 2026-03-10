import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.bgDark,
  fontFamily: 'Kaff',
  appBarTheme: const AppBarTheme(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),

    backgroundColor: AppColors.appBarDark,
    surfaceTintColor: Colors.transparent,
    scrolledUnderElevation: 2,
    centerTitle: false,
    elevation: 2,
    shadowColor: Color(0xff333333),
    shape: Border(
      bottom: BorderSide(color: Color(0xff111111), width: .5),
    ),
    iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
    titleTextStyle: TextStyle(color: AppColors.textPrimaryDark, fontFamily: 'Kaff-Black', fontSize: 16),
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardDark,
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: AppColors.textPrimaryDark),
    bodyMedium: TextStyle(color: AppColors.textSecondaryDark),
  ),
);
