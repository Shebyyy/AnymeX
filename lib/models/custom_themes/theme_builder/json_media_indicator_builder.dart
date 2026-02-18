import 'dart:ui';
import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';
import 'package:any mex/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

import '../../json_media_indicator_config.dart';
import '../../json_theme_config.dart';

/// Builder for JSON media indicator themes
class JsonMediaIndicatorBuilder {
  static Widget buildIndicator({
    required BuildContext context,
    required MediaIndicatorThemeData data,
    required JsonMediaIndicatorConfig config,
  }) {
    final colors = Theme.of(context).colorScheme;
    final container = config.container;
    final progress = config.progress;
    final content = config.content;
    final animations = config.animations;

    return AnimatedOpacity(
      opacity: data.isVisible ? 1.0 : 0.0,
      duration: Duration(milliseconds: animations?.fadeDuration ?? 200),
      curve: animations?.fadeCurve ?? Curves.easeInOut,
      child: AnimatedScale(
        scale: data.isVisible ? 1.0 : 0.9,
        duration: Duration(milliseconds: animations?.scaleDuration ?? 200),
        curve: animations?.scaleCurve ?? Curves.easeOutCubic,
        child: Align(
          alignment: config.alignment,
          child: _buildContent(context, data, config),
        ),
      ),
    );
  }

  static Widget _buildContent(
    BuildContext context,
    MediaIndicatorThemeData data,
    JsonMediaIndicatorConfig config,
  ) {
    final container = config.container;
    final progress = config.progress;
    final content = config.content;

    Widget child = Stack(
      alignment: Alignment.center,
      children: [
        if (progress != null) _buildProgress(context, data, progress),
        if (content != null) _buildContentElements(context, data, content),
      ],
    );

    if (container != null) {
      return _buildContainer(context, child, container);
    }

    return child;
  }

  static Widget _buildContainer(
    BuildContext context,
    Widget child,
    JsonMediaContainerConfig container,
  ) {
    double width = container?.width ?? 120;
    double height = container?.height ?? 120;

    if (container?.background != null) {
      return _buildContainerWithBackground(context, child, container!, width, height);
    }

    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }

  static Widget _buildContainerWithBackground(
    BuildContext context,
    Widget child,
    JsonMediaContainerConfig container,
    double width,
    double height,
  ) {
    final bg = container.background!;
    final decoration = BoxDecoration(
      color: _parseColor(bg.color, Colors.black.withOpacity(0.6)),
      borderRadius: _parseBorderRadius(container),
      border: bg.border?.buildBorder(),
      boxShadow: bg.shadow?.buildShadows(),
    );

    if (bg.gradient != null) {
      decoration = BoxDecoration(
        gradient: bg.gradient!.buildGradient(),
        borderRadius: _parseBorderRadius(container),
      );
    }

    if (bg.blur != null && bg.blur! > 0) {
      return ClipRRect(
        borderRadius: _parseBorderRadius(container),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: bg.blur!, sigmaY: bg.blur!),
          child: Container(
            width: width,
            height: height,
            decoration: decoration,
            child: child,
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: decoration,
      child: child,
    );
  }

  static Widget _buildProgress(
    BuildContext context,
    MediaIndicatorThemeData data,
    JsonMediaProgressConfig progress,
  ) {
    if (progress?.type == 'circular') {
      return _buildCircularProgress(context, data, progress);
    } else if (progress?.type == 'bar') {
      return _buildBarProgress(context, data, progress);
    } else {
      return _buildMinimalProgress(context, data, progress);
    }
  }

  static Widget _buildCircularProgress(
    BuildContext context,
    MediaIndicatorThemeData data,
    JsonMediaProgressConfig progress,
  ) {
    final colors = Theme.of(context).colorScheme;
    final accentColor = data.isVolumeIndicator
        ? colors.primary
        : colors.tertiary;

    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: progress?.strokeWidth ?? 8,
              backgroundColor: progress?.parsedTrackColor ??
                  (progress!.parsedTrackColor!.withOpacity(0.2))
                  : Colors.white.withOpacity(0.2),
              color: (progress?.parsedColor ?? accentColor).withOpacity(0.3),
              strokeCap: StrokeCap.round,
            ),
          ),
          SizedBox(
            width: 100,
            height: 100,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: data.value),
              duration: Duration(milliseconds: 150),
              curve: Curves.easeOut,
              builder: (context, animValue, _) {
                return CircularProgressIndicator(
                  value: animValue.clamp(0.0, 1.0),
                  strokeWidth: progress?.strokeWidth ?? 8,
                  backgroundColor: Colors.transparent,
                  color: progress?.parsedColor ?? accentColor,
                  strokeCap: StrokeCap.round,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildBarProgress(
    BuildContext context,
    MediaIndicatorThemeData data,
    JsonMediaProgressConfig progress,
  ) {
    final accentColor = progress?.parsedColor ?? Theme.of(context).colorScheme.primary;

    return Container(
      width: 200,
      height: progress?.height ?? 4,
      child: Stack(
        children: [
          // Track
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: progress?.parsedTrackColor ??
                    (progress!.parsedTrackColor!.withOpacity(0.3))
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(progress?.rounded ?? true ? 2.0 : 0),
              ),
            ),
          ),
          // Progress
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: FractionallySizedBox(
              widthFactor: data.value.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(
                    progress?.rounded ?? true ? 2.0 : 0,
                  ),
                  boxShadow: progress?.glow?.buildShadows(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildMinimalProgress(
    BuildContext context,
    MediaIndicatorThemeData data,
    JsonMediaProgressConfig progress,
  ) {
    final accentColor = progress?.parsedColor ?? Theme.of(context).colorScheme.primary;

    return Container(
      width: 200,
      height: progress?.height ?? 4,
      child: Stack(
        children: [
          // Track
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: progress?.parsedTrackColor ??
                    (progress!.parsedTrackColor!.withOpacity(0.3))
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(progress?.rounded ?? true ? 2.0 : 0),
              ),
            ),
          ),
          // Progress
          Positioned.fill(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: FractionallySizedBox(
              widthFactor: data.value.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(
                    progress?.rounded ?? true ? 2.0 : 0,
                  ),
                  boxShadow: progress?.glow?.buildShadows(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildContentElements(
    BuildContext context,
    MediaIndicatorThemeData data,
    JsonMediaContentConfig content,
  ) {
    final iconColor = content.parsedIconColor ?? Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (content.showIcon ?? true)
          Icon(
            data.icon,
            size: content.iconSize ?? 24,
            color: iconColor,
          ),
        if (content.showIcon == true) const SizedBox(height: 12),
        if (content.showPercentage ?? true)
          Text(
            '${(data.value * 100).round()}%',
            style: TextStyle(
              color: content.parsedPercentageColor ?? Colors.white,
              fontSize: content.percentageSize ?? 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
      ],
    );
  }

  static double _parseBorderRadius(JsonMediaContainerConfig container) {
    return container.shape == 'circle' ? 60.0 : 12.0;
  }

  static Color? _parseColor(String? colorString, Color defaultColor) {
    if (colorString == null) return defaultColor;
    String hex = colorString;
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    return Color(int.parse('FF$hex'));
  }
}
