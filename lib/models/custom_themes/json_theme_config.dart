import 'package:flutter/material.dart';

class JsonColorParser {
  static Color parse(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return Colors.transparent;
    }

    String hex = colorString.trim().toUpperCase();
    hex = hex.replaceAll('#', '').replaceAll('0X', '');

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    return Color(int.parse(hex, radix: 16));
  }
}

class JsonBackgroundConfig {
  final String? color;
  final double? opacity;
  final double? blur;
  final JsonBorderConfig? border;
  final JsonShadowConfig? shadow;
  final JsonGradientConfig? gradient;

  JsonBackgroundConfig({
    this.color,
    this.opacity,
    this.blur,
    this.border,
    this.shadow,
    this.gradient,
  });

  factory JsonBackgroundConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonBackgroundConfig();

    return JsonBackgroundConfig(
      color: json['color'] as String?,
      opacity: (json['opacity'] as num?)?.toDouble(),
      blur: (json['blur'] as num?)?.toDouble(),
      border: json['border'] != null
          ? JsonBorderConfig.fromJson(json['border'])
          : null,
      shadow: json['shadow'] != null
          ? JsonShadowConfig.fromJson(json['shadow'])
          : null,
      gradient: json['gradient'] != null
          ? JsonGradientConfig.fromJson(json['gradient'])
          : null,
    );
  }

  BoxDecoration buildDecoration(BuildContext context) {
    return BoxDecoration(
      color: color != null
          ? JsonColorParser.parse(color!).withOpacity(opacity ?? 1.0)
          : null,
      gradient: gradient?.buildGradient(),
      border: border?.buildBorder(),
      boxShadow: shadow?.buildShadows(),
      borderRadius: BorderRadius.circular(border?.radius ?? 12),
    );
  }
}

class JsonBorderConfig {
  final String? color;
  final double? width;
  final double? radius;

  JsonBorderConfig({
    this.color,
    this.width,
    this.radius,
  });

  factory JsonBorderConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonBorderConfig();

    return JsonBorderConfig(
      color: json['color'] as String?,
      width: (json['width'] as num?)?.toDouble(),
      radius: (json['radius'] as num?)?.toDouble(),
    );
  }

  Border? buildBorder() {
    if (color == null) return null;

    return Border.all(
      color: JsonColorParser.parse(color),
      width: width ?? 1.0,
      strokeAlign: BorderSide.strokeAlignInside,
    );
  }
}

class JsonShadowConfig {
  final String? color;
  final double? blur;
  final double? spread;
  final List<double>? offset;

  JsonShadowConfig({
    this.color,
    this.blur,
    this.spread,
    this.offset,
  });

  factory JsonShadowConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonShadowConfig();

    return JsonShadowConfig(
      color: json['color'] as String?,
      blur: (json['blur'] as num?)?.toDouble(),
      spread: (json['spread'] as num?)?.toDouble(),
      offset: (json['offset'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  List<BoxShadow> buildShadows() {
    if (color == null) return [];

    return [
      BoxShadow(
        color: JsonColorParser.parse(color).withOpacity(0.3),
        blurRadius: blur ?? 0,
        spreadRadius: spread ?? 0,
        offset: Offset(
          offset?.elementAt(0) ?? 0,
          offset?.elementAt(1) ?? 0,
        ),
      ),
    ];
  }
}

class JsonGradientConfig {
  final String? type;
  final List<String>? colors;
  final String? direction;

  JsonGradientConfig({
    this.type,
    this.colors,
    this.direction,
  });

  factory JsonGradientConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonGradientConfig();

    return JsonGradientConfig(
      type: json['type'] as String?,
      colors: (json['colors'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      direction: json['direction'] as String?,
    );
  }

  Gradient? buildGradient() {
    if (type != 'linear' || colors == null || colors!.length < 2) {
      return null;
    }

    final gradientColors =
        colors!.map((c) => JsonColorParser.parse(c)).toList();

    Alignment begin = Alignment.centerLeft;
    Alignment end = Alignment.centerRight;

    switch (direction) {
      case 'top_to_bottom':
        begin = Alignment.topCenter;
        end = Alignment.bottomCenter;
        break;
      case 'bottom_to_top':
        begin = Alignment.bottomCenter;
        end = Alignment.topCenter;
        break;
      case 'right_to_left':
        begin = Alignment.centerRight;
        end = Alignment.centerLeft;
        break;
      case 'left_to_right':
      default:
        break;
    }

    return LinearGradient(
      begin: begin,
      end: end,
      colors: gradientColors,
    );
  }
}

class JsonLayoutConfig {
  final double? paddingH;
  final double? paddingV;
  final double? spacing;
  final String? alignment;
  final String? mainAxis;
  final String? crossAxis;
  final double? cornerRadius;

  JsonLayoutConfig({
    this.paddingH,
    this.paddingV,
    this.spacing,
    this.alignment,
    this.mainAxis,
    this.crossAxis,
    this.cornerRadius,
  });

  factory JsonLayoutConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonLayoutConfig();

    final padding = json['padding'] as Map<String, dynamic>?;

    return JsonLayoutConfig(
      paddingH: (padding?['horizontal'] as num?)?.toDouble(),
      paddingV: (padding?['vertical'] as num?)?.toDouble(),
      spacing: (json['spacing'] as num?)?.toDouble(),
      alignment: json['alignment'] as String?,
      mainAxis: json['main_axis_alignment'] as String?,
      crossAxis: json['cross_axis_alignment'] as String?,
      cornerRadius: (json['corner_radius'] as num?)?.toDouble(),
    );
  }

  EdgeInsets get padding => EdgeInsets.symmetric(
        horizontal: paddingH ?? 16,
        vertical: paddingV ?? 12,
      );

  MainAxisAlignment get mainAxisAlign {
    switch (mainAxis) {
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'space_evenly':
        return MainAxisAlignment.spaceEvenly;
      case 'space_between':
        return MainAxisAlignment.spaceBetween;
      case 'space_around':
        return MainAxisAlignment.spaceAround;
      case 'start':
      default:
        return MainAxisAlignment.start;
    }
  }

  CrossAxisAlignment get crossAxisAlign {
    switch (crossAxis) {
      case 'center':
        return CrossAxisAlignment.center;
      case 'end':
        return CrossAxisAlignment.end;
      case 'start':
        return CrossAxisAlignment.start;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      case 'baseline':
        return CrossAxisAlignment.baseline;
      default:
        return CrossAxisAlignment.center;
    }
  }

  MainAxisAlignment get rowAlign {
    switch (alignment) {
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'start':
      default:
        return MainAxisAlignment.start;
    }
  }

  CrossAxisAlignment get columnAlign {
    switch (alignment) {
      case 'center':
        return CrossAxisAlignment.center;
      case 'end':
        return CrossAxisAlignment.end;
      case 'start':
      default:
        return CrossAxisAlignment.start;
    }
  }
}
