import 'dart:io';

import 'clip_models.dart';
import 'dart_hls_engine.dart';
import 'ffmpeg_engine.dart';

/// Chooses how a clip is cut, so the player code never has to.
///
/// * **HLS source**: [DartHlsEngine] downloads only the segments that cover
///   the range (handles AES-128 and fMP4 itself). If the FFmpeg add-on is
///   available it then trims that small local file to the exact start and
///   remuxes it to a clean mp4; without FFmpeg (iOS) the joined segments are
///   delivered as they are (`.ts` or `.mp4`).
/// * **Progressive source** (mp4, mkv over http/https): FFmpeg reads the range
///   directly through the loopback proxy. Needs the add-on.
/// * **Offline file**: FFmpeg. Needs the add-on.
///
/// FFmpeg's own HLS reader is deliberately not used: seeking into fMP4 HLS
/// produced corrupt output with FFmpeg 6.1 and 7.1 in testing.
class ClipPipeline {
  final FfmpegEngine? ffmpeg;
  final Aes128CbcDecryptor? decryptor;
  final Directory tempDir;

  /// Shown when a source needs FFmpeg but none is available. Differs by
  /// platform: iOS can never have it, others can install the add-on.
  final String noFfmpegHint;

  ClipPipeline({
    this.ffmpeg,
    this.decryptor,
    required this.tempDir,
    this.noFfmpegHint = 'Install the Clip add-on to cut it.',
  });

  Future<ClipResult> cut(
    ClipRequest request, {
    required ClipOutputPath outputPathFor,
    ClipProgress? onProgress,
    ClipCancelToken? cancel,
  }) async {
    if (request.length <= Duration.zero) {
      throw const ClipException('The clip must be longer than zero seconds');
    }

    if (!request.isRemote) {
      if (ffmpeg == null) {
        throw const ClipException(
          'Clipping offline files needs the Clip add-on on this device',
        );
      }
      return ffmpeg!.cut(
        request,
        outputPathFor: outputPathFor,
        onProgress: onProgress,
        cancel: cancel,
      );
    }

    final hls = DartHlsEngine(decryptor: decryptor);
    bool isHls;
    try {
      isHls = await hls.isPlaylist(Uri.parse(request.url!), request.headers);
    } catch (e) {
      hls.close();
      if (e is ClipException) rethrow;
      throw ClipException('Could not reach the video: $e');
    }

    if (!isHls) {
      hls.close();
      if (ffmpeg == null) {
        throw const ClipException(
          'This stream is not HLS. Install the Clip add-on to cut it.',
        );
      }
      return ffmpeg!.cut(
        request,
        outputPathFor: outputPathFor,
        onProgress: onProgress,
        cancel: cancel,
      );
    }

    await tempDir.create(recursive: true);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    String? tempPath;
    try {
      final joined = await hls.cut(
        request,
        outputPathFor: (ext) => tempPath = '${tempDir.path}/hls_$stamp.$ext',
        onProgress: (f) => onProgress?.call(ffmpeg == null ? f : f * 0.85),
        cancel: cancel,
      );

      if (ffmpeg == null) {
        // No remuxer: hand the joined segments over as the final file.
        final ext = joined.path.split('.').last;
        final finalPath = outputPathFor(ext);
        await File(joined.path).copy(finalPath);
        onProgress?.call(1.0);
        return ClipResult(
          path: finalPath,
          actualStart: joined.actualStart,
          bytes: await File(finalPath).length(),
          engine: joined.engine,
        );
      }

      final offset = request.start - joined.actualStart;
      final trimStart = offset.isNegative ? Duration.zero : offset;
      final remuxed = await ffmpeg!.cut(
        ClipRequest(
          localPath: joined.path,
          start: trimStart,
          end: trimStart + request.length,
          title: request.title,
          episode: request.episode,
        ),
        outputPathFor: outputPathFor,
        onProgress: (f) => onProgress?.call(0.85 + f * 0.15),
        cancel: cancel,
      );
      return ClipResult(
        path: remuxed.path,
        actualStart: joined.actualStart + trimStart,
        bytes: remuxed.bytes,
        engine: 'hls-dart+ffmpeg',
      );
    } finally {
      if (tempPath != null) {
        try {
          await File(tempPath!).delete();
        } catch (_) {}
      }
    }
  }
}
