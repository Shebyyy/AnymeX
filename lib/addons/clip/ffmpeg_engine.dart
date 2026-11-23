import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/ffmpeg_args.dart';
import '../core/loopback_proxy.dart';
import 'clip_models.dart';

/// Cuts clips with the FFmpeg binary delivered by the add-on
/// (Android, Windows, Linux, macOS). Never used on iOS.
class FfmpegEngine {
  final String binaryPath;
  const FfmpegEngine(this.binaryPath);

  /// Starts [binary]. Android blocks executing files from app storage
  /// directly, so there it goes through the system linker; this is the same
  /// approach TorrServerAddon already uses.
  static Future<Process> launch(String binary, List<String> args) {
    if (Platform.isAndroid) {
      final linker = File('/system/bin/linker64').existsSync()
          ? '/system/bin/linker64'
          : '/system/bin/linker';
      return Process.start(linker, [binary, ...args]);
    }
    return Process.start(binary, args);
  }

  /// Runs `ffmpeg -version`; used as a self-test after install.
  Future<String> version() async {
    final p = await launch(binaryPath, const ['-version']);
    final out = await p.stdout.transform(utf8.decoder).join();
    await p.stderr.drain<void>();
    final code = await p.exitCode.timeout(const Duration(seconds: 15));
    if (code != 0 || !out.contains('ffmpeg version')) {
      throw ClipException('FFmpeg self-test failed (exit $code)');
    }
    return out.split('\n').first.trim();
  }

  Future<ClipResult> cut(
    ClipRequest request, {
    required ClipOutputPath outputPathFor,
    ClipProgress? onProgress,
    ClipCancelToken? cancel,
  }) async {
    LoopbackProxy? proxy;
    try {
      final String input;
      if (request.isRemote) {
        proxy = await LoopbackProxy.start(headers: request.headers);
        input = proxy.urlFor(request.url!);
      } else if (request.localPath != null) {
        input = request.localPath!;
      } else {
        throw const ClipException('No video source to clip');
      }

      // mp4 first (plays everywhere); if the codecs do not fit mp4
      // (for example VP9 + Opus) retry as mkv.
      String lastError = '';
      for (final ext in const ['mp4', 'mkv']) {
        cancel?.throwIfCancelled();
        final output = outputPathFor(ext);
        final error = await _run(
          input: input,
          output: output,
          request: request,
          onProgress: onProgress,
          cancel: cancel,
        );
        if (error == null) {
          final size = await File(output).length();
          if (size == 0) {
            await File(output).delete();
            lastError = 'FFmpeg produced an empty file';
            continue;
          }
          return ClipResult(
            path: output,
            actualStart: request.start,
            bytes: size,
            engine: 'ffmpeg',
          );
        }
        lastError = error;
        try {
          await File(output).delete();
        } catch (_) {}
      }
      throw ClipException(_friendly(lastError));
    } finally {
      await proxy?.close();
    }
  }

  /// Returns null on success, otherwise FFmpeg's error text.
  Future<String?> _run({
    required String input,
    required String output,
    required ClipRequest request,
    ClipProgress? onProgress,
    ClipCancelToken? cancel,
  }) async {
    final args = buildFfmpegClipArgs(
      input: input,
      start: request.start,
      end: request.end,
      output: output,
    );
    final process = await launch(binaryPath, args);
    cancel?.onCancel(() => process.kill());

    final total = request.length.inMicroseconds;
    final sub = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final t = parseFfmpegProgressLine(line);
          if (t != null && total > 0) {
            onProgress?.call((t.inMicroseconds / total).clamp(0.0, 1.0));
          }
        });
    final errBuf = StringBuffer();
    final errSub = process.stderr
        .transform(utf8.decoder)
        .listen((chunk) => errBuf.write(chunk));

    final code = await process.exitCode;
    await sub.cancel();
    await errSub.cancel();
    cancel?.onCancel(null);

    if (cancel?.isCancelled ?? false) {
      try {
        await File(output).delete();
      } catch (_) {}
      throw const ClipCancelled();
    }
    if (code == 0) {
      onProgress?.call(1.0);
      return null;
    }
    return errBuf.toString().trim().isEmpty
        ? 'FFmpeg exited with code $code'
        : errBuf.toString().trim();
  }

  static String _friendly(String raw) {
    final e = raw.toLowerCase();
    if (e.contains('403') || e.contains('forbidden')) {
      return 'The server refused the request (403). Try again while the video is playing.';
    }
    if (e.contains('404') || e.contains('not found')) {
      return 'The video link is no longer available (404).';
    }
    if (e.contains('invalid data found') || e.contains('moov atom not found')) {
      return 'This stream format cannot be cut.';
    }
    final line = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return line.isEmpty ? 'Clip failed' : 'Clip failed: ${line.last}';
  }
}
