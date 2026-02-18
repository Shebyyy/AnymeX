import 'package:flutter/material.dart';
import 'json_theme_config.dart';
import 'json_theme_elements.dart';

/// Top controls configuration
class JsonTopControlsConfig {
  final JsonBackgroundConfig? background;
  final JsonLayoutConfig? layout;
  final List<JsonThemeElement> elements;

  JsonTopControlsConfig({
    this.background,
    this.layout,
    this.elements = const [],
  });

  factory JsonTopControlsConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonTopControlsConfig();
    
    final elementsList = json['elements'] as List<dynamic>? ?? [];
    final elements = elementsList
        .map((e) => parseThemeElement(e as Map<String, dynamic>))
        .toList();

    return JsonTopControlsConfig(
      background: json['background'] != null 
          ? JsonBackgroundConfig.fromJson(json['background'] as Map<String, dynamic>)
          : null,
      layout: json['layout'] != null
          ? JsonLayoutConfig.fromJson(json['layout'] as Map<String, dynamic>)
          : null,
      elements: elements,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (background != null) 'background': background?.toJson(),
      if (layout != null) 'layout': layout?.toJson(),
      'elements': elements.map((e) => e.toJson()).toList(),
    };
  }
}

/// Center controls configuration
class JsonCenterControlsConfig {
  final JsonBackgroundConfig? background;
  final JsonLayoutConfig? layout;
  final List<JsonThemeElement> elements;

  JsonCenterControlsConfig({
    this.background,
    this.layout,
    this.elements = const [],
  });

  factory JsonCenterControlsConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonCenterControlsConfig();
    
    final elementsList = json['elements'] as List<dynamic>? ?? [];
    final elements = elementsList
        .map((e) => parseThemeElement(e as Map<String, dynamic>))
        .toList();

    return JsonCenterControlsConfig(
      background: json['background'] != null 
          ? JsonBackgroundConfig.fromJson(json['background'] as Map<String, dynamic>)
          : null,
      layout: json['layout'] != null
          ? JsonLayoutConfig.fromJson(json['layout'] as Map<String, dynamic>)
          : null,
      elements: elements,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (background != null) 'background': background?.toJson(),
      if (layout != null) 'layout': layout?.toJson(),
      'elements': elements.map((e) => e.toJson()).toList(),
    };
  }
}

/// Bottom controls configuration
class JsonBottomControlsConfig {
  final JsonBackgroundConfig? background;
  final JsonLayoutConfig? layout;
  final JsonProgressBarConfig? progressBar;
  final JsonButtonsConfig? buttons;

  JsonBottomControlsConfig({
    this.background,
    this.layout,
    this.progressBar,
    this.buttons,
  });

  factory JsonBottomControlsConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonBottomControlsConfig();
    
    return JsonBottomControlsConfig(
      background: json['background'] != null 
          ? JsonBackgroundConfig.fromJson(json['background'] as Map<String, dynamic>)
          : null,
      layout: json['layout'] != null
          ? JsonLayoutConfig.fromJson(json['layout'] as Map<String, dynamic>)
          : null,
      progressBar: json['progress_bar'] != null
          ? JsonProgressBarConfig.fromJson(json['progress_bar'] as Map<String, dynamic>)
          : null,
      buttons: json['buttons'] != null
          ? JsonButtonsConfig.fromJson(json['buttons'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (background != null) 'background': background?.toJson(),
      if (layout != null) 'layout': layout?.toJson(),
      if (progressBar != null) 'progress_bar': progressBar?.toJson(),
      if (buttons != null) 'buttons': buttons?.toJson(),
    };
  }
}

/// Progress bar configuration
class JsonProgressBarConfig {
  final double? height;
  final String? color;
  final String? trackColor;
  final double? thumbSize;
  final String? thumbColor;
  final bool? showTime;
  final String? timeColor;
  final double? timeSize;
  final bool? rounded;

  JsonProgressBarConfig({
    this.height,
    this.color,
    this.trackColor,
    this.thumbSize,
    this.thumbColor,
    this.showTime,
    this.timeColor,
    this.timeSize,
    this.rounded,
  });

  factory JsonProgressBarConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonProgressBarConfig();
    
    return JsonProgressBarConfig(
      height: (json['height'] as num?)?.toDouble(),
      color: json['color'] as String?,
      trackColor: json['track_color'] as String?,
      thumbSize: (json['thumb_size'] as num?)?.toDouble(),
      thumbColor: json['thumb_color'] as String?,
      showTime: json['show_time'] as bool,
      timeColor: json['time_color'] as String?,
      timeSize: (json['time_size'] as num?)?.toDouble(),
      rounded: json['rounded'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (height != null) 'height': height,
      if (color != null) 'color': color,
      if (trackColor != null) 'track_color': trackColor,
      if (thumbSize != null) 'thumb_size': thumbSize,
      if (thumbColor != null) 'thumb_color': thumbColor,
      if (showTime != null) 'show_time': showTime,
      if (timeColor != null) 'time_color': timeColor,
      if (timeSize != null) 'time_size': timeSize,
      if (rounded != null) 'rounded': rounded,
    };
  }

  Color? get parsedColor => color != null ? _parseColor(color!) : null;
  Color? get parsedTrackColor => trackColor != null ? _parseColor(trackColor!) : null;
  Color? get parsedThumbColor => thumbColor != null ? _parseColor(thumbColor!) : null;
  Color? get parsedTimeColor => timeColor != null ? _parseColor(timeColor!) : null;

  Color _parseColor(String colorString) {
    String hex = colorString;
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    return Color(int.parse('FF$hex'));
  }
}

/// Buttons configuration
class JsonButtonsConfig {
  final bool? useBuiltinLayout;
  final String? buttonColor;
  final String? buttonActiveColor;
  final double? buttonSize;
  final double? buttonSpacing;

  JsonButtonsConfig({
    this.useBuiltinLayout = true,
    this.buttonColor,
    this.buttonActiveColor,
    this.buttonSize,
    this.buttonSpacing,
  });

  factory JsonButtonsConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonButtonsConfig();
    
    return JsonButtonsConfig(
      useBuiltinLayout: json['use_builtin_layout'] as bool? ?? true,
      buttonColor: json['button_color'] as String?,
      buttonActiveColor: json['button_active_color'] as String?,
      buttonSize: (json['button_size'] as num?)?.toDouble(),
      buttonSpacing: (json['button_spacing'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'use_builtin_layout': useBuiltinLayout,
      if (buttonColor != null) 'button_color': buttonColor,
      if (buttonActiveColor != null) 'button_active_color': buttonActiveColor,
      if (buttonSize != null) 'button_size': buttonSize,
      if (buttonSpacing != null) 'button_spacing': buttonSpacing,
    };
  }

  Color? get parsedButtonColor => buttonColor != null ? _parseColor(buttonColor!) : null;
  Color? get parsedButtonActiveColor => buttonActiveColor != null ? _parseColor(buttonActiveColor!) : null;

  Color _parseColor(String colorString) {
    String hex = colorString;
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    return Color(int.parse('FF$hex'));
  }
}
