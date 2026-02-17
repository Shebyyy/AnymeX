import 'package:flutter/material.dart';

/// Represents a color definition in theme JSON
class JsonThemeColor {
  final Color? solid;
  final Gradient? gradient;
  final double? opacity;

  JsonThemeColor({
    this.solid,
    this.gradient,
    this.opacity,
  });

  factory JsonThemeColor.fromJson(dynamic json) {
    if (json == null) return JsonThemeColor(solid: Colors.white);

    if (json is String) {
      return JsonThemeColor(solid: _parseColorString(json));
    }

    if (json is Map) {
      final color = json['color'];
      final gradient = json['gradient'];
      final opacity = (json['opacity'] as num?)?.toDouble();

      if (gradient != null) {
        return JsonThemeColor(
          gradient: _parseGradient(gradient),
          opacity: opacity,
        );
      }

      return JsonThemeColor(
        solid: color != null ? _parseColorString(color) : null,
        opacity: opacity,
      );
    }

    return JsonThemeColor(solid: Colors.white);
  }

  Color get color {
    if (solid != null) {
      return opacity != null ? solid!.withOpacity(opacity!) : solid!;
    }
    return Colors.white;
  }

  Color? get solidColor => solid;
  Gradient? get gradientColor => gradient;

  static Color _parseColorString(String colorStr) {
    colorStr = colorStr.trim();
    
    // Handle hex colors
    if (colorStr.startsWith('#')) {
      return _parseHexColor(colorStr);
    }
    if (colorStr.startsWith('0x')) {
      return Color(int.parse(colorStr));
    }
    
    // Handle rgba
    if (colorStr.startsWith('rgba')) {
      final parts = colorStr
          .substring(5, colorStr.length - 1)
          .split(',')
          .map((e) => double.parse(e.trim()))
          .toList();
      if (parts.length == 4) {
        return Color.fromARGB(
          (parts[3] * 255).round(),
          parts[0].round(),
          parts[1].round(),
          parts[2].round(),
        );
      }
    }
    
    // Handle rgb
    if (colorStr.startsWith('rgb')) {
      final parts = colorStr
          .substring(4, colorStr.length - 1)
          .split(',')
          .map((e) => double.parse(e.trim()))
          .toList();
      if (parts.length == 3) {
        return Color.fromARGB(255, parts[0].round(), parts[1].round(), parts[2].round());
      }
    }
    
    // Named colors
    return _parseNamedColor(colorStr);
  }

  static Color _parseHexColor(String hex) {
    String hexCode = hex.replaceAll('#', '');
    if (hexCode.length == 3) {
      final r = int.parse(hexCode[0] * 2, radix: 16);
      final g = int.parse(hexCode[1] * 2, radix: 16);
      final b = int.parse(hexCode[2] * 2, radix: 16);
      return Color.fromRGBO(r, g, b, 1.0);
    } else if (hexCode.length == 6) {
      final r = int.parse(hexCode.substring(0, 2), radix: 16);
      final g = int.parse(hexCode.substring(2, 4), radix: 16);
      final b = int.parse(hexCode.substring(4, 6), radix: 16);
      return Color.fromRGBO(r, g, b, 1.0);
    } else if (hexCode.length == 8) {
      final r = int.parse(hexCode.substring(0, 2), radix: 16);
      final g = int.parse(hexCode.substring(2, 4), radix: 16);
      final b = int.parse(hexCode.substring(4, 6), radix: 16);
      final a = int.parse(hexCode.substring(6, 8), radix: 16);
      return Color.fromARGB(a, r, g, b);
    }
    return Colors.white;
  }

  static Color _parseNamedColor(String name) {
    final lowerName = name.toLowerCase().trim();
    final colorMap = {
      'white': Colors.white,
      'black': Colors.black,
      'red': Colors.red,
      'green': Colors.green,
      'blue': Colors.blue,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'purple': Colors.purple,
      'pink': Colors.pink,
      'cyan': Colors.cyan,
      'teal': Colors.teal,
      'grey': Colors.grey,
      'gray': Colors.grey,
      'brown': Colors.brown,
      'transparent': Colors.transparent,
    };
    return colorMap[lowerName] ?? Colors.white;
  }

  static Gradient? _parseGradient(dynamic gradientJson) {
    if (gradientJson == null || gradientJson is! Map) return null;

    final type = gradientJson['type'];
    final colorsJson = gradientJson['colors'];
    if (colorsJson == null || colorsJson is! List) return null;

    final colors = <Color>[];
    for (final colorJson in colorsJson) {
      colors.add(_parseColorString(colorJson.toString()));
    }

    if (colors.isEmpty) return null;

    switch (type) {
      case 'linear':
        final begin = _parseAlignment(gradientJson['begin']);
        final end = _parseAlignment(gradientJson['end']);
        return LinearGradient(
          colors: colors,
          begin: begin ?? Alignment.topLeft,
          end: end ?? Alignment.bottomRight,
        );
      case 'radial':
        return RadialGradient(colors: colors);
      default:
        return LinearGradient(colors: colors);
    }
  }

  static Alignment? _parseAlignment(dynamic alignmentJson) {
    if (alignmentJson == null) return null;
    if (alignmentJson is String) {
      final map = {
        'top_left': Alignment.topLeft,
        'top_center': Alignment.topCenter,
        'top_right': Alignment.topRight,
        'center_left': Alignment.centerLeft,
        'center': Alignment.center,
        'center_right': Alignment.centerRight,
        'bottom_left': Alignment.bottomLeft,
        'bottom_center': Alignment.bottomCenter,
        'bottom_right': Alignment.bottomRight,
      };
      return map[alignmentJson.toLowerCase()];
    }
    return null;
  }
}

/// Represents box decoration from JSON
class JsonThemeDecoration {
  final JsonThemeColor? background;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? borderRadius;
  final JsonThemeBlur? blur;

  JsonThemeDecoration({
    this.background,
    this.border,
    this.boxShadow,
    this.borderRadius,
    this.blur,
  });

  factory JsonThemeDecoration.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonThemeDecoration();

    return JsonThemeDecoration(
      background: json['background'] != null
          ? JsonThemeColor.fromJson(json['background'])
          : null,
      border: _parseBorder(json['border']),
      boxShadow: _parseBoxShadows(json['shadow'] ?? json['box_shadow']),
      borderRadius: _parseBorderRadius(json['radius'] ?? json['border_radius']),
      blur: json['blur'] != null ? JsonThemeBlur.fromJson(json['blur']) : null,
    );
  }

  BoxDecoration build() {
    Color? bgColor;
    if (blur?.enabled == true && background != null) {
      bgColor = Colors.transparent;
    } else {
      bgColor = background?.solidColor;
    }

    return BoxDecoration(
      color: bgColor,
      gradient: background?.gradientColor,
      border: border,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
    );
  }

  static Border? _parseBorder(dynamic borderJson) {
    if (borderJson == null) return null;

    if (borderJson is Map && borderJson['color'] != null) {
      final color = JsonThemeColor.fromJson(borderJson['color']).solid;
      final width = (borderJson['width'] as num?)?.toDouble() ?? 1.0;
      final radius = (borderJson['radius'] as num?)?.toDouble() ?? 0.0;

      if (radius > 0) {
        return Border.all(color: color!, width: width);
      }

      final top = borderJson['top'];
      final bottom = borderJson['bottom'];
      final left = borderJson['left'];
      final right = borderJson['right'];

      if (top != null || bottom != null || left != null || right != null) {
        return Border(
          top: _parseBorderSide(top, color, width),
          bottom: _parseBorderSide(bottom, color, width),
          left: _parseBorderSide(left, color, width),
          right: _parseBorderSide(right, color, width),
        );
      }

      return Border.all(color: color!, width: width);
    }

    return null;
  }

  static BorderSide? _parseBorderSide(dynamic side, Color? defaultColor, double defaultWidth) {
    if (side == null || side is! Map) return null;
    final color = JsonThemeColor.fromJson(side['color']).solid ?? defaultColor;
    final width = (side['width'] as num?)?.toDouble() ?? defaultWidth;
    return BorderSide(color: color, width: width);
  }

  static List<BoxShadow>? _parseBoxShadows(dynamic shadowJson) {
    if (shadowJson == null) return null;

    if (shadowJson is List) {
      return shadowJson
          .map((e) => _parseSingleBoxShadow(e))
          .where((e) => e != null)
          .cast<BoxShadow>()
          .toList();
    }

    if (shadowJson is Map) {
      final shadow = _parseSingleBoxShadow(shadowJson);
      return shadow != null ? [shadow] : null;
    }

    return null;
  }

  static BoxShadow? _parseSingleBoxShadow(dynamic shadowJson) {
    if (shadowJson == null || shadowJson is! Map) return null;

    final color = JsonThemeColor.fromJson(shadowJson['color'] ?? Colors.black).solid;
    final blur = (shadowJson['blur'] as num?)?.toDouble() ?? 0.0;
    final spread = (shadowJson['spread'] as num?)?.toDouble() ?? 0.0;
    final offset = _parseOffset(shadowJson['offset']);

    return BoxShadow(
      color: color!,
      blurRadius: blur,
      spreadRadius: spread,
      offset: offset ?? Offset.zero,
    );
  }

  static Offset? _parseOffset(dynamic offsetJson) {
    if (offsetJson == null) return null;
    if (offsetJson is List && offsetJson.length >= 2) {
      return Offset(
        (offsetJson[0] as num).toDouble(),
        (offsetJson[1] as num).toDouble(),
      );
    }
    if (offsetJson is Map) {
      return Offset(
        (offsetJson['dx'] as num?)?.toDouble() ?? 0.0,
        (offsetJson['dy'] as num?)?.toDouble() ?? 0.0,
      );
    }
    return null;
  }

  static BorderRadius? _parseBorderRadius(dynamic radiusJson) {
    if (radiusJson == null) return null;

    if (radiusJson is num) {
      final r = radiusJson.toDouble();
      return BorderRadius.circular(r);
    }

    if (radiusJson is Map) {
      final all = (radiusJson['all'] as num?)?.toDouble();
      if (all != null) {
        return BorderRadius.circular(all);
      }

      final topLeft = (radiusJson['top_left'] as num?)?.toDouble();
      final topRight = (radiusJson['top_right'] as num?)?.toDouble();
      final bottomLeft = (radiusJson['bottom_left'] as num?)?.toDouble();
      final bottomRight = (radiusJson['bottom_right'] as num?)?.toDouble();

      if (topLeft != null || topRight != null || bottomLeft != null || bottomRight != null) {
        return BorderRadius.only(
          topLeft: Radius.circular(topLeft ?? 0),
          topRight: Radius.circular(topRight ?? 0),
          bottomLeft: Radius.circular(bottomLeft ?? 0),
          bottomRight: Radius.circular(bottomRight ?? 0),
        );
      }
    }

    return null;
  }
}

/// Represents blur effect from JSON
class JsonThemeBlur {
  final bool enabled;
  final double? sigma;

  JsonThemeBlur({
    this.enabled = false,
    this.sigma,
  });

  factory JsonThemeBlur.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonThemeBlur();
    return JsonThemeBlur(
      enabled: json['enabled'] == true,
      sigma: (json['sigma'] as num?)?.toDouble(),
    );
  }
}

/// Represents glow effect from JSON
class JsonThemeGlow {
  final JsonThemeColor? color;
  final double? blur;
  final double? spread;

  JsonThemeGlow({
    this.color,
    this.blur,
    this.spread,
  });

  factory JsonThemeGlow.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonThemeGlow();
    return JsonThemeGlow(
      color: json['color'] != null ? JsonThemeColor.fromJson(json['color']) : null,
      blur: (json['blur'] as num?)?.toDouble(),
      spread: (json['spread'] as num?)?.toDouble(),
    );
  }

  BoxShadow? build() {
    if (color?.solid == null) return null;
    return BoxShadow(
      color: color!.solid!.withOpacity(0.5),
      blurRadius: blur ?? 20.0,
      spreadRadius: spread ?? 0.0,
    );
  }
}

/// Represents text style from JSON
class JsonThemeTextStyle {
  final JsonThemeColor? color;
  final double? size;
  final FontWeight? weight;
  final String? fontFamily;
  final List<Shadow>? shadows;
  final TextDecoration? decoration;

  JsonThemeTextStyle({
    this.color,
    this.size,
    this.weight,
    this.fontFamily,
    this.shadows,
    this.decoration,
  });

  factory JsonThemeTextStyle.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonThemeTextStyle();
    return JsonThemeTextStyle(
      color: json['color'] != null ? JsonThemeColor.fromJson(json['color']) : null,
      size: (json['size'] as num?)?.toDouble(),
      weight: _parseFontWeight(json['weight']),
      fontFamily: json['family'] as String?,
      shadows: _parseTextShadows(json['shadow'] ?? json['shadows']),
      decoration: _parseTextDecoration(json['decoration']),
    );
  }

  TextStyle build() {
    return TextStyle(
      color: color?.solidColor,
      fontSize: size,
      fontWeight: weight,
      fontFamily: fontFamily,
      shadows: shadows,
      decoration: decoration,
    );
  }

  static FontWeight? _parseFontWeight(dynamic weight) {
    if (weight == null) return null;
    if (weight is num) {
      final w = weight.toInt();
      if (w >= 0 && w <= 8) {
        return FontWeight.values[w];
      }
      return FontWeight.normal;
    }
    if (weight is String) {
      final map = {
        'normal': FontWeight.normal,
        'bold': FontWeight.bold,
        'w100': FontWeight.w100,
        'w200': FontWeight.w200,
        'w300': FontWeight.w300,
        'w400': FontWeight.w400,
        'w500': FontWeight.w500,
        'w600': FontWeight.w600,
        'w700': FontWeight.w700,
        'w800': FontWeight.w800,
        'w900': FontWeight.w900,
      };
      return map[weight.toLowerCase()];
    }
    return null;
  }

  static List<Shadow>? _parseTextShadows(dynamic shadowsJson) {
    if (shadowsJson == null) return null;

    if (shadowsJson is List) {
      return shadowsJson
          .map((e) => _parseSingleTextShadow(e))
          .where((e) => e != null)
          .cast<Shadow>()
          .toList();
    }

    if (shadowsJson is Map) {
      final shadow = _parseSingleTextShadow(shadowsJson);
      return shadow != null ? [shadow] : null;
    }

    return null;
  }

  static Shadow? _parseSingleTextShadow(dynamic shadowJson) {
    if (shadowJson == null || shadowJson is! Map) return null;

    final color = JsonThemeColor.fromJson(shadowJson['color'] ?? Colors.black).solid;
    final blur = (shadowJson['blur'] as num?)?.toDouble() ?? 0.0;
    final offset = _parseOffset(shadowJson['offset']);

    return Shadow(
      color: color!,
      blurRadius: blur,
      offset: offset ?? Offset.zero,
    );
  }

  static Offset? _parseOffset(dynamic offsetJson) {
    if (offsetJson == null) return null;
    if (offsetJson is List && offsetJson.length >= 2) {
      return Offset(
        (offsetJson[0] as num).toDouble(),
        (offsetJson[1] as num).toDouble(),
      );
    }
    if (offsetJson is Map) {
      return Offset(
        (offsetJson['dx'] as num?)?.toDouble() ?? 0.0,
        (offsetJson['dy'] as num?)?.toDouble() ?? 0.0,
      );
    }
    return null;
  }

  static TextDecoration? _parseTextDecoration(dynamic decoration) {
    if (decoration == null) return null;
    if (decoration is String) {
      final map = {
        'underline': TextDecoration.underline,
        'overline': TextDecoration.overline,
        'line_through': TextDecoration.lineThrough,
        'none': TextDecoration.none,
      };
      return map[decoration.toLowerCase()];
    }
    return null;
  }
}

/// Represents padding from JSON
class JsonThemePadding {
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double? all;
  final double? horizontal;
  final double? vertical;

  JsonThemePadding({
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.all,
    this.horizontal,
    this.vertical,
  });

  factory JsonThemePadding.fromJson(dynamic json) {
    if (json == null) return JsonThemePadding();

    if (json is num) {
      return JsonThemePadding(all: json.toDouble());
    }

    if (json is Map) {
      return JsonThemePadding(
        left: (json['left'] as num?)?.toDouble(),
        right: (json['right'] as num?)?.toDouble(),
        top: (json['top'] as num?)?.toDouble(),
        bottom: (json['bottom'] as num?)?.toDouble(),
        all: (json['all'] as num?)?.toDouble(),
        horizontal: (json['horizontal'] as num?)?.toDouble(),
        vertical: (json['vertical'] as num?)?.toDouble(),
      );
    }

    return JsonThemePadding();
  }

  EdgeInsetsGeometry get padding {
    if (all != null) return EdgeInsets.all(all!);
    if (horizontal != null || vertical != null) {
      return EdgeInsets.symmetric(
        horizontal: horizontal ?? 0,
        vertical: vertical ?? 0,
      );
    }
    return EdgeInsets.only(
      left: left ?? 0,
      right: right ?? 0,
      top: top ?? 0,
      bottom: bottom ?? 0,
    );
  }
}

/// Represents margin from JSON
class JsonThemeMargin {
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double? all;
  final double? horizontal;
  final double? vertical;

  JsonThemeMargin({
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.all,
    this.horizontal,
    this.vertical,
  });

  factory JsonThemeMargin.fromJson(dynamic json) {
    if (json == null) return JsonThemeMargin();

    if (json is num) {
      return JsonThemeMargin(all: json.toDouble());
    }

    if (json is Map) {
      return JsonThemeMargin(
        left: (json['left'] as num?)?.toDouble(),
        right: (json['right'] as num?)?.toDouble(),
        top: (json['top'] as num?)?.toDouble(),
        bottom: (json['bottom'] as num?)?.toDouble(),
        all: (json['all'] as num?)?.toDouble(),
        horizontal: (json['horizontal'] as num?)?.toDouble(),
        vertical: (json['vertical'] as num?)?.toDouble(),
      );
    }

    return JsonThemeMargin();
  }

  EdgeInsetsGeometry get margin {
    if (all != null) return EdgeInsets.all(all!);
    if (horizontal != null || vertical != null) {
      return EdgeInsets.symmetric(
        horizontal: horizontal ?? 0,
        vertical: vertical ?? 0,
      );
    }
    return EdgeInsets.only(
      left: left ?? 0,
      right: right ?? 0,
      top: top ?? 0,
      bottom: bottom ?? 0,
    );
  }
}

/// Represents layout configuration from JSON
class JsonThemeLayout {
  final String? type;
  final String? align;
  final String? justify;
  final JsonThemePadding? padding;
  final double? spacing;
  final int? flex;
  final bool? expanded;

  JsonThemeLayout({
    this.type,
    this.align,
    this.justify,
    this.padding,
    this.spacing,
    this.flex,
    this.expanded,
  });

  factory JsonThemeLayout.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonThemeLayout();
    return JsonThemeLayout(
      type: json['type'] as String? ?? 'row',
      align: json['align'] as String?,
      justify: json['justify'] as String?,
      padding: json['padding'] != null
          ? JsonThemePadding.fromJson(json['padding'])
          : null,
      spacing: (json['spacing'] as num?)?.toDouble(),
      flex: (json['flex'] as int?),
      expanded: json['expanded'] as bool?,
    );
  }

  MainAxisAlignment get mainAxisAlignment {
    switch (justify) {
      case 'start':
        return MainAxisAlignment.start;
      case 'end':
        return MainAxisAlignment.end;
      case 'center':
        return MainAxisAlignment.center;
      case 'space_between':
        return MainAxisAlignment.spaceBetween;
      case 'space_around':
        return MainAxisAlignment.spaceAround;
      case 'space_evenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  CrossAxisAlignment get crossAxisAlignment {
    switch (align) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'end':
        return CrossAxisAlignment.end;
      case 'center':
        return CrossAxisAlignment.center;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      case 'baseline':
        return CrossAxisAlignment.baseline;
      default:
        return CrossAxisAlignment.center;
    }
  }

  MainAxisSize get mainAxisSize {
    return expanded == true ? MainAxisSize.max : MainAxisSize.min;
  }
}

/// Represents animations from JSON
class JsonThemeAnimations {
  final Map<String, JsonThemeAnimation>? tap;
  final Map<String, JsonThemeAnimation>? hover;
  final String? entry;
  final int? entryDuration;

  JsonThemeAnimations({
    this.tap,
    this.hover,
    this.entry,
    this.entryDuration,
  });

  factory JsonThemeAnimations.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonThemeAnimations();
    return JsonThemeAnimations(
      tap: json['tap'] != null
          ? {'scale': JsonThemeAnimation.fromJson(json['tap'])}
          : null,
      hover: json['hover'] != null
          ? {'brightness': JsonThemeAnimation.fromJson(json['hover'])}
          : null,
      entry: json['entry'] as String?,
      entryDuration: (json['entry_duration'] as num?)?.toInt(),
    );
  }
}

class JsonThemeAnimation {
  final double? amount;
  final int? duration;

  JsonThemeAnimation({
    this.amount,
    this.duration,
  });

  factory JsonThemeAnimation.fromJson(Map<String, dynamic>? json) {
    if (json == null) return JsonThemeAnimation();
    return JsonThemeAnimation(
      amount: (json['amount'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.toInt(),
    );
  }
}
