import 'dart:io';

import 'package:anymex/screens/anime/watch/widgets/watch_room/watch_room_bottom_sheet.dart';
import 'package:anymex/services/watchium_service.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// A compact floating button shown on the video player controls area.
///
/// When not in a room, shows a "Watch Together" people-group icon.
/// When in a room, shows a green dot indicator with a member-count badge.
/// On tap opens the [WatchRoomBottomSheet].
class WatchRoomButton extends StatefulWidget {
  /// Compact variant for the landscape bottom bar.
  final bool compact;

  const WatchRoomButton({
    super.key,
    this.compact = false,
  });

  @override
  State<WatchRoomButton> createState() => _WatchRoomButtonState();
}

class _WatchRoomButtonState extends State<WatchRoomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown() => _animationController.forward();
  void _handleTapUp() => _animationController.reverse();
  void _handleTapCancel() => _animationController.reverse();

  WatchiumService? _getWatchiumService() {
    try {
      return Get.find<WatchiumService>();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;

    final size = widget.compact
        ? (isDesktop ? 40.0 : 36.0)
        : (isDesktop ? 48.0 : 44.0);
    final iconSize = widget.compact ? 20.0 : 24.0;

    final service = _getWatchiumService();
    if (service == null) return const SizedBox.shrink();

    return Obx(() {
      final isInRoom = service.isInRoom.value;
      final memberCount = service.members.length;

      Widget button = GestureDetector(
        onTapDown: (_) => _handleTapDown(),
        onTapUp: (_) => _handleTapUp(),
        onTapCancel: _handleTapCancel,
        onTap: () {
          HapticFeedback.lightImpact();
          WatchRoomBottomSheet.show(context);
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: isInRoom
                        ? (isDark
                            ? theme.colorScheme.primary.opaque(
                                _isHovered ? 0.18 : 0.10,
                                iReallyMeanIt: true,
                              )
                            : (_isHovered
                                ? theme.colorScheme.primaryContainer
                                : theme
                                    .colorScheme.surfaceContainerHighest))
                        : (isDark
                            ? theme.colorScheme.surfaceVariant.opaque(
                                _isHovered ? 0.12 : 0.05,
                                iReallyMeanIt: true,
                              )
                            : (_isHovered
                                ? theme.colorScheme.surfaceContainerHigh
                                : theme
                                    .colorScheme.surfaceContainerHighest)),
                    borderRadius: BorderRadius.circular(
                      widget.compact ? 12 : 16,
                    ),
                    border: Border.all(
                      color: isInRoom
                          ? (isDark
                              ? theme.colorScheme.primary.opaque(
                                  _isHovered ? 0.4 : 0.25,
                                  iReallyMeanIt: true,
                                )
                              : theme.colorScheme.primary.opaque(
                                  _isHovered ? 0.5 : 0.35,
                                  iReallyMeanIt: true,
                                ))
                          : (isDark
                              ? theme.colorScheme.outline.opaque(
                                  _isHovered ? 0.25 : 0.1,
                                  iReallyMeanIt: true,
                                )
                              : theme.colorScheme.outline.opaque(
                                  _isHovered ? 0.4 : 0.3,
                                  iReallyMeanIt: true,
                                )),
                      width: _isHovered ? 1.0 : 0.5,
                    ),
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: isInRoom
                                  ? theme.colorScheme.primary.opaque(
                                      isDark ? 0.3 : 0.2,
                                      iReallyMeanIt: true,
                                    )
                                  : theme.colorScheme.primary.opaque(
                                      isDark ? 0.15 : 0.1,
                                      iReallyMeanIt: true,
                                    ),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      Symbols.group_rounded,
                      size: iconSize,
                      color: isInRoom
                          ? (isDark
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onPrimaryContainer)
                          : (isDark
                              ? (_isHovered
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface)
                              : theme.colorScheme.onSurface),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Wrap with badge when in room
      if (isInRoom) {
        button = Stack(
          clipBehavior: Clip.none,
          children: [
            button,
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.black87 : theme.colorScheme.surface,
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(minWidth: 16),
                child: Text(
                  '$memberCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      }

      return Tooltip(
        message: isInRoom
            ? 'Watch Together ($memberCount online)'
            : 'Watch Together',
        preferBelow: true,
        decoration: BoxDecoration(
          color: theme.colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onInverseSurface,
        ),
        child: button,
      );
    });
  }
}
