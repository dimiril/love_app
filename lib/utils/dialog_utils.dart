import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class DialogUtils {
  static void showTextSizeDialog(
      BuildContext context,
      ValueNotifier<double> textSizeNotifier,
      {
        double min = 12,
        double max = 30,
        double defaultValue = 14,
      }
      ) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
          surfaceTintColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            "حجم الخط",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Kaff',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: textSizeNotifier,
                builder: (context, currentSize, _) {
                  return Slider(
                    value: currentSize,
                    min: min,
                    max: max,
                    activeColor: AppColors.primary,
                    label: currentSize.round().toString(),
                    onChanged: (value) => textSizeNotifier.value = value,
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "موافق",
                style: TextStyle(
                  fontFamily: 'Kaff',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => textSizeNotifier.value = 14.0,
              child: const Text(
                "استعادة الافتراضي",
                style: TextStyle(
                  fontFamily: 'Kaff',
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
