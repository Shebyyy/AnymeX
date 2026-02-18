import 'dart:io';
import 'package:anymex/models/custom_themes/json_player_theme.dart';
import 'package:anymex/models/custom_themes/json_reader_theme.dart';
import 'package:anymex/models/custom_themes/json_media_indicator_theme.dart';
import 'package:anymex/models/custom_themes/theme_parser.dart';
import 'package:anymex/constants/theme_paths.dart';
import 'package:anymex/utils/logger.dart';

/// Theme loader service - loads custom themes from device storage
class ThemeLoader {
  static final List<JsonPlayerTheme> _playerThemes = [];
  static final List<JsonReaderTheme> _readerThemes = [];
  static final List<JsonMediaIndicatorTheme> _mediaIndicatorThemes = [];
  static bool _isLoaded = false;

  /// Initialize: create directories and load all themes from device storage
  static Future<void> initialize() async {
    if (_isLoaded) return;
    
    try {
      await _ensureThemeDirectories();
      await _loadAllThemes();
      _isLoaded = true;
      Logger.i('Custom themes loaded successfully');
    } catch (e) {
      Logger.i('Error initializing theme loader: \$e');
    }
  }

  static Future<void> _ensureThemeDirectories() async {
    final directories = [
      ThemePaths.playerThemesDir,
      ThemePaths.readerThemesDir,
      ThemePaths.mediaIndicatorThemesDir,
    ];
    
    for (final dir in directories) {
      final directory = Directory(dir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        Logger.i('Created theme directory: \$dir');
      }
    }
  }

  static Future<void> _loadAllThemes() async {
    await Future.wait([
      _loadPlayerThemes(),
      _loadReaderThemes(),
      _loadMediaIndicatorThemes(),
    ]);
  }

  static Future<void> _loadPlayerThemes() async {
    try {
      final directory = Directory(ThemePaths.playerThemesDir);
      if (!await directory.exists()) return;
      
      final files = directory.listSync()
          .where((entity) => entity.path.endsWith('.json'))
          .toList();
      
      for (final file in files) {
        try {
          if (file is File) {
            final jsonString = await file.readAsString();
            final theme = ThemeParser.parsePlayerTheme(jsonString);
            if (theme != null) {
              _playerThemes.add(theme);
              Logger.i('Loaded player theme: \${theme.name}');
            }
          }
        } catch (e) {
          Logger.i('Failed to load theme \${file.path}: \$e');
        }
      }
    } catch (e) {
      Logger.i('Error loading player themes: \$e');
    }
  }

  static Future<void> _loadReaderThemes() async {
    try {
      final directory = Directory(ThemePaths.readerThemesDir);
      if (!await directory.exists()) return;
      
      final files = directory.listSync()
          .where((entity) => entity.path.endsWith('.json'))
          .toList();
      
      for (final file in files) {
        try {
          if (file is File) {
            final jsonString = await file.readAsString();
            final theme = ThemeParser.parseReaderTheme(jsonString);
            if (theme != null) {
              _readerThemes.add(theme);
              Logger.i('Loaded reader theme: \${theme.name}');
            }
          }
        } catch (e) {
          Logger.i('Failed to load theme \${file.path}: \$e');
        }
      }
    } catch (e) {
      Logger.i('Error loading reader themes: \$e');
    }
  }

  static Future<void> _loadMediaIndicatorThemes() async {
    try {
      final directory = Directory(ThemePaths.mediaIndicatorThemesDir);
      if (!await directory.exists()) return;
      
      final files = directory.listSync()
          .where((entity) => entity.path.endsWith('.json'))
          .toList();
      
      for (final file in files) {
        try {
          if (file is File) {
            final jsonString = await file.readAsString();
            final theme = ThemeParser.parseMediaIndicatorTheme(jsonString);
            if (theme != null) {
              _mediaIndicatorThemes.add(theme);
              Logger.i('Loaded media indicator theme: \${theme.name}');
            }
          }
        } catch (e) {
          Logger.i('Failed to load theme \${file.path}: \$e');
        }
      }
    } catch (e) {
      Logger.i('Error loading media indicator themes: \$e');
    }
  }

  static Future<void> reloadThemes() async {
    _playerThemes.clear();
    _readerThemes.clear();
    _mediaIndicatorThemes.clear();
    await _loadAllThemes();
    Logger.i('Themes reloaded from device storage');
  }

  static List<JsonPlayerTheme> getPlayerThemes() => List.unmodifiable(_playerThemes);
  static List<JsonReaderTheme> getReaderThemes() => List.unmodifiable(_readerThemes);
  static List<JsonMediaIndicatorTheme> getMediaIndicatorThemes() => List.unmodifiable(_mediaIndicatorThemes);

  static Future<bool> savePlayerTheme(JsonPlayerTheme theme) async {
    try {
      final directory = Directory(ThemePaths.playerThemesDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final file = File('\${ThemePaths.playerThemesDir}/\${theme.id}.json');
      await file.writeAsString(theme.toJsonString());
      
      _playerThemes.removeWhere((t) => t.id == theme.id);
      _playerThemes.add(theme);
      
      Logger.i('Saved player theme: \${theme.name}');
      return true;
    } catch (e) {
      Logger.i('Failed to save player theme: \$e');
      return false;
    }
  }

  static Future<bool> deletePlayerTheme(String themeId) async {
    try {
      final file = File('\${ThemePaths.playerThemesDir}/\$themeId.json');
      if (await file.exists()) {
        await file.delete();
        _playerThemes.removeWhere((t) => t.id == themeId);
        Logger.i('Deleted player theme: \$themeId');
        return true;
      }
      return false;
    } catch (e) {
      Logger.i('Failed to delete player theme: \$e');
      return false;
    }
  }
}
