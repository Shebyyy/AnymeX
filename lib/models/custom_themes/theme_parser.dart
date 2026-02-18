import 'dart:convert';
import 'json_player_theme.dart';
import 'json_reader_theme.dart';
import 'json_media_indicator_theme.dart';
import 'package:anymex/utils/logger.dart';

/// Theme parser for JSON theme files
class ThemeParser {
  /// Parse player theme from JSON string
  static JsonPlayerTheme? parsePlayerTheme(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final theme = JsonPlayerTheme.fromJson(json);
      
      if (theme.isValid) {
        return theme;
      } else {
        Logger.i('Invalid player theme (validation failed): ${theme.validationErrors.join(', ')}');
        return null;
      }
    } catch (e) {
      Logger.i('Failed to parse player theme: $e');
      return null;
    }
  }

  /// Parse reader theme from JSON string
  static JsonReaderTheme? parseReaderTheme(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final theme = JsonReaderTheme.fromJson(json);
      
      if (theme.isValid) {
        return theme;
      } else {
        Logger.i('Invalid reader theme (validation failed): ${theme.validationErrors.join(', ')}');
        return null;
      }
    } catch (e) {
      Logger.i('Failed to parse reader theme: $e');
      return null;
    }
  }

  /// Parse media indicator theme from JSON string
  static JsonMediaIndicatorTheme? parseMediaIndicatorTheme(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final theme = JsonMediaIndicatorTheme.fromJson(json);
      
      if (theme.isValid) {
        return theme;
      } else {
        Logger.i('Invalid media indicator theme (validation failed): ${theme.validationErrors.join(', ')}');
        return null;
      }
    } catch (e) {
      Logger.i('Failed to parse media indicator theme: $e');
      return null;
    }
  }

  /// Validate theme schema
  static Map<String, dynamic> validateSchema(Map<String, dynamic> json) {
    final errors = <String>[];
    
    // Required fields
    if (!json.containsKey('id')) errors.add('Missing required field: id');
    if (!json.containsKey('name')) errors.add('Missing required field: name');
    
    // Validate format
    if (json.containsKey('id') && (json['id'] as String).isEmpty) {
      errors.add('id cannot be empty');
    }
    
    // Validate theme type
    if (json.containsKey('type')) {
      final type = json['type'] as String;
      if (!['player', 'reader', 'media_indicator'].contains(type)) {
        errors.add('Invalid theme type: $type');
      }
    }
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }
}
