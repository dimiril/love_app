import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/edit_design_provider.dart';
import 'background_layer.dart';
import 'main_text_layer.dart';
import 'overlays_layer.dart';

class DesignCanvas extends StatelessWidget {
  const DesignCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<EditDesignProvider, bool>(
      selector: (_, p) => p.state.content.isNotEmpty,
      builder: (context, hasContent, _) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(color: Colors.white),
          child: const Stack(
            fit: StackFit.expand,
            children: [
              BackgroundLayer(),
              MainTextLayer(),
              OverlaysLayer(),
            ],
          ),
        );
      },
    );
  }
}
