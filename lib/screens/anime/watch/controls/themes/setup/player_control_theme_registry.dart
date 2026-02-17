import 'package:anymex/models/custom_themes/custom_player_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/cyberpunk_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/default_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/floating_orbs_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/ios26_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/minimal_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/netflix_desktop_player_theme.dart.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/netflix_mobile_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/prime_video_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/retro_vhs_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/player_control_themes/youtube_player_control_theme.dart';
import 'package:anymex/screens/anime/watch/controls/themes/setup/player_control_theme.dart';
import 'package:anymex/services/custom_theme_loader.dart';
import 'package:anymex/utils/logger.dart';

class PlayerControlThemeRegistry {
  static const String defaultThemeId = 'default';

  static final List<PlayerControlTheme> builtinThemes = [
    DefaultPlayerControlTheme(),
    Ios26PlayerControlTheme(),
    NetflixDesktopPlayerControlTheme(),
    NetflixMobilePlayerControlTheme(),
    PrimeVideoPlayerControlTheme(),
    YouTubePlayerControlTheme(),
    MinimalPlayerControlTheme(),
    CyberpunkPlayerControlTheme(),
    FloatingOrbsPlayerControlTheme(),
    RetroVhsPlayerControlTheme(),
  ];

  static Future<List<PlayerControlTheme>> getAllThemes() async {
    try {
      final customThemes = await CustomThemeLoader.loadCustomPlayerThemes();
      return [...builtinThemes, ...customThemes];
    } catch (e) {
      Logger.i('Error loading custom themes, using built-in only: $e');
      return builtinThemes;
    }
  }

  static List<PlayerControlTheme> get themes => builtinThemes;

  static PlayerControlTheme resolve(String id) {
    return builtinThemes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => builtinThemes.first,
    );
  }
}
