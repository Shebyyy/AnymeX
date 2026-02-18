import 'dart:convert';
import 'dart:ui' as ui;
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controller/player_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'json_theme_base.dart';
import 'json_player_controls_config.dart';
import 'theme_builder/json_player_theme_builder.dart';

/// JSON-based player control theme
class JsonPlayerTheme extends JsonThemeBase implements PlayerControlTheme {
  final String id;
  final String name;
  final String version;
  final String author;
  final JsonTopControlsConfig topControls;
  final JsonCenterControlsConfig centerControls;
  final JsonBottomControlsConfig bottomControls;

  JsonPlayerTheme({
    required this.id,
    required this.name,
    this.version = '1.0',
    this.author = 'Unknown',
    required this.topControls,
    required this.centerControls,
    required this.bottomControls,
  });

  @override
  Widget buildTopControls(BuildContext context, PlayerController controller) {
    return JsonPlayerThemeBuilder.buildTopControls(
      context: context,
      controller: controller,
      config: topControls,
    );
  }

  @override
  Widget buildCenterControls(BuildContext context, PlayerController controller) {
    return JsonPlayerThemeBuilder.buildCenterControls(
      context: context,
      controller: controller,
      config: centerControls,
    );
  }

  @override
  Widget buildBottomControls(BuildContext context, PlayerController controller) {
    return JsonPlayerThemeBuilder.buildBottomControls(
      context: context,
      controller: controller,
      config: bottomControls,
    );
  }

  factory JsonPlayerTheme.fromJson(Map<String, dynamic> json) {
    return JsonPlayerTheme(
      id: json['id'] as String? ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Unknown Theme',
      version: json['version'] as String? ?? '1.0',
      author: json['author'] as String? ?? 'Unknown',
      topControls: JsonTopControlsConfig.fromJson(
        json['top_controls'] as Map<String, dynamic>?,
      ),
      centerControls: JsonCenterControlsConfig.fromJson(
        json['center_controls'] as Map<String, dynamic>?,
      ),
      bottomControls: JsonBottomControlsConfig.fromJson(
        json['bottom_controls'] as Map<String, dynamic>?,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'player',
      'id': id,
      'name': name,
      'version': version,
      'author': author,
      'top_controls': topControls.toJson(),
      'center_controls': centerControls.toJson(),
      'bottom_controls': bottomControls.toJson(),
    };
  }

  @override
  List<String> get validationErrors {
    final errors = <String>[];
    
    // Validate ID
    if (id.isEmpty) {
      errors.add('Theme ID cannot be empty');
    } else if (!RegExp(r'^[a-z0-9_]+$').hasMatch(id)) {
      errors.add('Theme ID must contain only lowercase letters, numbers, and underscores');
    }
    
    // Validate name
    if (name.isEmpty) {
      errors.add('Theme name cannot be empty');
    }
    
    // Validate required sections
    if (topControls.elements.isEmpty) {
      errors.add('Top controls must have at least one element');
    }
    
    if (centerControls.elements.isEmpty) {
      errors.add('Center controls must have at least one element');
    }
    
    // Validate colors
    errors.addAll(_validateColors());
    
    return errors;
  }

  List<String> _validateColors() {
    final errors = <String>[];
    
    // Validate background colors if specified
    if (topControls.background?.color != null) {
      if (!_isValidColor(topControls.background!.color!)) {
        errors.add('Invalid background color in top controls');
      }
    }
    
    if (centerControls.background?.color != null) {
      if (!_isValidColor(centerControls.background!.color!)) {
        errors.add('Invalid background color in center controls');
      }
    }
    
    if (bottomControls.background?.color != null) {
      if (!_isValidColor(bottomControls.background!.color!)) {
        errors.add('Invalid background color in bottom controls');
      }
    }
    
    // Validate element colors
    for (final element in [...topControls.elements, ...centerControls.elements]) {
      if (element.color != null && !_isValidColor(element.color!)) {
        errors.add('Invalid color for element: ${element.type}');
      }
    }
    
    // Validate progress bar colors
    if (bottomControls.progressBar?.color != null) {
      if (!_isValidColor(bottomControls.progressBar!.color!)) {
        errors.add('Invalid progress bar color');
      }
    }
    
    if (bottomControls.progressBar?.trackColor != null) {
      if (!_isValidColor(bottomControls.progressBar!.trackColor!)) {
        errors.add('Invalid progress bar track color');
      }
    }
    
    return errors;
  }

  bool _isValidColor(String colorString) {
    return RegExp(r'^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$').hasMatch(colorString);
  }

  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}
