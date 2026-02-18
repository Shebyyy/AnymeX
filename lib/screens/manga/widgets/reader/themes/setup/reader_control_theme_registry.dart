import 'package:anymex/screens/manga/widgets/reader/themes/reader_control_themes/default_reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/reader_control_themes/ios_reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';
import 'package:anymex/models/custom_themes/json_reader_theme.dart';
import 'package:anymex/services/theme_loader.dart';
import 'package:anymex/utils/logger.dart';

class ReaderControlThemeRegistry {
  static const String defaultThemeId = 'default';

  // Built-in Dart themes
  static final List<ReaderControlTheme> _builtinDartThemes = [
    DefaultReaderControlTheme(),
    IOSReaderControlTheme(),
  ];

  // All themes combined
  static List<ReaderControlTheme> _allThemes = [];
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
        ...ThemeLoader.getReaderThemes(),
      ];
      
      _isInitialized = true;
      Logger.i('ReaderControlThemeRegistry initialized with ${_allThemes.length} themes');
    } catch (e) {
      Logger.i('Error initializing ReaderControlThemeRegistry: $e');
      // Fallback to built-in themes only
      _allThemes = List.from(_builtinDartThemes);
      _isInitialized = true;
    }
  }

  /// Get all themes (must call initialize() first)
  static Future<List<ReaderControlTheme>> getAllThemes() async {
    if (!_isInitialized) {
      await initialize();
    }
    return List.unmodifiable(_allThemes);
  }

  /// Get themes synchronously
  static List<ReaderControlTheme> get themes {
    if (!_isInitialized) {
      return List.from(_builtinDartThemes);
    }
    return List.unmodifiable(_allThemes);
  }

  static ReaderControlTheme resolve(String id) {
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
      ...ThemeLoader.getReaderThemes(),
    ];
    
    Logger.i('ReaderControlThemeRegistry reloaded with ${_allThemes.length} themes');
  }
}
