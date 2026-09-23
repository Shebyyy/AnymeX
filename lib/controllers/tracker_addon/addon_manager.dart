import 'dart:convert';
import 'package:anymex/controllers/network/network_manager.dart';
import 'package:anymex/controllers/tracker_addon/addon_manifest.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// Remote repository item in `addons.json`.
class RemoteAddonInfo {
  final String id;
  final String name;
  final String version;
  final String? author;
  final String? description;
  final String? icon;
  final String color;
  final List<String> capabilities;
  final String? authType;
  final String manifestUrl;

  const RemoteAddonInfo({
    required this.id,
    required this.name,
    required this.version,
    this.author,
    this.description,
    this.icon,
    required this.color,
    required this.capabilities,
    this.authType,
    required this.manifestUrl,
  });

  factory RemoteAddonInfo.fromJson(Map<String, dynamic> json) {
    return RemoteAddonInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
      author: json['author'] as String?,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String? ?? '#7E57C2',
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['anime'],
      authType: json['auth_type'] as String?,
      manifestUrl: json['manifest_url'] as String? ?? '',
    );
  }
}

/// Remote Add-on Repository (`addons.json`).
class AddonRepository {
  final String name;
  final int version;
  final String? description;
  final List<RemoteAddonInfo> addons;

  const AddonRepository({
    required this.name,
    required this.version,
    this.description,
    required this.addons,
  });

  factory AddonRepository.fromJson(Map<String, dynamic> json) {
    final list = (json['addons'] as List<dynamic>?)
            ?.map((e) => RemoteAddonInfo.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return AddonRepository(
      name: json['name'] as String? ?? 'Tracker Add-on Repository',
      version: (json['version'] as num?)?.toInt() ?? 1,
      description: json['description'] as String?,
      addons: list,
    );
  }
}

/// Manages installed tracker add-ons, repository loading, and JSON persistence.
class AddonManager extends GetxController {
  static AddonManager get to => Get.find<AddonManager>();

  http.Client get _client => NetworkManager.instance.compatibleClient;

  final RxList<AddonManifest> installedAddons = <AddonManifest>[].obs;
  final RxList<RemoteAddonInfo> availableAddons = <RemoteAddonInfo>[].obs;
  final RxList<String> repoUrls = <String>[].obs;
  final RxBool isLoadingRepo = false.obs;

  static const String defaultRepoUrl =
      'https://raw.githubusercontent.com/Shebyyy/AnymeX-Addon-Services/main/addons.json';

  @override
  void onInit() {
    super.onInit();
    _loadInstalledAddons();
    _loadRepoUrls();
  }

  void _loadInstalledAddons() {
    final raw = ServiceKeys.installedAddons.get<String>('[]');
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = <AddonManifest>[];
      for (final item in decoded) {
        if (item is Map) {
          list.add(AddonManifest.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      installedAddons.value = list;
    } catch (e) {
      Logger.e('Failed to load installed addons: $e');
      installedAddons.clear();
    }
  }

  void _saveInstalledAddons() {
    final list = installedAddons.map((a) => a.toJson()).toList();
    ServiceKeys.installedAddons.set(jsonEncode(list));
  }

  void _loadRepoUrls() {
    final raw = ServiceKeys.trackerAddonRepos.get<String>('[]');
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      repoUrls.value = decoded.map((e) => e.toString()).toList();
      if (repoUrls.isEmpty) {
        repoUrls.add(defaultRepoUrl);
        _saveRepoUrls();
      }
    } catch (_) {
      repoUrls.value = [defaultRepoUrl];
    }
  }

  void _saveRepoUrls() {
    ServiceKeys.trackerAddonRepos.set(jsonEncode(repoUrls));
  }

  bool isInstalled(String addonId) {
    return installedAddons.any((a) => a.id == addonId);
  }

  AddonManifest? getInstalled(String addonId) {
    try {
      return installedAddons.firstWhere((a) => a.id == addonId);
    } catch (_) {
      return null;
    }
  }

  /// Install or update an add-on manifest directly.
  Future<bool> installAddon(AddonManifest manifest) async {
    final index = installedAddons.indexWhere((a) => a.id == manifest.id);
    if (index >= 0) {
      installedAddons[index] = manifest;
    } else {
      installedAddons.add(manifest);
    }
    _saveInstalledAddons();
    return true;
  }

  /// Uninstall an add-on and clear its auth tokens.
  Future<void> uninstallAddon(String addonId) async {
    installedAddons.removeWhere((a) => a.id == addonId);
    _saveInstalledAddons();

    // Clean up stored auth tokens for this add-on
    DynamicKeys.trackerAddonToken.delete(addonId);
    DynamicKeys.trackerAddonRefreshToken.delete(addonId);
    DynamicKeys.trackerAddonProfile.delete(addonId);
  }

  /// Fetch remote repository index (`addons.json`).
  Future<void> fetchRepositories() async {
    isLoadingRepo.value = true;
    final results = <RemoteAddonInfo>[];

    for (final url in repoUrls) {
      try {
        final resp = await _client.get(Uri.parse(url));
        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
          final repo = AddonRepository.fromJson(decoded);
          results.addAll(repo.addons);
        }
      } catch (e) {
        Logger.e('Failed to fetch addon repo from $url: $e');
      }
    }

    availableAddons.value = results;
    isLoadingRepo.value = false;
  }

  /// Download and install an add-on manifest from its URL.
  Future<bool> installFromUrl(String manifestUrl) async {
    try {
      final resp = await _client.get(Uri.parse(manifestUrl));
      if (resp.statusCode == 200) {
        final manifest = AddonManifest.tryParse(resp.body);
        if (manifest != null && manifest.id.isNotEmpty) {
          return await installAddon(manifest);
        }
      }
    } catch (e) {
      Logger.e('Failed to install addon from URL $manifestUrl: $e');
    }
    return false;
  }

  /// Install an add-on from a raw JSON string.
  Future<bool> installFromJson(String jsonString) async {
    try {
      final manifest = AddonManifest.tryParse(jsonString);
      if (manifest != null && manifest.id.isNotEmpty) {
        return await installAddon(manifest);
      }
    } catch (e) {
      Logger.e('Failed to parse addon JSON: $e');
    }
    return false;
  }

  void addRepoUrl(String url) {
    if (!repoUrls.contains(url)) {
      repoUrls.add(url);
      _saveRepoUrls();
      fetchRepositories();
    }
  }

  void removeRepoUrl(String url) {
    repoUrls.remove(url);
    _saveRepoUrls();
    fetchRepositories();
  }
}
