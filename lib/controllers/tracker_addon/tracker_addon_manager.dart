import 'dart:convert';

import 'package:anymex/controllers/tracker_addon/generic_tracker_service.dart';
import 'package:anymex/controllers/tracker_addon/tracker_manifest.dart';
import 'package:anymex/controllers/tracker_addon/tracker_registry.dart';
import 'package:anymex/database/kv_helper.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';

/// Manages the lifecycle of tracker add-ons: install, uninstall,
/// import, export, and caches GenericTrackerService instances.
class TrackerAddonManager extends GetxController {
  final TrackerRegistry registry;

  static const _installedKey = 'tracker_addon_installed';

  /// Cache of manifest ID → GenericTrackerService.
  final Map<String, GenericTrackerService> _services = {};

  /// List of installed addon IDs.
  final RxList<String> installedAddonIds = <String>[].obs;

  TrackerAddonManager({required this.registry}) {
    _loadInstalled();
  }

  // ── Public API ──────────────────────────────────────────────

  /// Get a service by addon ID.
  GenericTrackerService? getService(String id) => _services[id];

  /// All registered services.
  List<GenericTrackerService> get allServices => _services.values.toList();

  /// All logged-in addon services.
  List<OnlineService> get loggedInServices =>
      _services.values.where((s) => s.isLoggedIn.value).toList();

  /// All logged-in OnlineService instances (for ServiceHandler).
  List<OnlineService> get loggedInOnlineServices =>
      _services.values
          .where((s) => s.isLoggedIn.value)
          .cast<OnlineService>()
          .toList();

  /// Install a tracker from a pre-built [TrackerManifest].
  /// Returns an error message, or null on success.
  String? installFromManifest(TrackerManifest manifest) {
    if (manifest.id.isEmpty) {
      return 'Manifest has no ID';
    }
    if (installedAddonIds.contains(manifest.id)) {
      return '${manifest.name} is already installed';
    }

    // Validate manifest
    if (manifest.api.baseUrl.isEmpty) {
      return 'Invalid manifest: missing base_url';
    }

    _registerAddon(manifest);
    return null;
  }

  /// Install a tracker from a JSON string.
  /// Returns an error message, or null on success.
  String? installFromJson(String jsonStr) {
    final manifest = TrackerManifest.tryParse(jsonStr);
    if (manifest == null) {
      return 'Invalid manifest JSON';
    }
    return installFromManifest(manifest);
  }

  /// Uninstall a tracker addon.
  void uninstall(String id) {
    final service = _services[id];
    if (service != null) {
      service.dispose();
      _services.remove(id);
    }
    installedAddonIds.remove(id);
    registry.unregister(id);
    _persistInstalled();
    Logger.i('Uninstalled tracker addon: $id');
  }

  /// Export all installed manifests as a JSON string.
  String exportAll() {
    final manifests = _services.values
        .map((s) => s.manifest.toMap())
        .toList();
    return jsonEncode(manifests);
  }

  // ── Internal ────────────────────────────────────────────────

  void _registerAddon(TrackerManifest manifest) {
    // Create the service
    final service = GenericTrackerService(manifest: manifest);
    _services[manifest.id] = service;

    // Register in the name/color registry
    registry.register(
      id: manifest.id,
      name: manifest.name,
      color: manifest.color,
    );

    // Track as installed
    if (!installedAddonIds.contains(manifest.id)) {
      installedAddonIds.add(manifest.id);
    }

    // Persist the manifest JSON for re-creation on restart
    _persistInstalled();

    // Auto-login if we have a stored token
    service.autoLogin();

    Logger.i('Installed tracker addon: ${manifest.name} (${manifest.id})');
  }

  /// Load installed addons from storage on startup.
  void _loadInstalled() {
    try {
      final raw = KvHelper.get<String>(_installedKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw) as List<dynamic>;
      for (final entry in decoded) {
        final manifest = TrackerManifest.fromJson(entry as Map<String, dynamic>);
        _services[manifest.id] = GenericTrackerService(manifest: manifest);
        installedAddonIds.add(manifest.id);
        registry.register(
          id: manifest.id,
          name: manifest.name,
          color: manifest.color,
        );
      }

      Logger.i('Loaded ${decoded.length} installed tracker addons');
    } catch (e) {
      Logger.e('Failed to load installed addons: $e');
    }
  }

  /// Save installed addon manifests to storage.
  void _persistInstalled() {
    final manifests =
        _services.values.map((s) => s.manifest.toMap()).toList();
    KvHelper.set<String>(_installedKey, jsonEncode(manifests));
  }
}
