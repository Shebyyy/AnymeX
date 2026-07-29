import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

class PipController {
  static const _channel = MethodChannel('com.ryan.anymex/pip');

  static void Function()? onPlay;
  static void Function()? onPause;
  static void Function()? onForward;
  static void Function()? onBackward;
  static void Function(bool)? onPipModeChanged;

  static bool _isDesktopPipActive = false;
  static Size? _savedWindowSize;
  static Offset? _savedWindowPosition;
  static bool _savedAlwaysOnTop = false;
  static bool _savedSkipTaskbar = false;

  static bool get isDesktop => Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS;

  static bool get _isDesktopPipAvailable => isDesktop;

  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPipPlay':
          onPlay?.call();
          break;
        case 'onPipPause':
          onPause?.call();
          break;
        case 'onPipForward':
          onForward?.call();
          break;
        case 'onPipBackward':
          onBackward?.call();
          break;
        case 'onPipModeChanged':
          final active = call.arguments as bool? ?? false;
          onPipModeChanged?.call(active);
          break;
      }
    });
  }

  static Future<void> updatePlaybackState(bool playing) async {
    if (Platform.isAndroid) {
      try {
        await _channel
            .invokeMethod('updatePlaybackState', {'playing': playing});
      } catch (_) {}
    }
  }

  static Future<bool> get isAvailable async {
    if (isDesktop) return true;
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        return await _channel.invokeMethod<bool>('isPipAvailable') ?? false;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  static Future<bool> get isActive async {
    if (isDesktop) return _isDesktopPipActive;
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        return await _channel.invokeMethod<bool>('isPipActive') ?? false;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  static Future<bool> enter({
    int aspectWidth = 16,
    int aspectHeight = 9,
    String? videoUrl,
    Map<String, String>? headers,
  }) async {
    if (isDesktop) return _enterDesktopPip(aspectWidth: aspectWidth, aspectHeight: aspectHeight);
    if (Platform.isIOS) {
      try {
        return await _channel.invokeMethod<bool>('enterPip', {
              'width': aspectWidth,
              'height': aspectHeight,
              'url': videoUrl ?? '',
              'headers': headers ?? {},
            }) ??
            false;
      } catch (_) {
        return false;
      }
    }
    if (Platform.isAndroid) {
      try {
        return await _channel.invokeMethod<bool>('enterPip', {
              'width': aspectWidth,
              'height': aspectHeight,
            }) ??
            false;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  static Future<bool> exitPip() async {
    if (isDesktop && _isDesktopPipActive) {
      return _exitDesktopPip();
    }
    return false;
  }

  static Future<void> setAutoEnter({required bool enabled}) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('setAutoEnter', {'enabled': enabled});
      } catch (_) {}
    }
  }

  static Future<bool> _enterDesktopPip({required int aspectWidth, required int aspectHeight}) async {
    if (!_isDesktopPipAvailable) return false;

    try {
      _savedWindowSize = await windowManager.getSize();
      _savedWindowPosition = await windowManager.getPosition();
      _savedAlwaysOnTop = await windowManager.isAlwaysOnTop();
      _savedSkipTaskbar = await windowManager.isSkipTaskbar();

      final display = WidgetsBinding.instance.platformDispatcher.views.first;
      final physicalSize = display.physicalSize / display.devicePixelRatio;
      final screenWidth = physicalSize.width;
      final screenHeight = physicalSize.height;

      final pipWidth = (screenWidth * 0.3).clamp(320.0, 640.0);
      final pipHeight = (pipWidth * aspectHeight / aspectWidth);

      final pipX = screenWidth - pipWidth - 16;
      final pipY = screenHeight - pipHeight - 16;

      await windowManager.setSize(Size(pipWidth, pipHeight));
      await windowManager.setPosition(Offset(pipX, pipY));
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setSkipTaskbar(true);
      await windowManager.setResizable(false);
      await windowManager.setMinSize(Size(pipWidth, pipHeight));
      await windowManager.setMaxSize(Size(pipWidth, pipHeight));

      _isDesktopPipActive = true;
      onPipModeChanged?.call(true);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _exitDesktopPip() async {
    try {
      if (_savedWindowSize != null) {
        await windowManager.setSize(_savedWindowSize!);
      }
      if (_savedWindowPosition != null) {
        await windowManager.setPosition(_savedWindowPosition!);
      }
      await windowManager.setAlwaysOnTop(_savedAlwaysOnTop);
      await windowManager.setSkipTaskbar(_savedSkipTaskbar);
      await windowManager.setResizable(true);
      await windowManager.setMinSize(const Size(400, 300));

      _isDesktopPipActive = false;
      onPipModeChanged?.call(false);
      return true;
    } catch (_) {
      return false;
    }
  }
}
