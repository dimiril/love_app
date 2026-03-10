import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_icons.dart';
import '../../providers/edit_design_provider.dart';
import '../../utils/snack_bar.dart';
import '../widgets/design_canvas.dart';
import '../widgets/grid_tool_bar.dart';

class EditMessageScreen extends StatefulWidget {
  final String content;

  const EditMessageScreen({super.key, required this.content});

  @override
  State<EditMessageScreen> createState() => _EditMessageScreenState();
}

class _EditMessageScreenState extends State<EditMessageScreen> {
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EditDesignProvider>().init(widget.content);
      }
    });
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "تنبيه",
          style: TextStyle(color: Colors.white, fontFamily: 'Kaff-Black', fontSize: 18),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          "هل أنت متأكد من الخروج؟ ستفقد كافة التعديلات التي قمت بها على التصميم.",
          style: TextStyle(color: Colors.white70, fontFamily: 'Kaff', fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceAround,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("إكمال التعديل", style: TextStyle(color: Colors.grey, fontFamily: 'Kaff')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("خروج", style: TextStyle(color: Colors.white, fontFamily: 'Kaff', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _shareAsImage() async {
    try {
      final boundary =
      _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      try {
        final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

        final pngBytes = byteData!.buffer.asUint8List();

        final directory = await getTemporaryDirectory();
        final imagePath =
        File('${directory.path}/shared_design.png');

        await imagePath.writeAsBytes(pngBytes);

        const appUrl =
            "https://play.google.com/store/apps/details?id=love.messages.romantic.whispers.heartfelt.quotes";

        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: "تصميم من تطبيق مسجاتي++ ❤️\n\nحمل التطبيق من هنا 👇\n$appUrl",
        );
      } finally {
        image.dispose();
      }
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(context, "حدث خطأ في المشاركة");
    }
  }

  Future<void> openWhatsApp(BuildContext context, String message) async {
    final url = Uri.parse(
      "https://wa.me/?text=${Uri.encodeComponent(message)}",
    );

    try {
      final canLaunch = await canLaunchUrl(url);

      if (!context.mounted) return; // check مباشرة بعد await

      if (canLaunch) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        AppSnackBar.show(context, "واتساب غير مثبت على جهازك");
      }
    } catch (e) {
      if (!context.mounted) return;
      AppSnackBar.show(context, "حدث خطأ أثناء محاولة فتح واتساب");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitConfirmation();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            systemNavigationBarColor: Color(0xff0d0d0d),
            statusBarColor: Colors.black,
            systemNavigationBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.light,
          ),
          backgroundColor: Colors.black,
          elevation: 0,
          shape: Border(
              bottom: BorderSide.none
          ),
          leading: IconButton(
            onPressed: () async {
              final shouldPop = await _showExitConfirmation();
              if (shouldPop && context.mounted) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(
                AppIcons.close,
                size: 22,
                color: Colors.white
            ),
          ),
          title: const Text("المصمم الاحترافي",
              style: TextStyle(fontFamily: 'Kaff', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(
                onPressed: () => openWhatsApp(context, widget.content),
                icon: Icon(AppIcons.whatsapp, color: Colors.white)),
            IconButton(
                onPressed: _shareAsImage,
                icon: Icon(AppIcons.share, color: Colors.white)),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: true,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: RepaintBoundary(
                    key: _globalKey,
                    child: const DesignCanvas(),
                  ),
                ),
              ),
              const GridToolBar(),
            ],
          ),
        ),
      ),
    );
  }
}
