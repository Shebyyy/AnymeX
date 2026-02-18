import 'package:flutter/material.dart';
import 'json_theme_config.dart';

/// Container configuration for media indicator
class JsonMediaContainerConfig {
  final double? width;
  final double? height;
  final JsonBackgroundConfig? background;
  final String? shape;

  JsonMediaContainerConfig({
    this.width,
    this.height,
    this.background,
    this.shape,
  });

  factory JsonMediaContainerConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonMediaContainerConfig();
    
    return JsonMediaContainerConfig(
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      background: json['background'] != null
          ? JsonBackgroundConfig.fromJson(json['background'] as Map<String, dynamic>)
          : null,
      shape: json['shape'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (background != null) 'background': background?.toJson(),
      if (shape != null) 'shape': shape,
    };
  }
}

/// Progress configuration for media indicator
class JsonMediaProgressConfig {
  final String? type; // 'circular', 'bar', 'minimal'
  final double? strokeWidth;
  final String? color;
  final String? trackColor;
  final bool? showTrack;
  final JsonShadowConfig? glow;
  final double? height;
  final bool? rounded;

  JsonMediaProgressConfig({
    this.type = 'circular',
    this.strokeWidth,
    this.color,
    this.trackColor,
    this.showTrack = true,
    this.glow,
    this.height,
    this.rounded = true,
  });

  factory JsonMediaProgressConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonMediaProgressConfig();
    
    return JsonMediaProgressConfig(
      type: json['type'] as String? ?? 'circular',
      strokeWidth: (json['stroke_width'] as num?)?.toDouble(),
      color: json['color'] as String?,
      trackColor: json['track_color'] as String?,
      showTrack: json['show_track'] as bool? ?? true,
      glow: json['glow'] != null
          ? JsonShadowConfig.fromJson(json['glow'] as Map<String, dynamic>)
          : null,
      height: (json['height'] as num?)?.toDouble(),
      rounded: json['rounded'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (strokeWidth != null) 'stroke_width': strokeWidth,
      if (color != null) 'color': color,
      if (trackColor != null) 'track_color': trackColor,
      'show_track': showTrack,
      if (glow != null) 'glow': glow?.toJson(),
      if (height != null) 'height': height,
      'rounded': rounded,
    };
  }

  Color? get parsedColor => color != null ? _parseColor(color!) : null;
  Color? get parsedTrackColor => trackColor != null ? _parseColor(trackColor!) : null;
  List<BoxShadow>? get glowShadows => glow?.buildShadows();

  Color _parseColor(String colorString) {
    String hex = colorString;
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    return Color(int.parse('FF$hex', radix: 16));
  }
}

/// Content configuration for media indicator
class JsonMediaContentConfig {
  final bool? showIcon;
  final double? iconSize;
  final String? iconColor;
  final bool? showPercentage;
  final double? percentageSize;
  final String? percentageColor;

  JsonMediaContentConfig({
    this.showIcon = true,
    this.iconSize,
    this.iconColor,
    this.showPercentage = true,
    this.percentageSize,
    this.percentageColor,
  });

  factory JsonMediaContentConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonMediaContentConfig();
    
    return JsonMediaContentConfig(
      showIcon: json['show_icon'] as bool? ?? true,
      iconSize: (json['icon_size'] as num?)?.toDouble(),
      iconColor: json['icon_color'] as String?,
      showPercentage: json['show_percentage'] as bool? ?? true,
      percentageSize: (json['percentage_size'] as num?)?.toDouble(),
      percentageColor: json['percentage_color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'show_icon': showIcon,
      if (iconSize != null) 'icon_size': iconSize,
      if (iconColor != null) 'icon_color': iconColor,
      'show_percentage': showPercentage,
      if (percentageSize != null) 'percentage_size': percentageSize,
      if (percentageColor != null) 'percentage_color': percentageColor,
    };
  }

  Color? get parsedIconColor => iconColor != null ? _parseColor(iconColor!) : null;
  Color? get parsedPercentageColor => percentageColor != null ? _parseColor(percentageColor!) : null;

  Color _parseColor(String colorString) {
    String hex = colorString;
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    return Color(int.parse('FF$hex', radix: 16));
  }
}

/// Animations configuration
class JsonAnimationsConfig {
  final int? fadeDuration;
  final int? scaleDuration;
  final int? slideDuration;
  final String? curve;

  JsonAnimationsConfig({
    this.fadeDuration = 200,
    this.scaleDuration = 200,
    this.slideDuration = 300,
    this.curve = 'ease_out_cubic',
  });

  factory JsonAnimationsConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonAnimationsConfig();
    
    return JsonAnimationsConfig(
      fadeDuration: (json['fade_duration'] as num?)?.toInt() ?? 200,
      scaleDuration: (json['scale_duration'] as num?)?.toInt() ?? 200,
      slideDuration: (json['slide_duration'] as num?)?.toInt() ?? 300,
      curve: json['curve'] as String? ?? 'ease_out_cubic',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fade_duration': fadeDuration,
      'scale_duration': scaleDuration,
      'slide_duration': slideDuration,
      'curve': curve,
    };
  }

  Curve get fadeCurve => _parseCurve(curve ?? 'ease_out_cubic');
  Curve get scaleCurve => _parseCurve(curve ?? 'ease_out_cubic');
  Curve get slideCurve => _parseCurve(curve ?? 'ease_out_cubic');

  Curve _parseCurve(String curveName) {
    switch (curveName.toLowerCase()) {
      case 'ease_in':
        return Curves.easeIn;
      case 'ease_out':
        return Curves.easeOut;
      case 'ease_in_out':
        return Curves.easeInOut;
      case 'ease_in_cubic':
        return Curves.easeInCubic;
      case 'ease_out_cubic':
        return Curves.easeOutCubic;
      case 'ease_in_out_cubic':
        return Curves.easeInOutCubic;
      case 'ease_in_back':
        return Curves.easeInBack;
      case 'ease_out_back':
        return Curves.easeOutBack;
      case 'ease_in_out_back':
        return Curves.easeInOutBack;
      case 'ease_in_quad':
        return Curves.easeInQuad;
      case 'ease_out_quad':
        return Curves.easeOutQuad;
      case 'ease_in_out_quad':
        return Curves.easeInOutQuad;
      case 'elastic_in':
        return Curves.elasticIn;
      case 'elastic_out':
        return Curves.elasticOut;
      case 'elastic_in_out':
        return Curves.elasticInOut;
      default:
        return Curves.easeOutCubic;
    }
  }
}

/// Main configuration for media indicator theme
class JsonMediaIndicatorConfig {
  final String? style;
  final String? position;
  final JsonMediaContainerConfig? container;
  final JsonMediaProgressConfig? progress;
  final JsonMediaContentConfig? content;
  final JsonAnimationsConfig? animations;

  JsonMediaIndicatorConfig({
    this.style = 'circular',
    this.position = 'center',
    this.container,
    this.progress,
    this.content,
    this.animations,
  });

  factory JsonMediaIndicatorConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonMediaIndicatorConfig();
    
    return JsonMediaIndicatorConfig(
      style: json['style'] as String? ?? 'circular',
      position: json['position'] as String? ?? 'center',
      container: json['container'] != null
          ? JsonMediaContainerConfig.fromJson(json['container'] as Map<String, dynamic>)
          : null,
      progress: json['progress'] != null
          ? JsonMediaProgressConfig.fromJson(json['progress'] as Map<String, dynamic>)
          : null,
      content: json['content'] != null
          ? JsonMediaContentConfig.fromJson(json['content'] as Map<String, dynamic>)
          : null,
      animations: json['animations'] != null
          ? JsonAnimationsConfig.fromJson(json['animations'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'style': style,
      if (position != null) 'position': position,
      if (container != null) 'container': container?.toJson(),
      if (progress != null) 'progress': progress?.toJson(),
      if (content != null) 'content': content?.toJson(),
      if (animations != null) 'animations': animations?.toJson(),
    };
  }

  Alignment get alignment {
    switch (position) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      case 'top':
        return Alignment.topCenter;
      case 'bottom':
        return Alignment.bottomCenter;
      case 'center':
      default:
        return Alignment.center;
    }
  }
}
