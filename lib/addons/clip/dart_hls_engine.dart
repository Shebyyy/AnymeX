import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../core/hls_playlist.dart';
import 'clip_models.dart';

/// Pure Dart HLS cutter: downloads only the segments that cover the range
/// and joins them. No native code, so it works on iOS (where downloaded
/// executables and frameworks cannot be loaded) and as a fallback elsewhere.
///
/// Limits: HLS only, whole-segment granularity (the clip can start up to one
/// segment early), MPEG-TS segments give a `.ts` file, fMP4 segments give a
/// `.mp4` file, SAMPLE-AES and byte-range segments are not supported.
class DartHlsEngine {
  final Aes128CbcDecryptor? decryptor;
  final HttpClient _client = HttpClient();

  DartHlsEngine({this.decryptor}) {
    _client.connectionTimeout = const Duration(seconds: 20);
  }

  Future<Uint8List> _get(
    Uri uri,
    Map<String, String> headers, {
    int attempts = 3,
  }) async {
    Object? last;
    for (var i = 0; i < attempts; i++) {
      try {
        final req = await _client.getUrl(uri);
        headers.forEach((k, v) => req.headers.set(k, v));
        final res = await req.close();
        if (res.statusCode != 200 && res.statusCode != 206) {
          await res.drain<void>();
          throw ClipException('HTTP ${res.statusCode} for ${uri.host}');
        }
        final b = BytesBuilder(copy: false);
        await for (final chunk in res) {
          b.add(chunk);
        }
        return b.takeBytes();
      } catch (e) {
        last = e;
        if (e is ClipException && e.message.contains('HTTP 4')) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 300 * (i + 1)));
      }
    }
    throw ClipException('Download failed: $last');
  }

  Future<String> _getText(Uri uri, Map<String, String> headers) async =>
      utf8.decode(await _get(uri, headers), allowMalformed: true);

  /// Reads only the first bytes of [uri] to see whether it is an HLS
  /// playlist, so a direct mp4 is never downloaded just to be rejected.
  Future<bool> isPlaylist(Uri uri, Map<String, String> headers) async {
    final req = await _client.getUrl(uri);
    headers.forEach((k, v) => req.headers.set(k, v));
    req.headers.set(HttpHeaders.rangeHeader, 'bytes=0-511');
    final res = await req.close();
    if (res.statusCode != 200 && res.statusCode != 206) {
      await res.drain<void>();
      throw ClipException('HTTP ${res.statusCode} for ${uri.host}');
    }
    final first = await res.first; // cancels the rest of the body
    final head = utf8.decode(first, allowMalformed: true);
    return head.replaceFirst('\uFEFF', '').trimLeft().startsWith('#EXTM3U');
  }

  void close() => _client.close(force: true);

  static Uint8List _ivFor(HlsSegment s) {
    final hex = s.key?.ivHex;
    if (hex != null) {
      var h = hex.toLowerCase();
      if (h.startsWith('0x')) h = h.substring(2);
      h = h.padLeft(32, '0');
      final out = Uint8List(16);
      for (var i = 0; i < 16; i++) {
        out[i] = int.parse(h.substring(i * 2, i * 2 + 2), radix: 16);
      }
      return out;
    }
    final iv = Uint8List(16);
    var seq = s.mediaSequence;
    for (var i = 15; i >= 12; i--) {
      iv[i] = seq & 0xff;
      seq >>= 8;
    }
    return iv;
  }

  Future<ClipResult> cut(
    ClipRequest request, {
    required ClipOutputPath outputPathFor,
    ClipProgress? onProgress,
    ClipCancelToken? cancel,
  }) async {
    if (!request.isRemote) {
      throw const ClipException(
        'Offline files need the FFmpeg add-on on this platform',
      );
    }
    var playlistUri = Uri.parse(request.url!);
    if (!await isPlaylist(playlistUri, request.headers)) {
      throw const ClipException(
        'This source is not an HLS stream; this platform can only clip HLS',
      );
    }
    var text = await _getText(playlistUri, request.headers);
    if (isMasterPlaylist(text)) {
      final variants = parseMasterPlaylist(text, playlistUri);
      if (variants.isEmpty) throw const ClipException('Empty HLS playlist');
      variants.sort((a, b) => b.bandwidth.compareTo(a.bandwidth));
      playlistUri = variants.first.uri;
      text = await _getText(playlistUri, request.headers);
    }
    final media = parseMediaPlaylist(text, playlistUri);
    if (media.segments.isEmpty) throw const ClipException('No segments found');

    final chosen = selectSegments(
      media,
      request.start.inMilliseconds / 1000.0,
      request.end.inMilliseconds / 1000.0,
    );
    if (chosen.isEmpty) {
      throw const ClipException('The chosen time is outside the video');
    }
    if (chosen.any((s) => s.hasByteRange)) {
      throw const ClipException('Byte-range HLS is not supported here');
    }
    if (chosen.any((s) => s.key != null && !s.key!.isAes128)) {
      throw const ClipException('This stream uses unsupported encryption');
    }
    if (chosen.any((s) => s.key != null) && decryptor == null) {
      throw const ClipException('Encrypted stream, decryptor unavailable');
    }

    final initUri = chosen.first.initUri;
    final output = outputPathFor(initUri != null ? 'mp4' : 'ts');
    final sink = File(output).openWrite();
    final keys = <Uri, Uint8List>{};
    try {
      if (initUri != null) {
        sink.add(await _get(initUri, request.headers));
      }
      for (var i = 0; i < chosen.length; i++) {
        cancel?.throwIfCancelled();
        final s = chosen[i];
        var data = await _get(s.uri, request.headers);
        final key = s.key;
        if (key != null && key.uri != null) {
          final keyBytes = keys[key.uri!] ??= await _get(
            key.uri!,
            request.headers,
          );
          data = decryptor!(data, keyBytes, _ivFor(s));
        }
        sink.add(data);
        onProgress?.call((i + 1) / chosen.length);
      }
      await sink.flush();
      await sink.close();
    } catch (_) {
      try {
        await sink.close();
      } catch (_) {}
      try {
        await File(output).delete();
      } catch (_) {}
      rethrow;
    } finally {
      _client.close(force: true);
    }
    return ClipResult(
      path: output,
      actualStart: Duration(milliseconds: (chosen.first.start * 1000).round()),
      bytes: await File(output).length(),
      engine: 'hls-dart',
    );
  }
}
