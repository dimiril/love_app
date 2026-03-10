import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class TimeAgoFormatter {
  static String format(BuildContext context, DateTime dateTime) {
    final t = AppLocalizations.of(context);
    if (t == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 5) {
      return t.tr('now');
    } else if (difference.inMinutes < 1) {
      final seconds = difference.inSeconds;
      return t.tr('secondsAgo', args: {'count': seconds.toString()});
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return t.tr('minutesAgo', args: {'count': minutes.toString()});
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return t.tr('hoursAgo', args: {'count': hours.toString()});
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return t.tr('daysAgo', args: {'count': days.toString()});
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return t.tr('weeksAgo', args: {'count': weeks.toString()});
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return t.tr('monthsAgo', args: {'count': months.toString()});
    } else {
      final years = (difference.inDays / 365).floor();
      return t.tr('yearsAgo', args: {'count': years.toString()});
    }
  }
}
