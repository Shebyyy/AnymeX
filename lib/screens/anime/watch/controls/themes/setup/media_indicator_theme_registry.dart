import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/default_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/ios_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/minimal_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/neon_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/retro_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/elegant_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/cinema_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/bubble_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/media_indicator_themes/gaming_media_indicator_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/media_indicator_theme.dart';
import 'package:anymex/models/custom_themes/custom_media_indicator_theme.dart';
import 'package:anymex/services/custom_theme_loader.dart';
import 'package:anymex/utils/logger.dart';

class MediaIndicatorThemeRegistry {
  static const String defaultThemeId = 'default';

  static final List<MediaIndicatorTheme> builtinThemes = [
    DefaultMediaIndicatorTheme(),
    IosMediaIndicatorTheme(),
    MinimalMediaIndicatorTheme(),
    NeonMediaIndicatorTheme(),
    RetroMediaIndicatorTheme(),
    ElegantMediaIndicatorTheme(),
    CinemaMediaIndicatorTheme(),
    BubbleMediaIndicatorTheme(),
    GamingMediaIndicatorTheme(),
  ];

  static Future<List<MediaIndicatorTheme>> getAllThemes() async {
    try {
      final customThemes = await CustomThemeLoader.loadCustomMediaIndicatorThemes();
      return [...builtinThemes, ...customThemes];
    } catch (e) {
      Logger.i('Error loading custom themes, using built-in only: $e');
      return builtinThemes;
    }
  }

  static List<MediaIndicatorTheme> get themes => builtinThemes;

  static MediaIndicatorTheme resolve(String id) {
    return builtinThemes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => builtinThemes.first,
    );
  }
}
