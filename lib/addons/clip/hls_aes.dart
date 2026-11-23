import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// AES-128-CBC with PKCS#7 padding, as used by `METHOD=AES-128` in HLS.
/// Uses `pointycastle`, which the app already depends on.
Uint8List aes128CbcDecrypt(Uint8List cipher, Uint8List key, Uint8List iv) {
  if (key.length != 16) {
    throw ArgumentError('AES-128 key must be 16 bytes, got ${key.length}');
  }
  if (iv.length != 16) {
    throw ArgumentError('IV must be 16 bytes, got ${iv.length}');
  }
  if (cipher.isEmpty || cipher.length % 16 != 0) {
    throw ArgumentError('Encrypted segment length is not a multiple of 16');
  }
  final cbc = CBCBlockCipher(AESEngine())
    ..init(false, ParametersWithIV(KeyParameter(key), iv));
  final out = Uint8List(cipher.length);
  for (var offset = 0; offset < cipher.length; offset += 16) {
    cbc.processBlock(cipher, offset, out, offset);
  }
  final pad = out.last;
  if (pad < 1 || pad > 16) {
    throw StateError('Bad PKCS#7 padding (wrong key or IV?)');
  }
  return Uint8List.sublistView(out, 0, out.length - pad);
}
