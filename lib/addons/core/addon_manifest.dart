import 'dart:convert';

/// One entry of the root `addons.json` in the add-ons repository.
class AddonIndexEntry {
  final String id;
  final String name;
  final String description;
  final String version;

  /// Directory of the add-on inside the repo, e.g. `add-on/clip`.
  final String path;

  /// Path of the add-on manifest relative to the repo root.
  final String manifest;
  final List<String> platforms;

  const AddonIndexEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.path,
    required this.manifest,
    required this.platforms,
  });

  factory AddonIndexEntry.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final path = (json['path'] as String?) ?? 'add-on/$id';
    return AddonIndexEntry(
      id: id,
      name: (json['name'] as String?) ?? id,
      description: (json['description'] as String?) ?? '',
      version: json['version'] as String,
      path: path,
      manifest: (json['manifest'] as String?) ?? '$path/manifest.json',
      platforms: ((json['platforms'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Root `addons.json`: the list of add-ons and their latest versions.
class AddonIndex {
  final int schema;
  final List<AddonIndexEntry> addons;

  const AddonIndex({required this.schema, required this.addons});

  factory AddonIndex.parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return AddonIndex(
      schema: (json['schema'] as num?)?.toInt() ?? 1,
      addons: ((json['addons'] as List?) ?? const [])
          .map((e) => AddonIndexEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  AddonIndexEntry? byId(String id) {
    for (final a in addons) {
      if (a.id == id) return a;
    }
    return null;
  }
}

/// A downloadable file of an add-on for one platform key.
class AddonFileSpec {
  /// Path relative to the add-on directory, e.g. `bin/linux-x64/ffmpeg`.
  final String path;
  final String sha256;
  final int? size;
  final bool executable;

  const AddonFileSpec({
    required this.path,
    required this.sha256,
    this.size,
    this.executable = false,
  });

  String get fileName => path.split('/').last;

  factory AddonFileSpec.fromJson(Map<String, dynamic> json) => AddonFileSpec(
    path: json['path'] as String,
    sha256: (json['sha256'] as String).toLowerCase(),
    size: (json['size'] as num?)?.toInt(),
    executable: (json['executable'] as bool?) ?? false,
  );
}

/// `add-on/<id>/manifest.json`: version plus per-platform files.
class AddonManifest {
  final int schema;
  final String id;
  final String version;
  final String? notes;
  final Map<String, AddonFileSpec> files;

  const AddonManifest({
    required this.schema,
    required this.id,
    required this.version,
    required this.files,
    this.notes,
  });

  factory AddonManifest.parse(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final files = <String, AddonFileSpec>{};
    ((json['files'] as Map?) ?? const {}).forEach((key, value) {
      files[key.toString()] = AddonFileSpec.fromJson(
        value as Map<String, dynamic>,
      );
    });
    return AddonManifest(
      schema: (json['schema'] as num?)?.toInt() ?? 1,
      id: json['id'] as String,
      version: json['version'] as String,
      notes: json['notes'] as String?,
      files: files,
    );
  }
}

/// Compares dotted numeric versions (`1.2.10` > `1.2.9`). Non-numeric parts
/// count as 0. Returns a negative, zero or positive number like `compareTo`.
int compareVersions(String a, String b) {
  List<int> parts(String v) =>
      v.split(RegExp(r'[.+-]')).map((e) => int.tryParse(e) ?? 0).toList();
  final pa = parts(a);
  final pb = parts(b);
  final n = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < n; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}
