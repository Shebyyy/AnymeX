import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/default_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/ios26_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/netflix_desktop_player_theme.dart.dart.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/netflix_mobile_player_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme.dart';
import 'anymex/models/custom_themes/json_player_theme.dart';
import 'package:anymex/services/theme_loader.dart';
import '../utils/logger.dart';

class PlayerControlThemeRegistry {
  static const String defaultThemeId = 'default';

  // Built-in Dart themes
  static final List<PlayerControlTheme> _builtinDartThemes = [
    DefaultPlayerControlTheme(),
    Ios26PlayerControlTheme(),
    NetflixDesktopPlayerControlTheme(),
    NetflixMobilePlayerControlTheme(),
  ];

  // All themes combined
  static List<PlayerControlTheme> _allThemes = [];
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
        ...ThemeLoader.getPlayerThemes(),
      ];
      
      _isInitialized = true;
      Logger.i('PlayerControlThemeRegistry initialized with ${_allThemes.length} themes');
    } catch (e) {
      Logger.i('Error initializing PlayerControlThemeRegistry: $e');
      // Fallback to built-in themes only
      _allThemes = List.from(_builtinDartThemes);
      _isInitialized = true;
    }
  }

  /// Get all themes (must call initialize() first)
  static Future<List<PlayerControlTheme>> getAllThemes() async {
    if (!_isInitialized) {
      await initialize();
    }
    return List.unmodifiable(_allThemes);
  }

  /// Get themes synchronously
  static List<PlayerControlTheme> get themes {
    if (!_isInitialized) {
      return List.from(_builtinDartThemes);
    }
    return List.unmodifiable(_allThemes);
  }

  static PlayerControlTheme resolve(String id) {
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
      ...ThemeLoader.getPlayerThemes(),
    ];
    
    Logger.i('PlayerControlThemeRegistry reloaded with ${_allThemes.length} themes');
  }
}
