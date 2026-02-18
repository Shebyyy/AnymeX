import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/default_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/ios_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/minimal_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';
import 'package:anymex/models/custom_themes/json_media_indicator_theme.dart';
import 'package:anymex/services/theme_loader.dart';
import 'package:anymex/utils/logger.dart';

class MediaIndicatorThemeRegistry {
  static const String defaultThemeId = 'default';

  // Built-in Dart themes
  static final List<MediaIndicatorTheme> _builtinDartThemes = [
    DefaultMediaIndicatorTheme(),
    IosMediaIndicatorTheme(),
    MinimalMediaIndicatorTheme(),
  ];

  // All themes combined
  static List<MediaIndicatorTheme> _allThemes = [];
  static bool _isInitialized = false;

  /// Initialize registry with Dart themes + JSON themes from device storage
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load JSON themes from device storage
      await ThemeLoader.initialize();
      
      // Combine: Dart themes + JSON themes from device
      _allThemes = [
        ..._builtinDartThemes,
        ...ThemeLoader.getMediaIndicatorThemes(),
      ];
      
      _isInitialized = true;
      Logger.i('MediaIndicatorThemeRegistry initialized with ${_allThemes.length} themes');
    } catch (e) {
      Logger.i('Error initializing MediaIndicatorThemeRegistry: $e');
      // Fallback to built-in themes only
      _allThemes = List.from(_builtinDartThemes);
      _isInitialized = true;
    }
  }

  /// Get all themes (must call initialize() first)
  static Future<List<MediaIndicatorTheme>> getAllThemes() async {
    if (!_isInitialized) {
      await initialize();
    }
    return List.unmodifiable(_allThemes);
  }

  /// Get themes synchronously
  static List<MediaIndicatorTheme> get themes {
    if (!_isInitialized) {
      return List.from(_builtinDartThemes);
    }
    return List.unmodifiable(_allThemes);
  }

  static MediaIndicatorTheme resolve(String id) {
    if (!_isInitialized) {
      return _builtinDartThemes.firstWhere(
        (theme) => theme.id == id,
        orElse: () => _builtinDartThemes.first,
      );
    }

    return _allThemes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => _allThemes.first,
    );
  }

  /// Reload themes from device storage
  static Future<void> reloadThemes() async {
    await ThemeLoader.reloadThemes();
    
    // Rebuild all themes list
    _allThemes = [
      ..._builtinDartThemes,
      ...ThemeLoader.getMediaIndicatorThemes(),
    ];
    
    Logger.i('MediaIndicatorThemeRegistry reloaded with ${_allThemes.length} themes');
  }
}
