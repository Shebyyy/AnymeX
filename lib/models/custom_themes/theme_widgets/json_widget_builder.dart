import 'dart:math' as math;

import 'package:anymex/models/custom_themes/theme_widgets/json_theme_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Builds widgets dynamically from JSON configuration
class JsonWidgetBuilder {
  /// Parse and build widgets from component list
  static List<Widget> buildComponents(
    List<dynamic> componentsJson,
    Map<String, dynamic> contextData,
  ) {
    if (componentsJson.isEmpty) return [];
    
    return componentsJson
        .map((json) => _buildComponent(json, contextData))
        .where((w) => w != null)
        .cast<Widget>()
        .toList();
  }

  /// Build a single component from JSON
  static Widget? _buildComponent(
    Map<String, dynamic> json,
    Map<String, dynamic> contextData,
  ) {
    final type = json['type'] as String?;
    if (type == null) return null;

    switch (type) {
      case 'icon_button':
        return _buildIconButton(json, contextData);
      case 'text':
        return _buildText(json, contextData);
      case 'container':
        return _buildContainer(json, contextData);
      case 'progress_slider':
        return _buildProgressSlider(json, contextData);
      case 'row':
      case 'column':
        return _buildRowColumn(json, contextData);
      default:
        return null;
    }
  }

  /// Build icon button component
  static Widget _buildIconButton(
    Map<String, dynamic> json,
    Map<String, dynamic> contextData,
  ) {
    final icon = _parseIcon(json['icon']);
    final size = (json['size'] as num?)?.toDouble() ?? 24.0;
    final color = JsonThemeColor.fromJson(json['color']).solid;
    final background = JsonThemeDecoration.fromJson(json['background'] as Map?);
    final onTap = json['on_tap'] as String?;
    final animations = JsonThemeAnimations.fromJson(json['animations'] as Map?);
    final glow = JsonThemeGlow.fromJson(json['glow'] as Map?);
    final margin = JsonThemeMargin.fromJson(json['margin']);
    final padding = JsonThemePadding.fromJson(json['padding']);
    final disabled = json['disabled'] == true;

    Widget iconWidget = Icon(
      icon,
      color: disabled ? (color ?? Colors.white).withOpacity(0.4) : (color ?? Colors.white),
      size: size,
    );

    // Add glow effect
    if (glow.build() != null && !disabled) {
      iconWidget = Container(
        decoration: BoxDecoration(boxShadow: [glow.build()!]),
        child: iconWidget,
      );
    }

    // Wrap in background if specified
    if (background.background != null || background.border != null) {
      iconWidget = Container(
        decoration: background.build(),
        padding: padding.padding as EdgeInsets?,
        child: iconWidget,
      );
    } else {
      iconWidget = Padding(padding: padding.padding as EdgeInsets?, child: iconWidget);
    }

    // Apply margin
    if (margin.margin != null) {
      iconWidget = Padding(padding: margin.margin as EdgeInsets?, child: iconWidget);
    }

    // Handle tap action if specified
    if (onTap != null && !disabled) {
      VoidCallback? action = _parseAction(onTap, contextData);
      if (action != null) {
        return InkWell(
          onTap: action,
          borderRadius: background.borderRadius ?? BorderRadius.circular(8),
          child: iconWidget,
        );
      }
    }

    return iconWidget;
  }

  /// Build text component
  static Widget _buildText(
    Map<String, dynamic> json,
    Map<String, dynamic> contextData,
  ) {
    final content = _replacePlaceholders(
      json['content'] as String? ?? '',
      contextData,
    );
    final style = JsonThemeTextStyle.fromJson(json['style'] as Map?);
    final margin = JsonThemeMargin.fromJson(json['margin']);
    final padding = JsonThemePadding.fromJson(json['padding']);
    final decoration = JsonThemeDecoration.fromJson(json['decoration'] as Map?);
    final textAlign = _parseTextAlign(json['align']);
    final maxLines = (json['max_lines'] as num?)?.toInt();
    final overflow = _parseTextOverflow(json['overflow']);

    Widget textWidget = Text(
      content,
      style: style.build(),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );

    // Wrap in decoration if specified
    if (decoration.background != null || decoration.border != null) {
      textWidget = Container(
        decoration: decoration.build(),
        padding: padding.padding as EdgeInsets?,
        child: textWidget,
      );
    } else {
      textWidget = Padding(padding: padding.padding as EdgeInsets?, child: textWidget);
    }

    // Apply margin
    if (margin.margin != null) {
      textWidget = Padding(padding: margin.margin as EdgeInsets?, child: textWidget);
    }

    return textWidget;
  }

  /// Build container component
  static Widget _buildContainer(
    Map<String, dynamic> json,
    Map<String, dynamic> contextData,
  ) {
    final decoration = JsonThemeDecoration.fromJson(json['decoration'] as Map?);
    final margin = JsonThemeMargin.fromJson(json['margin']);
    final padding = JsonThemePadding.fromJson(json['padding']);
    final layout = JsonThemeLayout.fromJson(json['layout'] as Map?);
    final childrenJson = json['children'] as List?;
    final child = json['child'] as Map?;

    // Build children
    List<Widget> children = [];
    if (childrenJson != null) {
      children = buildComponents(childrenJson, contextData);
    }

    Widget containerChild;
    if (child != null) {
      containerChild = _buildComponent(child, contextData) ?? Container();
    } else if (children.isNotEmpty) {
      if (layout.type == 'column') {
        containerChild = Column(
          mainAxisSize: layout.mainAxisSize,
          mainAxisAlignment: layout.mainAxisAlignment,
          crossAxisAlignment: layout.crossAxisAlignment,
          children: children,
        );
      } else {
        containerChild = Row(
          mainAxisSize: layout.mainAxisSize,
          mainAxisAlignment: layout.mainAxisAlignment,
          crossAxisAlignment: layout.crossAxisAlignment,
          children: children,
        );
      }
    } else {
      containerChild = Container();
    }

    // Apply blur if enabled
    if (decoration.blur?.enabled == true) {
      containerChild = ClipRRect(
        borderRadius: decoration.borderRadius ?? BorderRadius.zero,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: decoration.blur?.sigma ?? 10.0,
            sigmaY: decoration.blur?.sigma ?? 10.0,
          ),
          child: containerChild,
        ),
      );
    }

    // Build container with decoration
    Widget container = Container(
      decoration: decoration.build(),
      padding: padding.padding as EdgeInsets?,
      child: containerChild,
    );

    // Apply margin
    if (margin.margin != null) {
      container = Padding(padding: margin.margin as EdgeInsets?, child: container);
    }

    return container;
  }

  /// Build progress slider component
  static Widget _buildProgressSlider(
    Map<String, dynamic> json,
    Map<String, dynamic> contextData,
  ) {
    final height = (json['height'] as num?)?.toDouble() ?? 4.0;
    final trackColor = JsonThemeColor.fromJson(json['track_color']).solid ?? Colors.white24;
    final progressColor = JsonThemeColor.fromJson(json['progress_color']).solid ?? Colors.blue;
    final thumbJson = json['thumb'] as Map?;
    final margin = JsonThemeMargin.fromJson(json['margin']);
    
    final thumbSize = (thumbJson?['size'] as num?)?.toDouble() ?? 14.0;
    final thumbColor = JsonThemeColor.fromJson(thumbJson?['color']).solid ?? progressColor;
    final thumbGlow = JsonThemeGlow.fromJson(thumbJson?['glow'] as Map?);
    
    // Get progress value from context
    final progress = (contextData['progress'] as double? ?? 0.0).clamp(0.0, 1.0);

    // Build thumb widget with glow
    Widget thumbWidget = Container(
      width: thumbSize,
      height: thumbSize,
      decoration: BoxDecoration(
        color: thumbColor,
        shape: BoxShape.circle,
        boxShadow: thumbGlow.build() != null ? [thumbGlow.build()!] : null,
      ),
    );

    Widget slider = Container(
      height: height,
      child: Stack(
        children: [
          // Track
          ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: Container(
              color: trackColor,
              width: double.infinity,
              height: height,
            ),
          ),
          // Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: FractionallySizedBox(
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: Container(
                color: progressColor,
                height: height,
              ),
            ),
          ),
          // Thumb
          Positioned(
            left: (progress * 300) - (thumbSize / 2), // Approximate positioning
            top: (height - thumbSize) / 2,
            child: thumbWidget,
          ),
        ],
      ),
    );

    // Apply margin
    if (margin.margin != null) {
      slider = Padding(padding: margin.margin as EdgeInsets?, child: slider);
    }

    return slider;
  }

  /// Build row/column layout component
  static Widget _buildRowColumn(
    Map<String, dynamic> json,
    Map<String, dynamic> contextData,
  ) {
    final layout = JsonThemeLayout.fromJson(json['layout'] as Map?);
    final childrenJson = json['children'] as List?;
    final decoration = JsonThemeDecoration.fromJson(json['decoration'] as Map?);
    final margin = JsonThemeMargin.fromJson(json['margin']);
    final padding = JsonThemePadding.fromJson(json['padding']);

    List<Widget> children = [];
    if (childrenJson != null) {
      children = buildComponents(childrenJson, contextData);
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
      // Default to row
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

    // Build container with decoration
    Widget container = Container(
      decoration: decoration.build(),
      padding: padding.padding as EdgeInsets?,
      child: child,
    );

    // Apply margin
    if (margin.margin != null) {
      container = Padding(padding: margin.margin as EdgeInsets?, child: container);
    }

    return container;
  }

  /// Parse icon string to IconData
  static IconData _parseIcon(dynamic iconJson) {
    if (iconJson == null) return Icons.circle;

    if (iconJson is String) {
      final iconMap = {
        'arrow_back': Icons.arrow_back,
        'arrow_back_ios': Icons.arrow_back_ios,
        'close': Icons.close,
        'play_arrow': Icons.play_arrow,
        'pause': Icons.pause,
        'stop': Icons.stop,
        'skip_next': Icons.skip_next,
        'skip_previous': Icons.skip_previous,
        'fast_forward': Icons.fast_forward,
        'fast_rewind': Icons.fast_rewind,
        'replay_10': Icons.replay_10_rounded,
        'forward_10': Icons.forward_10_rounded,
        'settings': Icons.settings,
        'more_vert': Icons.more_vert,
        'more_horiz': Icons.more_horiz,
        'brightness_high': Icons.brightness_high,
        'brightness_low': Icons.brightness_low,
        'brightness_medium': Icons.brightness_medium,
        'volume_up': Icons.volume_up,
        'volume_down': Icons.volume_down,
        'volume_mute': Icons.volume_mute,
        'volume_off': Icons.volume_off,
        'playlist_play': Icons.playlist_play,
        'subtitles': Icons.subtitles,
        'tune': Icons.tune,
        'style': Icons.style,
        'aspect_ratio': Icons.aspect_ratio,
        'speed': Icons.speed,
        'skip_next_rounded': Icons.skip_next_rounded,
        'play_circle': Icons.play_circle_outline,
        'pause_circle': Icons.pause_circle_outline,
        'fullscreen': Icons.fullscreen,
        'fullscreen_exit': Icons.fullscreen_exit,
        'favorite': Icons.favorite,
        'favorite_border': Icons.favorite_border,
        'bookmark': Icons.bookmark,
        'bookmark_border': Icons.bookmark_border,
        'share': Icons.share,
        'download': Icons.download,
        'check_circle': Icons.check_circle,
        'chevron_left': Icons.chevron_left,
        'chevron_right': Icons.chevron_right,
        'chevron_up': Icons.chevron_up,
        'chevron_down': Icons.chevron_down,
        'first_page': Icons.first_page,
        'last_page': Icons.last_page,
        'menu': Icons.menu,
        'home': Icons.home,
        'search': Icons.search,
      };

      return iconMap[iconJson.toLowerCase()] ?? Icons.circle;
    }

    return Icons.circle;
  }

  /// Parse action string and return callback
  static VoidCallback? _parseAction(String action, Map<String, dynamic> contextData) {
    // This would need to be implemented based on available actions
    // For now, return null (will be implemented in theme-specific builders)
    return null;
  }

  /// Parse text alignment
  static TextAlign? _parseTextAlign(dynamic align) {
    if (align == null) return null;
    if (align is String) {
      switch (align.toLowerCase()) {
        case 'left':
          return TextAlign.left;
        case 'right':
          return TextAlign.right;
        case 'center':
          return TextAlign.center;
        case 'justify':
          return TextAlign.justify;
        case 'start':
          return TextAlign.start;
        case 'end':
          return TextAlign.end;
      }
    }
    return null;
  }

  /// Parse text overflow
  static TextOverflow _parseTextOverflow(dynamic overflow) {
    if (overflow == null) return TextOverflow.fade;
    if (overflow is String) {
      switch (overflow.toLowerCase()) {
        case 'clip':
          return TextOverflow.clip;
        case 'ellipsis':
          return TextOverflow.ellipsis;
        case 'fade':
          return TextOverflow.fade;
        case 'visible':
          return TextOverflow.visible;
      }
    }
    return TextOverflow.fade;
  }

  /// Replace placeholders in content with actual values
  static String _replacePlaceholders(String content, Map<String, dynamic> contextData) {
    String result = content;
    
    // Replace {{placeholder}} with actual values
    contextData.forEach((key, value) {
      final placeholder = '{{$key}}';
      result = result.replaceAll(placeholder, value?.toString() ?? '');
    });
    
    return result;
  }
}
