import 'dart:convert';
import 'dart:io';

import 'package:anymex/models/custom_themes/custom_media_indicator_theme.dart';
import 'package:anymex/models/custom_themes/custom_player_theme.dart';
import 'package:anymex/models/custom_themes/custom_reader_theme.dart';
import 'package:anymex/utils/logger.dart';
import 'package:path_provider/path_provider.dart';

class CustomThemeLoader {
  static const String _themesDir = 'custom_themes';

  static Future<String> get _customThemesPath async {
    final directory = await _getCustomThemesDirectory();
    return directory.path;
  }

  static Future<Directory> _getCustomThemesDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final customThemesDir = Directory('${appDocDir.path}/$_themesDir');

    if (!await customThemesDir.exists()) {
      await customThemesDir.create(recursive: true);
      Logger.i('Created custom themes directory: ${customThemesDir.path}');
    }

    return customThemesDir;
  }

  // Media Indicator Themes
  static Future<List<CustomMediaIndicatorTheme>> loadCustomMediaIndicatorThemes() async {
    try {
      final directory = await _getCustomThemesDirectory();

      if (!await directory.exists()) {
        Logger.i('Custom themes directory does not exist');
        return [];
      }

      final files = directory.listSync();
      final themeFiles = files
          .where((file) => file.path.endsWith('.json'))
          .where((file) => file.path.contains('media_indicator'))
          .toList();

      Logger.i('Found ${themeFiles.length} custom media indicator themes');

      final themes = <CustomMediaIndicatorTheme>[];
      for (final file in themeFiles) {
        try {
          final jsonString = await file.readAsString();
          final jsonData = json.decode(jsonString);

          if (jsonData['type'] == 'media_indicator') {
            final theme = CustomMediaIndicatorTheme.fromJson(jsonData);
            themes.add(theme);
            Logger.i('Loaded custom media indicator theme: ${theme.name}');
          }
        } catch (e) {
          Logger.i('Error loading theme from ${file.path}: $e');
        }
      }

      return themes;
    } catch (e) {
      Logger.i('Error loading custom media indicator themes: $e');
      return [];
    }
  }

  static Future<bool> saveCustomMediaIndicatorTheme(CustomMediaIndicatorTheme theme) async {
    try {
      final directory = await _getCustomThemesDirectory();
      final fileName = 'media_indicator_${theme.id}.json';
      final file = File('${directory.path}/$fileName');

      final jsonString = json.encode(theme.toJson());
      await file.writeAsString(jsonString);

      Logger.i('Saved custom media indicator theme: ${theme.name} to ${file.path}');
      return true;
    } catch (e) {
      Logger.i('Error saving custom media indicator theme: $e');
      return false;
    }
  }

  static Future<bool> deleteCustomMediaIndicatorTheme(String themeId) async {
    try {
      final directory = await _getCustomThemesDirectory();
      final fileName = 'media_indicator_$themeId.json';
      final file = File('${directory.path}/$fileName');

      if (await file.exists()) {
        await file.delete();
        Logger.i('Deleted custom media indicator theme: $themeId');
        return true;
      }

      return false;
    } catch (e) {
      Logger.i('Error deleting custom media indicator theme: $e');
      return false;
    }
  }

  // Player Themes
  static Future<List<CustomPlayerTheme>> loadCustomPlayerThemes() async {
    try {
      final directory = await _getCustomThemesDirectory();

      if (!await directory.exists()) {
        Logger.i('Custom themes directory does not exist');
        return [];
      }

      final files = directory.listSync();
      final themeFiles = files
          .where((file) => file.path.endsWith('.json'))
          .where((file) => file.path.contains('player'))
          .toList();

      Logger.i('Found ${themeFiles.length} custom player themes');

      final themes = <CustomPlayerTheme>[];
      for (final file in themeFiles) {
        try {
          final jsonString = await file.readAsString();
          final jsonData = json.decode(jsonString);

          if (jsonData['type'] == 'player') {
            final theme = CustomPlayerTheme.fromJson(jsonData);
            themes.add(theme);
            Logger.i('Loaded custom player theme: ${theme.name}');
          }
        } catch (e) {
          Logger.i('Error loading theme from ${file.path}: $e');
        }
      }

      return themes;
    } catch (e) {
      Logger.i('Error loading custom player themes: $e');
      return [];
    }
  }

  static Future<bool> saveCustomPlayerTheme(CustomPlayerTheme theme) async {
    try {
      final directory = await _getCustomThemesDirectory();
      final fileName = 'player_${theme.id}.json';
      final file = File('${directory.path}/$fileName');

      final jsonString = json.encode(theme.toJson());
      await file.writeAsString(jsonString);

      Logger.i('Saved custom player theme: ${theme.name} to ${file.path}');
      return true;
    } catch (e) {
      Logger.i('Error saving custom player theme: $e');
      return false;
    }
  }

  static Future<bool> deleteCustomPlayerTheme(String themeId) async {
    try {
      final directory = await _getCustomThemesDirectory();
      final fileName = 'player_$themeId.json';
      final file = File('${directory.path}/$fileName');

      if (await file.exists()) {
        await file.delete();
        Logger.i('Deleted custom player theme: $themeId');
        return true;
      }

      return false;
    } catch (e) {
      Logger.i('Error deleting custom player theme: $e');
      return false;
    }
  }

  // Reader Themes
  static Future<List<CustomReaderTheme>> loadCustomReaderThemes() async {
    try {
      final directory = await _getCustomThemesDirectory();

      if (!await directory.exists()) {
        Logger.i('Custom themes directory does not exist');
        return [];
      }

      final files = directory.listSync();
      final themeFiles = files
          .where((file) => file.path.endsWith('.json'))
          .where((file) => file.path.contains('reader'))
          .toList();

      Logger.i('Found ${themeFiles.length} custom reader themes');

      final themes = <CustomReaderTheme>[];
      for (final file in themeFiles) {
        try {
          final jsonString = await file.readAsString();
          final jsonData = json.decode(jsonString);

          if (jsonData['type'] == 'reader') {
            final theme = CustomReaderTheme.fromJson(jsonData);
            themes.add(theme);
            Logger.i('Loaded custom reader theme: ${theme.name}');
          }
        } catch (e) {
          Logger.i('Error loading theme from ${file.path}: $e');
        }
      }

      return themes;
    } catch (e) {
      Logger.i('Error loading custom reader themes: $e');
      return [];
    }
  }

  static Future<bool> saveCustomReaderTheme(CustomReaderTheme theme) async {
    try {
      final directory = await _getCustomThemesDirectory();
      final fileName = 'reader_${theme.id}.json';
      final file = File('${directory.path}/$fileName');

      final jsonString = json.encode(theme.toJson());
      await file.writeAsString(jsonString);

      Logger.i('Saved custom reader theme: ${theme.name} to ${file.path}');
      return true;
    } catch (e) {
      Logger.i('Error saving custom reader theme: $e');
      return false;
    }
  }

  static Future<bool> deleteCustomReaderTheme(String themeId) async {
    try {
      final directory = await _getCustomThemesDirectory();
      final fileName = 'reader_$themeId.json';
      final file = File('${directory.path}/$fileName');

      if (await file.exists()) {
        await file.delete();
        Logger.i('Deleted custom reader theme: $themeId');
        return true;
      }

      return false;
    } catch (e) {
      Logger.i('Error deleting custom reader theme: $e');
      return false;
    }
  }

  // Export/Import - Generic
  static Future<String?> exportTheme(dynamic theme) async {
    try {
      final directory = await getExternalStorageDirectory();
      String fileName = '';
      String jsonString = '';

      if (theme is CustomMediaIndicatorTheme) {
        fileName = '${theme.name.replaceAll(' ', '_')}_media_indicator_theme.json';
        jsonString = json.encode(theme.toJson());
      } else if (theme is CustomPlayerTheme) {
        fileName = '${theme.name.replaceAll(' ', '_')}_player_theme.json';
        jsonString = json.encode(theme.toJson());
      } else if (theme is CustomReaderTheme) {
        fileName = '${theme.name.replaceAll(' ', '_')}_reader_theme.json';
        jsonString = json.encode(theme.toJson());
      } else {
        Logger.i('Unknown theme type for export');
        return null;
      }

      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      Logger.i('Exported theme to: ${file.path}');
      return file.path;
    } catch (e) {
      Logger.i('Error exporting theme: $e');
      return null;
    }
  }

  static Future<bool> importTheme(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString);

      final type = jsonData['type'];

      if (type == 'media_indicator') {
        final theme = CustomMediaIndicatorTheme.fromJson(jsonData);
        return await saveCustomMediaIndicatorTheme(theme);
      } else if (type == 'player') {
        final theme = CustomPlayerTheme.fromJson(jsonData);
        return await saveCustomPlayerTheme(theme);
      } else if (type == 'reader') {
        final theme = CustomReaderTheme.fromJson(jsonData);
        return await saveCustomReaderTheme(theme);
      }

      Logger.i('Unknown theme type: $type');
      return false;
    } catch (e) {
      Logger.i('Error importing theme: $e');
      return false;
    }
  }

  static Future<Directory> getExternalStorageDirectory() async {
    if (Platform.isAndroid) {
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        return directory;
      }
      return await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }
}
