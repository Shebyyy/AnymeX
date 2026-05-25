class DesktopMediaNotification {
  void init({
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function(Duration position) onSeek,
    required Future<void> Function() onSkipToNext,
    required Future<void> Function() onPrevious,
  }) {}

  Future<void> updateMetadata({
    required String title,
    required String artist,
    String? artworkUrl,
    Duration? duration,
  }) async {}

  Future<void> updatePlaybackState({
    required Duration position,
    required bool isPlaying,
    required bool isBuffering,
    required double playbackSpeed,
  }) async {}

  void updateSkipButtons({
    required bool canSkipNext,
    required bool canSkipPrevious,
  }) {}

  Future<void> stop() async {}
}
