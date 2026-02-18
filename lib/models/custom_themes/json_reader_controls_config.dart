import 'package:flutter/material.dart';
import 'json_theme_config.dart';
import 'json_theme_elements.dart';

/// Reader top controls configuration
class JsonReaderTopControlsConfig {
  final JsonBackgroundConfig? background;
  final JsonLayoutConfig? layout;
  final List<JsonThemeElement> elements;

  JsonReaderTopControlsConfig({
    this.background,
    this.layout,
    this.elements = const [],
  });

  factory JsonReaderTopControlsConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonReaderTopControlsConfig();
    
    final elementsList = json['elements'] as List<dynamic>? ?? [];
    final elements = elementsList
        .map((e) => parseThemeElement(e as Map<String, dynamic>))
        .toList();

    return JsonReaderTopControlsConfig(
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

/// Reader bottom controls configuration
class JsonReaderBottomControlsConfig {
  final JsonBackgroundConfig? background;
  final JsonLayoutConfig? layout;
  final JsonProgressBarConfig? progressBar;
  final JsonNavigationConfig? navigation;

  JsonReaderBottomControlsConfig({
    this.background,
    this.layout,
    this.progressBar,
    this.navigation,
  });

  factory JsonReaderBottomControlsConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonReaderBottomControlsConfig();
    
    return JsonReaderBottomControlsConfig(
      background: json['background'] != null 
          ? JsonBackgroundConfig.fromJson(json['background'] as Map<String, dynamic>)
          : null,
      layout: json['layout'] != null
          ? JsonLayoutConfig.fromJson(json['layout'] as Map<String, dynamic>)
          : null,
      progressBar: json['progress_bar'] != null
          ? JsonProgressBarConfig.fromJson(json['progress_bar'] as Map<String, dynamic>)
          : null,
      navigation: json['navigation'] != null
          ? JsonNavigationConfig.fromJson(json['navigation'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (background != null) 'background': background?.toJson(),
      if (layout != null) 'layout': layout?.toJson(),
      if (progressBar != null) 'progress_bar': progressBar?.toJson(),
      if (navigation != null) 'navigation': navigation?.toJson(),
    };
  }
}

/// Reader navigation configuration
class JsonNavigationConfig {
  final double? iconSize;
  final String? iconColor;
  final bool? showPageNumbers;
  final bool? showChapters;
  final bool? showPageSlider;

  JsonNavigationConfig({
    this.iconSize,
    this.iconColor,
    this.showPageNumbers = true,
    this.showChapters = false,
    this.showPageSlider = true,
  });

  factory JsonNavigationConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonNavigationConfig();
    
    return JsonNavigationConfig(
      iconSize: (json['icon_size'] as num?)?.toDouble(),
      iconColor: json['icon_color'] as String?,
      showPageNumbers: json['show_page_numbers'] as bool? ?? true,
      showChapters: json['show_chapters'] as bool? ?? false,
      showPageSlider: json['show_page_slider'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (iconSize != null) 'icon_size': iconSize,
      if (iconColor != null) 'icon_color': iconColor,
      'show_page_numbers': showPageNumbers,
      'show_chapters': showChapters,
      'show_page_slider': showPageSlider,
    };
  }

  Color? get parsedIconColor => iconColor != null ? _parseColor(iconColor!) : null;

  Color _parseColor(String colorString) {
    String hex = colorString;
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    return Color(int.parse('FF$hex'));
  }
}
