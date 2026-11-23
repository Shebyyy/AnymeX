// Checks the pointycastle based HLS decryptor. Needs package resolution for
// pointycastle, so it is run with the app's normal tooling (flutter test /
// dart with a package config), not with the plain core checks:
//
//   dart --packages=<package_config.json> test/addons/aes_check.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../../lib/addons/clip/clip_models.dart';
import '../../lib/addons/clip/clip_pipeline.dart';
import '../../lib/addons/clip/ffmpeg_engine.dart';
import '../../lib/addons/clip/hls_aes.dart';

int fails = 0;
void check(String n, bool ok, [String d = '']) {
  stdout.writeln('  ${ok ? 'ok  ' : 'FAIL'}  $n ${ok ? '' : d}');
  if (!ok) fails++;
}

Uint8List unhex(String h) => Uint8List.fromList([
  for (var i = 0; i < h.length; i += 2)
    int.parse(h.substring(i, i + 2), radix: 16),
]);
String hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

Future<void> main() async {
  final env = Platform.environment;
  stdout.writeln('aes-128-cbc');

  // NIST SP 800-38A F.2.2 (CBC-AES128.Decrypt), two blocks, no padding block:
  // decrypting the first two ciphertext blocks must give the plaintext blocks.
  final key = unhex('2b7e151628aed2a6abf7158809cf4f3c');
  final iv = unhex('000102030405060708090a0b0c0d0e0f');
  final ct = unhex(
    '7649abac8119b246cee98e9b12e9197d5086cb9b507219ee95db113a917678b2',
  );
  // The helper strips PKCS#7, so build a padded ciphertext with openssl below;
  // here check the raw block transform by appending a valid padding block.
  final openssl = env['ADDON_OPENSSL'] ?? 'openssl';
  final plainKnown = unhex(
    '6bc1bee22e409f96e93d7e117393172aae2d8a571e03ac9c9eb76fac45af8e51',
  );
  final tmp = await Directory.systemTemp.createTemp('aes');
  await File('${tmp.path}/p.bin').writeAsBytes(plainKnown);
  final enc = Process.runSync(openssl, [
    'enc',
    '-aes-128-cbc',
    '-K',
    hex(key),
    '-iv',
    hex(iv),
    '-in',
    '${tmp.path}/p.bin',
  ], stdoutEncoding: null);
  final encBytes = Uint8List.fromList(enc.stdout as List<int>);
  check(
    'NIST vector: first 32 ciphertext bytes match',
    hex(encBytes.sublist(0, 32)) == hex(ct),
    hex(encBytes.sublist(0, 32)),
  );
  check(
    'NIST vector: decrypt gives the plaintext',
    hex(aes128CbcDecrypt(encBytes, key, iv)) == hex(plainKnown),
  );

  // random sizes vs openssl
  final rnd = Random(7);
  var allOk = true;
  for (final n in [1, 15, 16, 17, 100, 4096, 188 * 50, 100003]) {
    final plain = Uint8List.fromList(List.generate(n, (_) => rnd.nextInt(256)));
    final k = Uint8List.fromList(List.generate(16, (_) => rnd.nextInt(256)));
    final v = Uint8List.fromList(List.generate(16, (_) => rnd.nextInt(256)));
    await File('${tmp.path}/r.bin').writeAsBytes(plain);
    final e = Process.runSync(openssl, [
      'enc',
      '-aes-128-cbc',
      '-K',
      hex(k),
      '-iv',
      hex(v),
      '-in',
      '${tmp.path}/r.bin',
    ], stdoutEncoding: null);
    final out = aes128CbcDecrypt(
      Uint8List.fromList(e.stdout as List<int>),
      k,
      v,
    );
    if (hex(out) != hex(plain)) allOk = false;
  }
  check('random lengths round-trip against openssl', allOk);

  bool threw(void Function() f) {
    try {
      f();
      return false;
    } catch (_) {
      return true;
    }
  }

  check(
    'wrong key length rejected',
    threw(() => aes128CbcDecrypt(Uint8List(16), Uint8List(8), iv)),
  );
  check(
    'non multiple of 16 rejected',
    threw(() => aes128CbcDecrypt(Uint8List(17), key, iv)),
  );
  check(
    'wrong key -> bad padding error',
    threw(
      () => aes128CbcDecrypt(
        encBytes,
        Uint8List.fromList(List.filled(16, 1)),
        iv,
      ),
    ),
  );

  final ff = env['ADDON_FFMPEG'];
  final probe = env['ADDON_FFPROBE'];
  final hls = env['ADDON_HLS_BASE'];
  if (ff != null && probe != null && hls != null) {
    stdout.writeln('encrypted hls with the real decryptor');
    final pipe = ClipPipeline(
      ffmpeg: FfmpegEngine(ff),
      decryptor: aes128CbcDecrypt,
      tempDir: Directory('${tmp.path}/t'),
    );
    try {
      final r = await pipe.cut(
        ClipRequest(
          url: '$hls/enc/index.m3u8',
          start: const Duration(seconds: 8),
          end: const Duration(seconds: 20),
        ),
        outputPathFor: (e) => '${tmp.path}/enc.$e',
      );
      final p = Process.runSync(probe, [
        '-v',
        'error',
        '-show_entries',
        'format=duration',
        '-of',
        'csv=p=0',
        r.path,
      ]);
      final d = double.tryParse((p.stdout as String).trim()) ?? -1;
      check(
        'pipeline AES-128 hls -> playable mp4 (${d}s)',
        r.path.endsWith('.mp4') && d > 11 && d < 20,
      );
    } catch (e) {
      check('pipeline AES-128 hls', false, '$e');
    }
  }
  await tmp.delete(recursive: true);
  stdout.writeln(fails == 0 ? '\nall passed' : '\n$fails failed');
  exit(fails == 0 ? 0 : 1);
}
