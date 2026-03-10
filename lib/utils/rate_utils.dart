import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/app_colors.dart';
import 'shared_pref.dart';

class RateUtils {
  static const String _lastPromptKey = 'last_rate_prompt_date';
  static const String _isRatedKey = 'is_app_rated';

  /// ✅ التحقق مما إذا كان يجب إظهار حوار التقييم (كل 48 ساعة)
  static Future<void> checkAndShowRateDialog(BuildContext context) async {
    final bool isRated = SharedPref.getBool(_isRatedKey) ?? false;
    if (isRated) return; // لا تظهر أبداً إذا قيم المستخدم

    final String? lastPromptStr = SharedPref.getString(_lastPromptKey);
    final DateTime now = DateTime.now();

    if (lastPromptStr == null) {
      // 🔹 أول مرة يفتح المستخدم التطبيق:
      // نسجل تاريخ اليوم لكي تبدأ عملية حساب الـ 48 ساعة من الآن.
      await SharedPref.setString(_lastPromptKey, now.toIso8601String());
      return;
    }

    try {
      final DateTime lastPromptDate = DateTime.parse(lastPromptStr);
      // ✅ نتحقق من مرور 48 ساعة (يومين) على الأقل
      final int hoursDifference = now.difference(lastPromptDate).inHours;

      if (hoursDifference >= 48) {
        if (context.mounted) {
          _showRateDialog(context);
        }
      }
    } catch (e) {
      // في حال وجود خطأ في قراءة التاريخ، نعيد تعيينه
      await SharedPref.setString(_lastPromptKey, now.toIso8601String());
    }
  }

  static void _showRateDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        titlePadding: const EdgeInsets.only(top: 24),
        title: const Center(
          child: Column(
            children: [
              Icon(Icons.stars_rounded, size: 60, color: Colors.amber),
              SizedBox(height: 12),
              Text("تقييم التطبيق", style: TextStyle(fontFamily: 'Kaff-black', fontSize: 18)),
            ],
          ),
        ),
        content: const Text(
          "هل يعجبك التطبيق؟ رأيك يهمنا جداً ويساعدنا على التحسين المستمر. لن يستغرق الأمر أكثر من دقيقة!",
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Kaff', fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    // إذا ضغط "لاحقاً": نسجل تاريخ اللحظة لكي يظهر بعد يومين آخرين
                    await SharedPref.setString(_lastPromptKey, DateTime.now().toIso8601String());
                    Navigator.pop(ctx);
                  },
                  child: const Text("لاحقاً", style: TextStyle(color: Colors.grey, fontFamily: 'Kaff')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // حفظ أن المستخدم قيم بنجاح (لن يظهر الحوار ثانية)
                    await SharedPref.setBool(_isRatedKey, true);
                    Navigator.pop(ctx);
                    
                    const packageName = "love.messages.romantic.whispers.heartfelt.quotes";
                    final Uri url = Uri.parse("https://play.google.com/store/apps/details?id=$packageName");
                    try {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text("تقييم الآن", style: TextStyle(fontFamily: 'Kaff', fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
