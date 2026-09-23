import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/tracker_addon/addon_manifest.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';

class AddonMapper {
  /// Extract a value using dot-notation path, e.g. "attributes.titles.en".
  /// Supports fallback paths separated by " || ", e.g. "attributes.titles.en || attributes.canonicalTitle".
  static dynamic getPath(dynamic data, String path) {
    if (data == null) return null;
    final expressions = path.split('||').map((s) => s.trim());
    for (final expr in expressions) {
      final val = _resolveSinglePath(data, expr);
      if (val != null && val.toString().trim().isNotEmpty) {
        return val;
      }
    }
    return null;
  }

  static dynamic _resolveSinglePath(dynamic current, String path) {
    if (current == null) return null;
    final segments = path.split('.');
    dynamic node = current;

    for (var segment in segments) {
      if (node == null) return null;

      // Handle array index like items[0]
      if (segment.contains('[') && segment.endsWith(']')) {
        final bracketIdx = segment.indexOf('[');
        final key = segment.substring(0, bracketIdx);
        final idxStr =
            segment.substring(bracketIdx + 1, segment.length - 1);
        final index = int.tryParse(idxStr);

        if (key.isNotEmpty) {
          if (node is Map) {
            node = node[key];
          } else {
            return null;
          }
        }
        if (node is List && index != null && index >= 0 && index < node.length) {
          node = node[index];
        } else {
          return null;
        }
      } else {
        if (node is Map) {
          node = node[segment];
        } else {
          return null;
        }
      }
    }
    return node;
  }

  /// Helper to resolve relative image URLs against add-on base URL
  static String resolveImageUrl(String url, AddonManifest manifest) {
    final clean = url.trim();
    if (clean.isEmpty) return clean;
    if (clean.startsWith('http://') || clean.startsWith('https://')) return clean;
    final base = Uri.tryParse(manifest.api.baseUrl);
    if (base != null && base.hasScheme) {
      final origin = '${base.scheme}://${base.host}';
      return clean.startsWith('/') ? '$origin$clean' : '$origin/$clean';
    }
    return clean;
  }

  /// Map a raw JSON object to AnymeX `Media` model.
  static Media mapToMedia(
    Map<String, dynamic> json,
    AddonManifest manifest, {
    bool isAnime = true,
    Map<String, String>? customMapping,
  }) {
    final mapping = customMapping ?? manifest.endpoints.details?.mapping ?? {};

    String extract(String field, [String fallback = '']) {
      final path = mapping[field] ?? field;
      final val = getPath(json, path);
      return val?.toString() ?? fallback;
    }

    List<String> extractList(String field) {
      final path = mapping[field] ?? field;
      final val = getPath(json, path);
      if (val is List) {
        return val.map((e) {
          if (e is Map) {
            return e['name']?.toString() ?? e['title']?.toString() ?? '';
          }
          return e.toString();
        }).where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    final id = extract('id', '0');
    final title = extract('title', extract('canonicalTitle', 'Unknown'));
    final romajiTitle = extract('romajiTitle', extract('englishTitle', title));
    final poster = resolveImageUrl(extract('poster', extract('image', '')), manifest);
    final largePoster = resolveImageUrl(extract('largePoster', poster), manifest);
    final coverRaw = extract('cover', extract('banner', ''));
    final cover = coverRaw.isNotEmpty ? resolveImageUrl(coverRaw, manifest) : null;
    final description = extract('description', extract('synopsis', ''));
    final totalEpisodes = extract('totalEpisodes', extract('episodeCount', '?'));
    final totalChapters = extract('totalChapters', extract('chapterCount', '?'));
    final status = extract('status', 'Unknown');
    final rating = extract('rating', extract('score', '0.0'));
    final popularity = extract('popularity', '0');
    final format = extract('format', extract('type', isAnime ? 'TV' : 'MANGA'));
    final duration = extract('duration', '');
    final season = extract('season', '');
    final premiered = extract('premiered', extract('startDate', ''));
    final aired = extract('aired', extract('aired_on', premiered));
    final genres = extractList('genres');
    final studios = extractList('studios');

    final nextEpisodeStr = extract('episode', extract('nextEpisode', ''));
    final airingAtStr = extract('airingAt', extract('airing_at', extract('next_episode_at', '')));
    NextAiringEpisode? nextAiring;
    if (airingAtStr.isNotEmpty) {
      int? airingTimestamp;
      final parsedDate = DateTime.tryParse(airingAtStr);
      if (parsedDate != null) {
        airingTimestamp = parsedDate.millisecondsSinceEpoch ~/ 1000;
      } else {
        airingTimestamp = int.tryParse(airingAtStr);
      }
      if (airingTimestamp != null) {
        final epNum = int.tryParse(nextEpisodeStr) ?? 1;
        final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        nextAiring = NextAiringEpisode(
          airingAt: airingTimestamp,
          episode: epNum,
          timeUntilAiring: airingTimestamp - nowSeconds,
        );
      }
    }

    final determinedMediaType = isAnime ? ItemType.anime : ItemType.manga;

    return Media(
      id: id,
      title: title.isEmpty ? 'Unknown' : title,
      romajiTitle: romajiTitle,
      poster: poster,
      largePoster: largePoster,
      cover: cover,
      description: description,
      totalEpisodes: totalEpisodes,
      totalChapters: totalChapters,
      status: status,
      rating: rating,
      popularity: popularity,
      format: format,
      duration: duration,
      season: season,
      premiered: premiered,
      aired: aired,
      genres: genres,
      studios: studios.isNotEmpty ? studios : null,
      mediaType: determinedMediaType,
      serviceType: ServicesType.addon,
      nextAiringEpisode: nextAiring,
    );
  }

  /// Map raw JSON to AnymeX `TrackedMedia` (for library entries).
  static TrackedMedia mapToTrackedMedia(
    Map<String, dynamic> json,
    AddonManifest manifest, {
    bool isAnime = true,
  }) {
    final mapping = manifest.endpoints.userLibrary?.mapping ?? {};

    String extract(String field, [String fallback = '']) {
      final path = mapping[field] ?? field;
      final val = getPath(json, path);
      return val?.toString() ?? fallback;
    }

    final id = extract('id', '0');
    final mediaId = extract('mediaId', id);
    final title = extract('title', 'Unknown');
    final poster = resolveImageUrl(extract('poster', extract('image', '')), manifest);
    final rawStatus = extract('status', 'current').toLowerCase().trim();
    final canonicalStatus = manifest.statusMap[rawStatus] ??
        manifest.statusMap[rawStatus.toUpperCase()] ??
        returnConvertedStatus(rawStatus);

    final progressStr =
        extract('progress', extract('episodeProgress', extract('chapterProgress', '0')));
    final totalCountStr =
        extract('totalEpisodes', extract('totalChapters', '?'));
    final scoreStr = extract('score', extract('rating', '0'));

    return TrackedMedia(
      id: mediaId,
      mediaListId: id,
      title: title,
      poster: poster,
      episodeCount: isAnime ? progressStr : '0',
      chapterCount: isAnime ? '0' : progressStr,
      userProgress: int.tryParse(progressStr) ?? 0,
      totalEpisodes: totalCountStr,
      watchingStatus: canonicalStatus,
      score: scoreStr,
      rating: scoreStr,
      type: isAnime ? 'ANIME' : 'MANGA',
      servicesType: ServicesType.addon,
    );
  }

  /// Map raw JSON to AnymeX `Profile`.
  static Profile mapToProfile(
    Map<String, dynamic> json,
    AddonManifest manifest,
  ) {
    final mapping = manifest.endpoints.userProfile?.mapping ?? {};

    String extract(String field, [String fallback = '']) {
      final path = mapping[field] ?? field;
      final val = getPath(json, path);
      return val?.toString() ?? fallback;
    }

    final id = extract('id');
    final name = extract('name', 'User');
    final avatarRaw = extract('avatar');
    final bannerRaw = extract('banner');

    final avatar = avatarRaw.isNotEmpty
        ? resolveImageUrl(avatarRaw, manifest)
        : null;
    final banner = bannerRaw.isNotEmpty
        ? resolveImageUrl(bannerRaw, manifest)
        : null;

    return Profile(
      id: id.isNotEmpty ? id : null,
      name: name,
      avatar: avatar,
      cover: banner,
    );
  }
}
