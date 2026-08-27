import 'dart:convert';

import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/services/anilist/anilist_data.dart';
import 'package:anymex/controllers/services/mal/mal_service.dart';
import 'package:anymex/controllers/services/simkl/simkl_service.dart';
import 'package:anymex/controllers/track/track_binding.dart';
import 'package:anymex/controllers/tracker_addon/generic_tracker_service.dart';
import 'package:anymex/controllers/tracker_addon/tracker_addon_manager.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:get/get.dart';

class TrackBindingController extends GetxController {
  final Map<String, List<TrackBinding>> _cache = {};

  final RxInt bindingsVersion = 0.obs;

  List<TrackBinding> getBindingsFor(String mediaId) {
    if (_cache.containsKey(mediaId)) {
      return List.unmodifiable(_cache[mediaId]!);
    }
    final raw = DynamicKeys.trackBindings.get<String>(mediaId, '[]');
    final list = <TrackBinding>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      for (final entry in decoded) {
        if (entry is Map) {
          list.add(TrackBinding.fromJson(
              Map<String, dynamic>.from(entry)));
        }
      }
    } catch (e) {
      Logger.e('TrackBinding decode failed for $mediaId: $e');
    }
    _cache[mediaId] = list;
    return List.unmodifiable(list);
  }

  bool hasAnyBinding(String mediaId) => getBindingsFor(mediaId).isNotEmpty;

  int bindingCount(String mediaId) => getBindingsFor(mediaId).length;

  Future<void> bind(String mediaId, TrackBinding binding) async {
    final list = getBindingsFor(mediaId)
        .where((b) => b.trackerId != binding.trackerId)
        .toList();
    list.add(binding);
    _cache[mediaId] = list;
    _persist(mediaId, list);
    bindingsVersion.value++;
  }

  Future<void> unbind(String mediaId, int trackerId) async {
    final list =
        getBindingsFor(mediaId).where((b) => b.trackerId != trackerId).toList();
    _cache[mediaId] = list;
    _persist(mediaId, list);
    bindingsVersion.value++;
  }

  void _persist(String mediaId, List<TrackBinding> list) {
    DynamicKeys.trackBindings.set<String>(
      mediaId,
      jsonEncode(list.map((b) => b.toJson()).toList()),
    );
  }

  OnlineService _online(Tracker t) {
    switch (t) {
      case Tracker.anilist:
        return Get.find<AnilistData>();
      case Tracker.mal:
        return Get.find<MalService>();
      case Tracker.simkl:
        return Get.find<SimklService>();
    }
  }

  /// Get the OnlineService for an addon tracker by its ID.
  OnlineService? _onlineAddon(String addonId) {
    try {
      return Get.find<TrackerAddonManager>().getService(addonId);
    } catch (_) {
      return null;
    }
  }

  /// Get the OnlineService for any binding (built-in or addon).
  OnlineService? _serviceForBinding(TrackBinding b) {
    if (b.isAddon) {
      return _onlineAddon(b.addonTrackerId!);
    }
    return _online(b.tracker);
  }

  bool isLoggedIn(Tracker t) => _online(t).isLoggedIn.value;

  /// Check if an addon tracker is logged in.
  bool isAddonLoggedIn(String addonId) {
    final service = _onlineAddon(addonId);
    return service?.isLoggedIn.value ?? false;
  }

  List<Tracker> loggedInTrackers() =>
      Tracker.values.where(isLoggedIn).toList();

  /// Get all logged-in tracker IDs (built-in names + addon IDs).
  List<String> allLoggedInTrackerIds() {
    final ids = <String>[];
    for (final t in Tracker.values) {
      if (isLoggedIn(t)) ids.add(t.name);
    }
    try {
      for (final s in Get.find<TrackerAddonManager>().loggedInServices) {
        if (s is GenericTrackerService) {
          ids.add(s.manifest.id);
        }
      }
    } catch (_) {}
    return ids;
  }

  Future<List<Media>> searchOn(Tracker t, SearchParams params) {
    if (params.args is! bool) {
      params = SearchParams(
        query: params.query,
        isManga: params.isManga,
        filters: params.filters,
        args: false,
        page: params.page,
      );
    }
    switch (t) {
      case Tracker.anilist:
        return Get.find<AnilistData>().search(params);
      case Tracker.mal:
        return Get.find<MalService>().search(params);
      case Tracker.simkl:
        return Get.find<SimklService>().search(params);
    }
  }

  Future<List<Media>> searchOnSimkl(
    String query, {
    SimklSearchCategory category = SimklSearchCategory.anime,
    int page = 1,
  }) {
    return Get.find<SimklService>().searchByCategory(query, category, page: page);
  }

  Future<void> pushProgress(
    String mediaId,
    int progress, {
    required bool isAnime,
    String? status,
  }) async {
    final bindings = getBindingsFor(mediaId);
    if (bindings.isEmpty) return;

    await Future.wait(bindings.map((b) async {
      final service = _serviceForBinding(b);
      if (service == null || !service.isLoggedIn.value) return;
      try {
        await service.updateListEntry(UpdateListEntryParams(
          listId: b.remoteId,
          progress: progress,
          status: status ?? b.status,
          isAnime: isAnime,
        ));
        b.progress = progress;
        if (status != null) b.status = status;
      } catch (e) {
        Logger.e('Track sync failed for ${b.trackerName} ($mediaId): $e');
      }
    }));

    _persist(mediaId, bindings);
  }

  TrackBinding bindingFromSearchResult(
    Tracker tracker,
    Media result, {
    required bool isAnime,
  }) {
    final service = _online(tracker);
    final list = isAnime ? service.animeList : service.mangaList;

    TrackedMedia? existing;
    try {
      existing = list.firstWhere(
        (t) =>
            t.id == result.id ||
            t.mediaListId == result.id ||
            (result.idMal.isNotEmpty &&
                result.idMal != '0' &&
                t.idMal == result.idMal),
      );
    } catch (_) {
      existing = null;
    }

    return TrackBinding(
      trackerId: tracker.index,
      remoteId: result.id,
      title: result.title,
      poster: result.poster,
      totalEpisodes: result.totalEpisodes,
      isAnime: isAnime,
      progress: int.tryParse(existing?.episodeCount ?? '') ?? 0,
      status: (existing?.watchingStatus?.isNotEmpty ?? false)
          ? existing!.watchingStatus!
          : 'CURRENT',
      score: double.tryParse(existing?.score ?? ''),
      private: existing?.isPrivate ?? false,
    );
  }

  Future<void> updateBindingFields(
    String mediaId,
    TrackBinding binding, {
    int? progress,
    String? status,
    double? score,
    bool? isPrivate,
  }) async {
    final newProgress = progress ?? binding.progress;
    final newStatus = status ?? binding.status;
    final newScore = score ?? binding.score;
    final newPrivate = isPrivate ?? binding.private;

    final service = _serviceForBinding(binding);
    if (service != null && service.isLoggedIn.value) {
      try {
        await service.updateListEntry(UpdateListEntryParams(
          listId: binding.remoteId,
          progress: newProgress,
          status: newStatus,
          score: newScore,
          isAnime: binding.isAnime,
          isPrivate: newPrivate,
        ));
      } catch (e) {
        Logger.e(
            'Track remote update failed for ${binding.trackerName} ($mediaId): $e — keeping local update only');
      }
    }

    binding.progress = newProgress;
    binding.status = newStatus;
    binding.score = newScore;
    binding.private = newPrivate;

    final list = getBindingsFor(mediaId)
        .where((b) => b.trackerId != binding.trackerId)
        .toList();
    list.add(binding);
    _cache[mediaId] = list;
    _persist(mediaId, list);
    bindingsVersion.value++;
  }

  /// Search on an addon tracker.
  Future<List<Media>> searchOnAddon(
    String addonId,
    String query, {
    bool isManga = false,
  }) async {
    final service = _onlineAddon(addonId);
    if (service == null) return [];
    if (service is GenericTrackerService) {
      return service.search(query, isManga: isManga);
    }
    return [];
  }

  /// Create a binding from an addon tracker search result.
  TrackBinding bindingFromAddonSearchResult({
    required String addonId,
    required int trackerIndex,
    required Media result,
    required bool isAnime,
  }) {
    return TrackBinding.forAddon(
      addonId: addonId,
      trackerIndex: trackerIndex,
      remoteId: result.id,
      title: result.title,
      poster: result.poster,
      totalEpisodes: result.totalEpisodes,
      isAnime: isAnime,
      status: 'CURRENT',
      progress: 0,
    );
  }
}
