import 'dart:async';
import 'dart:io';

import 'package:anymex/addons/addon_repo.dart';
import 'package:anymex/addons/core/addon_manifest.dart';
import 'package:anymex/addons/core/platform_key.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Base class for add-ons that live in the add-ons repository
/// (see [AddonRepo]): reads the index and manifest, downloads the file for
/// this platform, verifies SHA-256, marks it executable, tracks the version.
abstract class RemoteAddon extends Addon {
  /// Whether this platform needs a file download at all. False on iOS, where
  /// nothing downloaded can run, so the add-on works with built-in code.
  bool get needsDownload => currentPlatformKey() != null;

  Future<Directory> get addonDir async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'addons', id));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File?> installedBinary() async {
    final key = currentPlatformKey();
    if (key == null) return null;
    final dir = await addonDir;
    final spec = File(p.join(dir.path, 'installed.json'));
    if (!await spec.exists()) return null;
    final name = (await spec.readAsString()).trim().split('\n').first;
    final f = File(p.join(dir.path, name));
    return await f.exists() ? f : null;
  }

  Future<String?> installedVersion() async {
    final dir = await addonDir;
    final f = File(p.join(dir.path, 'version.txt'));
    return await f.exists() ? (await f.readAsString()).trim() : null;
  }

  Future<AddonManifest> fetchManifest() async {
    final index = await _get(AddonRepo.indexUri());
    final entry = AddonIndex.parse(index).byId(id);
    if (entry == null) {
      throw StateError('Add-on "$id" is not listed in the add-ons repository');
    }
    final body = await _get(AddonRepo.fileUri(entry.manifest));
    return AddonManifest.parse(body);
  }

  Future<String> _get(Uri uri) async {
    final client = http.Client();
    try {
      final res = await client.get(uri).timeout(const Duration(seconds: 25));
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode} for ${uri.path}');
      }
      return res.body;
    } finally {
      client.close();
    }
  }

  /// Subclasses can reject a freshly downloaded file (for example by running
  /// it once). Throw to abort and clean up the install.
  Future<void> verifyInstalled(File binary) async {}

  @override
  Future<bool> isInstalled() async {
    if (!needsDownload) return true;
    return (await installedBinary()) != null;
  }

  @override
  Future<void> install() async {
    if (downloading.value || !needsDownload) return;
    downloading.value = true;
    progress.value = 0;
    final client = http.Client();
    File? part;
    try {
      final manifest = await fetchManifest();
      final key = currentPlatformKey()!;
      final spec = manifest.files[key];
      if (spec == null) {
        throw UnsupportedError('No $name build for $key yet');
      }
      final dir = await addonDir;
      final target = File(p.join(dir.path, spec.fileName));
      part = File('${target.path}.part');

      final req = http.Request(
        'GET',
        AddonRepo.fileUri('add-on/$id/${spec.path}'),
      );
      final res = await client.send(req);
      if (res.statusCode != 200) {
        throw HttpException('Download failed (HTTP ${res.statusCode})');
      }
      final total = res.contentLength ?? spec.size ?? 0;
      final sink = part.openWrite();
      final digestSink = _DigestSink();
      final hasher = sha256.startChunkedConversion(digestSink);
      var received = 0;
      await for (final chunk in res.stream) {
        sink.add(chunk);
        hasher.add(chunk);
        received += chunk.length;
        if (total > 0) progress.value = received / total;
      }
      await sink.flush();
      await sink.close();
      hasher.close();
      final actual = digestSink.value.toString();
      if (actual != spec.sha256) {
        throw StateError('Checksum mismatch, download discarded');
      }

      if (await target.exists()) await target.delete();
      await part.rename(target.path);
      if (spec.executable && !Platform.isWindows) {
        await Process.run('chmod', ['755', target.path]);
      }
      try {
        await verifyInstalled(target);
      } catch (_) {
        await target.delete();
        rethrow;
      }
      await File(p.join(dir.path, 'installed.json'))
          .writeAsString('${spec.fileName}\n');
      await File(p.join(dir.path, 'version.txt'))
          .writeAsString(manifest.version);
      installed.value = true;
      hasUpdate.value = false;
      progress.value = 1;
    } finally {
      client.close();
      if (part != null && await part.exists()) {
        try {
          await part.delete();
        } catch (_) {}
      }
      downloading.value = false;
    }
  }

  @override
  Future<void> uninstall() async {
    final dir = await addonDir;
    if (await dir.exists()) await dir.delete(recursive: true);
    installed.value = !needsDownload;
    hasUpdate.value = false;
    progress.value = 0;
  }

  @override
  Future<void> update() async {
    await install();
  }

  @override
  Future<bool> checkForUpdate() async {
    if (!needsDownload) return false;
    final local = await installedVersion();
    if (local == null) return false;
    final manifest = await fetchManifest();
    final newer = compareVersions(manifest.version, local) > 0;
    hasUpdate.value = newer;
    return newer;
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest value;
  @override
  void add(Digest data) => value = data;
  @override
  void close() {}
}
