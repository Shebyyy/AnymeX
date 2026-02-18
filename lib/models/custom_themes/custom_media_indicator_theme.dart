import 'dart:convert';

import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';
import 'package:flutter/material.dart';

class CustomMediaIndicatorTheme implements MediaIndicatorTheme {
  final String id;
  final String name;
  final String author;
  final Map<String, dynamic> config;

  CustomMediaIndicatorTheme({
    required this.id,
    required this.name,
    this.author = 'Unknown',
    required this.config,
  });

  factory CustomMediaIndicatorTheme.fromJson(Map<String, dynamic> json) {
    return CustomMediaIndicatorTheme(
      id: json['id'] ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] ?? 'Custom Theme',
      author: json['author'] ?? 'Unknown',
      config: json['config'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'media_indicator',
      'id': id,
      'name': name,
      'author': author,
      'version': '1.0',
      'config': config,
    };
  }

  @override
  Widget buildIndicator(BuildContext context, MediaIndicatorThemeData data) {
    final colors = Theme.of(context).colorScheme;
    final themeConfig = config['theme'] ?? {};
    final layoutConfig = config['layout'] ?? {};

    final position = layoutConfig['position'] ?? (data.isVolumeIndicator ? 'left' : 'right');
    final alignment = position == 'left' ? Alignment.centerLeft : Alignment.centerRight;

    final accentColor = data.isVolumeIndicator
        ? colors.primary
        : colors.tertiary;
    final customColor = themeConfig['accent_color'];
    final useCustomColor = themeConfig['use_custom_accent'] == true;

    final effectiveColor = useCustomColor && customColor != null
        ? Color(int.parse(customColor))
        : accentColor;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: themeConfig['width'] ?? 60.0,
          height: themeConfig['height'] ?? 220.0,
          decoration: _buildDecoration(context, themeConfig, effectiveColor),
          child: _buildContent(context, data, themeConfig, effectiveColor),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(BuildContext context, Map<String, dynamic> themeConfig, Color accentColor) {
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = themeConfig['background_color'];
    final showBorder = themeConfig['show_border'] ?? true;
    final borderRadius = themeConfig['border_radius'] ?? 12.0;
    final useBlur = themeConfig['use_blur'] ?? false;

    Color bgColor = Colors.black87;
    if (backgroundColor != null) {
      bgColor = Color(int.parse(backgroundColor));
    } else if (themeConfig['background_type'] == 'surface') {
      bgColor = colors.surfaceContainerHighest;
    }

    final baseDecoration = BoxDecoration(
      color: useBlur ? Colors.transparent : bgColor,
      borderRadius: BorderRadius.circular(borderRadius.toDouble()),
      border: showBorder
          ? Border.all(
              color: accentColor.withOpacity(0.3),
              width: themeConfig['border_width']?.toDouble() ?? 2.0,
            )
          : null,
      boxShadow: themeConfig['shadow_enabled'] == true
          ? [
              BoxShadow(
                color: accentColor.withOpacity(0.3),
                blurRadius: themeConfig['shadow_blur']?.toDouble() ?? 12.0,
                offset: Offset(0, themeConfig['shadow_offset']?.toDouble() ?? 4.0),
              ),
            ]
          : [],
    );

    if (!useBlur) return baseDecoration;

    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius.toDouble()),
    );
  }

  Widget _buildContent(
    BuildContext context,
    MediaIndicatorThemeData data,
    Map<String, dynamic> themeConfig,
    Color accentColor,
  ) {
    final style = themeConfig['style'] ?? 'bar';
    final showIcon = themeConfig['show_icon'] ?? true;
    final showPercentage = themeConfig['show_percentage'] ?? true;

    if (style == 'bar') {
      return _buildBarContent(context, data, themeConfig, accentColor, showIcon, showPercentage);
    } else if (style == 'circular') {
      return _buildCircularContent(context, data, themeConfig, accentColor, showIcon, showPercentage);
    } else if (style == 'minimal') {
      return _buildMinimalContent(context, data, themeConfig, accentColor);
    }

    return _buildDefaultContent(context, data, themeConfig, accentColor, showIcon, showPercentage);
  }

  Widget _buildBarContent(
    BuildContext context,
    MediaIndicatorThemeData data,
    Map<String, dynamic> themeConfig,
    Color accentColor,
    bool showIcon,
    bool showPercentage,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showIcon)
          Icon(
            data.icon,
            color: Colors.white,
            size: themeConfig['icon_size']?.toDouble() ?? 28.0,
          ),
        if (showIcon) const SizedBox(height: 12),
        Container(
          height: themeConfig['progress_height']?.toDouble() ?? 140.0,
          width: themeConfig['progress_width']?.toDouble() ?? 8.0,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(themeConfig['progress_radius']?.toDouble() ?? 4.0),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: data.value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(themeConfig['progress_radius']?.toDouble() ?? 4.0),
                ),
              ),
            ),
          ),
        ),
        if (showPercentage) const SizedBox(height: 12),
        if (showPercentage)
          Text(
            '${(data.value * 100).round()}%',
            style: TextStyle(
              color: Colors.white,
              fontSize: themeConfig['text_size']?.toDouble() ?? 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Widget _buildCircularContent(
    BuildContext context,
    MediaIndicatorThemeData data,
    Map<String, dynamic> themeConfig,
    Color accentColor,
    bool showIcon,
    bool showPercentage,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: themeConfig['circle_size']?.toDouble() ?? 80.0,
          height: themeConfig['circle_size']?.toDouble() ?? 80.0,
          child: CircularProgressIndicator(
            value: 1.0,
            strokeWidth: themeConfig['track_stroke']?.toDouble() ?? 8.0,
            backgroundColor: Colors.white.withOpacity(0.15),
            color: accentColor.withOpacity(0.3),
          ),
        ),
        SizedBox(
          width: themeConfig['circle_size']?.toDouble() ?? 100.0,
          height: themeConfig['circle_size']?.toDouble() ?? 100.0,
          child: CircularProgressIndicator(
            value: data.value.clamp(0.0, 1.0),
            strokeWidth: themeConfig['stroke_width']?.toDouble() ?? 8.0,
            backgroundColor: Colors.transparent,
            color: accentColor,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon)
              Icon(
                data.icon,
                color: Colors.white,
                size: themeConfig['icon_size']?.toDouble() ?? 24.0,
              ),
            if (showIcon && showPercentage) const SizedBox(height: 4),
            if (showPercentage)
              Text(
                '${(data.value * 100).round()}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: themeConfig['text_size']?.toDouble() ?? 11.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMinimalContent(
    BuildContext context,
    MediaIndicatorThemeData data,
    Map<String, dynamic> themeConfig,
    Color accentColor,
  ) {
    final barHeight = themeConfig['minimal_bar_height']?.toDouble() ?? 4.0;
    final showDots = themeConfig['show_dots'] ?? true;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80.0,
          height: barHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(barHeight / 2),
            child: LinearProgressIndicator(
              value: data.value.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(accentColor),
            ),
          ),
        ),
        if (showDots)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(10, (index) {
                return Container(
                  width: 6.0,
                  height: 6.0,
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  decoration: BoxDecoration(
                    color: index < (data.value * 10).round()
                        ? accentColor
                        : Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultContent(
    BuildContext context,
    MediaIndicatorThemeData data,
    Map<String, dynamic> themeConfig,
    Color accentColor,
    bool showIcon,
    bool showPercentage,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showIcon)
          Icon(
            data.icon,
            color: Colors.white,
            size: themeConfig['icon_size']?.toDouble() ?? 24.0,
          ),
        if (showIcon) const SizedBox(height: 16),
        Text(
          showPercentage ? '${(data.value * 100).round()}%' : '',
          style: TextStyle(
            color: Colors.white,
            fontSize: themeConfig['text_size']?.toDouble() ?? 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
