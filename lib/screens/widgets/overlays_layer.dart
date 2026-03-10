import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/edit_design_provider.dart';
import 'individual_overlay_item.dart';

class OverlaysLayer extends StatelessWidget {
  const OverlaysLayer({super.key});

  @override
  Widget build(BuildContext context) {
    // إعادة البناء فقط عند إضافة أو حذف عنصر من القائمة
    final overlaysCount = context.select((EditDesignProvider p) => p.state.overlays.length);
    
    return Stack(
      children: List.generate(
        overlaysCount, 
        (index) => IndividualOverlayItem(index: index),
      ),
    );
  }
}
