import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/edit_design_provider.dart';
import 'action_icon.dart';

class GridToolBar extends StatelessWidget {
  const GridToolBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<EditDesignProvider>();
    final tools = [
      {'icon': Icons.format_bold_rounded, 'label': 'عريض', 'onTap': () => provider.toggleBold()},
      {'icon': Icons.format_italic_rounded, 'label': 'مائل', 'onTap': () => provider.toggleItalic()},
      {'icon': AppIcons.edit, 'label': 'تعديل', 'onTap': () => _showEditContentDialog(context)},
      {'icon': AppIcons.txt, 'label': 'نص +', 'onTap': () => _addTextOverlay(context)},
      {'icon': AppIcons.stickers, 'label': 'ملصق', 'onTap': () => _showStickerPicker(context)},
      {'icon': AppIcons.photoPlus, 'label': 'خلفية', 'onTap': () => _pickImage(context)},
      {'icon': AppIcons.palette, 'label': 'الألوان', 'onTap': () => _showBgPicker(context)},
      {'icon': AppIcons.gradienter, 'label': 'تدرج', 'onTap': () => _showGradientPicker(context)},
      {'icon': AppIcons.typeface, 'label': 'الخط', 'onTap': () => _showFontPicker(context)},
      {'icon': AppIcons.textColor, 'label': 'اللون', 'onTap': () => _showTextColorPicker(context)},
      {'icon': AppIcons.textSize, 'label': 'الحجم', 'onTap': () => _showFontSizePicker(context)},
      {'icon': AppIcons.layers, 'label': 'الشفافية', 'onTap': () => _showOpacityPicker(context)},
      {'icon': AppIcons.alignCenter, 'label': 'المحاذاة', 'onTap': () => _toggleAlign(context)},
      {'icon': AppIcons.restore, 'label': 'إعادة ضبط', 'onTap': () => provider.resetTransform()},
      {'icon': AppIcons.shadow, 'label': 'الظل', 'onTap': () => _showShadowPicker(context)},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      decoration: const BoxDecoration(
          color: Color(0xff0d0d0d),
          border: Border(top: BorderSide(color: Color(0xff1e1e1e))),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -3))]),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: tools.length,
        itemBuilder: (ctx, index) => ActionIcon(
          icon: tools[index]['icon'] as IconData,
          label: tools[index]['label'] as String,
          onTap: tools[index]['onTap'] as VoidCallback,
        ),
      ),
    );
  }

  void _showEditContentDialog(BuildContext context) {
    final prov = context.read<EditDesignProvider>();
    final controller = TextEditingController(text: prov.state.content);

    _showSheet(context, "تعديل محتوى الرسالة", Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(color: Colors.white, fontFamily: 'Kaff', fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding: const EdgeInsets.all(16),
          ),
          autofocus: true,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                prov.setContent(controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
            ),
            child: const Text("تحديث التصميم", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Kaff')),
          ),
        )
      ],
    ));
  }

  void _showGradientPicker(BuildContext context) {
    final prov = context.read<EditDesignProvider>();
    final List<List<Color>> gradientPresets = [
      [Colors.blue, Colors.purple],
      [Colors.orange, Colors.red],
      [Colors.green, Colors.teal],
      [Colors.pink, Colors.deepOrange],
      [Colors.indigo, Colors.cyan],
      [Colors.black87, Colors.grey],
      [const Color(0xff833ab4), const Color(0xfffd1d1d), const Color(0xfffcb045)],
      [const Color(0xff00b09b), const Color(0xff96c93d)],
      [const Color(0xff4facfe), const Color(0xff00f2fe)],
    ];

    _showSheet(context, "اختر تدرجاً لونياً", GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: gradientPresets.length,
      itemBuilder: (ctx, index) => InkWell(
        onTap: () {
          prov.setGradient(gradientPresets[index]);
          Navigator.pop(context);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(colors: gradientPresets[index]),
          ),
        ),
      ),
    ));
  }

  void _addTextOverlay(BuildContext context) {
    final prov = context.read<EditDesignProvider>();
    _showSheet(context, "أضف نصاً إضافياً", TextField(
      style: const TextStyle(color: Colors.white, fontFamily: 'Kaff'),
      decoration: InputDecoration(
        hintText: "اكتب هنا...",
        hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      autofocus: true,
      onSubmitted: (val) {
        if (val.isNotEmpty) {
          prov.addOverlay(val, true);
          Navigator.pop(context);
        }
      },
    ));
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && context.mounted) {
      context.read<EditDesignProvider>().setBgImage(File(pickedFile.path));
    }
  }

  void _showStickerPicker(BuildContext context) {
    final stickers = List.generate(15, (index) => 'assets/stickers/${index + 1}.png');
    _showSheet(context, "اختر ملصقاً", GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: stickers.length,
      itemBuilder: (ctx, index) => InkWell(
        onTap: () {
          context.read<EditDesignProvider>().addOverlay(stickers[index], false);
          Navigator.pop(context);
        },
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.all(4),
          child: Image.asset(stickers[index], fit: BoxFit.contain),
        ),
      ),
    ));
  }

  void _showFontSizePicker(BuildContext context) {
    _showSheet(context, "حجم الخط", Selector<EditDesignProvider, double>(
      selector: (_, p) => p.state.fontSize,
      builder: (ctx, val, _) => Slider(
          value: val,
          min: 14,
          max: 60,
          activeColor: AppColors.primary,
          onChanged: (v) => context.read<EditDesignProvider>().setFontSize(v)
      ),
    ));
  }

  void _showOpacityPicker(BuildContext context) {
    _showSheet(context, "شفافية الخلفية", Selector<EditDesignProvider, double>(
      selector: (_, p) => p.state.bgOpacity,
      builder: (ctx, val, _) => Slider(
          value: val,
          min: 0.0,
          max: 1.0,
          activeColor: AppColors.primary,
          onChanged: (v) => context.read<EditDesignProvider>().setBgOpacity(v)
      ),
    ));
  }

  void _showShadowPicker(BuildContext context) {
    final prov = context.read<EditDesignProvider>();
    _showSheet(context, "تحكم الظل", SingleChildScrollView(
      child: Column(
        children: [
          Selector<EditDesignProvider, bool>(
            selector: (_, p) => p.state.hasShadow,
            builder: (ctx, hasShadow, _) => SwitchListTile(
              title: const Text("تفعيل الظل", style: TextStyle(fontSize: 14, fontFamily: 'Kaff', color: Colors.white)),
              value: hasShadow,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => prov.toggleShadow(),
            ),
          ),
          Selector<EditDesignProvider, bool>(
            selector: (_, p) => p.state.hasShadow,
            builder: (ctx, hasShadow, _) {
              if (!hasShadow) return const SizedBox.shrink();
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text("قوة التغبيش (Blur)", style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ),
                  Selector<EditDesignProvider, double>(
                    selector: (_, p) => p.state.shadowBlurRadius,
                    builder: (ctx, blur, _) => Slider(
                      value: blur,
                      min: 0, max: 30,
                      activeColor: AppColors.primary,
                      onChanged: (v) => prov.setShadowBlurRadius(v),
                    ),
                  ),
                  const Text("مكان الظل (أفقي)", style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Selector<EditDesignProvider, double>(
                    selector: (_, p) => p.state.shadowOffset.dx,
                    builder: (ctx, dx, _) => Slider(
                      value: dx,
                      min: -20, max: 20,
                      activeColor: AppColors.primary,
                      onChanged: (v) => prov.setShadowOffset(Offset(v, prov.state.shadowOffset.dy)),
                    ),
                  ),
                  const Text("مكان الظل (عمودي)", style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Selector<EditDesignProvider, double>(
                    selector: (_, p) => p.state.shadowOffset.dy,
                    builder: (ctx, dy, _) => Slider(
                      value: dy,
                      min: -20, max: 20,
                      activeColor: AppColors.primary,
                      onChanged: (v) => prov.setShadowOffset(Offset(prov.state.shadowOffset.dx, v)),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text("لون الظل", style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ),
                  _colorGrid(context, (c) => prov.setShadowColor(c)),
                ],
              );
            },
          ),
        ],
      ),
    ));
  }

  void _showFontPicker(BuildContext context) {
    final prov = context.read<EditDesignProvider>();
    final fonts = ['Kaff', 'Casablanca', 'Tajawal', 'Jazeera', 'Vibes', 'Navis', 'Ziba', 'STC', 'F105', 'Font2', 'Roboto'];
    _showSheet(context, "نوع الخط", SizedBox(
      height: 300,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: fonts.length,
        itemBuilder: (ctx, index) => ListTile(
          title: Text(fonts[index], style: TextStyle(fontFamily: fonts[index], color: Colors.white)),
          onTap: () { prov.setSelectedFont(fonts[index]); Navigator.pop(context); },
        ),
      ),
    ));
  }

  void _showBgPicker(BuildContext context) => _showSheet(context, "لون الخلفية", _colorGrid(context, (c) => context.read<EditDesignProvider>().setBgColor(c)));

  void _showTextColorPicker(BuildContext context) => _showSheet(context, "لون النص", _colorGrid(context, (c) => context.read<EditDesignProvider>().setTextColor(c)));

  Widget _colorGrid(BuildContext context, Function(Color) onSelect) {
    final List<Color> palette = [
      Colors.black, Colors.white, Colors.grey, Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan, Colors.teal, Colors.green,
      Colors.lightGreen, Colors.lime, Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
      Colors.brown, Colors.blueGrey, Colors.red.shade300, Colors.blue.shade300, Colors.green.shade300,
      Colors.orange.shade300, Colors.purple.shade300, Colors.red.shade900, Colors.blue.shade900,
      Colors.green.shade900, Colors.orange.shade900,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: palette.length,
      itemBuilder: (ctx, index) => IconButton(
        padding: EdgeInsets.zero,
        icon: CircleAvatar(
          backgroundColor: palette[index],
          radius: 18,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
          ),
        ),
        onPressed: () => onSelect(palette[index]),
      ),
    );
  }

  void _toggleAlign(BuildContext context) {
    final prov = context.read<EditDesignProvider>();
    TextAlign next;
    if (prov.state.textAlign == TextAlign.center) { next = TextAlign.right; }
    else if (prov.state.textAlign == TextAlign.right) { next = TextAlign.left; }
    else { next = TextAlign.center; }
    prov.setTextAlign(next);
  }

  void _showSheet(BuildContext context, String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff0d0d0d),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea( // ✅ حماية المحتوى من شريط التنقل السفلي
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), // ✅ رفع المحتوى فوق الكيبورد
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 15),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Kaff', color: Colors.white, fontSize: 16)),
                const SizedBox(height: 20),
                content,
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
