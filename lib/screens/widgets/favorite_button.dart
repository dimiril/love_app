import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../models/message_model.dart';
import '../../providers/database_provider.dart';

class FavoriteButton extends StatelessWidget {
  final MessageModel msg;

  const FavoriteButton({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    return Selector<DatabaseProvider, bool>(
      selector: (_, provider) => provider.isFavorite(msg.id),
      builder: (_, isFav, __) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            final scale = TweenSequence<double>([
              TweenSequenceItem(
                tween: Tween(begin: 0.8, end: 1.3),
                weight: 50,
              ),
              TweenSequenceItem(
                tween: Tween(begin: 1.3, end: 1.0),
                weight: 50,
              ),
            ]).animate(animation);

            return ScaleTransition(scale: scale, child: child);
          },
          child: IconButton(
            key: ValueKey(isFav),
            onPressed: () =>
                context.read<DatabaseProvider>().toggleFavorite(msg),
            icon: Icon(
              isFav ? AppIcons.favoriteFill : AppIcons.favorite,
              size: 25,
              color: isFav ? Colors.red : AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}
