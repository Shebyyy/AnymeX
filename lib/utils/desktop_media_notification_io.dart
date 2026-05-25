import 'dart:async';
import 'dart:io';

import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/windows_smtc.dart';

class DesktopMediaNotification {
  bool _initialized = false;
  bool _stopped = true;

  late Future<void> Function() _onPlay;
  late Future<void> Function() _onPause;
  late Future<void> Function(Duration) _onSeek;
  late Future<void> Function() _onSkipToNext;
  late Future<void> Function() _onSkipToPrevious;

  bool _canSkipNext = false;
  bool _canSkipPrevious = false;

  String _title = '';
  String _artist = '';
  String? _artworkUrl;
  Duration _duration = Duration.zero;

  void init({
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function(Duration) onSeek,
    required Future<void> Function() onSkipToNext,
    required Future<void> Function() onPrevious,
  }) {
    _onPlay = onPlay;
    _onPause = onPause;
    _onSeek = onSeek;
    _onSkipToNext = onSkipToNext;
    _onSkipToPrevious = onPrevious;
    _initialized = true;
    _stopped = false;

    if (Platform.isWindows) {
      windowsSmtc.init(
        onPlay: () async => _onPlay(),
        onPause: () async => _onPause(),
        onSeek: (pos) async => _onSeek(pos),
        onNext: () async => _onSkipToNext(),
        onPrevious: () async => _onSkipToPrevious(),
      );
    }

    Logger.i('DesktopMediaNotification initialized (${Platform.operatingSystem})');
  }

  Future<void> updateMetadata({
    required String title,
    required String artist,
    String? artworkUrl,
    Duration? duration,
  }) async {
    if (!_initialized || _stopped) return;
    _title = title;
    _artist = artist;
    _artworkUrl = artworkUrl;
    if (duration != null) _duration = duration;

    if (Platform.isWindows) {
      windowsSmtc.updateMetadata(
        title: title,
        artist: artist,
        artworkUrl: artworkUrl,
        duration: duration,
      );
      return;
    }

    if (Platform.isLinux) {
      await _updateLinuxMpris2(
        title: _title,
        artist: _artist,
        position: Duration.zero,
        duration: _duration,
        isPlaying: false,
        isBuffering: false,
        canSeek: true,
      );
    }
  }

  Future<void> updatePlaybackState({
    required Duration position,
    required bool isPlaying,
    required bool isBuffering,
    required double playbackSpeed,
  }) async {
    if (!_initialized || _stopped) return;

    if (Platform.isWindows) {
      windowsSmtc.updatePlaybackState(
        position: position,
        isPlaying: isPlaying,
        isBuffering: isBuffering,
        playbackSpeed: playbackSpeed,
      );
      return;
    }

    if (Platform.isLinux) {
      await _updateLinuxMpris2(
        title: _title,
        artist: _artist,
        position: position,
        duration: _duration,
        isPlaying: isPlaying,
        isBuffering: isBuffering,
        canSeek: true,
      );
    }
  }

  void updateSkipButtons({
    required bool canSkipNext,
    required bool canSkipPrevious,
  }) {
    _canSkipNext = canSkipNext;
    _canSkipPrevious = canSkipPrevious;

    if (Platform.isWindows) {
      windowsSmtc.updateSkipButtons(
        canSkipNext: canSkipNext,
        canSkipPrevious: canSkipPrevious,
      );
    }
  }

  Future<void> stop() async {
    _stopped = true;

    if (Platform.isWindows) {
      windowsSmtc.stop();
    }

    if (Platform.isLinux) {
      await _stopLinuxMpris2();
    }
  }

  String? _mprisBusName;

  Future<void> _ensureMpris2Registered() async {
    if (_mprisBusName != null) return;

    try {
      _mprisBusName = 'org.mpris.MediaPlayer2.AnymeX';

      final result = await Process.run('dbus-send', [
        '--session',
        '--dest=org.freedesktop.DBus',
        '/org/freedesktop/DBus',
        'org.freedesktop.DBus.RequestName',
        "string:$_mprisBusName",
        'uint32:0',
      ]).timeout(const Duration(seconds: 3));

      if (result.exitCode != 0) {
        Logger.w('MPRIS2 registration failed: ${result.stderr}');
        _mprisBusName = null;
        return;
      }

      Logger.i('MPRIS2 player registered: $_mprisBusName');
    } catch (e) {
      Logger.w('MPRIS2 registration error: $e');
      _mprisBusName = null;
    }
  }

  Future<void> _updateLinuxMpris2({
    required String title,
    required String artist,
    required Duration position,
    required Duration duration,
    required bool isPlaying,
    required bool isBuffering,
    required bool canSeek,
  }) async {
    await _ensureMpris2Registered();
    if (_mprisBusName == null) return;

    final posUs = position.inMicroseconds;
    final durUs = duration.inMicroseconds;

    final status = isBuffering ? 'Paused' : (isPlaying ? 'Playing' : 'Paused');

    await _dbusSetProperty(
      interface: 'org.mpris.MediaPlayer2.Player',
      property: 'PlaybackStatus',
      value: 'variant:string:$status',
    );

    await _dbusSetProperty(
      interface: 'org.mpris.MediaPlayer2.Player',
      property: 'Position',
      value: 'variant:int64:$posUs',
    );

    final artValue = (_artworkUrl != null && _artworkUrl!.isNotEmpty)
        ? 'variant:string:${_artworkUrl!}'
        : 'variant:string:';

    await _dbusSend(
      args: [
        '--session',
        '--print-reply',
        '--dest=org.freedesktop.DBus.Properties',
        '/org/mpris/MediaPlayer2',
        'org.freedesktop.DBus.Properties.Set',
        "string:org.mpris.MediaPlayer2.Player",
        'array:string:Metadata',
        'dict:entry:string:variant:',
        'string:xesam:title',
        'variant:string:$title',
        'string:xesam:artist',
        'variant:string:$artist',
        'string:mpris:artUrl',
        artValue,
        'string:mpris:trackid',
        'variant:string:$_mprisBusName/track/0',
        'string:mpris:length',
        'variant:int64:$durUs',
      ],
    );

    await _dbusSetProperties({
      'CanSeek': 'variant:boolean:$canSeek',
      'CanGoNext': 'variant:boolean:$_canSkipNext',
      'CanGoPrevious': 'variant:boolean:$_canSkipPrevious',
    });
  }

  Future<void> _dbusSetProperty({
    required String interface,
    required String property,
    required String value,
  }) async {
    await _dbusSend(
      args: [
        '--session',
        '--print-reply',
        '--dest=org.freedesktop.DBus.Properties',
        '/org/mpris/MediaPlayer2',
        'org.freedesktop.DBus.Properties.Set',
        "string:$interface",
        'array:string:$property',
        value,
      ],
    );
  }

  Future<void> _dbusSetProperties(Map<String, String> properties) async {}

  Future<void> _stopLinuxMpris2() async {
    if (_mprisBusName == null) return;

    try {
      await Process.run('dbus-send', [
        '--session',
        '--dest=org.freedesktop.DBus',
        '/org/freedesktop/DBus',
        'org.freedesktop.DBus.ReleaseName',
        "string:$_mprisBusName",
      ]).timeout(const Duration(seconds: 3));
      Logger.i('MPRIS2 player unregistered');
    } catch (e) {
      Logger.w('MPRIS2 unregister error: $e');
    }
    _mprisBusName = null;
  }

  Future<void> _dbusSend({required List<String> args}) async {
    try {
      await Process.run('dbus-send', args).timeout(const Duration(seconds: 3));
    } catch (e) {}
  }
}
