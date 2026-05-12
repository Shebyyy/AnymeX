import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum GifQuality {
  low(320, 'Low', '320px'),
  medium(480, 'Medium', '480px'),
  high(720, 'High', '720px');

  const GifQuality(this.width, this.label, this.sizeLabel);
  final int width;
  final String label;
  final String sizeLabel;
}

class GifRecorder {
  final List<Uint8List> _frames = [];
  bool _isRecording = false;
  int _maxDurationSeconds = 5;
  GifQuality _quality = GifQuality.medium;
  static const int fps = 10;
  static const int frameDelayMs = 100;

  bool get isRecording => _isRecording;
  int get frameCount => _frames.length;
  int get maxFrames => _maxDurationSeconds * fps;
  double get progress => _frames.isEmpty ? 0.0 : _frames.length / maxFrames;
  int get remainingFrames => maxFrames - _frames.length;
  GifQuality get quality => _quality;

  void configure({
    required int maxDurationSeconds,
    GifQuality quality = GifQuality.medium,
  }) {
    _maxDurationSeconds = maxDurationSeconds.clamp(1, 30);
    _quality = quality;
  }

  void startRecording({
    int maxDurationSeconds = 5,
    GifQuality quality = GifQuality.medium,
  }) {
    _maxDurationSeconds = maxDurationSeconds.clamp(1, 30);
    _quality = quality;
    _frames.clear();
    _isRecording = true;
  }

  void addFrame(Uint8List pngBytes) {
    if (!_isRecording) return;
    if (_frames.length >= maxFrames) {
      _isRecording = false;
      return;
    }
    _frames.add(pngBytes);
  }

  bool get isBufferFull => _frames.length >= maxFrames;

  void cancelRecording() {
    _isRecording = false;
    _frames.clear();
  }

  Future<Uint8List?> encodeGif() async {
    if (_frames.isEmpty) return null;

    final gifEncoder = img.GifEncoder(delay: frameDelayMs);

    for (int i = 0; i < _frames.length; i++) {
      final frame = _frames[i];
      final image = img.decodeImage(frame);
      if (image == null) continue;

      final resized = img.copyResize(image, width: _quality.width);
      gifEncoder.addFrame(resized, duration: frameDelayMs);
    }

    final result = gifEncoder.finish();
    if (result == null) return null;
    return Uint8List.fromList(result);
  }

  Future<String?> stopRecordingAndSave() async {
    _isRecording = false;
    if (_frames.isEmpty) return null;

    try {
      final gifBytes = await encodeGif();
      if (gifBytes == null) return null;

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/anymex_gif_$timestamp.gif';
      final file = File(filePath);
      await file.writeAsBytes(gifBytes);

      return filePath;
    } catch (e) {
      return null;
    }
  }

  Future<String?> saveToDownloads() async {
    _isRecording = false;
    if (_frames.isEmpty) return null;

    try {
      final gifBytes = await encodeGif();
      if (gifBytes == null) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'anymex_gif_$timestamp.gif';

      Directory? saveDir;
      if (Platform.isAndroid) {
        saveDir = Directory('/storage/emulated/0/Download');
        if (!await saveDir.exists()) {
          saveDir = await getExternalStorageDirectory();
        }
      }

      if (saveDir != null && await saveDir.exists()) {
        final filePath = '${saveDir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(gifBytes);
        return filePath;
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(gifBytes);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  Future<void> shareGif() async {
    final filePath = await stopRecordingAndSave();
    if (filePath == null) return;

    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Made with AnymeX 🎬',
    );
  }

  void dispose() {
    _isRecording = false;
    _frames.clear();
  }
}
