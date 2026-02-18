import 'dart:convert';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:anymex/database/data_keys/keys.dart';

/// Cache for recommendations to avoid repeated fetches
class RecommendationsCache {
  static final Map<String, List<Media>> _cache = {};
  static final Map<String, int> _pageCache = {};
  
  static List<Media>? get(String key, int page) {
    final cacheKey = '$key:$page';
    return _cache[cacheKey];
  }
  
  static void set(String key, int page, List<Media> recommendations) {
    final cacheKey = '$key:$page';
    _cache[cacheKey] = recommendations;
    _pageCache[key] = page;
  }
  
  static int getCurrentPage(String key) {
    return _pageCache[key] ?? 1;
  }
  
  static void clear() {
    _cache.clear();
    _pageCache.clear();
  }
}

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

/// Fetches AI anime recommendations
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

  // Check cache first
  final cacheKey = '${isAL ? 'AL' : 'MAL'}_${isManga ? 'manga' : 'anime'}_$isAdult';
  final cached = RecommendationsCache.get(cacheKey, page);
  if (cached != null) {
    Logger.i('Returning cached recommendations for page $page');
    return cached;
  }

  // Build set of already-tracked IDs
  final Set<String> trackedIds = _buildTrackedIdSet(service, isAL);

  List<Media> results = [];

  if (isManga) {
    // For manga, use native recommendations only
    results = await _fetchNativeRecommendations(
      isManga: true,
      isAL: isAL,
      page: page,
      isAdult: isAdult,
      service: service,
    );
  } else {
    // For anime: fetch from both sources
    final futures = await Future.wait([
      _fetchAnimeSproutRecommendations(
        userName: userName,
        isAL: isAL,
        options: options,
        trackedIds: trackedIds,
        service: service,
      ),
      _fetchNativeRecommendations(
        isManga: false,
        isAL: isAL,
        page: page,
        isAdult: isAdult,
        service: service,
      ),
    ]);

    final sproutRecs = futures[0];
    final nativeRecs = futures[1];

    // Merge results
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

  // Remove items already in user's list
  results = results
      .where((m) => m.id != null && !trackedIds.contains(m.id!))
      .toList();

  // Cache the results
  RecommendationsCache.set(cacheKey, page, results);

  if (results.isEmpty && page == 1) {
    snackBar('No recommendations found');
  }

  return results;
}

/// Build tracked IDs from existing data (no API calls)
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

/// Fetch from AnimeSprout
Future<List<Media>> _fetchAnimeSproutRecommendations({
  required String userName,
  required bool isAL,
  required AnimeSproutOptions options,
  required Set<String> trackedIds,
  required ServiceHandler service,
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

    // Parse response
    final body = response.body;
    final jsonStart = body.indexOf('"initialRecommendations"');
    if (jsonStart == -1) return [];

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

      // Skip plan-to-watch
      if (rec['planToWatch'] == true) continue;

      final title = (data['alternative_titles'] as Map?)?['en'] as String?;
      final titleFallback = data['title'] as String?;
      final picture = (data['main_picture'] as Map?)?['large'] as String?;
      final synopsis = data['synopsis'] as String?;
      final genres = (data['genres'] as List?)
          ?.map((g) => (g['name'] as String).toUpperCase())
          .toList();

      // Get or create ID
      String? resolvedId = malId;
      if (isAL) {
        // Check if we already have this MAL ID in user's list
        final existing = service.anilistService.animeList.firstWhereOrNull(
          (m) => m.id == malId || m.id == _malIdToAnilistIdSync(malId)
        );
        resolvedId = existing?.id ?? malId;
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

/// Quick sync MAL to AL ID conversion using existing data
String? _malIdToAnilistIdSync(String malId) {
  // This is a placeholder - you might want to maintain a mapping cache
  return null;
}

/// Fetch native recommendations using existing user data where possible
Future<List<Media>> _fetchNativeRecommendations({
  required bool isManga,
  required bool isAL,
  required int page,
  required bool isAdult,
  required ServiceHandler service,
}) async {
  if (isAL) {
    return _fetchAnilistRecommendationsOptimized(
      isManga: isManga,
      page: page,
      isAdult: isAdult,
      service: service,
    );
  } else {
    return _fetchMalRecommendationsOptimized(
      isManga: isManga,
      page: page,
      isAdult: isAdult,
      service: service,
    );
  }
}

/// Optimized AniList recommendations using existing data
Future<List<Media>> _fetchAnilistRecommendationsOptimized({
  required bool isManga,
  required int page,
  required bool isAdult,
  required ServiceHandler service,
}) async {
  try {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return [];

    // Use the user's existing list to find recommendations
    final userList = isManga ? service.anilistService.mangaList : service.anilistService.animeList;
    
    // Get IDs of items in user's list
    final userItemIds = userList.map((e) => e.id).whereType<String>().toSet();
    
    if (userItemIds.isEmpty) return [];

    // Take a subset for the query (API limits)
    const maxIds = 10;
    final sampleIds = userItemIds.take(maxIds).toList();

    final query = '''
    query(\$ids: [Int], \$page: Int, \$type: MediaType, \$isAdult: Boolean) {
      Page(page: \$page, perPage: 30) {
        media(
          id_in: \$ids,
          type: \$type,
          isAdult: \$isAdult
        ) {
          id
          title { romaji english }
          coverImage { large }
          description
          genres
          recommendations(page: 1, perPage: 5, sort: RATING_DESC) {
            nodes {
              mediaRecommendation {
                id
                title { romaji english }
                coverImage { large }
                description
                genres
              }
            }
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
          'ids': sampleIds.map((id) => int.tryParse(id)).whereType<int>().toList(),
          'page': page,
          'type': isManga ? 'MANGA' : 'ANIME',
          'isAdult': isAdult,
        },
      }),
    );

    if (response.statusCode != 200) {
      Logger.i('AniList recommendations failed: ${response.statusCode}');
      return [];
    }

    final data = jsonDecode(response.body);
    final mediaList = data['data']?['Page']?['media'] as List<dynamic>?;
    if (mediaList == null) return [];

    final results = <Media>[];
    final seenIds = <String>{};

    for (final media in mediaList) {
      final recs = media['recommendations']?['nodes'] as List<dynamic>?;
      if (recs == null) continue;

      for (final rec in recs) {
        final recMedia = rec['mediaRecommendation'] as Map<String, dynamic>?;
        if (recMedia == null) continue;

        final id = recMedia['id']?.toString();
        if (id == null || seenIds.contains(id) || userItemIds.contains(id)) continue;

        seenIds.add(id);

        final titleMap = recMedia['title'] as Map?;
        final title = (titleMap?['english'] as String?)?.isNotEmpty == true
            ? titleMap!['english'] as String
            : titleMap?['romaji'] as String? ?? 'Unknown';

        results.add(Media(
          id: id,
          title: title,
          poster: (recMedia['coverImage'] as Map?)?['large'] as String? ?? '',
          description: recMedia['description'] as String? ?? '',
          serviceType: ServicesType.anilist,
          genres: ((recMedia['genres'] as List?) ?? [])
              .map((g) => g.toString().toUpperCase())
              .toList(),
        ));
      }
    }

    return results;
  } catch (e) {
    Logger.i('AniList recommendations error: $e');
    return [];
  }
}

/// Optimized MAL recommendations
Future<List<Media>> _fetchMalRecommendationsOptimized({
  required bool isManga,
  required int page,
  required bool isAdult,
  required ServiceHandler service,
}) async {
  try {
    final type = isManga ? 'manga' : 'anime';
    
    // Use Jikan API with pagination that actually works
    final url = 'https://api.jikan.moe/v4/recommendations/$type';
    
    // Jikan pagination is offset-based, not page-based
    final response = await http.get(Uri.parse('$url?page=$page&limit=25'));
    
    if (response.statusCode != 200) {
      Logger.i('Jikan recommendations failed: ${response.statusCode}');
      return [];
    }

    final data = jsonDecode(response.body);
    final recs = data['data'] as List<dynamic>?;
    if (recs == null) return [];

    final userItemIds = (isManga ? service.malService.mangaList : service.malService.animeList)
        .map((e) => e.id)
        .whereType<String>()
        .toSet();

    final results = <Media>[];
    final seen = <String>{};

    for (final rec in recs) {
      final entries = rec['entry'] as List<dynamic>?;
      if (entries == null) continue;

      for (final entry in entries) {
        final malId = entry['mal_id']?.toString();
        if (malId == null || !seen.add(malId) || userItemIds.contains(malId)) continue;

        final title = entry['title'] as String? ?? 'Unknown';
        final imageUrl = (entry['images'] as Map?)?['jpg']?['large_image_url'] as String?;
        
        // Fetch additional details for description if needed
        String description = '';
        try {
          final detailsUrl = 'https://api.jikan.moe/v4/$type/$malId';
          final detailsResponse = await http.get(Uri.parse(detailsUrl));
          if (detailsResponse.statusCode == 200) {
            final detailsData = jsonDecode(detailsResponse.body);
            description = detailsData['data']?['synopsis'] as String? ?? '';
          }
        } catch (e) {
          // Ignore details fetch errors
        }

        results.add(Media(
          id: malId,
          title: title,
          poster: imageUrl ?? '',
          description: description,
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
