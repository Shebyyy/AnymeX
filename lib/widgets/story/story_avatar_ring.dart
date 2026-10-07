import 'package:anymex/utils/theme_extensions.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_container.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_image.dart';
import 'package:flutter/material.dart';

class StoryAvatarRing extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final bool hasUnseen;
  final bool isCurrentUser;
  final bool showAddBadge;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const StoryAvatarRing({
    super.key,
    this.avatarUrl,
    this.radius = 28,
    this.hasUnseen = false,
    this.isCurrentUser = false,
    this.showAddBadge = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final totalSize = (radius * 2) + 8;

    final gradientRing = SweepGradient(
      colors: [
        colors.primary,
        colors.tertiary,
        colors.secondary,
        colors.primary,
      ],
      stops: const [0.0, 0.4, 0.75, 1.0],
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnymeXContainer(
            width: totalSize,
            height: totalSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasUnseen ? gradientRing : null,
              border: hasUnseen
                  ? null
                  : Border.all(
                      color: colors.outline.withOpacity(0.3),
                      width: 1.5,
                    ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.5),
              child: AnymeXContainer(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius * 2),
                    child: avatarUrl != null && avatarUrl!.isNotEmpty
                        ? AnymeXImage(
                            imageUrl: avatarUrl!,
                            width: radius * 2,
                            height: radius * 2,
                            fit: BoxFit.cover,
                          )
                        : CircleAvatar(
                            radius: radius,
                            backgroundColor:
                                colors.secondaryContainer.opaque(0.5),
                            child: Icon(
                              Icons.person_rounded,
                              size: radius * 1.1,
                              color: colors.onSecondaryContainer,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          if (isCurrentUser && showAddBadge)
            Positioned(
              right: 2,
              bottom: 2,
              child: AnymeXContainer(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  size: 13,
                  color: colors.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
