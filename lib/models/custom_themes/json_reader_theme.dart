import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';
import 'package:anymex/screens/manga/controller/reader_controller.dart';
import 'package:flutter/material.dart';

import 'json_theme_base.dart';
import 'json_reader_controls_config.dart';
import '../theme_builder/json_reader_theme_builder.dart';

/// JSON-based reader control theme
class JsonReaderTheme extends JsonThemeBase implements ReaderControlTheme {
  final String id;
  final String name;
  final String version;
  final String author;
  final JsonReaderTopControlsConfig topControls;
  final JsonReaderBottomControlsConfig bottomControls;

  JsonReaderTheme({
    required this.id,
    required this.name,
    this.version = '1.0',
    this.author = 'Unknown',
    required this.topControls,
    required this.bottomControls,
  });

  @override
  Widget buildTopControls(BuildContext context, ReaderController controller) {
    return JsonReaderThemeBuilder.buildTopControls(
      context: context,
      controller: controller,
      config: topControls,
    );
  }

  @override
  Widget buildBottomControls(BuildContext context, ReaderController controller) {
    return JsonReaderThemeBuilder.buildBottomControls(
      context: context,
      controller: controller,
      config: bottomControls,
    );
  }

  factory JsonReaderTheme.fromJson(Map<String, dynamic> json) {
    return JsonReaderTheme(
      id: json['id'] as String? ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Unknown Theme',
      version: json['version'] as String? ?? '1.0',
      author: json['author'] as String? ?? 'Unknown',
      topControls: JsonReaderTopControlsConfig.fromJson(
        json['top_controls'] as Map<String, dynamic>?,
      ),
      bottomControls: JsonReaderBottomControlsConfig.fromJson(
        json['bottom_controls'] as Map<String, dynamic>?,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'reader',
      'id': id,
      'name': name,
      'version': version,
      'author': author,
      'top_controls': topControls.toJson(),
      'bottom_controls': bottomControls.toJson(),
    };
  }

  @override
  List<String> get validationErrors {
    final errors = <String>[];
    
    if (id.isEmpty) errors.add('Theme ID cannot be empty');
    if (name.isEmpty) errors.add('Theme name cannot be empty');
    
    if (topControls.elements.isEmpty) {
      errors.add('Top controls must have at least one element');
    }
    
    return errors;
  }

  String toJsonString() {
    return JsonEncoder.withIndent('  ').convert(toJson());
  }
}
