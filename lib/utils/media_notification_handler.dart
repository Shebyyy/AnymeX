import 'dart:async';
import 'dart:io';

import 'package:anymex/utils/logger.dart';
import 'package:audio_service/audio_service.dart';

import 'desktop_media_notification_stub.dart'
    if (dart.library.io) 'desktop_media_notification_io.dart';

typedef PlayCallback = Future<void> Function();
typedef PauseCallback = Future<void> Function();
typedef SeekCallback = Future<void> Function(Duration position);
typedef SkipToNextCallback = Future<void> Function();
typedef SkipToPreviousCallback = Future<void> Function();

class MediaNotificationHandler {
  static final MediaNotificationHandler _instance =
      MediaNotificationHandler._internal();
  static MediaNotificationHandler get instance => _instance;
  MediaNotificationHandler._internal();

  bool _initialized = false;

  final _audioHandler = _AnymeXAudioHandler();

  final _desktopHandler = DesktopMediaNotification();

  PlayCallback? _onPlay;
  PauseCallback? _onPause;
  SeekCallback? _onSeek;
  SkipToNextCallback? _onSkipToNext;
  SkipToPreviousCallback? _onSkipToPrevious;

  bool _sessionActive = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await AudioService.init(
        builder: () => _audioHandler,
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.anymex.app.media',
          androidNotificationChannelName: 'AnymeX Media',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: false,
          androidNotificationIcon: 'drawable/ic_launcher',
          androidShowNotificationBadge: true,
          androidNotificationClickStartsActivity: true,
        ),
      );
    } catch (e) {
      Logger.w('AudioService init failed (may be unsupported platform): $e');
    }

    try {
      _desktopHandler.init(
        onPlay: () async => _onPlay?.call() ?? Future.value(),
        onPause: () async => _onPause?.call() ?? Future.value(),
        onSeek: (pos) async => _onSeek?.call(pos) ?? Future.value(),
        onSkipToNext: () async => _onSkipToNext?.call() ?? Future.value(),
        onPrevious: () async => _onSkipToPrevious?.call() ?? Future.value(),
      );
    } catch (e) {
      Logger.w('Desktop media notification init failed: $e');
    }

    final platforms = <String>['Android', 'iOS', 'macOS'];
    if (Platform.isWindows) platforms.add('Windows (SMTC)');
    if (Platform.isLinux) platforms.add('Linux (MPRIS2)');
    Logger.i('MediaNotificationHandler initialized for: ${platforms.join(", ")}');
  }

  void startSession({
    required PlayCallback onPlay,
    required PauseCallback onPause,
    required SeekCallback onSeek,
    required SkipToNextCallback onSkipToNext,
    required SkipToPreviousCallback onSkipToPrevious,
  }) {
    _onPlay = onPlay;
    _onPause = onPause;
    _onSeek = onSeek;
    _onSkipToNext = onSkipToNext;
    _onSkipToPrevious = onSkipToPrevious;
    _sessionActive = true;
    Logger.i('MediaNotification session started');
  }

  Future<void> stopSession() async {
    _sessionActive = false;
    _onPlay = null;
    _onPause = null;
    _onSeek = null;
    _onSkipToNext = null;
    _onSkipToPrevious = null;

    try {
      await _audioHandler.stop();
    } catch (_) {}

    try {
      await _desktopHandler.stop();
    } catch (_) {}

    Logger.i('MediaNotification session stopped');
  }

  Future<void> updateMetadata({
    required String title,
    String? artist,
    String? artworkUrl,
    Duration? duration,
  }) async {
    if (!_sessionActive) return;

    final item = MediaItem(
      id: 'anymex-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      artist: artist ?? 'AnymeX',
      artUri: artworkUrl != null && artworkUrl.isNotEmpty
          ? Uri.tryParse(artworkUrl)
          : null,
      duration: duration,
    );

    try {
      _audioHandler._updateItem(item);
    } catch (_) {}

    try {
      await _desktopHandler.updateMetadata(
        title: title,
        artist: artist ?? 'AnymeX',
        artworkUrl: artworkUrl,
        duration: duration,
      );
    } catch (_) {}
  }

  Future<void> updateState({
    required Duration position,
    required Duration? bufferPosition,
    required bool isPlaying,
    required bool isBuffering,
    required double playbackSpeed,
  }) async {
    if (!_sessionActive) return;

    try {
      _audioHandler._updatePlaybackState(
        position: position,
        bufferPosition: bufferPosition,
        isPlaying: isPlaying,
        isBuffering: isBuffering,
        playbackSpeed: playbackSpeed,
      );
    } catch (_) {}

    try {
      await _desktopHandler.updatePlaybackState(
        position: position,
        isPlaying: isPlaying,
        isBuffering: isBuffering,
        playbackSpeed: playbackSpeed,
      );
    } catch (_) {}
  }

  void updateSkipButtons({
    required bool canSkipNext,
    required bool canSkipPrevious,
  }) {
    _audioHandler._canSkipNext = canSkipNext;
    _audioHandler._canSkipPrevious = canSkipPrevious;
    try {
      _desktopHandler.updateSkipButtons(
        canSkipNext: canSkipNext,
        canSkipPrevious: canSkipPrevious,
      );
    } catch (_) {}
  }
}

class _AnymeXAudioHandler extends BaseAudioHandler with SeekHandler {
  bool _canSkipNext = false;
  bool _canSkipPrevious = false;

  @override
  Future<void> play() async {
    final handler = MediaNotificationHandler.instance;
    if (handler._onPlay != null) {
      await handler._onPlay!();
    }
  }

  @override
  Future<void> pause() async {
    final handler = MediaNotificationHandler.instance;
    if (handler._onPause != null) {
      await handler._onPause!();
    }
  }

  @override
  Future<void> stop() async {
    await pause();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    final handler = MediaNotificationHandler.instance;
    if (handler._onSeek != null) {
      await handler._onSeek!(position);
    }
  }

  @override
  Future<void> skipToNext() async {
    final handler = MediaNotificationHandler.instance;
    if (handler._onSkipToNext != null && _canSkipNext) {
      await handler._onSkipToNext!();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final handler = MediaNotificationHandler.instance;
    if (handler._onSkipToPrevious != null && _canSkipPrevious) {
      await handler._onSkipToPrevious!();
    }
  }

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {}

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {}

  void _updateItem(MediaItem item) {
    mediaItem.add(item);
  }

  void _updatePlaybackState({
    required Duration position,
    required Duration? bufferPosition,
    required bool isPlaying,
    required bool isBuffering,
    required double playbackSpeed,
  }) {
    final controls = [
      MediaControl.skipToPrevious,
      if (isPlaying) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
    ];

    playbackState.add(PlaybackState(
      controls: controls,
      androidCompactActionIndices: const [0, 1, 2],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      processingState: isBuffering
          ? AudioProcessingState.buffering
          : AudioProcessingState.ready,
      playing: isPlaying,
      updatePosition: position,
      bufferedPosition: bufferPosition ?? Duration.zero,
      speed: playbackSpeed,
    ));
  }
}
