/// Formats seconds for FFmpeg (`12.345`).
String ffmpegSeconds(Duration d) =>
    (d.inMilliseconds / 1000.0).toStringAsFixed(3);

/// Arguments for a stream-copy cut of `[start, end)` from [input].
///
/// * `-ss` before `-i` seeks the input (fast, keyframe based),
/// * `-t` is the output duration,
/// * `-c copy` keeps the original streams (no re-encode, tiny binary),
/// * `-sn` drops subtitles (they cannot be copied into mp4),
/// * `-progress pipe:1` prints machine readable progress on stdout.
List<String> buildFfmpegClipArgs({
  required String input,
  required Duration start,
  required Duration end,
  required String output,
  int? audioStreamIndex,
}) {
  final duration = end - start;
  if (duration <= Duration.zero) {
    throw ArgumentError('end must be after start');
  }
  return [
    '-hide_banner',
    '-nostdin',
    '-loglevel',
    'error',
    '-progress',
    'pipe:1',
    '-ss',
    ffmpegSeconds(start),
    '-i',
    input,
    '-t',
    ffmpegSeconds(duration),
    '-map',
    '0:v:0',
    '-map',
    audioStreamIndex == null ? '0:a:0?' : '0:a:$audioStreamIndex?',
    '-sn',
    '-dn',
    '-c',
    'copy',
    '-avoid_negative_ts',
    'make_zero',
    '-y',
    output,
  ];
}

/// Parses an `out_time_us=123456` style progress line; null if not one.
Duration? parseFfmpegProgressLine(String line) {
  final l = line.trim();
  const keys = ['out_time_us=', 'out_time_ms='];
  for (final k in keys) {
    if (l.startsWith(k)) {
      final v = int.tryParse(l.substring(k.length));
      if (v == null || v < 0) return null;
      return Duration(microseconds: v); // ffmpeg reports microseconds for both
    }
  }
  return null;
}
