/// Theme directory paths for custom JSON themes
/// All custom themes are stored in device storage
class ThemePaths {
  // Base directory for AnymeX in device storage
  static const String baseDir = '/storage/emulated/0/AnymeX';
  
  // Main themes directory
  static const String themesDir = '$baseDir/themes';
  
  // Player themes directory
  static const String playerThemesDir = '$themesDir/player';
  
  // Reader themes directory
  static const String readerThemesDir = '$themesDir/reader';
  
  // Media indicator themes directory
  static const String mediaIndicatorThemesDir = '$themesDir/media_indicator';
}
