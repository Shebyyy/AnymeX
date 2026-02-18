import 'dart:ui' as ui;
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/progress_slider.dart';
import 'package:anymex/widgets/custom_widgets/custom_button.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/bottom_sheet.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/control_button.dart';
import 'package:anymex/screens/anime/watch/controls/widgets/progress_slider.dart';
import 'package:anymex/screens/other_features.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../json_player_controls_config.dart';
import '../../json_theme_config.dart';
import '../../json_theme_elements.dart';

/// Builder for JSON player themes
class JsonPlayerThemeBuilder {
  static Widget buildTopControls({
    required BuildContext context,
    required PlayerController controller,
    required JsonTopControlsConfig config,
  }) {
    final background = config.background;
    final layout = config.layout;

    List<Widget> children = config.elements.map((element) => _buildElement(context, controller, element)).toList();

    Widget child = Row(
      children: children,
    );

    if (background != null && background.color != null) {
      child = _applyBackground(context, child, background, layout);
    }

    if (layout != null) {
      child = Padding(
        padding: layout.padding,
        child: child,
      );
    }

    return SafeArea(
      bottom: false,
      child: child,
    );
  }

  static Widget buildCenterControls({
    required BuildContext context,
    required PlayerController controller,
    required JsonCenterControlsConfig config,
  }) {
    final layout = config.layout;

    List<Widget> children = config.elements.map((element) => _buildElement(context, controller, element)).toList();

    Widget child = Row(
      mainAxisAlignment: layout?.mainAxisAlign ?? MainAxisAlignment.center,
      crossAxisAlignment: layout?.crossAxisAlign ?? CrossAxisAlignment.center,
      children: children,
    );

    if (config.background != null && config.background.color != null) {
      child = _applyBackground(context, child, config.background, layout);
    }

    return Align(
      alignment: Alignment.center,
      child: child,
    );
  }

  static Widget buildBottomControls({
    required BuildContext context,
    required PlayerController controller,
    required JsonBottomControlsConfig config,
  }) {
    final background = config.background;
    final layout = config.layout;
    final progressBar = config.progressBar;
    final buttons = config.buttons;

    List<Widget> children = [];

    // Progress bar
    if (progressBar != null) {
      children.add(_buildProgressBar(context, controller, progressBar));
      children.add(const SizedBox(height: 8));
    }

    // Time display
    if (progressBar?.showTime == true) {
      children.add(_buildTimeDisplay(context, controller, progressBar));
      children.add(const SizedBox(width: 16));
    }

    // Buttons (using built-in layout)
    children.add(const Spacer());

    // Right side buttons
    children.addAll(_buildRightButtons(context, controller, buttons));

    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );

    if (background != null && background.color != null) {
      child = _applyBackground(context, child, background, layout);
    }

    if (layout != null) {
      child = Padding(
        padding: layout?.padding ?? const EdgeInsets.all(16),
        child: child,
      );
    }

    return SafeArea(
      top: false,
      child: child,
    );
  }

  static Widget _buildElement(
    BuildContext context,
    PlayerController controller,
    JsonThemeElement element,
  ) {
    final color = element.parsedColor;
    final glow = element.glowShadows;

    Widget child;

    switch (element.type) {
      case 'back_button':
        child = _buildIconButton(
          context: controller,
          element: element as JsonBackButtonElement,
          () => Get.back(),
        );
        break;

      case 'title':
        child = _buildTitle(context, controller, element as JsonTitleElement);
        break;

      case 'subtitle':
        child = _buildSubtitle(context, controller, element as JsonSubtitleElement);
        break;

      case 'settings_button':
        child = _buildIconButton(
          context,
          element as JsonSettingsButtonElement,
          () => showModalBottomSheet(
            context: Get.context!,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => Container(
              height: MediaQuery.of(Get.context!).size.height,
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: const SettingsPlayer(isModal: true),
            ),
          ),
        );
        break;

      case 'lock_button':
        child = _buildIconButton(
          context,
          element as JsonLockButtonElement,
          () => controller.isLocked.value = !controller.isLocked.value,
        );
        break;

      case 'play_pause':
        child = Obx(() => _buildPlayPauseButton(
          context,
          element as JsonPlayPauseElement,
          controller,
        ));
        break;

      case 'seek_backward':
        child = _buildIconButton(
          context,
          element as JsonSeekBackwardElement,
          () {
            final currentPos = controller.currentPosition.value;
            final seekBy = Duration(seconds: 15);
            final newPos = currentPos - seekBy;
            controller.seekTo(newPos.isNegative ? Duration.zero : newPos);
          },
        );
        break;

      case 'seek_forward':
        child = _buildIconButton(
          context,
          element as JsonSeekForwardElement,
          () {
            final currentPos = controller.currentPosition.value;
            final duration = controller.episodeDuration.value;
            final seekBy = Duration(seconds: 15);
            final newPos = currentPos + seekBy;
            controller.seekTo(newPos > duration ? duration : newPos);
          },
        );
        break;

      default:
        child = const SizedBox.shrink();
    }

    return child;
  }

  static Widget _buildIconButton(
    BuildContext context,
    JsonThemeElement element,
    VoidCallback onPressed,
  ) {
    final color = element.parsedColor;
    final glow = element.glowShadows;
    final size = element.size ?? 24;

    Widget button = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: size + 8,
          height: size + 8,
          child: Icon(
            _getIcon(element),
            color: color ?? Colors.white,
            size: size,
          ),
        ),
      ),
    );

    if (glow != null && glow.isNotEmpty) {
      button = Container(
        decoration: BoxDecoration(
          boxShadow: glow,
        ),
        child: button,
      );
    }

    return button;
  }

  static Widget _buildTitle(
    BuildContext context,
    PlayerController controller,
    JsonTitleElement element,
  ) {
    final color = element.parsedColor ?? Colors.white;
    final fontSize = element.fontSize ?? 16;

    return Expanded(
      child: Text(
        controller.currentEpisode.value.title ??
        controller.itemName ??
        'Unknown Title',
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: element.maxLines ?? 1,
      ),
    );
  }

  static Widget _buildSubtitle(
    BuildContext context,
    PlayerController controller,
    JsonSubtitleElement element,
  ) {
    final color = element.parsedColor ?? Colors.white70;
    final fontSize = element.fontSize ?? 12;

    String? subtitle;
    if (element.text != null) {
      subtitle = _replacePlaceholders(element.text!, controller);
    }

    if (subtitle == null || subtitle.isEmpty) return const SizedBox.shrink();

    return Expanded(
      child: Text(
        subtitle,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
        ),
        maxLines: element.maxLines ?? 2,
      ),
    );
  }

  static Widget _buildPlayPauseButton(
    BuildContext context,
    JsonPlayPauseElement element,
    PlayerController controller,
  ) {
    final icon = controller.isPlaying.value 
        ? element.iconPause ?? 'pause'
        : element.iconPlay ?? 'play_arrow';
    final size = element.size ?? 64;
    final color = element.parsedColor ?? Colors.white;
    final glow = element.glowShadows;

    Widget button = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: controller.togglePlayPause,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            _getIconByName(icon),
            color: color,
            size: size,
          ),
        ),
      ),
    );

    if (glow != null && glow.isNotEmpty) {
      button = Container(
        decoration: BoxDecoration(
          boxShadow: glow,
        ),
        child: button,
      );
    }

    return button;
  }

  static Widget _buildProgressBar(
    BuildContext context,
    PlayerController controller,
    JsonProgressBarConfig config,
  ) {
    return Obx(() {
      final position = controller.currentPosition.value.inMilliseconds;
      final duration = controller.episodeDuration.value.inMilliseconds;
      final progress = duration > 0 ? position / duration : 0.0;

      return SliderTheme(
        data: SliderThemeData(
          trackHeight: config.height ?? 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          activeTrackColor: config.parsedColor ?? Theme.of(context).colorScheme.primary,
          inactiveTrackColor: config.parsedTrackColor ?? Colors.white24,
          thumbColor: config.parsedThumbColor ?? config.parsedColor,
          overlayColor: (config.parsedThumbColor ?? Colors.blue).withOpacity(0.3),
        ),
        child: Slider(
          value: progress.clamp(0.0, 1.0),
          onChanged: (value) {
            final seekPosition = (value * duration).round();
            controller.seekTo(Duration(milliseconds: seekPosition));
          },
        ),
      );
    });
  }

  static Widget _buildTimeDisplay(
    BuildContext context,
    PlayerController controller,
    JsonProgressBarConfig config,
  ) {
    return Obx(() {
      return Text(
        '\${controller.formattedCurrentPosition} / \${controller.formattedEpisodeDuration}',
        style: TextStyle(
          color: config.parsedTimeColor ?? Colors.white,
          fontSize: config.timeSize ?? 13,
          fontWeight: FontWeight.w600,
        ),
      );
    });
  }

  static List<Widget> _buildRightButtons(
    BuildContext context,
    PlayerController controller,
    JsonButtonsConfig? buttons,
  ) {
    if (buttons?.useBuiltinLayout == true) {
      // Use built-in layout - this is complex, so just return empty for now
      // In a full implementation, you'd build the same button layout as built-in themes
      return [
        Obx(() => _buildIcon(
          Symbols.playlist_play_rounded,
          controller,
          () {
            controller.isEpisodePaneOpened.value =
                !controller.isEpisodePaneOpened.value;
          },
        )),
        const SizedBox(width: 12),
        Obx(() => _buildIcon(
          Symbols.subtitles_rounded,
          controller,
          () {
            controller.isOffline.value
                ? PlayerBottomSheets.showOfflineSubs(context, controller)
                : PlayerBottomSheets.showSubtitleTracks(context, controller);
          },
        )),
        const SizedBox(width: 12),
        Obx(() => _buildIcon(
          Icons.fullscreen_rounded,
          controller,
          controller.toggleFullScreen,
        )),
      ];
    }

    return [];
  }

  static Widget _buildIcon(
    IconData iconData,
    PlayerController controller,
    VoidCallback? onTap,
  ) {
    return ControlButton(
      icon: iconData,
      onPressed: onTap ?? () {},
      tooltip: '', // Could add tooltips
      compact: true,
    );
  }

  static Widget _applyBackground(
    BuildContext context,
    Widget child,
    JsonBackgroundConfig background,
    JsonLayoutConfig? layout,
  ) {
    Widget result = Container(
      decoration: background.buildDecoration(context),
      child: child,
    );

    if (background.blur != null && background.blur! > 0) {
      result = ClipRRect(
        borderRadius: BorderRadius.circular(layout?.cornerRadius ?? 0),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: background.blur!, sigmaY: background.blur!),
          child: result,
        ),
      );
    }

    return result;
  }

  static String _replacePlaceholders(String text, PlayerController controller) {
    return text.replaceAll('{{title}}', 
      controller.currentEpisode.value.title ?? ''
    ).replaceAll('{{episode}}',
      controller.currentEpisode.value.number ?? ''
    );
  }

  static IconData _getIcon(JsonThemeElement element) {
    if (element is JsonBackButtonElement && element.icon != null) {
      return _getIconByName(element.icon!);
    }
    if (element is JsonSettingsButtonElement && element.icon != null) {
      return _getIconByName(element.icon!);
    }
    if (element is JsonLockButtonElement && element.icon != null) {
      return _getIconByName(element.icon!);
    }
    return Icons.circle; // Default
  }

  static IconData _getIconByName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'arrow_back':
        return Icons.arrow_back_rounded;
      case 'close':
        return Icons.close_rounded;
      case 'settings':
        return Icons.settings_rounded;
      case 'lock':
        return Icons.lock_rounded;
      case 'play_arrow':
        return Icons.play_arrow_rounded;
      case 'pause':
        return Icons.pause_rounded;
      case 'replay_10':
        return Icons.replay_10_rounded;
      case 'forward_10':
        return Icons.forward_10_rounded;
      case 'fullscreen':
        return Icons.fullscreen_rounded;
      case 'fullscreen_exit':
        return Icons.fullscreen_exit_rounded;
      default:
        return Icons.circle;
    }
  }
}
