import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_strings.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/login_modal.dart';
import '../../utils/snack_bar.dart';
import '../widgets/app_circle_avatar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DatabaseProvider>().updateCacheSize();
    });
  }

  /// ✅ دالة فتح البريد الإلكتروني المطورة والمتوافقة مع Android 15
  Future<void> openEmail(BuildContext context) async {
    const String email = 'dimrirl1@gmail.com';
    final String subject = Uri.encodeComponent('طلب مساعدة من التطبيق');
    final String body = Uri.encodeComponent('مرحبا، أحتاج إلى مساعدة بخصوص...');

    final Uri emailUri = Uri.parse("mailto:$email?subject=$subject&body=$body");

    try {
      // محاولة الفتح مباشرة باستخدام وضع التطبيقات الخارجية
      final bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalNonBrowserApplication,
      );

      if (!launched) {
        throw 'Could not launch';
      }
    } catch (e) {
      try {
        await launchUrl(
          Uri.parse("mailto:$email"),
          mode: LaunchMode.externalNonBrowserApplication,
        );
      } catch (e2) {
        // ✅ تحقق من أن الـ context مازال موجودًا
        if (!context.mounted) return;

        // نسخ البريد الإلكتروني للحافظة إذا لم يوجد تطبيق بريد
        await Clipboard.setData(const ClipboardData(text: email));
        AppSnackBar.show(context, "لم يتم العثور على تطبيق بريد، تم نسخ الإيميل للمراسلة يدوياً");
      }
    }
  }

  Future<void> shareApp() async {
    const packageName = "love.messages.romantic.whispers.heartfelt.quotes";
    final String appLink = "https://play.google.com/store/apps/details?id=$packageName";
    await Share.share("حمل التطبيق الآن 👇\n$appLink");
  }

  Future<void> rateApp(BuildContext context) async {
    const packageName = "love.messages.romantic.whispers.heartfelt.quotes";
    final Uri playStoreUri = Uri.parse("https://play.google.com/store/apps/details?id=$packageName");
    try {
      await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) AppSnackBar.show(context, "تعذر فتح المتجر حالياً");
    }
  }

  Future<void> openPrivacyPolicy(BuildContext context) async {
    final Uri url = Uri.parse("https://sites.google.com/view/love-messages-arabic/privacy-ar");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) AppSnackBar.show(context, "تعذر فتح رابط الخصوصية");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(AppIcons.arrowRight, size: 22, color: theme.appBarTheme.iconTheme?.color),
        ),
        title: Text(t?.tr(AppStrings.settings) ?? "الإعدادات",
          style: theme.appBarTheme.titleTextStyle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (authProvider.isAuthenticated && user != null) ...[
              _buildProfileCard(context, user),
              const SizedBox(height: 24),
            ],

            _buildSectionTitle("الحساب والأمان"),
            _buildSettingsTile(
              context,
              title: "إعدادات الخصوصية",
              icon: AppIcons.privacy,
              onTap: () {
                if (authProvider.isAuthenticated) {
                  Navigator.pushNamed(context, AppRouter.privacySettings);
                } else {
                  AppSnackBar.show(context, "يرجى تسجيل الدخول أولاً", isError: true);
                }
              },
            ),
            _buildSettingsTile(
              context,
              title: t?.tr(AppStrings.favorite) ?? "المفضلة",
              icon: AppIcons.favorite,
              onTap: () => Navigator.pushNamed(context, AppRouter.favorite),
            ),
            _buildSettingsTile(
              context,
              title: "أتابعهم",
              icon: AppIcons.userFollow,
              onTap: () {
                if (authProvider.isAuthenticated) {
                  Navigator.pushNamed(context, AppRouter.userList, arguments: {
                    'userId': user!.id,
                    'title': "أتابعهم",
                    'isFollowers': false,
                  });
                } else {
                  AppSnackBar.show(context, "يرجى تسجيل الدخول أولاً", isError: true);
                }
              },
            ),
            _buildSettingsTile(
              context,
              title: "المتابعون",
              icon: AppIcons.userFollow,
              onTap: () {
                if (authProvider.isAuthenticated) {
                  Navigator.pushNamed(context, AppRouter.userList, arguments: {
                    'userId': user!.id,
                    'title': "المتابعون",
                    'isFollowers': true,
                  });
                } else {
                  AppSnackBar.show(context, "يرجى تسجيل الدخول أولاً", isError: true);
                }
              },
            ),
            _buildSettingsTile(
              context,
              title: t?.tr(AppStrings.messages) ?? "الرسائل",
              icon: AppIcons.posts,
              onTap: () {
                if (authProvider.isAuthenticated) {
                  Navigator.pushNamed(context, AppRouter.privateInbox);
                } else {
                  AppSnackBar.show(context, "يرجى تسجيل الدخول أولاً", isError: true);
                }
              },
            ),
            const SizedBox(height: 8),
            _buildSectionTitle("تفاعل"),
            _buildSettingsTile(
              context,
              title: "تواصل معنا عبر الإيميل",
              icon: AppIcons.headset,
              onTap: () => openEmail(context),
            ),
            _buildSettingsTile(
              context,
              title: "صفحتنا على الفيسبوك",
              icon: AppIcons.facebook,
              onTap: () {},
            ),
            _buildSettingsTile(
              context,
              title: "قيم التطبيق",
              icon: AppIcons.star,
              onTap: () => rateApp(context),
            ),

            _buildSettingsTile(
              context,
              title: "إدعمنا بنشر التطبيق مع أصدقائك",
              icon: AppIcons.share,
              onTap: () => shareApp(),
            ),
            const SizedBox(height: 8),
            _buildSectionTitle("التطبيق"),
            _buildSettingsTile(
              context,
              title: "سياسة الخصوصية",
              icon: AppIcons.privacy,
              onTap: () => openPrivacyPolicy(context),
            ),
            _buildSettingsTile(
              context,
              title: "إصدار التطبيق",
              subTitle: const Text("2.0.0", style: TextStyle(fontSize: 11, fontFamily: 'Kaff')),
              icon: Icons.info_outline,
              onTap: () {},
            ),
            
            Selector<DatabaseProvider, String>(
              selector: (_, provider) => provider.cacheSize,
              builder: (context, cacheSize, _) {
                return _buildSettingsTile(
                  context,
                  title: "مسح ذاكرة التخزين المؤقت",
                  subTitle: Text(cacheSize,
                    style: const TextStyle(fontFamily: "Kaff", fontSize: 10, color: Colors.red)),
                  icon: AppIcons.trash,
                  onTap: () async {
                    await context.read<DatabaseProvider>().clearAppCache();
                    if (context.mounted) AppSnackBar.show(context, "تم مسح ذاكرة التخزين المؤقت");
                  },
                );
              },
            ),

            const SizedBox(height: 32),
            authProvider.isAuthenticated
              ? _buildLogoutButton(context, authProvider)
              : _buildLoginButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, user) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 10)]
      ),
      child: Row(
        children: [
          AppCircleAvatar(imageUrl: user.photoUrl, radius: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
                Text(user.username != null ? "@${user.username}" : "",
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(AppIcons.edit, color: AppColors.primary),
            onPressed: () => Navigator.pushNamed(context, AppRouter.editProfile),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildSettingsTile(
      BuildContext context, {
        required String title,
        Widget? subTitle,
        required IconData icon,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: TextStyle(fontSize: 14, fontFamily: 'Kaff', color: theme.textTheme.bodyLarge?.color)),
        subtitle: subTitle,
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider auth) {
    return ElevatedButton.icon(
      onPressed: () => auth.logout(context),
      icon: const Icon(Icons.logout, color: Colors.white),
      label: const Text("تسجيل الخروج", style: TextStyle(color: Colors.white, fontFamily: 'Kaff-Black')),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ElevatedButton.icon(
      onPressed: () => LoginModal.show(context),
      icon: const Icon(Icons.login, color: Colors.white),
      label: Text(t?.tr(AppStrings.loginWithGoogle) ?? "تسجيل الدخول", 
        style: const TextStyle(color: Colors.white, fontFamily: 'Kaff-Black')),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
