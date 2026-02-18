import 'package:flutter/material.dart';
import 'package:anymex/utils/theme_extensions.dart';

/// Utility functions for theme styling
class ThemeUtils {
  /// Parse a hex color string to Color
  static Color parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;
    
    String hex = colorString;
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    
    return Color(int.parse('FF$hex'));
  }

  /// Create a BoxDecoration from a JsonBackgroundConfig
  static BoxDecoration buildDecoration(
    JsonBackgroundConfig config, {
    Color? color,
    double? opacity,
    JsonBorderConfig? border,
    JsonShadowConfig? shadow,
    JsonGradientConfig? gradient,
  }) {
    final decoration = BoxDecoration();

    if (color != null) {
      decoration.color = ThemeUtils.parseColor(color).withOpacity(opacity ?? 1.0);
    }

    if (border?.buildBorder() != null) {
      decoration.border = border.buildBorder();
    }

    if (shadow?.buildShadows() != null && shadow.buildShadows().isNotEmpty) {
      decoration.boxShadow = shadow.buildShadows();
    }

    if (gradient?.buildGradient() != null) {
      decoration.gradient = gradient.buildGradient();
    }

    return decoration;
  }

  /// Get alignment from string
  static Alignment getAlignment(String? alignment) {
    switch (alignment?.toLowerCase()) {
      case 'center':
        return Alignment.center;
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      case 'top':
        return Alignment.topCenter;
      case 'bottom':
        return Alignment.bottomCenter;
      case 'top_center':
        return Alignment.topCenter;
      case 'bottom_center':
        return Alignment.bottomCenter;
      case 'top_left':
        return Alignment.topLeft;
      case 'top_right':
        return Alignment.topRight;
      case 'bottom_left':
        return Alignment.bottomLeft;
      case 'bottom_right':
        return Alignment.bottomRight;
      default:
        return Alignment.center;
    }
  }

  /// Get MainAxisAlignment from string
  static MainAxisAlignment getMainAxisAlignment(String? alignment) {
    switch (alignment?.toLowerCase()) {
      case 'center':
        return MainAxisAlignment.center;
      case 'start':
        return MainAxisAlignment.start;
      case 'end':
        return MainAxisAlignment.end;
      case 'space_evenly':
        return MainAxisAlignment.spaceEvenly;
      case 'space_between':
        return MainAxisAlignment.spaceBetween;
      case 'space_around':
        return MainAxisAlignment.spaceAround;
      default:
        return MainAxisAlignment.start;
    }
  }

  /// Get CrossAxisAlignment from string
  static CrossAxisAlignment getCrossAxisAlignment(String? alignment) {
    switch (alignment?.toLowerCase()) {
      case 'center':
        return CrossAxisAlignment.center;
      case 'start':
        return CrossAxisAlignment.start;
      case 'end':
        return CrossAxisAlignment.end;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      case 'baseline':
        return CrossAxisAlignment.baseline;
      default:
        return CrossAxisAlignment.center;
    }
  }

  /// Create a rounded RoundedRectangleBorder
  static RoundedRectangleBorder getRoundedBorderRadius(double radius) {
    return BorderRadius.circular(radius);
  }
}
