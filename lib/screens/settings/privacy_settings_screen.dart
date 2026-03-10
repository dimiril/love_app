import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/user_service.dart';
import '../../utils/snack_bar.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _chatEnabled = true;
  bool _notificationsEnabled = true;
  bool _followEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _chatEnabled = user.chatEnabled;
      _notificationsEnabled = user.notificationsEnabled;
      _followEnabled = user.followEnabled;
    }
  }

  void _saveSettings() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user == null) return;

    setState(() => _isLoading = true);

    final updatedUser = await UserService().updatePrivacySettings(
      userId: authProvider.user!.id,
      chatEnabled: _chatEnabled,
      notificationsEnabled: _notificationsEnabled,
      followEnabled: _followEnabled,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (updatedUser != null) {
      authProvider.updateUserLocal(updatedUser);
      AppSnackBar.show(context, "تم حفظ إعدادات الخصوصية بنجاح");
    } else {
      AppSnackBar.show(context, "فشل حفظ الإعدادات", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("الإعدادات والتفضيلات", style: TextStyle(fontFamily: 'Kaff-Black', fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(AppIcons.arrowRight, size: 22, color: theme.appBarTheme.iconTheme?.color),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        children: [
          _buildSectionHeader("المظهر واللغة"),
          _buildSwitchCard(
            theme,
            title: "الوضع الداكن",
            subtitle: "تبديل المظهر بين الوضع الفاتح والداكن",
            value: themeProvider.isDark,
            onChanged: (val) => themeProvider.toggleTheme(),
            icon: Icons.dark_mode_outlined,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader("الخصوصية والتواصل"),
          _buildSwitchCard(
            theme,
            title: "السماح بالمراسلة",
            subtitle: "تمكين الآخرين من إرسال رسائل خاصة لك",
            value: _chatEnabled,
            onChanged: (val) => setState(() => _chatEnabled = val),
            icon: Icons.chat_bubble_outline_rounded,
          ),
          const SizedBox(height: 12),
          _buildSwitchCard(
            theme,
            themeColor: Colors.blue,
            title: "السماح بالمتابعة",
            subtitle: "تمكين الآخرين من متابعة حسابك",
            value: _followEnabled,
            onChanged: (val) => setState(() => _followEnabled = val),
            icon: Icons.person_add_outlined,
          ),
          const SizedBox(height: 12),
          _buildSwitchCard(
            theme,
            themeColor: Colors.orange,
            title: "التنبيهات",
            subtitle: "تلقي إشعارات فورية عند وصول جديد",
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
            icon: Icons.notifications_none_rounded,
          ),

          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              textStyle: const TextStyle(fontFamily: 'Kaff-Black', fontSize: 15),
            ),
            child: const Text("حفظ الإعدادات"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Kaff-Black',
            fontSize: 13,
            color: AppColors.primary,
          )
      ),
    );
  }

  Widget _buildSwitchCard(ThemeData theme, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    Color? themeColor,
  }) {
    final color = themeColor ?? AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: TextStyle(fontFamily: 'Kaff', fontWeight: FontWeight.bold, fontSize: 14, color: theme.textTheme.bodyLarge?.color)),
        subtitle: Text(subtitle, style: TextStyle(fontFamily: 'Kaff', fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: color,
        ),
      ),
    );
  }

}