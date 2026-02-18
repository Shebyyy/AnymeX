import 'package:anymex/models/custom_themes/custom_reader_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/reader_control_themes/default_reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/reader_control_themes/ios_reader_control_theme.dart';
import 'package:anymex/screens/manga/widgets/reader/themes/setup/reader_control_theme.dart';
import 'package:anymex/services/custom_theme_loader.dart';
import 'package:anymex/utils/logger.dart';

class ReaderControlThemeRegistry {
  static const String defaultThemeId = 'default';

  static final List<ReaderControlTheme> builtinThemes = [
    DefaultReaderControlTheme(),
    IOSReaderControlTheme(),
  ];

  // Cache for all themes (builtin + custom)
  static List<ReaderControlTheme> _allThemesCache = [];

  static Future<List<ReaderControlTheme>> getAllThemes() async {
    try {
      final customThemes = await CustomThemeLoader.loadCustomReaderThemes();
      _allThemesCache = [...builtinThemes, ...customThemes];
      return _allThemesCache;
    } catch (e) {
      Logger.i('Error loading custom themes, using built-in only: $e');
      _allThemesCache = builtinThemes;
      return builtinThemes;
    }
  }

  static List<ReaderControlTheme> get themes => builtinThemes;

  static ReaderControlTheme resolve(String id) {
    // Search in all cached themes first (includes custom)
    try {
      return _allThemesCache.firstWhere(
        (theme) => theme.id == id,
        orElse: () => builtinThemes.first,
      );
    } catch (_) {
      // Fallback to builtin if cache is empty
      return builtinThemes.firstWhere(
        (theme) => theme.id == id,
        orElse: () => builtinThemes.first,
      );
    }
  }
}
