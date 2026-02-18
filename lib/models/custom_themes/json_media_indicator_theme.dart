import 'dart:convert';
import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';
import 'package:flutter/material.dart';

import 'json_theme_base.dart';
import 'json_media_indicator_config.dart';
import 'theme_builder/json_media_indicator_builder.dart';

/// JSON-based media indicator theme
class JsonMediaIndicatorTheme extends JsonThemeBase implements MediaIndicatorTheme {
  final String id;
  final String name;
  final String version;
  final String author;
  final JsonMediaIndicatorConfig config;

  JsonMediaIndicatorTheme({
    required this.id,
    required this.name,
    this.version = '1.0',
    this.author = 'Unknown',
    required this.config,
  });

  @override
  Widget buildIndicator(BuildContext context, MediaIndicatorThemeData data) {
    return JsonMediaIndicatorBuilder.buildIndicator(
      context: context,
      data: data,
      config: config,
    );
  }

  factory JsonMediaIndicatorTheme.fromJson(Map<String, dynamic> json) {
    return JsonMediaIndicatorTheme(
      id: json['id'] as String? ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Unknown Theme',
      version: json['version'] as String? ?? '1.0',
      author: json['author'] as String? ?? 'Unknown',
      config: JsonMediaIndicatorConfig.fromJson(
        json['config'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'media_indicator',
      'id': id,
      'name': name,
      'version': version,
      'author': author,
      'config': config.toJson(),
    };
  }

  @override
  List<String> get validationErrors {
    final errors = <String>[];
    
    if (id.isEmpty) errors.add('Theme ID cannot be empty');
    if (name.isEmpty) errors.add('Theme name cannot be empty');
    
    return errors;
  }

  String toJsonString() {
    return JsonEncoder.withIndent('  ').convert(toJson());
  }
}
