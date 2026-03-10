import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/edit_design_provider.dart';
import '../../utils/editable_item.dart';
import '../../utils/snack_bar.dart';

class IndividualOverlayItem extends StatefulWidget {
  final int index;
  const IndividualOverlayItem({super.key, required this.index});

  @override
  State<IndividualOverlayItem> createState() => _IndividualOverlayItemState();
}

class _IndividualOverlayItemState extends State<IndividualOverlayItem> {
  double _localLastScale = 1.0;
  double _localLastRotation = 0.0;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<EditDesignProvider>();

    return Selector<EditDesignProvider, EditableItem>(
      selector: (_, p) => p.state.overlays[widget.index],
      builder: (context, item, child) {
        return Positioned(
          left: item.position.dx,
          top: item.position.dy,
          child: GestureDetector(
            onScaleStart: (_) {
              _localLastScale = 1.0;
              _localLastRotation = 0.0;
            },
            onScaleUpdate: (details) {
              double scaleDelta = details.scale / _localLastScale;
              double rotationDelta = details.rotation - _localLastRotation;
              
              provider.updateOverlayTransform(
                widget.index, 
                details.focalPointDelta, 
                scaleDelta, 
                rotationDelta
              );

              _localLastScale = details.scale;
              _localLastRotation = details.rotation;
            },
            onLongPress: () {
              provider.removeOverlay(item);
              AppSnackBar.show(context, "تم حذف العنصر");
            },
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..scale(item.scale, item.scale, 1.0)
                ..rotateZ(item.rotation),
              child: item.content.startsWith('assets/')
                  ? Image.asset(item.content, width: 100, height: 100, fit: BoxFit.contain)
                  : Text(item.content,
                  style: TextStyle(
                      fontFamily: provider.state.selectedFont,
                      color: provider.state.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
          ),
        );
      },
    );
  }
}
