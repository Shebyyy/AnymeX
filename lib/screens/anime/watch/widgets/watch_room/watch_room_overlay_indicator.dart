import 'dart:async';

import 'package:anymex/services/watchium_service.dart';
import 'package:anymex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// A small overlay pill shown on top of the video when in a watch-together
/// room. It displays the member count, sync status, and auto-hides after
/// 3 seconds of inactivity (similar to player controls).
///
/// Usage:
/// ```dart
/// // In your player's widget tree, positioned inside a Stack:
/// WatchRoomOverlayIndicator(
///   visible: showControls, // tie to player controls visibility
/// )
/// ```
///
/// The indicator reappears whenever controls become visible and hides
/// automatically after a configurable [autoHideDuration].
class WatchRoomOverlayIndicator extends StatefulWidget {
  /// Whether the player controls are currently visible. The indicator
  /// piggy-backs on this to decide when to show itself.
  final bool visible;

  /// How long the indicator stays visible after the controls disappear.
  /// Defaults to 3 seconds.
  final Duration autoHideDuration;

  /// Position the indicator at the top-left or top-right of the video.
  final WatchRoomIndicatorPosition position;

  const WatchRoomOverlayIndicator({
    super.key,
    this.visible = true,
    this.autoHideDuration = const Duration(seconds: 3),
    this.position = WatchRoomIndicatorPosition.topRight,
  });

  @override
  State<WatchRoomOverlayIndicator> createState() =>
      _WatchRoomOverlayIndicatorState();
}

class _WatchRoomOverlayIndicatorState extends State<WatchRoomOverlayIndicator> {
  WatchiumService? _service;
  Timer? _hideTimer;
  bool _indicatorVisible = false;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    _service = _tryGetService();
  }

  WatchiumService? _tryGetService() {
    try {
      return Get.find<WatchiumService>();
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(WatchRoomOverlayIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.visible && !_indicatorVisible) {
      _showIndicator();
    } else if (widget.visible) {
      // Controls still visible – reset hide timer so indicator persists.
      _resetHideTimer();
    }
  }

  void _showIndicator() {
    if (_service?.isInRoom.value != true) return;

    setState(() {
      _indicatorVisible = true;
    });

    // Animate in
    _animateOpacity(1.0);

    _resetHideTimer();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.autoHideDuration, _hideIndicator);
  }

  void _hideIndicator() {
    _animateOpacity(0.0).then((_) {
      if (mounted) {
        setState(() => _indicatorVisible = false);
      }
    });
  }

  Future<void> _animateOpacity(double target) async {
    // Simple animation via multi-step setState for a smooth fade.
    const steps = 8;
    const stepDuration = Duration(milliseconds: 30);
    final start = _opacity;
    final diff = target - start;

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      if (!mounted) return;
      setState(() {
        _opacity = start + (diff * (i / steps));
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_service == null) return const SizedBox.shrink();

    return Obx(() {
      final isInRoom = _service!.isInRoom.value;
      if (!isInRoom) return const SizedBox.shrink();

      final memberCount = _service!.members.length;
      final syncState = _service!.syncState.value;
      final isSynced = syncState.isSynced;

      final alignment = widget.position == WatchRoomIndicatorPosition.topLeft
          ? Alignment.topLeft
          : Alignment.topRight;

      if (!_indicatorVisible && _opacity <= 0) {
        return const SizedBox.shrink();
      }

      return Positioned.fill(
        child: IgnorePointer(
          ignoring: true,
          child: Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: AnimatedOpacity(
                opacity: _opacity.clamp(0.0, 1.0),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: _WatchRoomPill(
                  memberCount: memberCount,
                  isSynced: isSynced,
                  syncDifference: syncState.syncDifference,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Position enum for the overlay indicator.
enum WatchRoomIndicatorPosition { topLeft, topRight }

/// The actual pill / badge widget rendered by the overlay indicator.
class _WatchRoomPill extends StatelessWidget {
  final int memberCount;
  final bool isSynced;
  final double? syncDifference;

  const _WatchRoomPill({
    required this.memberCount,
    required this.isSynced,
    this.syncDifference,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // People icon
          Icon(
            Symbols.group_rounded,
            size: 16,
            color: isDark
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.black.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),

          // Member count text
          Text(
            'Watching with $memberCount ${memberCount == 1 ? "person" : "people"}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.black.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
          ),

          // Separator dot
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),

          // Sync status
          Icon(
            isSynced
                ? Symbols.check_circle_rounded
                : Symbols.sync_rounded,
            size: 14,
            color: isSynced
                ? const Color(0xFF4CAF50)
                : const Color(0xFFFFB74D),
          ),
          const SizedBox(width: 4),
          Text(
            isSynced
                ? 'Synced'
                : (syncDifference != null
                    ? '${syncDifference!.abs().toStringAsFixed(1)}s off'
                    : 'Syncing...'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isSynced
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFFB74D),
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
