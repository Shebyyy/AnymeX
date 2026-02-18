import 'dart:convert';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:anymex/database/data_keys/keys.dart';

/// Options for AnimeSprout recommendations
class AnimeSproutOptions {
  final bool extraSeasons;
  final bool movies;
  final bool specials;
  final bool music;

  const AnimeSproutOptions({
    this.extraSeasons = true,
    this.movies = true,
    this.specials = true,
    this.music = false,
  });

  Map<String, String> toQueryParams({String? source}) {
    return {
      if (source != null) 'source': source,
      if (extraSeasons) 'exs': 'true',
      if (specials) 'specials': 'true',
      if (movies) 'movies': 'true',
      if (music) 'music': 'true',
    };
  }
}

/// Fetches AI anime recommendations combining AnimeSprout + native AL/MAL recommendations.
/// Only works for anime (AnimeSprout is anime-only).
/// For manga, falls back to native service recommendations only.
Future<List<Media>> getAiRecommendations(
  bool isManga,
  int page, {
  bool isAdult = false,
  String? username,
  AnimeSproutOptions options = const AnimeSproutOptions(),
}) async {
  final service = Get.find<ServiceHandler>();
  final isAL = service.serviceType.value == ServicesType.anilist;
  final userName =
      username?.trim() ?? service.onlineService.profileData.value.name ?? '';

  if (userName.isEmpty) {
    snackBar('Please log in to get recommendations');
    return [];
  }

  // Build set of already-tracked IDs to exclude from recommendations
  final Set<String> trackedIds = _buildTrackedIdSet(service, isAL);

  List<Media> results = [];

  if (isManga) {
    // AnimeSprout is anime-only; use native service recs for manga
    results = await _fetchNativeRecommendations(
      isManga: true,
      isAL: isAL,
      page: page,
      isAdult: isAdult,
    );
  } else {
    // Anime: fetch from both AnimeSprout and native recs, then merge & dedupe
    final futures = await Future.wait([
      _fetchAnimeSproutRecommendations(
        userName: userName,
        isAL: isAL,
        options: options,
        trackedIds: trackedIds,
      ),
      _fetchNativeRecommendations(
        isManga: false,
        isAL: isAL,
        page: page,
        isAdult: isAdult,
      ),
    ]);

    final sproutRecs = futures[0];
    final nativeRecs = futures[1];

    // Merge: sprout first, then native recs not already in sprout results
    final seenIds = <String>{};
    for (final m in sproutRecs) {
      if (m.id != null && seenIds.add(m.id!)) {
        results.add(m);
      }
    }
    for (final m in nativeRecs) {
      if (m.id != null && seenIds.add(m.id!)) {
        results.add(m);
      }
    }
  }

  // Remove items already in user's list (watched, reading, plan-to-watch, etc.)
  results = results
      .where((m) => m.id != null && !trackedIds.contains(m.id!))
      .toList();

  // Dedupe by id
  final seen = <String>{};
  results = results.where((m) => m.id != null && seen.add(m.id!)).toList();

  if (results.isEmpty) {
    snackBar('No recommendations found');
  }

  return results;
}

/// Build a set of all tracked media IDs (any status) so we can exclude them.
Set<String> _buildTrackedIdSet(ServiceHandler service, bool isAL) {
  final ids = <String>{};
  try {
    if (isAL) {
      for (final m in service.anilistService.animeList) {
        if (m.id != null) ids.add(m.id!);
      }
      for (final m in service.anilistService.mangaList) {
        if (m.id != null) ids.add(m.id!);
      }
    } else {
      for (final m in service.malService.animeList) {
        if (m.id != null) ids.add(m.id!);
      }
      for (final m in service.malService.mangaList) {
        if (m.id != null) ids.add(m.id!);
      }
    }
  } catch (e) {
    Logger.i('Error building tracked IDs: $e');
  }
  return ids;
}

/// Fetch recommendations from AnimeSprout (anime only).
/// AnimeSprout returns MAL IDs; if user is on AniList we need to convert via
/// AniList's GraphQL (idMal field).
Future<List<Media>> _fetchAnimeSproutRecommendations({
  required String userName,
  required bool isAL,
  required AnimeSproutOptions options,
  required Set<String> trackedIds,
}) async {
  try {
    final source = isAL ? 'anilist' : null;
    final params = options.toQueryParams(source: source);
    final uri = Uri.https(
      'anime.ameo.dev',
      '/user/$userName/recommendations',
      params,
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      Logger.i('AnimeSprout failed: ${response.statusCode}');
      return [];
    }

    // Parse the embedded JSON props from the HTML response
    final body = response.body;
    final jsonStart = body.indexOf('"initialRecommendations"');
    if (jsonStart == -1) return [];

    // Extract just the JSON script tag content
    final scriptStart = body.lastIndexOf('<script', jsonStart);
    final scriptEnd = body.indexOf('</script>', jsonStart);
    if (scriptStart == -1 || scriptEnd == -1) return [];

    final scriptContent = body.substring(scriptStart, scriptEnd);
    final jsonTagStart = scriptContent.indexOf('{');
    if (jsonTagStart == -1) return [];

    final jsonStr = scriptContent.substring(jsonTagStart);
    final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;

    final initialRecs = jsonData['initialRecommendations'] as Map<String, dynamic>?;
    if (initialRecs == null || initialRecs['type'] != 'ok') return [];

    final recommendations = initialRecs['recommendations'] as List<dynamic>;
    final animeData = initialRecs['animeData'] as Map<String, dynamic>;

    final List<Media> results = [];

    for (final rec in recommendations) {
      final malId = rec['id']?.toString();
      if (malId == null) continue;

      final data = animeData[malId] as Map<String, dynamic>?;
      if (data == null) continue;

      // Skip plan-to-watch items (already tracked)
      if (rec['planToWatch'] == true) continue;

      final title = (data['alternative_titles'] as Map?)?['en'] as String?;
      final titleFallback = data['title'] as String?;
      final picture = (data['main_picture'] as Map?)?['large'] as String?;
      final synopsis = data['synopsis'] as String?;
      final genres = (data['genres'] as List?)
          ?.map((g) => (g['name'] as String).toUpperCase())
          .toList();

      // Resolve the actual service ID
      String? resolvedId;
      if (isAL) {
        // Convert MAL ID -> AniList ID
        resolvedId = await _malIdToAnilistId(malId);
        resolvedId ??= malId; // fallback to MAL id if conversion fails
      } else {
        resolvedId = malId;
      }

      if (trackedIds.contains(resolvedId)) continue;

      results.add(Media(
        id: resolvedId,
        title: (title?.isNotEmpty == true ? title : titleFallback) ?? 'Unknown',
        poster: picture ?? '',
        description: synopsis ?? '',
        serviceType: isAL ? ServicesType.anilist : ServicesType.mal,
        genres: genres ?? [],
      ));
    }

    return results;
  } catch (e) {
    Logger.i('AnimeSprout fetch error: $e');
    return [];
  }
}

/// Convert a MAL ID to an AniList ID using AniList's GraphQL.
Future<String?> _malIdToAnilistId(String malId) async {
  try {
    final token = AuthKeys.authToken.get<String?>();
    final query = '''
    query(\$idMal: Int) {
      Media(idMal: \$idMal, type: ANIME) {
        id
      }
    }
    ''';

    final response = await http.post(
      Uri.parse('https://graphql.anilist.co'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'query': query,
        'variables': {'idMal': int.tryParse(malId)},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final id = data['data']?['Media']?['id'];
      return id?.toString();
    }
  } catch (e) {
    Logger.i('MAL->AL ID conversion error for $malId: $e');
  }
  return null;
}

/// Fetch native recommendations from AniList GraphQL or MAL/Jikan API.
Future<List<Media>> _fetchNativeRecommendations({
  required bool isManga,
  required bool isAL,
  required int page,
  required bool isAdult,
}) async {
  if (isAL) {
    return _fetchAnilistRecommendations(isManga: isManga, page: page);
  } else {
    return _fetchMalRecommendations(isManga: isManga, page: page);
  }
}

/// Fetch recommendations from AniList using the Recommendations query.
/// Gets recommendations for media in the user's list, sorted by rating.
Future<List<Media>> _fetchAnilistRecommendations({
  required bool isManga,
  required int page,
}) async {
  try {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return [];

    final query = '''
    query(\$page: Int, \$type: MediaType) {
      Page(page: \$page, perPage: 30) {
        recommendations(sort: RATING_DESC, onList: true) {
          rating
          mediaRecommendation {
            id
            title { romaji english }
            coverImage { large }
            description
            genres
            type
            mediaListEntry { status }
          }
        }
      }
    }
    ''';

    final response = await http.post(
      Uri.parse('https://graphql.anilist.co'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'query': query,
        'variables': {
          'page': page,
          'type': isManga ? 'MANGA' : 'ANIME',
        },
      }),
    );

    if (response.statusCode != 200) {
      Logger.i('AniList recommendations failed: ${response.statusCode}');
      return [];
    }

    final data = jsonDecode(response.body);
    final recs = data['data']?['Page']?['recommendations'] as List<dynamic>?;
    if (recs == null) return [];

    final results = <Media>[];
    for (final rec in recs) {
      final media = rec['mediaRecommendation'] as Map<String, dynamic>?;
      if (media == null) continue;

      // Skip if already in user's list
      if (media['mediaListEntry'] != null) continue;

      final id = media['id']?.toString();
      if (id == null) continue;

      final titleMap = media['title'] as Map?;
      final title = (titleMap?['english'] as String?)?.isNotEmpty == true
          ? titleMap!['english'] as String
          : titleMap?['romaji'] as String? ?? 'Unknown';

      results.add(Media(
        id: id,
        title: title,
        poster: (media['coverImage'] as Map?)?['large'] as String? ?? '',
        description: media['description'] as String? ?? '',
        serviceType: ServicesType.anilist,
        genres: ((media['genres'] as List?) ?? [])
            .map((g) => g.toString().toUpperCase())
            .toList(),
      ));
    }

    return results;
  } catch (e) {
    Logger.i('AniList recommendations error: $e');
    return [];
  }
}

/// Fetch recommendations from Jikan (MAL) recent recommendations endpoint.
Future<List<Media>> _fetchMalRecommendations({
  required bool isManga,
  required int page,
}) async {
  try {
    final type = isManga ? 'manga' : 'anime';
    final url =
        'https://api.jikan.moe/v4/recommendations/$type?page=$page';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      Logger.i('Jikan recommendations failed: ${response.statusCode}');
      return [];
    }

    final data = jsonDecode(response.body);
    final recs = data['data'] as List<dynamic>?;
    if (recs == null) return [];

    final results = <Media>[];
    final seen = <String>{};

    for (final rec in recs) {
      // Each rec has an 'entry' list of 2 related anime
      final entries = rec['entry'] as List<dynamic>?;
      if (entries == null) continue;

      for (final entry in entries) {
        final malId = entry['mal_id']?.toString();
        if (malId == null || !seen.add(malId)) continue;

        final title = entry['title'] as String? ?? 'Unknown';
        final imageUrl =
            (entry['images'] as Map?)?['jpg']?['large_image_url'] as String?;

        results.add(Media(
          id: malId,
          title: title,
          poster: imageUrl ?? '',
          serviceType: ServicesType.mal,
          genres: [],
        ));
      }
    }

    return results;
  } catch (e) {
    Logger.i('Jikan recommendations error: $e');
    return [];
  }
}
