import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_icons.dart';
import '../core/constants/app_strings.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../utils/snack_bar.dart';

class LoginModal {
  static void show(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor, // ✅ خلفية ديناميكية
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          bottom: true,
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // شريط السحب العلوي
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // أيقونة القفل
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_person_rounded, size: 32, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    
                    // العناوين
                    Text(
                      t?.tr(AppStrings.loginWithGoogle) ?? "تسجيل الدخول",
                      style: TextStyle(
                        fontFamily: 'Kaff-black', 
                        fontSize: 18,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "يجب تسجيل الدخول لتتمكن من استخدام هذه الميزة والوصول لكامل خصائص التطبيق",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Kaff', 
                        fontSize: 13, 
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // زر جوجل المطور
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              final success = await authProvider.login();
                              if (success && context.mounted) {
                                Navigator.pop(context);
                                AppSnackBar.show(context, t?.tr(AppStrings.loginSuccess) ?? "تم تسجيل الدخول بنجاح");
                              }
                            },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          side: BorderSide(
                            color: isDark ? Colors.white10 : const Color(0xFFE0E0E0),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        icon: authProvider.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                          : const Icon(AppIcons.brandGoogle, size: 24, color: Colors.red),
                        label: Text(
                          t?.tr(AppStrings.loginWithGoogle) ?? "متابعة باستخدام جوجل",
                          style: const TextStyle(
                            fontFamily: "Kaff", 
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
