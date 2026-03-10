import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../routes/app_router.dart';

class AppSnackBar {
  static void _show(
      BuildContext context,
      String message, {
        required bool isError,
      }) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context) ??
        (navigatorKey.currentContext != null ? ScaffoldMessenger.of(navigatorKey.currentContext!) : null);

    scaffoldMessenger?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.start,
          style: const TextStyle(fontFamily: 'Kaff', fontSize: 12),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),

      ),
    );
  }

  static void show(BuildContext context, String message, {bool isError = false}) {
    _show(context, message, isError: isError);
  }

  static void success(BuildContext context, String key) {
    final t = AppLocalizations.of(context);
    final message = t?.tr(key) ?? key;
    _show(context, message, isError: false);
  }

  static void error(BuildContext context, String key) {
    final t = AppLocalizations.of(context);
    final message = t?.tr(key) ?? key;
    _show(context, message, isError: true);
  }
}
