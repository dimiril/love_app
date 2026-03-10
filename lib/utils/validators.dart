import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class Validators {
  /// ===============================
  /// Helpers
  /// ===============================
  static AppLocalizations? _t(BuildContext context) {
    return AppLocalizations.of(context);
  }

  /// ===============================
  /// General
  /// ===============================

  // حقل مطلوب (عام)
  static String? required(
      BuildContext context,
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return _t(context)!.tr('requiredField');
    }
    return null;
  }

  // الحد الأدنى للأحرف
  static String? minLength(
      BuildContext context,
      String? value,
      int min,
      ) {
    if (value == null || value.trim().length < min) {
      return _t(context)
      !.tr('minLength')
          .replaceAll('{min}', min.toString());
    }
    return null;
  }

  // الحد الأقصى للأحرف (مثلاً bio)
  static String? maxLength(
      BuildContext context,
      String? value,
      int max,
      ) {
    if (value != null && value.length > max) {
      return _t(context)
      !.tr('maxLength')
          .replaceAll('{max}', max.toString());
    }
    return null;
  }

  /// ===============================
  /// Auth (Google Sign-In friendly)
  /// ===============================

  // Email (مفيد فـ edit profile)
  static String? email(
      BuildContext context,
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return _t(context)!.tr('emailRequired');
    }

    final regex =
    RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!regex.hasMatch(value.trim())) {
      return _t(context)!.tr('emailInvalid');
    }
    return null;
  }

  // Username / Name
  static String? username(
      BuildContext context,
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return _t(context)!.tr('usernameRequired');
    }

    if (value.length < 3) {
      return _t(context)!
          .tr('minLength')
          .replaceAll('{min}', '3');
    }
    return null;
  }

  /// ===============================
  /// Posts (Text / Image)
  /// ===============================

  // Post text (نص المشاركة)
  static String? postText(
      BuildContext context,
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return _t(context)!.tr('postEmpty');
    }

    if (value.length < 3) {
      return _t(context)!
          .tr('minLength')
          .replaceAll('{min}', '3');
    }
    return null;
  }

  // Post (نص أو صورة)
  static String? postTextOrImage(
      BuildContext context, {
        String? text,
        String? imagePath,
      }) {
    if ((text == null || text.trim().isEmpty) &&
        (imagePath == null || imagePath.isEmpty)) {
      return _t(context)!.tr('postNeedTextOrImage');
    }
    return null;
  }

  /// ===============================
  /// Comments & Replies
  /// ===============================

  static String? comment(
      BuildContext context,
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return _t(context)!.tr('commentEmpty');
    }
    return null;
  }

  static String? reply(
      BuildContext context,
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return _t(context)!.tr('replyEmpty');
    }
    return null;
  }

  /// ===============================
  /// Profile
  /// ===============================

  // Bio
  static String? bio(
      BuildContext context,
      String? value,
      ) {
    if (value != null && value.length > 150) {
      return _t(context)!
          .tr('maxLength')
          .replaceAll('{max}', '150');
    }
    return null;
  }

  // Image required (avatar)
  static String? imageRequired(
      BuildContext context,
      String? imagePath,
      ) {
    if (imagePath == null || imagePath.isEmpty) {
      return _t(context)!.tr('imageRequired');
    }
    return null;
  }
}