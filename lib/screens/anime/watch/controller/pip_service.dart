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

  // ---- INITIALIZATION ----
  static Future<bool> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }

    try {
      // Check minimum Android version
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        _androidVersion = androidInfo.version.sdkInt;

        if (_androidVersion! < 26) {
          debugPrint('Device API too low for PiP ($_androidVersion)');
          return false;
        }
      }

      // 👉 REAL API: isSupported()
      _isPipAvailable = await _pip.isSupported();

      if (_isPipAvailable) {
        // 👉 PipOptions depends on platform
        PipOptions options;

        if (Platform.isAndroid) {
          options = PipOptions(
            autoEnterEnabled: false,
            aspectRatioX: 16,
            aspectRatioY: 9,
            seamlessResizeEnabled: true,
          );
        } else {
          // iOS options
          options = PipOptions(
            autoEnterEnabled: false,
            preferredContentWidth: 480,
            preferredContentHeight: 270,
          );
        }

        await _pip.setup(options);

        // ---- STATE OBSERVER ----
        await _pip.registerStateChangedObserver(
          PipStateChangedObserver(
            onPipStateChanged: (state, error) {
              _isPipActive = (state == PipState.pipStateStarted);
              debugPrint('PiP state changed: $state');
            },
          ),
        );
      }

      debugPrint('PiP available: $_isPipAvailable');
      return _isPipAvailable;
    } catch (e) {
      debugPrint('PIP initialization error: $e');
      return false;
    }
  }

  // ---- ENTER PIP ----
  static Future<bool> enterPipMode() async {
    if (!_isPipAvailable) {
      debugPrint('Cannot enter PiP: device unsupported');
      return false;
    }

    try {
      // 👉 REAL API: start()
      final ok = await _pip.start();
      debugPrint('PiP start result: $ok');
      return ok;
    } catch (e) {
      debugPrint('Failed to enter PiP: $e');
      return false;
    }
  }

  // ---- EXIT PIP ----
  static Future<void> exitPipMode() async {
    // pip package exits automatically — only stop() exists
    try {
      await _pip.stop();
    } catch (_) {
      // ignore
    }
  }

  // ---- CLEAN UP ----
  static Future<void> dispose() async {
    try {
      await _pip.unregisterStateChangedObserver();
      await _pip.dispose();
    } catch (e) {
      debugPrint('PiP dispose error: $e');
    }
  }

  // ---- SETTINGS ----
  static bool get autoPipEnabled => _storage.read(_autoPipKey) ?? true;

  static Future<void> setAutoPipEnabled(bool enabled) async {
    await _storage.write(_autoPipKey, enabled);
    debugPrint('Auto PiP: ${enabled ? "Enabled" : "Disabled"}');
  }

  // ---- GETTERS ----
  static bool get isPipActive => _isPipActive;
  static bool get isPipAvailable => _isPipAvailable;
  static int? get androidVersion => _androidVersion;
}
