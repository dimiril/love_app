import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/edit_design_provider.dart';

class MainTextLayer extends StatefulWidget {
  const MainTextLayer({super.key});

  @override
  State<MainTextLayer> createState() => _MainTextLayerState();
}

class _MainTextLayerState extends State<MainTextLayer> {
  double _lastScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Selector<EditDesignProvider, (String, Offset, double, double, String, Color, FontWeight, TextAlign, bool, double, double)>(
      selector: (_, p) => (
        p.state.content,
        p.state.position,
        p.state.scale,
        p.state.rotation,
        p.state.selectedFont,
        p.state.textColor,
        p.state.fontWeight,
        p.state.textAlign,
        p.state.hasShadow,
        p.state.fontSize,
        p.state.lineHeight
      ),
      builder: (context, data, _) {
        final provider = context.read<EditDesignProvider>();

        return Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: data.$2,
            child: GestureDetector(
              onScaleStart: (_) => _lastScale = 1.0,
              onScaleUpdate: (details) {
                provider.updatePosition(details.focalPointDelta);
                provider.updateScale(details.scale / _lastScale);
                _lastScale = details.scale;
              },
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..scale(data.$3, data.$3, 1.0)
                  ..rotateZ(data.$4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    data.$1,
                    textAlign: data.$8,
                    style: TextStyle(
                      fontFamily: data.$5, // يستخدم الخط المحلي الممرر من الـ Provider
                      fontSize: data.$10,
                      color: data.$6,
                      fontWeight: data.$7,
                      height: data.$11,
                      shadows: data.$9
                          ? [Shadow(
                              blurRadius: provider.state.shadowBlurRadius,
                              color: provider.state.shadowColor,
                              offset: provider.state.shadowOffset
                            )]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
