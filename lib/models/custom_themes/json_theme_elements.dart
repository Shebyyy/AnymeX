import 'package:flutter/material.dart';
import 'json_theme_config.dart';

/// Base class for theme elements
abstract class JsonThemeElement {
  final String type;
  final double? size;
  final String? color;
  final JsonShadowConfig? glow;
  final String? position;

  JsonThemeElement({
    required this.type,
    this.size,
    this.color,
    this.glow,
    this.position,
  });

  factory JsonThemeElement.fromJson(Map<String, dynamic> json) {
    final glow = json['glow'] != null
        ? JsonShadowConfig.fromJson(json['glow'] as Map<String, dynamic>)
        : null;

    return _UnknownElement(
      type: json['type'] as String,
      size: (json['size'] as num?)?.toDouble(),
      color: json['color'] as String?,
      glow: glow,
      position: json['position'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (size != null) 'size': size,
      if (color != null) 'color': color,
      if (glow != null) 'glow': glow?.toJson(),
      if (position != null) 'position': position,
    };
  }

  Color? get parsedColor => color != null ? _parseColor(color!) : null;

  Color _parseColor(String colorString) {
    String hex = colorString;
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    return Color(int.parse('FF$hex'));
  }

  List<BoxShadow>? get glowShadows {
    if (glow?.color == null) return null;
    return glow?.buildShadows();
  }
}

/// Back button element
class JsonBackButtonElement extends JsonThemeElement {
  final String? icon;

  JsonBackButtonElement({
    super.type = 'back_button',
    this.icon,
    super.size,
    super.color,
    super.glow,
    super.position,
  });

  factory JsonBackButtonElement.fromJson(Map<String, dynamic> json) {
    return JsonBackButtonElement(
      icon: json['icon'] as String?,
      size: (json['size'] as num?)?.toDouble(),
      color: json['color'] as String?,
      glow: json['glow'] != null
          ? JsonShadowConfig.fromJson(json['glow'] as Map<String, dynamic>)
          : null,
      position: json['position'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (icon != null) json['icon'] = icon;
    return json;
  }
}

/// Title text element
class JsonTitleElement extends JsonThemeElement {
  final String? text;
  final double? fontSize;
  final int? maxLines;
  final String? alignment;

  JsonTitleElement({
    super.type = 'title',
    this.text,
    this.fontSize,
    this.maxLines,
    this.alignment,
    super.size,
    super.color,
    super.glow,
    super.position,
  });

  factory JsonTitleElement.fromJson(Map<String, dynamic> json) {
    return JsonTitleElement(
      text: json['text'] as String?,
      fontSize: (json['size'] as num?)?.toDouble(),
      maxLines: (json['max_lines'] as int?) ?? 1,
      alignment: json['alignment'] as String?,
      size: (json['size'] as num?)?.toDouble(),
      color: json['color'] as String?,
      glow: json['glow'] != null
          ? JsonShadowConfig.fromJson(json['glow'] as Map<String, dynamic>)
          : null,
      position: json['position'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (text != null) json['text'] = text;
    if (fontSize != null) json['size'] = fontSize;
    if (maxLines != null) json['max_lines'] = maxLines;
    if (alignment != null) json['alignment'] = alignment;
    return json;
  }
}

/// Subtitle text element
class JsonSubtitleElement extends JsonThemeElement {
  final String? text;
  final double? fontSize;
  final int? maxLines;

  JsonSubtitleElement({
    super.type = 'subtitle',
    this.text,
    this.fontSize,
    this.maxLines,
    super.size,
    super.color,
    super.glow,
    super.position,
  });

  factory JsonSubtitleElement.fromJson(Map<String, dynamic> json) {
    return JsonSubtitleElement(
      text: json['text'] as String?,
      fontSize: (json['size'] as num?)?.toDouble(),
      maxLines: (json['max_lines'] as int?) ?? 2,
      size: (json['size'] as num?)?.toDouble(),
      color: json['color'] as String?,
      glow: json['glow'] != null
          ? JsonShadowConfig.fromJson(json['glow'] as Map<String, dynamic>)
          : null,
      position: json['position'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (text != null) json['text'] = text;
    if (fontSize != null) json['size'] = fontSize;
    if (maxLines != null) json['max_lines'] = maxLines;
    return json;
  }
}

/// Settings button element
class JsonSettingsButtonElement extends JsonThemeElement {
  final String? icon;

  JsonSettingsButtonElement({
    super.type = 'settings_button',
    this.icon,
    super.size,
    super.color,
    super.glow,
    super.position,
  });

  factory JsonSettingsButtonElement.fromJson(Map<String, dynamic> json) {
    return JsonSettingsButtonElement(
      icon: json['icon'] as String?,
      size: (json['size'] as num?)?.toDouble(),
      color: json['color'] as String?,
      glow: json['glow'] != null
          ? JsonShadowConfig.fromJson(json['glow'] as Map<String, dynamic>)
          : null,
      position: json['position'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (icon != null) json['icon'] = icon;
    return json;
  }
}

/// Lock button element
class JsonLockButtonElement extends JsonThemeElement {
  final String? icon;

  JsonLockButtonElement({
    super.type = 'lock_button',
    this.icon,
    super.size,
    super.color,
    super.glow,
    super.position,
  });

  factory JsonLockButtonElement.fromJson(Map<String, dynamic> json) {
    return JsonLockButtonElement(
      icon: json['icon'] as String?,
      size: (json['size'] as num?)?.toDouble(),
      color: json['color'] as String?,
      glow: json['glow'] != null
          ? JsonShadowConfig.fromJson(json['glow'] as Map<String, dynamic>)
          : null,
      position: json['position'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (icon != null) json['icon'] = icon;
    return json;
  }
}

/// Play/Pause button element
class JsonPlayPauseElement extends JsonThemeElement {
  final String? iconPlay;
  final String? iconPause;

  JsonPlayPauseElement({
    super.type = 'play_pause',
    this.iconPlay,
    this.iconPause,
    super.size,
    super.color,
    super.glow,
    super.position,
  });

  factory JsonPlayPauseElement.fromJson(Map<String, dynamic> json) {
    return JsonPlayPauseElement(
      iconPlay: json['icon_play'] as String?,
      iconPause: json['icon_pause'] as String?,
      size: (json['size'] as num?)?.toDouble(),
      color: json['color'] as String?,
      glow: json['glow'] != null
          ? JsonShadowConfig.fromJson(json['glow'] as Map<String, dynamic>)
          : null,
      position: json['position'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (iconPlay != null) json['icon_play'] = iconPlay;
    if (iconPause != null) json['icon_pause'] = iconPause;
    return json;
  }
}

/// Seek backward button element
class JsonSeekBackwardElement extends JsonThemeElement {
  final String? icon;

  JsonSeekBackwardElement({
    super.type = 'seek_backward',
    this.icon,
    super.size,
    super.color,
    super.glow,
    super.position,
  });

  factory JsonSeekBackwardElement.fromJson(Map<String, dynamic> json) {
    return JsonSeekBackwardElement(
      icon: json['icon'] as String?,
      size: (json['size'] as num?)?.toDouble(),
      color: json['color'] as String?,
      glow: json['glow'] != null
          ? JsonShadowConfig.fromJson(json['glow'] as Map<String, dynamic>)
          : null,
      position: json['position'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (icon != null) json['icon'] = icon;
    return json;
  }
}

/// Seek forward button element
class JsonSeekForwardElement extends JsonThemeElement {
  final String? icon;

  JsonSeekForwardElement({
    super.type = 'seek_forward',
    this.icon,
    super.size,
    super.color,
    super.glow,
    super.position,
  });

  factory JsonSeekForwardElement.fromJson(Map<String, dynamic> json) {
    return JsonSeekForwardElement(
      icon: json['icon'] as String?,
      size: (json['size'] as num?)?.toDouble(),
      color: json['color'] as String?,
      glow: json['glow'] != null
          ? JsonShadowConfig.fromJson(json['glow'] as Map<String, dynamic>)
          : null,
      position: json['position'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    if (icon != null) json['icon'] = icon;
    return json;
  }
}

/// Parse element from JSON based on type
JsonThemeElement parseThemeElement(Map<String, dynamic> json) {
  final type = json['type'] as String;
  
  switch (type) {
    case 'back_button':
      return JsonBackButtonElement.fromJson(json);
    case 'title':
      return JsonTitleElement.fromJson(json);
    case 'subtitle':
      return JsonSubtitleElement.fromJson(json);
    case 'settings_button':
      return JsonSettingsButtonElement.fromJson(json);
    case 'lock_button':
      return JsonLockButtonElement.fromJson(json);
    case 'play_pause':
      return JsonPlayPauseElement.fromJson(json);
    case 'seek_backward':
      return JsonSeekBackwardElement.fromJson(json);
    case 'seek_forward':
      return JsonSeekForwardElement.fromJson(json);
    default:
      return _UnknownElement(
        type: type,
        size: (json['size'] as num?)?.toDouble(),
        color: json['color'] as String?,
        glow: json['glow'] != null
            ? JsonShadowConfig.fromJson(json['glow'] as Map<String, dynamic>)
            : null,
        position: json['position'] as String?,
      );
  }
}

/// Unknown element type fallback
class _UnknownElement extends JsonThemeElement {
  _UnknownElement({
    required super.type,
    super.size,
    super.color,
    super.glow,
    super.position,
  });
}
