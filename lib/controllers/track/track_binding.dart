import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/tracker_addon/tracker_registry.dart';
import 'package:get/get.dart';

class TrackBinding {
  /// For built-in trackers: uses the Tracker enum index.
  /// For addon trackers: uses the addon index from TrackerRegistry (>= 100).
  final int trackerId;

  /// String ID of the tracker (e.g., 'anilist', 'kitsu', 'bangumi').
  /// For addon trackers, this is the manifest ID.
  final String? addonTrackerId;

  final String remoteId;

  final String title;
  final String? poster;
  final String? totalEpisodes;

  String status;

  double? score;

  int progress;

  final bool isAnime;
  bool private;

  TrackBinding({
    required this.trackerId,
    this.addonTrackerId,
    required this.remoteId,
    required this.title,
    this.poster,
    this.totalEpisodes,
    this.status = 'CURRENT',
    this.score,
    this.progress = 0,
    required this.isAnime,
    this.private = false,
  });

  /// Whether this binding is for an addon tracker.
  bool get isAddon => addonTrackerId != null && addonTrackerId!.isNotEmpty;

  /// Get the Tracker enum value (only valid for built-in trackers).
  Tracker get tracker {
    if (isAddon) {
      // Addon trackers don't have a Tracker enum value.
      // Return anilist as safe fallback (won't be used for addon logic).
      return Tracker.anilist;
    }
    if (trackerId < Tracker.values.length) {
      return Tracker.values[trackerId];
    }
    return Tracker.anilist;
  }

  /// Get the display name of the tracker this binding belongs to.
  String get trackerName {
    if (isAddon) {
      try {
        if (Get.isRegistered<TrackerRegistry>()) {
          return Get.find<TrackerRegistry>().getTrackerName(addonTrackerId!);
        }
      } catch (_) {}
      return addonTrackerId!;
    }
    return tracker.label;
  }

  /// Get the color of the tracker (hex string).
  String get trackerColor {
    if (isAddon) {
      try {
        if (Get.isRegistered<TrackerRegistry>()) {
          return Get.find<TrackerRegistry>().getTrackerColor(addonTrackerId!);
        }
      } catch (_) {}
      return '#666666';
    }
    return '#${tracker.color.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  Map<String, dynamic> toJson() => {
        'trackerId': trackerId,
        if (addonTrackerId != null) 'addonTrackerId': addonTrackerId,
        'remoteId': remoteId,
        'title': title,
        'poster': poster,
        'totalEpisodes': totalEpisodes,
        'status': status,
        'score': score,
        'progress': progress,
        'isAnime': isAnime,
        'private': private,
      };

  factory TrackBinding.fromJson(Map<String, dynamic> json) {
    return TrackBinding(
      trackerId: (json['trackerId'] as num?)?.toInt() ?? 0,
      addonTrackerId: json['addonTrackerId'] as String?,
      remoteId: json['remoteId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      poster: json['poster']?.toString(),
      totalEpisodes: json['totalEpisodes']?.toString(),
      status: json['status']?.toString() ?? 'CURRENT',
      score: (json['score'] as num?)?.toDouble(),
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      isAnime: json['isAnime'] as bool? ?? true,
      private: json['private'] as bool? ?? false,
    );
  }

  /// Create a TrackBinding for an addon tracker.
  factory TrackBinding.forAddon({
    required String addonId,
    required int trackerIndex,
    required String remoteId,
    required String title,
    String? poster,
    String? totalEpisodes,
    String status = 'CURRENT',
    double? score,
    int progress = 0,
    required bool isAnime,
    bool private = false,
  }) {
    return TrackBinding(
      trackerId: trackerIndex,
      addonTrackerId: addonId,
      remoteId: remoteId,
      title: title,
      poster: poster,
      totalEpisodes: totalEpisodes,
      status: status,
      score: score,
      progress: progress,
      isAnime: isAnime,
      private: private,
    );
  }
}

/// Built-in tracker enum — unchanged for backward compatibility.
/// Addon trackers are identified by their `addonTrackerId` string field
/// in TrackBinding, not by this enum.
enum Tracker {
  anilist,
  mal,
  simkl;

  String get label => switch (this) {
        Tracker.anilist => 'AniList',
        Tracker.mal => 'MyAnimeList',
        Tracker.simkl => 'Simkl',
      };

  int get color => switch (this) {
        Tracker.anilist => 0xFF02A9FF,
        Tracker.mal => 0xFF2E51A2,
        Tracker.simkl => 0xFF7E57C2,
      };

  String get iconAsset => switch (this) {
        Tracker.anilist => 'assets/images/anilist-icon.png',
        Tracker.mal => 'assets/images/mal-icon.png',
        Tracker.simkl => 'assets/images/simkl-icon.png',
      };

  ServicesType get servicesType => switch (this) {
        Tracker.anilist => ServicesType.anilist,
        Tracker.mal => ServicesType.mal,
        Tracker.simkl => ServicesType.simkl,
      };
}
