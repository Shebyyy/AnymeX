import 'package:anymex/models/custom_themes/theme_widgets/json_theme_config.dart';
import 'package:anymex/models/custom_themes/theme_widgets/json_widget_builder.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomPlayerTheme implements PlayerControlTheme {
  final String id;
  final String name;
  final String author;
  final Map<String, dynamic> config;

  CustomPlayerTheme({
    required this.id,
    required this.name,
    this.author = 'Unknown',
    required this.config,
  });

  factory CustomPlayerTheme.fromJson(Map<String, dynamic> json) {
    return CustomPlayerTheme(
      id: json['id'] ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] ?? 'Custom Theme',
      author: json['author'] ?? 'Unknown',
      config: json['config'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'player',
      'id': id,
      'name': name,
      'author': author,
      'version': '2.0',
      'config': config,
    };
  }

  @override
  String get name => this.name;

  @override
  String get id => this.id;

  @override
  Widget buildTopControls(BuildContext context, PlayerController controller) {
    final topControlsConfig = config['top_controls'] as Map<String, dynamic>?;
    
    // Check if using rich JSON format or legacy format
    if (topControlsConfig != null && topControlsConfig.containsKey('components')) {
      // Rich JSON format
      return _buildRichTopControls(context, controller, topControlsConfig);
    } else {
      // Legacy/simple format
      return _buildSimpleTopControls(context, controller, topControlsConfig ?? {});
    }
  }

  Widget _buildRichTopControls(
    BuildContext context,
    PlayerController controller,
    Map<String, dynamic> config,
  ) {
    final decoration = JsonThemeDecoration.fromJson(config['decoration'] as Map?);
    final layout = JsonThemeLayout.fromJson(config['layout'] as Map?);
    final childrenJson = config['components'] as List?;

    // Build context data for widgets
    final contextData = {
      'title': controller.title ?? 'Unknown',
      'controller': controller,
    };

    // Build children
    List<Widget> children = [];
    if (childrenJson != null) {
      children = JsonWidgetBuilder.buildComponents(childrenJson, contextData);
    }

    Widget child;
    if (layout.type == 'column') {
      child = Column(
        mainAxisSize: layout.mainAxisSize,
        mainAxisAlignment: layout.mainAxisAlignment,
        crossAxisAlignment: layout.crossAxisAlignment,
        children: children,
      );
    } else {
      child = Row(
        mainAxisSize: layout.mainAxisSize,
        mainAxisAlignment: layout.mainAxisAlignment,
        crossAxisAlignment: layout.crossAxisAlignment,
        children: children,
      );
    }

    // Apply blur if enabled
    if (decoration.blur?.enabled == true) {
      child = ClipRRect(
        borderRadius: decoration.borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: decoration.blur?.sigma ?? 10.0,
            sigmaY: decoration.blur?.sigma ?? 10.0,
          ),
          child: child,
        ),
      );
    }

    // Build container
    return Container(
      decoration: decoration.build(),
      padding: (layout.padding?.padding) as EdgeInsets?,
      child: child,
    );
  }

  Widget _buildSimpleTopControls(
    BuildContext context,
    PlayerController controller,
    Map<String, dynamic> config,
  ) {
    final colors = Theme.of(context).colorScheme;
    final showBackground = config['show_background'] ?? true;
    final backgroundColor = _parseColor(config['background_color'], Colors.black54);
    final padding = EdgeInsets.symmetric(
      horizontal: (config['horizontal_padding'] as num?)?.toDouble() ?? 16.0,
      vertical: (config['vertical_padding'] as num?)?.toDouble() ?? 12.0,
    );

    return Container(
      color: showBackground ? backgroundColor : Colors.transparent,
      padding: padding,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _buildBackButton(context, config),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                controller.title ?? 'Unknown',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: (config['title_size'] as num?)?.toDouble() ?? 18.0,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            _buildTopActions(context, controller, config),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildCenterControls(BuildContext context, PlayerController controller) {
    final centerControlsConfig = config['center_controls'] as Map<String, dynamic>?;
    
    if (centerControlsConfig != null && centerControlsConfig.containsKey('components')) {
      return _buildRichCenterControls(context, controller, centerControlsConfig);
    } else {
      return _buildSimpleCenterControls(context, controller, centerControlsConfig ?? {});
    }
  }

  Widget _buildRichCenterControls(
    BuildContext context,
    PlayerController controller,
    Map<String, dynamic> config,
  ) {
    final decoration = JsonThemeDecoration.fromJson(config['decoration'] as Map?);
    final layout = JsonThemeLayout.fromJson(config['layout'] as Map?);
    final childrenJson = config['components'] as List?;

    final contextData = {
      'controller': controller,
      'isPlaying': controller.isPlaying.value,
    };

    List<Widget> children = [];
    if (childrenJson != null) {
      children = JsonWidgetBuilder.buildComponents(childrenJson, contextData);
    }

    Widget child;
    if (layout.type == 'column') {
      child = Column(
        mainAxisSize: layout.mainAxisSize,
        mainAxisAlignment: layout.mainAxisAlignment,
        crossAxisAlignment: layout.crossAxisAlignment,
        children: children,
      );
    } else {
      child = Row(
        mainAxisSize: layout.mainAxisSize,
        mainAxisAlignment: layout.mainAxisAlignment,
        crossAxisAlignment: layout.crossAxisAlignment,
        children: children,
      );
    }

    if (decoration.blur?.enabled == true) {
      child = ClipRRect(
        borderRadius: decoration.borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: decoration.blur?.sigma ?? 10.0,
            sigmaY: decoration.blur?.sigma ?? 10.0,
          ),
          child: child,
        ),
      );
    }

    return Container(
      decoration: decoration.build(),
      padding: (layout.padding?.padding) as EdgeInsets?,
      child: child,
    );
  }

  Widget _buildSimpleCenterControls(
    BuildContext context,
    PlayerController controller,
    Map<String, dynamic> config,
  ) {
    final showPlayPause = config['show_play_pause'] ?? true;
    final showSkipButtons = config['show_skip_buttons'] ?? true;
    final iconSize = (config['icon_size'] as num?)?.toDouble() ?? 48.0;
    final iconColor = _parseColor(config['icon_color'], Colors.white);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (showSkipButtons)
          _buildCenterButton(
            context,
            Icons.replay_10_rounded,
            () => controller.seekRelative(-10),
            iconSize * 0.7,
            iconColor,
          ),
        if (showPlayPause)
          Obx(() => _buildCenterButton(
            context,
            controller.isPlaying.value ? Icons.pause_rounded : Icons.play_arrow_rounded,
            () => controller.togglePlayPause(),
            iconSize,
            iconColor,
          )),
        if (showSkipButtons)
          _buildCenterButton(
            context,
            Icons.forward_10_rounded,
            () => controller.seekRelative(10),
            iconSize * 0.7,
            iconColor,
          ),
      ],
    );
  }

  @override
  Widget buildBottomControls(BuildContext context, PlayerController controller) {
    final bottomControlsConfig = config['bottom_controls'] as Map<String, dynamic>?;
    
    if (bottomControlsConfig != null && bottomControlsConfig.containsKey('components')) {
      return _buildRichBottomControls(context, controller, bottomControlsConfig);
    } else {
      return _buildSimpleBottomControls(context, controller, bottomControlsConfig ?? {});
    }
  }

  Widget _buildRichBottomControls(
    BuildContext context,
    PlayerController controller,
    Map<String, dynamic> config,
  ) {
    final decoration = JsonThemeDecoration.fromJson(config['decoration'] as Map?);
    final layout = JsonThemeLayout.fromJson(config['layout'] as Map?);
    final childrenJson = config['components'] as List?;

    final position = controller.position.value.inMilliseconds;
    final duration = controller.duration.value.inMilliseconds;
    final progress = duration > 0 ? position / duration : 0.0;

    final contextData = {
      'controller': controller,
      'progress': progress,
      'position': _formatDuration(controller.position.value),
      'duration': _formatDuration(controller.duration.value),
    };

    List<Widget> children = [];
    if (childrenJson != null) {
      children = JsonWidgetBuilder.buildComponents(childrenJson, contextData);
    }

    Widget child;
    if (layout.type == 'column') {
      child = Column(
        mainAxisSize: layout.mainAxisSize,
        mainAxisAlignment: layout.mainAxisAlignment,
        crossAxisAlignment: layout.crossAxisAlignment,
        children: children,
      );
    } else {
      child = Row(
        mainAxisSize: layout.mainAxisSize,
        mainAxisAlignment: layout.mainAxisAlignment,
        crossAxisAlignment: layout.crossAxisAlignment,
        children: children,
      );
    }

    if (decoration.blur?.enabled == true) {
      child = ClipRRect(
        borderRadius: decoration.borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: decoration.blur?.sigma ?? 10.0,
            sigmaY: decoration.blur?.sigma ?? 10.0,
          ),
          child: child,
        ),
      );
    }

    return Container(
      decoration: decoration.build(),
      padding: (layout.padding?.padding) as EdgeInsets?,
      child: child,
    );
  }

  Widget _buildSimpleBottomControls(
    BuildContext context,
    PlayerController controller,
    Map<String, dynamic> config,
  ) {
    final colors = Theme.of(context).colorScheme;
    final showBackground = config['show_background'] ?? true;
    final backgroundColor = _parseColor(config['background_color'], Colors.black54);
    final showProgress = config['show_progress'] ?? true;
    final showTime = config['show_time'] ?? true;

    return Container(
      color: showBackground ? backgroundColor : Colors.transparent,
      padding: EdgeInsets.symmetric(
        horizontal: (config['horizontal_padding'] as num?)?.toDouble() ?? 16.0,
        vertical: (config['vertical_padding'] as num?)?.toDouble() ?? 12.0,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress) _buildProgressBar(context, controller, config),
            if (showProgress && showTime) const SizedBox(height: 12),
            if (showTime) _buildTimeRow(context, controller, config),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, Map<String, dynamic> themeConfig) {
    final iconColor = _parseColor(themeConfig['icon_color'], Colors.white);
    final iconSize = (themeConfig['icon_size'] as num?)?.toDouble() ?? 24.0;

    return IconButton(
      icon: Icon(Icons.arrow_back_rounded),
      color: iconColor,
      iconSize: iconSize,
      onPressed: () => Navigator.pop(context),
    );
  }

  Widget _buildTopActions(
    BuildContext context,
    PlayerController controller,
    Map<String, dynamic> themeConfig,
  ) {
    final iconColor = _parseColor(themeConfig['icon_color'], Colors.white);
    final iconSize = (themeConfig['icon_size'] as num?)?.toDouble() ?? 24.0;
    final showMore = themeConfig['show_more_button'] ?? true;

    return Row(
      children: [
        if (showMore)
          IconButton(
            icon: Icon(Icons.more_vert_rounded),
            color: iconColor,
            iconSize: iconSize,
            onPressed: () => controller.openSettings(),
          ),
      ],
    );
  }

  Widget _buildCenterButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
    double size,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black26,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
          size: size,
        ),
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    PlayerController controller,
    Map<String, dynamic> themeConfig,
  ) {
    final progressColor = _parseColor(themeConfig['progress_color'], Colors.blue);
    final trackColor = _parseColor(themeConfig['track_color'], Colors.white24);
    final height = (themeConfig['progress_height'] as num?)?.toDouble() ?? 4.0;

    return Obx(() {
      final position = controller.position.value.inMilliseconds;
      final duration = controller.duration.value.inMilliseconds;
      final progress = duration > 0 ? position / duration : 0.0;

      return SliderTheme(
        data: SliderThemeData(
          trackHeight: height,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          activeTrackColor: progressColor,
          inactiveTrackColor: trackColor,
          thumbColor: progressColor,
          overlayColor: progressColor.withOpacity(0.3),
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

  Widget _buildTimeRow(
    BuildContext context,
    PlayerController controller,
    Map<String, dynamic> themeConfig,
  ) {
    final textColor = _parseColor(themeConfig['time_color'], Colors.white);
    final fontSize = (themeConfig['time_size'] as num?)?.toDouble() ?? 14.0;

    return Obx(() {
      final position = _formatDuration(controller.position.value);
      final duration = _formatDuration(controller.duration.value);

      return Row(
        children: [
          Text(
            position,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
            ),
          ),
          const Spacer(),
          Text(
            duration,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
            ),
          ),
        ],
      );
    });
  }

  Color? _parseColor(dynamic colorValue, Color defaultColor) {
    if (colorValue == null) return defaultColor;
    if (colorValue is int) return Color(colorValue);
    if (colorValue is String) {
      if (colorValue.startsWith('0x')) {
        return Color(int.parse(colorValue));
      }
      return Color(int.parse(colorValue));
    }
    return defaultColor;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
