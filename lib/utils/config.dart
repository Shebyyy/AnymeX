import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/error_handler.dart';

/// App configuration management
class AppConfig {
  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._();
  
  AppConfig._();

  // App metadata
  static const String appName = 'AnymeX';
  static const String appVersion = '3.0.3';
  static const String buildNumber = '25';
  
  // API endpoints and configurations
  static const String anilistApiUrl = 'https://graphql.anilist.co';
  static const String malApiUrl = 'https://api.myanimelist.net/v2';
  static const String simklApiUrl = 'https://api.simkl.com';
  
  // Extension repositories
  static const String defaultAnimeRepo = 'https://raw.githubusercontent.com/aniyomiorg/aniyomi-extensions/main/repo.min.json';
  static const String defaultMangaRepo = 'https://raw.githubusercontent.com/aniyomiorg/aniyomi-extensions/main/repo.min.json';
  static const String defaultMangayomiRepo = 'https://raw.githubusercontent.com/kodjodevf/mangayomi-extensions/main/repo.min.json';
  
  // Cache settings
  static const Duration defaultCacheExpiry = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int maxLogFileSize = 10 * 1024 * 1024; // 10MB
  
  // Player settings
  static const Duration defaultSkipDuration = Duration(seconds: 85);
  static const Duration defaultSeekDuration = Duration(seconds: 10);
  static const double defaultPlaybackSpeed = 1.0;
  static const int defaultMarkAsCompletedThreshold = 90; // percentage
  
  // UI settings
  static const double defaultGlowDensity = 0.8;
  static const double defaultRadiusMultiplier = 1.0;
  static const double defaultBlurMultiplier = 1.0;
  static const double defaultCardRoundness = 12.0;
  static const double defaultTabBarHeight = 56.0;
  static const double defaultTabBarWidth = 120.0;
  static const double defaultTabBarRoundness = 16.0;
  
  // Network settings
  static const Duration defaultNetworkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Theme settings
  static const bool defaultDarkMode = true;
  static const bool defaultOledMode = false;
  static const bool defaultSystemTheme = true;
  static const String defaultColorScheme = 'blue';
}

/// Environment-specific configuration
enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static Environment currentEnvironment = Environment.production;
  
  static bool get isDevelopment => currentEnvironment == Environment.development;
  static bool get isStaging => currentEnvironment == Environment.staging;
  static bool get isProduction => currentEnvironment == Environment.production;
  
  static void setEnvironment(Environment env) {
    currentEnvironment = env;
    Logger.i('Environment set to: ${env.name}', 'EnvironmentConfig');
  }
}

/// Feature flags for enabling/disabling features
class FeatureFlags {
  static const bool enableDiscordRPC = true;
  static const bool enableExtensions = true;
  static const bool enableOfflineMode = true;
  static const bool enableCustomThemes = true;
  static const bool enableAdvancedPlayer = true;
  static const bool enableAnalytics = false; // Disabled by default for privacy
  static const bool enableCrashReporting = true;
  static const bool enableDebugMode = false; // Only in development
}

/// Runtime configuration manager
class RuntimeConfig extends GetxController {
  static RuntimeConfig get instance => Get.find<RuntimeConfig>();
  
  final RxBool _isFirstLaunch = true.obs;
  final RxBool _isOnline = true.obs;
  final RxString _currentLanguage = 'en'.obs;
  final RxString _currentRegion = 'US'.obs;
  final RxInt _lastAppVersion = 0.obs;
  
  bool get isFirstLaunch => _isFirstLaunch.value;
  bool get isOnline => _isOnline.value;
  String get currentLanguage => _currentLanguage.value;
  String get currentRegion => _currentRegion.value;
  int get lastAppVersion => _lastAppVersion.value;
  
  @override
  void onInit() {
    super.onInit();
    _loadConfig();
  }
  
  Future<void> _loadConfig() async {
    try {
      final box = Hive.box('runtimeConfig');
      _isFirstLaunch.value = box.get('isFirstLaunch', defaultValue: true);
      _currentLanguage.value = box.get('currentLanguage', defaultValue: 'en');
      _currentRegion.value = box.get('currentRegion', defaultValue: 'US');
      _lastAppVersion.value = box.get('lastAppVersion', defaultValue: 0);
      
      // Check if this is a new version
      final currentVersion = int.tryParse(AppConfig.buildNumber) ?? 0;
      if (currentVersion > _lastAppVersion.value) {
        _handleAppUpdate(currentVersion);
      }
    } catch (e, stackTrace) {
      ErrorHandler.instance.handleError(
        error: e,
        stackTrace: stackTrace,
        type: ErrorType.storage,
        severity: ErrorSeverity.medium,
        customMessage: 'Failed to load runtime configuration',
      );
    }
  }
  
  Future<void> _saveConfig() async {
    try {
      final box = Hive.box('runtimeConfig');
      await box.putAll({
        'isFirstLaunch': _isFirstLaunch.value,
        'currentLanguage': _currentLanguage.value,
        'currentRegion': _currentRegion.value,
        'lastAppVersion': _lastAppVersion.value,
      });
    } catch (e, stackTrace) {
      ErrorHandler.instance.handleError(
        error: e,
        stackTrace: stackTrace,
        type: ErrorType.storage,
        severity: ErrorSeverity.medium,
        customMessage: 'Failed to save runtime configuration',
      );
    }
  }
  
  void _handleAppUpdate(int newVersion) {
    _lastAppVersion.value = newVersion;
    _saveConfig();
    Logger.i('App updated to version: $newVersion', 'RuntimeConfig');
  }
  
  void setFirstLaunchCompleted() {
    _isFirstLaunch.value = false;
    _saveConfig();
  }
  
  void setOnlineStatus(bool isOnline) {
    _isOnline.value = isOnline;
  }
  
  void setLanguage(String language) {
    _currentLanguage.value = language;
    _saveConfig();
  }
  
  void setRegion(String region) {
    _currentRegion.value = region;
    _saveConfig();
  }
}

/// Validation utilities for configuration
class ConfigValidator {
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  static bool isValidLanguageCode(String code) {
    return code.length == 2 && RegExp(r'^[a-z]{2}$').hasMatch(code);
  }
  
  static bool isValidRegionCode(String code) {
    return code.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(code);
  }
  
  static bool isValidPort(int port) {
    return port > 0 && port <= 65535;
  }
  
  static bool isValidPercentage(int value) {
    return value >= 0 && value <= 100;
  }
  
  static bool isValidDuration(Duration duration) {
    return duration.inMilliseconds > 0 && duration.inHours <= 24;
  }
}

/// Configuration utilities
class ConfigUtils {
  static Duration getTimeoutDuration({int? customSeconds}) {
    final seconds = customSeconds ?? AppConfig.defaultNetworkTimeout.inSeconds;
    return Duration(seconds: seconds);
  }
  
  static String getApiUrl(String service) {
    switch (service.toLowerCase()) {
      case 'anilist':
        return AppConfig.anilistApiUrl;
      case 'mal':
        return AppConfig.malApiUrl;
      case 'simkl':
        return AppConfig.simklApiUrl;
      default:
        throw ArgumentError('Unknown service: $service');
    }
  }
  
  static String getDefaultRepo(String type) {
    switch (type.toLowerCase()) {
      case 'anime':
        return AppConfig.defaultAnimeRepo;
      case 'manga':
        return AppConfig.defaultMangaRepo;
      case 'mangayomi':
        return AppConfig.defaultMangayomiRepo;
      default:
        throw ArgumentError('Unknown repo type: $type');
    }
  }
  
  static Map<String, dynamic> getDefaultPlayerSettings() {
    return {
      'skipDuration': AppConfig.defaultSkipDuration.inSeconds,
      'seekDuration': AppConfig.defaultSeekDuration.inSeconds,
      'playbackSpeed': AppConfig.defaultPlaybackSpeed,
      'markAsCompleted': AppConfig.defaultMarkAsCompletedThreshold,
    };
  }
  
  static Map<String, dynamic> getDefaultUISettings() {
    return {
      'glowDensity': AppConfig.defaultGlowDensity,
      'radiusMultiplier': AppConfig.defaultRadiusMultiplier,
      'blurMultiplier': AppConfig.defaultBlurMultiplier,
      'cardRoundness': AppConfig.defaultCardRoundness,
      'tabBarHeight': AppConfig.defaultTabBarHeight,
      'tabBarWidth': AppConfig.defaultTabBarWidth,
      'tabBarRoundness': AppConfig.defaultTabBarRoundness,
    };
  }
}