import 'dart:io';
import 'package:pip/pip.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get_storage/get_storage.dart';

class PipService {
  static final Pip _pip = Pip();
  static bool _isPipAvailable = false;
  static bool _isPipActive = false;
  static int? _androidVersion;
  
  // Storage keys
  static const String _autoPipKey = 'pip_auto_enable';
  static final _storage = GetStorage();

  // Check if PIP is available (Android 8.0+ or iOS 14+)
  static Future<bool> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }
    
    try {
      // Check Android version
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        _androidVersion = androidInfo.version.sdkInt;
        
        // PIP requires Android 8.0 (API 26) or higher
        if (_androidVersion! < 26) {
          debugPrint('PIP not available: Android $_androidVersion < 26');
          return false;
        }
      }
      
      // Check if device supports PIP
      _isPipAvailable = await _pip.isAvailable ?? false;
      
      if (_isPipAvailable) {
        // Setup PIP with options
        PipOptions options;
        if (Platform.isAndroid) {
          options = PipOptions(
            autoEnterEnabled: false, // We'll control this manually
            aspectRatioX: 16,
            aspectRatioY: 9,
            seamlessResizeEnabled: true,
          );
        } else {
          // iOS
          options = PipOptions(
            autoEnterEnabled: false,
            preferredContentWidth: 480,
            preferredContentHeight: 270,
          );
        }
        
        await _pip.setup(options);
        
        // Register state observer
        await _pip.registerStateChangedObserver(
          PipStateChangedObserver(
            onPipStateChanged: (state, error) {
              _isPipActive = (state == PipState.pipStateStarted);
              debugPrint('PIP state changed: $state');
            },
          ),
        );
      }
      
      debugPrint('PIP available: $_isPipAvailable (Android: $_androidVersion)');
      return _isPipAvailable;
    } catch (e) {
      debugPrint('PIP initialization error: $e');
      return false;
    }
  }

  // Enter PIP mode
  static Future<bool> enterPipMode() async {
    if (!_isPipAvailable) {
      debugPrint('PIP not available on this device');
      return false;
    }

    try {
      await _pip.enterPipMode();
      return true;
    } catch (e) {
      debugPrint('Failed to enter PIP: $e');
      return false;
    }
  }

  // Exit PIP mode (works automatically when user taps PIP window)
  static Future<void> exitPipMode() async {
    // PIP exits automatically when user taps window
    // No explicit exit needed for pip package
    debugPrint('PIP will exit when user taps window');
  }

  // Clean up
  static Future<void> dispose() async {
    try {
      await _pip.unregisterStateChangedObserver();
      await _pip.dispose();
    } catch (e) {
      debugPrint('PIP dispose error: $e');
    }
  }

  // Settings: Auto-enable PIP on home button
  static bool get autoPipEnabled => _storage.read(_autoPipKey) ?? true;
  
  static Future<void> setAutoPipEnabled(bool enabled) async {
    await _storage.write(_autoPipKey, enabled);
    debugPrint('Auto-PIP ${enabled ? "enabled" : "disabled"}');
  }

  static bool get isPipActive => _isPipActive;
  static bool get isPipAvailable => _isPipAvailable;
  static int? get androidVersion => _androidVersion;
}
