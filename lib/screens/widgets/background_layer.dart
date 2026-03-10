import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/edit_design_provider.dart';

class BackgroundLayer extends StatelessWidget {
  const BackgroundLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<EditDesignProvider, (Color, File?, double, bool, List<Color>, Alignment, Alignment)>(
      selector: (_, p) => (
        p.state.bgColor, 
        p.state.bgImage, 
        p.state.bgOpacity, 
        p.state.isGradient, 
        p.state.gradientColors, 
        p.state.gradientBegin, 
        p.state.gradientEnd
      ),
      builder: (context, data, _) {
        return Container(
          decoration: BoxDecoration(
            color: data.$4 ? null : data.$1,
            gradient: data.$4 
                ? LinearGradient(
                    colors: data.$5,
                    begin: data.$6,
                    end: data.$7,
                  )
                : null,
            image: data.$2 != null
                ? DecorationImage(image: FileImage(data.$2!), fit: BoxFit.cover)
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: data.$2 != null ? data.$1.withValues(alpha: data.$3) : Colors.transparent,
            ),
          ),
        );
      },
    );
  }
}
