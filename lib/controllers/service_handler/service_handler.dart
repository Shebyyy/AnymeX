import 'package:anymex/controllers/cacher/cache_controller.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/controllers/services/mal/mal_service.dart';
import 'package:anymex/controllers/services/simkl/simkl_service.dart';
import 'package:anymex/controllers/source/source_controller.dart';
import 'package:anymex/controllers/tracker_addon/tracker_addon_manager.dart';
import 'package:anymex/controllers/tracker_addon/tracker_registry.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/database/kv_helper.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Service/base_service.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex_extension_runtime_bridge/Models/Source.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ServicesType {
  anilist,
  mal,
  simkl,
  extensions;

  bool get isMal => this == ServicesType.mal;
  bool get isAL => this == ServicesType.anilist;
  bool get isSimkl => this == ServicesType.simkl;

  BaseService get service {
    switch (this) {
      case ServicesType.anilist:
        return Get.find<AnilistData>();
      case ServicesType.mal:
        return Get.find<MalService>();
      case ServicesType.simkl:
        return Get.find<SimklService>();
      case ServicesType.extensions:
        return Get.find<SourceController>();
    }
  }

  OnlineService get onlineService {
    switch (this) {
      case ServicesType.anilist:
        return Get.find<AnilistData>();
      case ServicesType.mal:
        return Get.find<MalService>();
      case ServicesType.simkl:
        return Get.find<SimklService>();
      default:
        return Get.find<AnilistData>();
    }
  }
}

final serviceHandler = Get.find<ServiceHandler>();

class ServiceHandler extends GetxController {
  final serviceType = ServicesType.anilist.obs;
  final anilistService = Get.find<AnilistData>();
  final malService = Get.find<MalService>();
  final simklService = Get.find<SimklService>();
  final extensionService = Get.find<SourceController>();

  // ── Add-on Tracker Support ─────────────────────────────────────
  /// ID of the currently active addon tracker (null if using built-in).
  final Rxn<String> activeAddonId = Rxn<String>(null);

  /// The add-on manager (registered in main.dart).
  TrackerAddonManager get addonManager {
    if (Get.isRegistered<TrackerAddonManager>()) {
      return Get.find<TrackerAddonManager>();
    }
    // Fallback: not yet available (early init)
    throw StateError('TrackerAddonManager not yet registered');
  }

  /// Registry shortcut.
  TrackerRegistry get registry {
    if (Get.isRegistered<TrackerRegistry>()) {
      return Get.find<TrackerRegistry>();
    }
    throw StateError('TrackerRegistry not yet registered');
  }

  /// Check if the current service is an add-on tracker.
  bool get isAddonActive => activeAddonId.value != null;

  /// Get the active addon's OnlineService, if any.
  OnlineService? get activeAddonService {
    final id = activeAddonId.value;
    if (id == null) return null;
    return addonManager.getService(id);
  }

  BaseService get service {
    switch (serviceType.value) {
      case ServicesType.anilist:
        return anilistService;
      case ServicesType.mal:
        return malService;
      case ServicesType.simkl:
        return simklService;
      case ServicesType.extensions:
        return extensionService;
    }
  }

  OnlineService get onlineService {
    switch (serviceType.value) {
      case ServicesType.anilist:
        return anilistService;
      case ServicesType.mal:
        return malService;
      case ServicesType.simkl:
        return simklService;
      default:
        return anilistService;
    }
  }

  OnlineService? get activeOrLoggedInOnlineService {
    // If an addon is active, return it
    final addon = activeAddonService;
    if (addon != null && addon.isLoggedIn.value) return addon;

    if (serviceType.value == ServicesType.extensions) {
      // Check addon services first
      for (final s in addonManager.loggedInOnlineServices) {
        return s;
      }
      // Fall back to built-in
      if (anilistService.isLoggedIn.value) return anilistService;
      if (malService.isLoggedIn.value) return malService;
      if (simklService.isLoggedIn.value) return simklService;
      return null;
    }
    return onlineService;
  }

  Rx<Profile> get profileData {
    // If addon active, use its profile
    final addon = activeAddonService;
    if (addon != null && addon.isLoggedIn.value) {
      return addon.profileData;
    }
    if (serviceType.value == ServicesType.extensions) {
      final activeService = activeOrLoggedInOnlineService;
      if (activeService != null) {
        return activeService.profileData;
      }
      return Profile(name: 'Guest').obs;
    }
    return onlineService.profileData;
  }

  RxList<TrackedMedia> get animeList {
    final addon = activeAddonService;
    if (addon != null) return addon.animeList;
    return onlineService.animeList;
  }

  RxList<TrackedMedia> get mangaList {
    final addon = activeAddonService;
    if (addon != null) return addon.mangaList;
    return onlineService.mangaList;
  }

  Rx<TrackedMedia> get currentMedia {
    final addon = activeAddonService;
    if (addon != null) return addon.currentMedia;
    return onlineService.currentMedia;
  }

  RxBool get isLoggedIn {
    final addon = activeAddonService;
    if (addon != null) return addon.isLoggedIn;
    if (serviceType.value == ServicesType.extensions) {
      return (activeOrLoggedInOnlineService != null).obs;
    }
    return onlineService.isLoggedIn;
  }

  // Online Services Method
  Future<void> login(BuildContext context) {
    final addon = activeAddonService;
    if (addon != null) return addon.login(context);
    return onlineService.login(context);
  }

  Future<void> logout() {
    final addon = activeAddonService;
    if (addon != null) {
      activeAddonId.value = null;
      return addon.logout();
    }
    return onlineService.logout();
  }

  Future<void> autoLogin() async {
    // Also auto-login addon services (if manager is available)
    List<Future<void>> addonFutures = [];
    try {
      addonFutures = addonManager.allServices
          .where((s) => s.hasToken)
          .map((s) => s.autoLogin())
          .toList();
    } catch (_) {
      // TrackerAddonManager not yet registered — skip
    }
    await Future.wait([
      ...addonFutures,
      malService.autoLogin(),
      anilistService.autoLogin(),
      simklService.autoLogin(),
    ]);
  }
  @override
  Future<void> refresh() => onlineService.refresh();

  Future<void> updateListEntry(
    UpdateListEntryParams params,
  ) async {
    final addon = activeAddonService;
    if (addon != null && addon.isLoggedIn.value) {
      return addon.updateListEntry(params);
    }
    return await onlineService.updateListEntry(params);
  }

  RxList<Widget> animeWidgets(BuildContext context) =>
      service.animeWidgets(context);
  RxList<Widget> mangaWidgets(BuildContext context) =>
      service.mangaWidgets(context);
  RxList<Widget> homeWidgets(BuildContext context) =>
      service.homeWidgets(context);

  RxList<Widget> novelWidgets(BuildContext context) =>
      service.novelWidgets(context);

  Source? getSourceForMedia(Media media) {
    if (media.serviceType == ServicesType.extensions) {
      return extensionService.installedNovelExtensions.firstWhere(
        (source) => source.name == media.sourceName,
        orElse: () => extensionService.installedNovelExtensions.first,
      );
    }
    return null;
  }

  @override
  void onReady() {
    super.onReady();
    fetchHomePage();
    autoLogin();
  }

  Future<void> fetchHomePage() => service.fetchHomePage();

  Future<Media> fetchDetails(FetchDetailsParams params) async {
    try {
      if (serviceType.value == ServicesType.extensions) {
        return service.fetchDetails(params);
      }
      Media? data = cacheController.getCacheById(params.id);
      return data ?? service.fetchDetails(params);
    } catch (e) {
      Logger.i("Cache Error => $e");
      return service.fetchDetails(params);
    }
  }

  Future<List<Media>?> search(SearchParams params) async =>
      service.search(params);

  void clearState() => service.clearState();

  void changeService(ServicesType type) {
    activeAddonId.value = null; // Deactivate any addon
    ServiceKeys.serviceType.set(type.index);
    serviceType.value = type;
    if (!service.isDataLoaded) {
      fetchHomePage();
    }
  }

  /// Switch to an add-on tracker as the active tracking service.
  /// The content browsing remains on the current ServicesType,
  /// but tracking operations (update progress, list) go through the addon.
  void changeToAddonTracker(String addonId) {
    if (!addonManager.hasService(addonId)) {
      Logger.w('Cannot switch to unknown addon: $addonId');
      return;
    }
    activeAddonId.value = addonId;
    KvHelper.set('activeAddonServiceId', addonId);
    Logger.i('Switched tracking to addon: $addonId');
  }

  /// Remove the addon tracker and go back to built-in tracking.
  void clearAddonTracker() {
    activeAddonId.value = null;
    KvHelper.remove('activeAddonServiceId');
  }

  @override
  void onInit() {
    super.onInit();
    serviceType.value =
        ServicesType.values[ServiceKeys.serviceType.get<int>(0)];
    // Restore active addon from storage
    final savedAddon = KvHelper.get<String>('activeAddonServiceId');
    if (savedAddon != null && savedAddon.isNotEmpty) {
      activeAddonId.value = savedAddon;
    }
  }
}
