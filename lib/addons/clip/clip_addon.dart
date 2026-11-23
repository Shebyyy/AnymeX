import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';

import 'package:anymex/addons/clip/clip_models.dart';
import 'package:anymex/addons/clip/clip_pipeline.dart';
import 'package:anymex/addons/clip/ffmpeg_engine.dart';
import 'package:anymex/addons/clip/hls_aes.dart';
import 'package:anymex/addons/core/clip_naming.dart';
import 'package:anymex/addons/remote_addon.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Cuts clips out of the video being watched.
///
/// Android, Windows, Linux, macOS download a small FFmpeg binary from the
/// add-ons repository. iOS cannot run downloaded code, so there the add-on is
/// always "installed" and uses the built-in HLS cutter (HLS sources only).
class ClipAddon extends RemoteAddon {
  @override
  String get id => 'clip';

  @override
  String get name => 'Clip Recorder';

  @override
  IconData get icon => Icons.content_cut_rounded;

  final activeClip = false.obs;
  final clipProgress = 0.0.obs;
  ClipCancelToken? _token;

  @override
  Future<void> verifyInstalled(File binary) async {
    await FfmpegEngine(binary.path).version();
  }

  Future<Directory> clipsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'AnymeX', 'Clips'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  void cancel() => _token?.cancel();

  Future<ClipResult> createClip(ClipRequest request) async {
    if (activeClip.value) {
      throw const ClipException('A clip is already being created');
    }
    activeClip.value = true;
    clipProgress.value = 0;
    final token = _token = ClipCancelToken();
    try {
      final binary = await installedBinary();
      final dir = await clipsDir();
      final tmp = await getTemporaryDirectory();
      final pipeline = ClipPipeline(
        ffmpeg: binary == null ? null : FfmpegEngine(binary.path),
        decryptor: aes128CbcDecrypt,
        noFfmpegHint: Platform.isIOS
            ? 'On iOS only HLS streams can be clipped.'
            : 'Install the Clip add-on to cut it.',
        tempDir: Directory(p.join(tmp.path, 'clip_work')),
      );
      return await pipeline.cut(
        request,
        outputPathFor: (ext) => _uniquePath(
          dir,
          clipFileName(
            title: request.title,
            episode: request.episode,
            start: request.start,
            extension: ext,
          ),
        ),
        onProgress: (f) => clipProgress.value = f,
        cancel: token,
      );
    } finally {
      activeClip.value = false;
      _token = null;
    }
  }

  static String _uniquePath(Directory dir, String fileName) {
    var candidate = p.join(dir.path, fileName);
    var n = 1;
    final base = p.basenameWithoutExtension(fileName);
    final ext = p.extension(fileName);
    while (File(candidate).existsSync()) {
      candidate = p.join(dir.path, '${base}_$n$ext');
      n++;
    }
    return candidate;
  }
}
