import 'dart:typed_data';

/// What the player asks the add-on to cut.
class ClipRequest {
  /// Remote source (http/https). Null when [localPath] is used.
  final String? url;
  final Map<String, String> headers;

  /// Offline / downloaded file, used instead of [url] when set.
  final String? localPath;
  final Duration start;
  final Duration end;
  final String title;
  final String episode;

  const ClipRequest({
    this.url,
    this.headers = const {},
    this.localPath,
    required this.start,
    required this.end,
    this.title = '',
    this.episode = '',
  });

  Duration get length => end - start;
  bool get isRemote => localPath == null && url != null;

  /// Builds a request from what the player was actually given: an http(s)
  /// URL (extension link, or the TorrServer stream URL for torrents) or a
  /// local file path / `file://` URI (offline downloads).
  factory ClipRequest.fromPlayerSource({
    required String? source,
    Map<String, String>? headers,
    required Duration start,
    required Duration end,
    String title = '',
    String episode = '',
  }) {
    final src = source?.trim() ?? '';
    if (src.isEmpty) {
      throw const ClipException('Nothing is playing yet');
    }
    final lower = src.toLowerCase();
    final remote = lower.startsWith('http://') || lower.startsWith('https://');
    if (remote) {
      return ClipRequest(
        url: src,
        headers: headers ?? const {},
        start: start,
        end: end,
        title: title,
        episode: episode,
      );
    }
    final path = lower.startsWith('file://')
        ? Uri.parse(src).toFilePath()
        : src;
    return ClipRequest(
      localPath: path,
      start: start,
      end: end,
      title: title,
      episode: episode,
    );
  }
}

class ClipResult {
  final String path;

  /// Where the clip really starts. Stream copy snaps to a keyframe / segment,
  /// so this can be a little earlier than requested.
  final Duration actualStart;
  final int bytes;
  final String engine;

  const ClipResult({
    required this.path,
    required this.actualStart,
    required this.bytes,
    required this.engine,
  });
}

class ClipException implements Exception {
  final String message;
  const ClipException(this.message);
  @override
  String toString() => message;
}

class ClipCancelled implements Exception {
  const ClipCancelled();
  @override
  String toString() => 'Clip cancelled';
}

class ClipCancelToken {
  bool _cancelled = false;
  void Function()? _listener;

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
    _listener?.call();
  }

  void onCancel(void Function()? listener) => _listener = listener;

  void throwIfCancelled() {
    if (_cancelled) throw const ClipCancelled();
  }
}

typedef ClipProgress = void Function(double fraction);
typedef ClipOutputPath = String Function(String extension);
typedef Aes128CbcDecryptor = Uint8List Function(
  Uint8List cipher,
  Uint8List key,
  Uint8List iv,
);
