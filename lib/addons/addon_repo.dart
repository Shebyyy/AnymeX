/// Where add-ons are downloaded from: a plain GitHub repository, no releases.
///
/// Layout of that repository:
///   addons.json                      index: id, version, path, platforms
///   add-on/<id>/manifest.json        version + per-platform files + sha256
///   add-on/<id>/bin/<platform>/...   the downloadable files
///   add-on/<id>/build/...            scripts used by CI to produce them
class AddonRepo {
  AddonRepo._();

  // TODO(owner): point these at the real add-ons repository.
  static const String owner = 'Shebyyy';
  static const String name = 'AnymeX-Addons';
  static const String branch = 'main';

  static const String base =
      'https://raw.githubusercontent.com/$owner/$name/$branch';

  static Uri indexUri() => Uri.parse('$base/addons.json');

  /// [relative] is a path relative to the repository root.
  static Uri fileUri(String relative) => Uri.parse('$base/$relative');
}
