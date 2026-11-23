import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'hls_playlist.dart';

/// A tiny HTTP proxy bound to 127.0.0.1 only.
///
/// FFmpeg is built without a TLS library (small, identical on every
/// platform, no CA-bundle problems on Android). This proxy lets it read any
/// https source over plain http: Dart's own network stack does the TLS, adds
/// the source's headers, forwards `Range`, follows redirects and rewrites
/// HLS playlists so every segment / key / init URI also goes through it.
class LoopbackProxy {
  final Map<String, String> headers;
  final HttpClient _client = HttpClient();
  late final HttpServer _server;
  bool _closed = false;

  LoopbackProxy._(this.headers) {
    _client.autoUncompress = false;
    _client.connectionTimeout = const Duration(seconds: 20);
  }

  static Future<LoopbackProxy> start({Map<String, String>? headers}) async {
    final proxy = LoopbackProxy._(headers ?? const {});
    proxy._server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    proxy._server.listen(proxy._handle, onError: (_) {});
    return proxy;
  }

  int get port => _server.port;

  /// URL that FFmpeg should open instead of [remote].
  String urlFor(String remote) =>
      'http://127.0.0.1:$port/p?u=${Uri.encodeQueryComponent(remote)}';

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _client.close(force: true);
    await _server.close(force: true);
  }

  static bool _looksLikePlaylist(Uri uri, String? contentType) {
    final path = uri.path.toLowerCase();
    final ct = (contentType ?? '').toLowerCase();
    return path.endsWith('.m3u8') ||
        path.endsWith('.m3u') ||
        ct.contains('mpegurl');
  }

  Future<void> _handle(HttpRequest req) async {
    try {
      final target = req.uri.queryParameters['u'];
      if (req.uri.path != '/p' || target == null) {
        req.response.statusCode = HttpStatus.notFound;
        await req.response.close();
        return;
      }
      final remote = Uri.parse(target);
      final isHead = req.method == 'HEAD';
      final upstreamReq = isHead
          ? await _client.headUrl(remote)
          : await _client.getUrl(remote);
      upstreamReq.followRedirects = true;
      upstreamReq.maxRedirects = 8;
      headers.forEach((k, v) => upstreamReq.headers.set(k, v));
      final range = req.headers.value(HttpHeaders.rangeHeader);
      if (range != null)
        upstreamReq.headers.set(HttpHeaders.rangeHeader, range);
      upstreamReq.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');

      final upstream = await upstreamReq.close();
      final res = req.response;
      res.statusCode = upstream.statusCode;

      final ct = upstream.headers.contentType?.toString();
      if (!isHead && _looksLikePlaylist(remote, ct)) {
        final body = await upstream.transform(utf8.decoder).join();
        final base = upstream.redirects.isNotEmpty
            ? upstream.redirects.last.location.isAbsolute
                  ? upstream.redirects.last.location
                  : remote.resolveUri(upstream.redirects.last.location)
            : remote;
        final rewritten = rewritePlaylistUris(
          body,
          base,
          (abs) => urlFor(abs.toString()),
        );
        final bytes = utf8.encode(rewritten);
        res.headers.contentType = ContentType(
          'application',
          'vnd.apple.mpegurl',
        );
        res.headers.contentLength = bytes.length;
        res.add(bytes);
        await res.close();
        return;
      }

      if (ct != null) res.headers.set(HttpHeaders.contentTypeHeader, ct);
      for (final name in const [
        HttpHeaders.contentLengthHeader,
        HttpHeaders.contentRangeHeader,
        HttpHeaders.acceptRangesHeader,
      ]) {
        final v = upstream.headers.value(name);
        if (v != null) res.headers.set(name, v);
      }
      if (!isHead) await res.addStream(upstream);
      await res.close();
    } catch (_) {
      try {
        req.response.statusCode = HttpStatus.badGateway;
        await req.response.close();
      } catch (_) {}
    }
  }
}
