import 'dart:convert';

import 'package:anymex/database/kv_helper.dart';
import 'package:anymex/utils/logger.dart';

/// Storage keys for per-addon auth tokens.
/// Each key stores values keyed by addon ID.
class AddonKeys {
  AddonKeys._();

  static const _prefix = 'addon_';

  /// Access token
  static const authToken = AddonKey('auth_token');

  /// Refresh token
  static const authRefreshToken = AddonKey('auth_refresh_token');

  /// User ID
  static const authUserId = AddonKey('auth_user_id');

  /// Cached user data JSON
  static const authUserData = AddonKey('auth_user_data');
}

/// Helper for per-addon key-value storage.
class AddonKey {
  final String suffix;
  const AddonKey(this.suffix);

  String _key(String addonId) => '${AddonKeys._prefix}${suffix}_$addonId';

  T? get<T>(String addonId, {T? defaultVal}) {
    return KvHelper.get<T>(_key(addonId), defaultVal: defaultVal);
  }

  void set<T>(String addonId, T value) {
    KvHelper.set<T>(_key(addonId), value);
  }

  void delete(String addonId) {
    KvHelper.remove(_key(addonId));
  }
}

/// Runtime registry for tracker add-ons.
///
/// Stores a map of addon ID → {name, color} so that other parts of
/// the app (e.g. TrackBinding) can look up display info without
/// needing the full TrackerManifest or GenericTrackerService.
class TrackerRegistry {
  static const _registryKey = 'tracker_addon_registry';

  Map<String, Map<String, String>> _entries = {};

  TrackerRegistry() {
    _load();
  }

  // ── Read ──────────────────────────────────────────────────────

  /// Whether an addon with [id] is registered.
  bool isAddon(String id) => _entries.containsKey(id);

  /// Get the display name for an addon.
  String getTrackerName(String id) {
    return _entries[id]?['name'] ?? id;
  }

  /// Get the hex color for an addon (e.g. '#FD6585').
  String getTrackerColor(String id) {
    return _entries[id]?['color'] ?? '#666666';
  }

  /// Get all registered addon IDs.
  List<String> get addonIds => _entries.keys.toList();

  /// Register (or update) an addon entry.
  void register({
    required String id,
    required String name,
    required String color,
  }) {
    _entries[id] = {'name': name, 'color': color};
    _save();
    Logger.i('TrackerRegistry: registered $id ($name)');
  }

  /// Unregister an addon.
  void unregister(String id) {
    _entries.remove(id);
    _save();
    Logger.i('TrackerRegistry: unregistered $id');
  }

  // ── Persistence ───────────────────────────────────────────────

  void _load() {
    try {
      final raw = KvHelper.get<String>(_registryKey);
      if (raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _entries = decoded.map((k, v) {
          final map = v as Map;
          return MapEntry(
            k,
            {
              'name': (map['name'] as String?) ?? k,
              'color': (map['color'] as String?) ?? '#666666',
            },
          );
        });
      }
    } catch (e) {
      Logger.e('TrackerRegistry: failed to load: $e');
      _entries = {};
    }
  }

  void _save() {
    KvHelper.set<String>(_registryKey, jsonEncode(_entries));
  }
}
