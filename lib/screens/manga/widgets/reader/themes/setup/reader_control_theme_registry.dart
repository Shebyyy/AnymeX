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

  static Future<List<ReaderControlTheme>> getAllThemes() async {
    try {
      final customThemes = await CustomThemeLoader.loadCustomReaderThemes();
      return [...builtinThemes, ...customThemes];
    } catch (e) {
      Logger.i('Error loading custom themes, using built-in only: $e');
      return builtinThemes;
    }
  }

  static List<ReaderControlTheme> get themes => builtinThemes;

  static ReaderControlTheme resolve(String id) {
    return builtinThemes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => builtinThemes.first,
    );
  }
}
