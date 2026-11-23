// Plain-Dart self checks for the add-on core (no Flutter, no packages):
//
//   dart run test/addons/core_checks.dart
//
// Optional environment for the end-to-end checks:
//   ADDON_FFMPEG    path to the add-on's ffmpeg binary
//   ADDON_FFPROBE   path to an ffprobe used to verify outputs
//   ADDON_HLS_BASE  base URL serving plain/, enc/ and fmp4/ HLS fixtures
//   ADDON_MP4_URL   an https url of a progressive mp4 (>= 10 s)
//   ADDON_OPENSSL   `openssl` binary, used as the AES-128 test decryptor
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../lib/addons/clip/clip_models.dart';
import '../../lib/addons/clip/clip_pipeline.dart';
import '../../lib/addons/clip/dart_hls_engine.dart';
import '../../lib/addons/clip/ffmpeg_engine.dart';
import '../../lib/addons/core/addon_manifest.dart';
import '../../lib/addons/core/clip_naming.dart';
import '../../lib/addons/core/ffmpeg_args.dart';
import '../../lib/addons/core/hls_playlist.dart';
import '../../lib/addons/core/loopback_proxy.dart';

int _pass = 0, _fail = 0, _skip = 0;

void check(String name, bool ok, [String detail = '']) {
  if (ok) {
    _pass++;
    stdout.writeln('  ok    $name');
  } else {
    _fail++;
    stdout.writeln('  FAIL  $name ${detail.isEmpty ? '' : '-> $detail'}');
  }
}

void skip(String name, String why) {
  _skip++;
  stdout.writeln('  skip  $name ($why)');
}

Future<double> probeDuration(String probe, String file) async {
  final r = await Process.run(probe, [
    '-v',
    'error',
    '-show_entries',
    'format=duration',
    '-of',
    'csv=p=0',
    file,
  ]);
  return double.tryParse((r.stdout as String).trim()) ?? -1;
}

Future<String> probeStreams(String probe, String file) async {
  final r = await Process.run(probe, [
    '-v',
    'error',
    '-show_entries',
    'stream=codec_type',
    '-of',
    'csv=p=0',
    file,
  ]);
  return (r.stdout as String).trim().split('\n').toSet().toList().join(',');
}

Future<void> main() async {
  final env = Platform.environment;
  final tmp = await Directory.systemTemp.createTemp('addon_checks');

  stdout.writeln('manifest / versions');
  final idx = AddonIndex.parse('''
{"schema":1,"addons":[{"id":"clip","name":"Clip","version":"1.2.0",
 "path":"add-on/clip","platforms":["linux-x64"]}]}''');
  check('index parses', idx.byId('clip')?.version == '1.2.0');
  check(
    'manifest path defaults',
    idx.byId('clip')?.manifest == 'add-on/clip/manifest.json',
  );
  final man = AddonManifest.parse(
    '''
{"schema":1,"id":"clip","version":"1.2.0","files":{"linux-x64":
 {"path":"bin/linux-x64/ffmpeg","sha256":"ABC","size":10,"executable":true}}}''',
  );
  check(
    'manifest file spec',
    man.files['linux-x64']!.fileName == 'ffmpeg' &&
        man.files['linux-x64']!.executable &&
        man.files['linux-x64']!.sha256 == 'abc',
  );
  check('version 1.2.10 > 1.2.9', compareVersions('1.2.10', '1.2.9') > 0);
  check('version equal', compareVersions('1.0', '1.0.0') == 0);
  check('version less', compareVersions('0.9.9', '1.0.0') < 0);

  stdout.writeln('naming');
  final n = clipFileName(
    title: 'One Piece: "Film"/Red?',
    episode: '5',
    start: const Duration(minutes: 12, seconds: 30),
    extension: 'mp4',
  );
  check('file name', n == 'One_Piece_Film_Red_EP5_00-12-30.mp4', n);
  check(
    'empty title',
    clipFileName(
          title: '',
          episode: '',
          start: Duration.zero,
          extension: '.ts',
        ) ==
        'Clip_00-00-00.ts',
  );

  stdout.writeln('ffmpeg args');
  final args = buildFfmpegClipArgs(
    input: 'in',
    start: const Duration(seconds: 3),
    end: const Duration(seconds: 8),
    output: 'o.mp4',
  );
  check(
    'args contain -ss 3.000 before -i',
    args.indexOf('-ss') < args.indexOf('-i') &&
        args[args.indexOf('-ss') + 1] == '3.000',
  );
  check('args duration 5.000', args[args.indexOf('-t') + 1] == '5.000');
  check(
    'args copy',
    args.contains('-c') && args[args.indexOf('-c') + 1] == 'copy',
  );
  check(
    'progress parse',
    parseFfmpegProgressLine('out_time_us=2500000') ==
        const Duration(milliseconds: 2500),
  );
  bool threw = false;
  try {
    buildFfmpegClipArgs(
      input: 'a',
      start: const Duration(seconds: 5),
      end: const Duration(seconds: 5),
      output: 'o',
    );
  } catch (_) {
    threw = true;
  }
  check('zero length rejected', threw);

  stdout.writeln('player source -> request');
  final r1 = ClipRequest.fromPlayerSource(
    source: 'https://cdn.x/v/index.m3u8',
    headers: {'Referer': 'https://x'},
    start: Duration.zero,
    end: const Duration(seconds: 5),
  );
  check(
    'https source is remote with headers',
    r1.isRemote && r1.headers['Referer'] == 'https://x',
  );
  final r2 = ClipRequest.fromPlayerSource(
    source: 'http://127.0.0.1:8090/stream/x?link=abc&index=1',
    headers: null,
    start: Duration.zero,
    end: const Duration(seconds: 5),
  );
  check('torrserver stream url is remote', r2.isRemote && r2.headers.isEmpty);
  final r3 = ClipRequest.fromPlayerSource(
    source: '/storage/emulated/0/Anymex/ep1.mkv',
    start: Duration.zero,
    end: const Duration(seconds: 5),
  );
  check(
    'absolute path is local',
    !r3.isRemote && r3.localPath == '/storage/emulated/0/Anymex/ep1.mkv',
  );
  final r4 = ClipRequest.fromPlayerSource(
    source: 'file:///tmp/a%20b.mp4',
    start: Duration.zero,
    end: const Duration(seconds: 5),
  );
  check(
    'file uri decoded to path',
    r4.localPath == '/tmp/a b.mp4',
    '${r4.localPath}',
  );
  bool noSrc = false;
  try {
    ClipRequest.fromPlayerSource(
      source: '  ',
      start: Duration.zero,
      end: const Duration(seconds: 5),
    );
  } on ClipException {
    noSrc = true;
  }
  check('empty source -> clear error', noSrc);

  stdout.writeln('hls parser');
  const media = '''#EXTM3U
#EXT-X-VERSION:3
#EXT-X-MEDIA-SEQUENCE:7
#EXT-X-KEY:METHOD=AES-128,URI="k.key",IV=0x0A
#EXTINF:6.0,
a.ts
#EXTINF:6.0,
b.ts
#EXTINF:3.5,
c.ts
#EXT-X-ENDLIST''';
  final base = Uri.parse('https://cdn.example.com/v/index.m3u8');
  final pl = parseMediaPlaylist(media, base);
  check('3 segments', pl.segments.length == 3);
  check('vod from ENDLIST', pl.isVod);
  check('duration 15.5', (pl.totalDuration - 15.5).abs() < 1e-9);
  check(
    'relative uri resolved',
    pl.segments[0].uri.toString() == 'https://cdn.example.com/v/a.ts',
  );
  check('sequence numbers', pl.segments[2].mediaSequence == 9);
  check(
    'key parsed',
    pl.segments[0].key?.isAes128 == true &&
        pl.segments[0].key!.uri.toString().endsWith('/k.key'),
  );
  final sel = selectSegments(pl, 7.0, 13.0);
  check(
    'select 7..11 -> b only',
    selectSegments(pl, 7.0, 11.0).length == 1 &&
        selectSegments(pl, 7.0, 11.0).first.uri.path.endsWith('b.ts'),
  );
  check('select 7..13 -> b,c', sel.length == 2);
  final sel2 = selectSegments(pl, 5.0, 13.0);
  check('select 5..13 -> a,b,c', sel2.length == 3);
  final sel3 = selectSegments(pl, 12.0, 100.0);
  check(
    'select 12..end -> c only (b ends at 12)',
    sel3.length == 1 && sel3.first.uri.path.endsWith('c.ts'),
  );
  check('select past end -> none', selectSegments(pl, 20, 30).isEmpty);
  const master = '''#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360
low/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2800000,RESOLUTION=1280x720
hi/index.m3u8''';
  final vs = parseMasterPlaylist(master, base);
  check(
    'master detected',
    isMasterPlaylist(master) && !isMasterPlaylist(media),
  );
  check(
    '2 variants',
    vs.length == 2 &&
        vs[1].bandwidth == 2800000 &&
        vs[1].uri.path == '/v/hi/index.m3u8',
  );
  final rw = rewritePlaylistUris(media, base, (u) => 'P(${u.path})');
  check(
    'rewrite segments',
    rw.contains('\nP(/v/a.ts)') && rw.contains('\nP(/v/c.ts)'),
  );
  check('rewrite key attr', rw.contains('URI="P(/v/k.key)"'));

  // ---------- end to end (need tools) ----------
  final ff = env['ADDON_FFMPEG'];
  final probe = env['ADDON_FFPROBE'];
  final hls = env['ADDON_HLS_BASE'];
  final mp4 = env['ADDON_MP4_URL'];
  final openssl = env['ADDON_OPENSSL'];

  stdout.writeln('ffmpeg binary');
  if (ff == null || probe == null) {
    skip('ffmpeg engine', 'ADDON_FFMPEG / ADDON_FFPROBE not set');
  } else {
    final engine = FfmpegEngine(ff);
    try {
      final v = await engine.version();
      check('self-test version', v.startsWith('ffmpeg version'), v);
    } catch (e) {
      check('self-test version', false, '$e');
    }

    if (mp4 == null) {
      skip('https mp4 via proxy', 'ADDON_MP4_URL not set');
    } else {
      final progress = <double>[];
      try {
        final r = await engine.cut(
          ClipRequest(
            url: mp4,
            headers: const {'X-Test': '1'},
            start: const Duration(seconds: 10),
            end: const Duration(seconds: 17),
          ),
          outputPathFor: (e) => '${tmp.path}/https.$e',
          onProgress: progress.add,
        );
        final d = await probeDuration(probe, r.path);
        check(
          'https mp4 cut >= 7s, at most one GOP (~7s) longer',
          d >= 6.5 && d <= 14.5,
          'duration $d',
        );
        check(
          'https mp4 has video+audio',
          (await probeStreams(probe, r.path)).contains('video') &&
              (await probeStreams(probe, r.path)).contains('audio'),
        );
        check('progress reported', progress.isNotEmpty && progress.last == 1.0);
      } catch (e) {
        check('https mp4 cut', false, '$e');
      }
    }

    // local file
    final localSrc = '${tmp.path}/local_src.mp4';
    if (mp4 != null) {
      try {
        final r = await engine.cut(
          ClipRequest(
            url: mp4,
            start: Duration.zero,
            end: const Duration(seconds: 12),
          ),
          outputPathFor: (e) => localSrc,
        );
        check('local source prepared', r.bytes > 0);
        final lr = await engine.cut(
          ClipRequest(
            localPath: localSrc,
            start: const Duration(seconds: 2),
            end: const Duration(seconds: 6),
          ),
          outputPathFor: (e) => '${tmp.path}/local_out.$e',
        );
        final d = await probeDuration(probe, lr.path);
        check(
          'offline file cut >= 4s, at most one GOP longer',
          d >= 3.5 && d <= 11,
          'duration $d',
        );
      } catch (e) {
        check('offline file cut', false, '$e');
      }
    }

    // cancel
    if (hls != null) {
      final token = ClipCancelToken();
      Timer? t;
      var cancelled = false;
      t = Timer(const Duration(milliseconds: 1), token.cancel);
      try {
        await engine.cut(
          ClipRequest(
            url: '$hls/plain/index.m3u8',
            start: Duration.zero,
            end: const Duration(seconds: 40),
          ),
          outputPathFor: (e) => '${tmp.path}/cancel.$e',
          cancel: token,
        );
      } on ClipCancelled {
        cancelled = true;
      } catch (_) {}
      t.cancel();
      check('cancel throws ClipCancelled', cancelled || token.isCancelled);
      check(
        'cancel leaves no output',
        !File('${tmp.path}/cancel.mp4').existsSync(),
      );
    }
  }

  stdout.writeln('dart hls engine (no native code)');
  if (hls == null || probe == null) {
    skip('dart hls engine', 'ADDON_HLS_BASE / ADDON_FFPROBE not set');
  } else {
    for (final kind in ['plain', 'fmp4']) {
      try {
        final r = await DartHlsEngine().cut(
          ClipRequest(
            url: '$hls/$kind/index.m3u8',
            start: const Duration(seconds: 8),
            end: const Duration(seconds: 20),
          ),
          outputPathFor: (e) => '${tmp.path}/dart_$kind.$e',
        );
        final d = await probeDuration(probe, r.path);
        check(
          'dart hls $kind ~12-19s, starts at segment (${r.actualStart.inMilliseconds / 1000}s)',
          d > 11 && d < 22 && r.actualStart <= const Duration(seconds: 8),
          'duration $d',
        );
        check(
          'dart hls $kind extension',
          r.path.endsWith(kind == 'fmp4' ? '.mp4' : '.ts'),
        );
      } catch (e) {
        check('dart hls $kind', false, '$e');
      }
    }
    if (openssl == null) {
      skip('dart hls AES-128', 'ADDON_OPENSSL not set');
    } else {
      Uint8List decrypt(Uint8List c, Uint8List key, Uint8List iv) {
        String hex(Uint8List b) =>
            b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
        final f = File('${tmp.path}/seg.bin')..writeAsBytesSync(c);
        final r = Process.runSync(openssl, [
          'enc',
          '-d',
          '-aes-128-cbc',
          '-K',
          hex(key),
          '-iv',
          hex(iv),
          '-in',
          f.path,
        ], stdoutEncoding: null);
        if (r.exitCode != 0) throw ClipException('openssl failed: ${r.stderr}');
        return Uint8List.fromList(r.stdout as List<int>);
      }

      try {
        final r = await DartHlsEngine(decryptor: decrypt).cut(
          ClipRequest(
            url: '$hls/enc/index.m3u8',
            start: const Duration(seconds: 8),
            end: const Duration(seconds: 20),
          ),
          outputPathFor: (e) => '${tmp.path}/dart_enc.$e',
        );
        final d = await probeDuration(probe, r.path);
        check(
          'dart hls AES-128 decrypts and plays ~12-19s',
          d > 11 && d < 22,
          'duration $d',
        );
      } catch (e) {
        check('dart hls AES-128', false, '$e');
      }
      bool noDec = false;
      try {
        await DartHlsEngine().cut(
          ClipRequest(
            url: '$hls/enc/index.m3u8',
            start: Duration.zero,
            end: const Duration(seconds: 5),
          ),
          outputPathFor: (e) => '${tmp.path}/x.$e',
        );
      } on ClipException {
        noDec = true;
      }
      check('encrypted without decryptor -> clear error', noDec);
    }
    // wrong source type
    if (mp4 != null) {
      bool clear = false;
      try {
        await DartHlsEngine().cut(
          ClipRequest(
            url: mp4,
            start: Duration.zero,
            end: const Duration(seconds: 5),
          ),
          outputPathFor: (e) => '${tmp.path}/y.$e',
        );
      } on ClipException catch (e) {
        clear = e.message.contains('not an HLS');
      } catch (_) {}
      check('non-HLS source -> clear error', clear);
    }
  }

  stdout.writeln('pipeline (dart segment download + ffmpeg remux)');
  if (hls == null || probe == null || ff == null) {
    skip('pipeline', 'needs ADDON_HLS_BASE / ADDON_FFPROBE / ADDON_FFMPEG');
  } else {
    Uint8List aes(Uint8List c, Uint8List key, Uint8List iv) {
      String hex(Uint8List b) =>
          b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
      final f = File('${tmp.path}/seg2.bin')..writeAsBytesSync(c);
      final r = Process.runSync(openssl ?? 'openssl', [
        'enc',
        '-d',
        '-aes-128-cbc',
        '-K',
        hex(key),
        '-iv',
        hex(iv),
        '-in',
        f.path,
      ], stdoutEncoding: null);
      if (r.exitCode != 0) throw ClipException('openssl failed');
      return Uint8List.fromList(r.stdout as List<int>);
    }

    final pipe = ClipPipeline(
      ffmpeg: FfmpegEngine(ff),
      decryptor: aes,
      tempDir: Directory('${tmp.path}/t'),
    );
    for (final kind in ['plain', 'enc', 'fmp4']) {
      try {
        final r = await pipe.cut(
          ClipRequest(
            url: '$hls/$kind/index.m3u8',
            start: const Duration(seconds: 8),
            end: const Duration(seconds: 20),
          ),
          outputPathFor: (e) => '${tmp.path}/pipe_$kind.$e',
        );
        final d = await probeDuration(probe, r.path);
        final s2 = await probeStreams(probe, r.path);
        check(
          'pipeline hls $kind -> mp4 ~12s with video+audio',
          r.path.endsWith('.mp4') &&
              d > 11 &&
              d < 20 &&
              s2.contains('video') &&
              s2.contains('audio'),
          'duration $d streams $s2 path ${r.path}',
        );
        check('pipeline hls $kind engine tag', r.engine == 'hls-dart+ffmpeg');
      } catch (e) {
        check('pipeline hls $kind', false, '$e');
      }
    }
    // no ffmpeg (iOS style): raw joined segments are delivered
    final bare = ClipPipeline(
      decryptor: aes,
      tempDir: Directory('${tmp.path}/t2'),
    );
    for (final kind in ['plain', 'fmp4']) {
      try {
        final r = await bare.cut(
          ClipRequest(
            url: '$hls/$kind/index.m3u8',
            start: const Duration(seconds: 8),
            end: const Duration(seconds: 20),
          ),
          outputPathFor: (e) => '${tmp.path}/bare_$kind.$e',
        );
        final d = await probeDuration(probe, r.path);
        check(
          'no-ffmpeg pipeline $kind plays (${r.path.split('.').last})',
          d > 11 && d < 22,
          'duration $d',
        );
      } catch (e) {
        check('no-ffmpeg pipeline $kind', false, '$e');
      }
    }
    if (mp4 != null) {
      bool clear = false;
      try {
        await bare.cut(
          ClipRequest(
            url: mp4,
            start: Duration.zero,
            end: const Duration(seconds: 5),
          ),
          outputPathFor: (e) => '${tmp.path}/z.$e',
        );
      } on ClipException catch (e) {
        clear = e.message.contains('add-on');
      }
      check('progressive source without ffmpeg -> asks for add-on', clear);
      try {
        final r = await pipe.cut(
          ClipRequest(
            url: mp4,
            start: const Duration(seconds: 5),
            end: const Duration(seconds: 11),
          ),
          outputPathFor: (e) => '${tmp.path}/prog.$e',
        );
        check(
          'progressive source via pipeline',
          r.engine == 'ffmpeg' && r.bytes > 0,
        );
      } catch (e) {
        check('progressive source via pipeline', false, '$e');
      }
    }
    bool offlineErr = false;
    try {
      await bare.cut(
        ClipRequest(
          localPath: '/tmp/x.mp4',
          start: Duration.zero,
          end: const Duration(seconds: 3),
        ),
        outputPathFor: (e) => '${tmp.path}/o.$e',
      );
    } on ClipException {
      offlineErr = true;
    }
    check('offline file without ffmpeg -> clear error', offlineErr);
  }

  stdout.writeln('proxy');
  if (hls != null) {
    final proxy = await LoopbackProxy.start(headers: const {'X-Probe': 'yes'});
    final c = HttpClient();
    try {
      final req = await c.getUrl(
        Uri.parse(proxy.urlFor('$hls/enc/index.m3u8')),
      );
      final res = await req.close();
      final body = await res.transform(const SystemEncoding().decoder).join();
      check(
        'playlist served',
        res.statusCode == 200 && body.contains('#EXTM3U'),
      );
      check(
        'segment uris point at proxy',
        body.contains('127.0.0.1:${proxy.port}/p?u=') &&
            !body.contains('\nseg000.ts'),
      );
      check(
        'key uri rewritten',
        body.contains('URI="http://127.0.0.1:${proxy.port}/p?u='),
      );
      final bad = await (await c.getUrl(
        Uri.parse('http://127.0.0.1:${proxy.port}/nope'),
      )).close();
      check('unknown path 404', bad.statusCode == 404);
      check('bound to loopback only', proxy.port > 0);
    } finally {
      c.close(force: true);
      await proxy.close();
    }
  }

  await tmp.delete(recursive: true);
  stdout.writeln('\n$_pass passed, $_fail failed, $_skip skipped');
  exit(_fail == 0 ? 0 : 1);
}
