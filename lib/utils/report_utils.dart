import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/report_service.dart';
import 'snack_bar.dart';

class ReportUtils {
  static void showReportSheet(
      BuildContext context,
      String reportableId,
      String reportableType, {
        Color backgroundColor = Colors.white,
        Color textColor = Colors.black87,
        Color iconColor = Colors.black87,
        Color dividerColor = const Color(0xFFE0E0E0),
      }) {
    final t = AppLocalizations.of(context);
    final authProvider = context.read<AuthProvider>();
    final int currentUserId = authProvider.isAuthenticated ? authProvider.user!.id : 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // تحديد العنوان بناءً على النوع
    String title = t?.tr(AppStrings.reportContent) ?? "الإبلاغ عن المحتوى";
    if (reportableType == 'chat') title = t?.tr(AppStrings.reportChat) ?? "الإبلاغ عن المحادثة";
    if (reportableType == 'user') title = t?.tr(AppStrings.reportUser) ?? "الإبلاغ عن المستخدم";

    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor == const Color(0xff333333) ? backgroundColor : isDark ? AppColors.bgDark : AppColors.bgLight,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (innerContext) {
        return SafeArea(
          top: false,
          bottom: true,
          child: Container(
            padding: const EdgeInsets.only(top: 12, bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: dividerColor, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(fontFamily: 'Kaff-black', fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 10),
                
                if (reportableType == 'video') ...[
                  _reportOption(context, innerContext, reportableId, reportableType, currentUserId, t?.tr(AppStrings.reportCopyright) ?? "انتهاك حقوق النشر", Icons.copyright, t, textColor, iconColor),
                  _reportOption(context, innerContext, reportableId, reportableType, currentUserId, t?.tr(AppStrings.reportInappropriate) ?? "محتوى غير لائق", Icons.visibility_off, t, textColor, iconColor),
                ],

                if (reportableType == 'user') ...[
                  _reportOption(context, innerContext, reportableId, reportableType, currentUserId, t?.tr(AppStrings.reportFakeAccount) ?? "حساب زائف أو انتحال شخصية", Icons.person_search, t, textColor, iconColor),
                  _reportOption(context, innerContext, reportableId, reportableType, currentUserId, t?.tr(AppStrings.reportScam) ?? "احتيال أو تضليل", Icons.monetization_on_outlined, t, textColor, iconColor),
                ],

                if (reportableType == 'chat') ...[
                  _reportOption(context, innerContext, reportableId, reportableType, currentUserId, t?.tr(AppStrings.reportHarassment) ?? "تحرش أو مضايقة", Icons.do_not_disturb_on_total_silence, t, textColor, iconColor),
                ],

                // خيارات مشتركة
                _reportOption(context, innerContext, reportableId, reportableType, currentUserId, t?.tr(AppStrings.reportSpam) ?? "محتوى مزعج أو سبام", Icons.report_gmailerrorred, t, textColor, iconColor),
                _reportOption(context, innerContext, reportableId, reportableType, currentUserId, t?.tr(AppStrings.reportHateSpeech) ?? "عنف أو كراهية", Icons.warning_amber, t, textColor, iconColor),
                _reportOption(context, innerContext, reportableId, reportableType, currentUserId, t?.tr(AppStrings.reportOther) ?? "سبب آخر", Icons.info_outline, t, textColor, iconColor),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _reportOption(BuildContext context, BuildContext innerContext, String reportableId, String reportableType, int userId, String reason, IconData icon, AppLocalizations? t, Color textColor, Color iconColor) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(reason, style: TextStyle(fontFamily: 'Kaff', fontSize: 12, color: textColor)),
      minTileHeight: 45,
      onTap: () async {
        Navigator.pop(innerContext);
        final reportService = ReportService();
        final id = int.tryParse(reportableId) ?? 0;
        final success = await reportService.sendReport(userId: userId, reportableId: id, reportableType: reportableType, reason: reason);
        if (!context.mounted) return;
        if (success) {
          AppSnackBar.show(context, t?.tr(AppStrings.thanksForReport) ?? "شكراً لك، تم إرسال البلاغ");
        } else {
          AppSnackBar.show(context, "فشل إرسال البلاغ", isError: true);
        }
      },
    );
  }
}
