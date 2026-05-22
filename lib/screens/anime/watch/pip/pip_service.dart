import 'dart:io';

import 'package:anymex/controllers/settings/settings.dart';
import 'package:anymex/utils/logger.dart';
import 'package:pip/pip.dart';

typedef PipStateChangedCallback = void Function(bool isPipActive);

class PipService {
  static final PipService _instance = PipService._internal();
  factory PipService() => _instance;
  PipService._internal();

  final _pip = Pip();
  bool _isPipActive = false;
  bool _isSetup = false;
  PipStateChangedCallback? onPipStateChanged;

  bool get isPipActive => _isPipActive;

  Future<bool> isSupported() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      return await _pip.isSupported();
    } catch (e) {
      Logger.e('PiP isSupported check failed: $e');
      return false;
    }
  }

  Future<bool> isAutoEnterSupported() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _pip.isAutoEnterSupported();
    } catch (e) {
      return false;
    }
  }

  Future<void> setup() async {
    if (_isSetup) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      final supported = await isSupported();
      if (!supported) return;

      final settings = settingsController;
      final autoEnter = settings.autoEnterPip;

      final options = PipOptions(
        autoEnterEnabled: autoEnter,
        aspectRatioX: 16,
        aspectRatioY: 9,
      );

      await _pip.setup(options);

      await _pip.registerStateChangedObserver(
        PipStateChangedObserver(
          onPipStateChanged: (state, error) {
            switch (state) {
              case PipState.pipStateStarted:
                _isPipActive = true;
                onPipStateChanged?.call(true);
                break;
              case PipState.pipStateStopped:
                _isPipActive = false;
                onPipStateChanged?.call(false);
                break;
              case PipState.pipStateFailed:
                _isPipActive = false;
                onPipStateChanged?.call(false);
                break;
            }
          },
        ),
      );

      _isSetup = true;
    } catch (e) {
      Logger.e('PiP setup failed: $e');
    }
  }

  Future<void> enterPip() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final supported = await isSupported();
      if (!supported) return;

      if (!_isSetup) await setup();
      await _pip.start();
      _isPipActive = true;
      onPipStateChanged?.call(true);
    } catch (e) {
      Logger.e('PiP enter failed: $e');
    }
  }

  Future<void> exitPip() async {
    try {
      await _pip.stop();
      _isPipActive = false;
      onPipStateChanged?.call(false);
    } catch (e) {
      Logger.e('PiP exit failed: $e');
    }
  }

  Future<void> updateAutoEnter(bool enabled) async {
    if (!Platform.isAndroid) return;
    try {
      final options = PipOptions(
        autoEnterEnabled: enabled,
        aspectRatioX: 16,
        aspectRatioY: 9,
      );
      await _pip.setup(options);
    } catch (e) {
      Logger.e('PiP updateAutoEnter failed: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _pip.dispose();
      _isSetup = false;
      _isPipActive = false;
      onPipStateChanged = null;
    } catch (e) {
      Logger.e('PiP dispose failed: $e');
    }
  }
}
