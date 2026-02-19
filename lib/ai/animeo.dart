import 'dart:convert';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:anymex/database/data_keys/keys.dart';

class RecommendationCache {
  static final Map<String, List<Media>> _cache = {};
  static final Map<String, int> _pageCache = {};
  
  static List<Media>? get(String key, int page) {
    final cacheKey = '$key:$page';
    return _cache[cacheKey];
  }
  
  static void set(String key, int page, List<Media> items) {
    final cacheKey = '$key:$page';
    _cache[cacheKey] = items;
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

Future<List<Media>> getAiRecommendations(
  bool isManga,
  int page, {
  bool isAdult = false,
  String? username,
  AnimeSproutOptions options = const AnimeSproutOptions(),
  bool refresh = false,
}) async {
  final service = Get.find<ServiceHandler>();
  final isAL = service.serviceType.value == ServicesType.anilist;
  final userName =
      username?.trim() ?? service.onlineService.profileData.value.name ?? '';

  if (userName.isEmpty) {
    snackBar('Please log in to get recommendations');
    return [];
  }

  final cacheKey = '${isManga ? 'manga' : 'anime'}:$userName:${isAL ? 'al' : 'mal'}:${isAdult ? 'adult' : 'sfw'}';
  
  if (!refresh) {
    final cached = RecommendationCache.get(cacheKey, page);
    if (cached != null) {
      return cached;
    }
  }

  final trackedIds = _buildTrackedIdSet(service, isAL);

  List<Media> results = [];

  final futures = await Future.wait([
    _fetchAnimeSproutRecommendations(
      userName: userName,
      isAL: isAL,
      options: options,
      trackedIds: trackedIds,
      isAdult: isAdult,
    ),
    _fetchNativeRecommendations(
      isManga: isManga,
      isAL: isAL,
      page: page,
      isAdult: isAdult,
    ),
  ], eagerError: false);

  final sproutRecs = futures[0] as List<Media>;
  final nativeRecs = futures[1] as List<Media>;

  final Map<String, Media> uniqueMap = {};

  for (final media in sproutRecs) {
    if (media.id != null && !trackedIds.contains(media.id)) {
      uniqueMap[media.id!] = media;
    }
  }

  for (final media in nativeRecs) {
    if (media.id != null && !trackedIds.contains(media.id)) {
      bool isDuplicate = false;
      for (final existingId in uniqueMap.keys) {
        if (existingId == media.id) {
          isDuplicate = true;
          break;
        }
        if (isAL && media.malId != null) {
          final existingMedia = uniqueMap[existingId];
          if (existingMedia?.malId == media.malId) {
            isDuplicate = true;
            break;
          }
        }
      }
      
      if (!isDuplicate) {
        uniqueMap[media.id!] = media;
      }
    }
  }

  results = uniqueMap.values.toList();

  const int pageSize = 30;
  final startIndex = (page - 1) * pageSize;
  if (startIndex < results.length) {
    final endIndex = (startIndex + pageSize).clamp(0, results.length);
    results = results.sublist(startIndex, endIndex);
  } else {
    results = [];
  }

  if (results.isEmpty && page == 1) {
    snackBar('No recommendations found');
  }

  RecommendationCache.set(cacheKey, page, results);
  return results;
}

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

Future<List<Media>> _fetchAnimeSproutRecommendations({
  required String userName,
  required bool isAL,
  required AnimeSproutOptions options,
  required Set<String> trackedIds,
  required bool isAdult,
}) async {
  try {
    final source = isAL ? 'anilist' : null;
    final params = options.toQueryParams(source: source);
    
    final uri = Uri.https(
      'anime.ameo.dev',
      '/user/$userName/recommendations',
      params,
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      Logger.i('AnimeSprout failed: ${response.statusCode}');
      return [];
    }

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
    int processed = 0;

    for (final rec in recommendations) {
      if (processed >= 50) break;

      final malId = rec['id']?.toString();
      if (malId == null) continue;

      final data = animeData[malId] as Map<String, dynamic>?;
      if (data == null) continue;

      if (rec['planToWatch'] == true) continue;

      if (!isAdult) {
        final nsfw = data['nsfw'] == true || 
                     (data['genres'] as List?)?.any((g) => 
                       ['HENTAI', 'EROTICA'].contains(g['name']?.toUpperCase())) == true;
        if (nsfw) continue;
      }

      final title = (data['alternative_titles'] as Map?)?['en'] as String?;
      final titleFallback = data['title'] as String?;
      final picture = (data['main_picture'] as Map?)?['large'] as String?;
      final synopsis = data['synopsis'] as String?;
      final genres = (data['genres'] as List?)
          ?.map((g) => (g['name'] as String).toUpperCase())
          .toList();

      String? resolvedId;
      int? parsedMalId;
      if (isAL) {
        resolvedId = await _getAnilistIdFromMal(malId);
        parsedMalId = int.tryParse(malId);
      } else {
        resolvedId = malId;
        parsedMalId = int.tryParse(malId);
      }

      if (trackedIds.contains(resolvedId)) continue;

      results.add(Media(
        id: resolvedId,
        malId: parsedMalId,
        title: (title?.isNotEmpty == true ? title : titleFallback) ?? 'Unknown',
        poster: picture ?? '',
        description: synopsis ?? '',
        serviceType: isAL ? ServicesType.anilist : ServicesType.mal,
        genres: genres ?? [],
      ));
      
      processed++;
    }

    return results;
  } catch (e) {
    Logger.i('AnimeSprout fetch error: $e');
    return [];
  }
}

final Map<String, String> _malToAnilistCache = {};

Future<String?> _getAnilistIdFromMal(String malId) async {
  if (_malToAnilistCache.containsKey(malId)) {
    return _malToAnilistCache[malId];
  }

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
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final id = data['data']?['Media']?['id']?.toString();
      if (id != null) {
        _malToAnilistCache[malId] = id;
        return id;
      }
    }
  } catch (e) {
    Logger.i('MAL->AL conversion error for $malId: $e');
  }
  return null;
}

Future<List<Media>> _fetchNativeRecommendations({
  required bool isManga,
  required bool isAL,
  required int page,
  required bool isAdult,
}) async {
  if (isAL) {
    return _fetchAnilistRecommendations(
      isManga: isManga, 
      page: page,
      isAdult: isAdult,
    );
  } else {
    return _fetchMalRecommendations(
      isManga: isManga, 
      page: page,
      isAdult: isAdult,
    );
  }
}

Future<List<Media>> _fetchAnilistRecommendations({
  required bool isManga,
  required int page,
  required bool isAdult,
}) async {
  try {
    final token = AuthKeys.authToken.get<String?>();
    if (token == null) return [];

    final query = '''
    query(\$page: Int, \$type: MediaType) {
      Page(page: \$page, perPage: 50) {
        recommendations(sort: RATING_DESC) {
          mediaRecommendation {
            id
            idMal
            title {
              romaji
              english
              native
            }
            coverImage {
              large
              color
            }
            description
            genres
            type
            isAdult
            averageScore
            format
            status
            episodes
            chapters
            volumes
          }
        }
      }
    }
    ''';

    Logger.i('Fetching AniList recommendations for page $page, type: ${isManga ? "MANGA" : "ANIME"}');

    final response = await http.post(
      Uri.parse('https://graphql.anilist.co'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'query': query,
        'variables': {
          'page': page,
          'type': isManga ? 'MANGA' : 'ANIME',
        },
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      Logger.i('AniList recommendations failed: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 429) {
        await Future.delayed(const Duration(seconds: 2));
        return _fetchAnilistRecommendations(
          isManga: isManga, 
          page: page, 
          isAdult: isAdult
        );
      }
      return [];
    }

    final data = jsonDecode(response.body);
    final recs = data['data']?['Page']?['recommendations'] as List<dynamic>?;
    if (recs == null || recs.isEmpty) {
      Logger.i('No recommendations found in response');
      return [];
    }

    final results = <Media>[];
    final seenIds = <String>{};

    for (final rec in recs) {
      final media = rec['mediaRecommendation'] as Map<String, dynamic>?;
      if (media == null) continue;

      if (!isAdult && media['isAdult'] == true) continue;

      final id = media['id']?.toString();
      if (id == null || !seenIds.add(id)) continue;

      final titleMap = media['title'] as Map?;
      String title = 'Unknown';
      if (titleMap != null) {
        title = titleMap['english'] ?? titleMap['romaji'] ?? titleMap['native'] ?? 'Unknown';
      }

      final genres = (media['genres'] as List?)
          ?.map((g) => g.toString().toUpperCase())
          .where((g) => g.isNotEmpty)
          .toList() ?? [];

      final coverImage = media['coverImage'] as Map?;
      final poster = coverImage?['large'] as String? ?? '';

      results.add(Media(
        id: id,
        malId: media['idMal'] as int?,
        title: title,
        poster: poster,
        description: media['description'] as String? ?? '',
        serviceType: ServicesType.anilist,
        genres: genres,
        averageScore: media['averageScore']?.toString(),
        format: media['format']?.toString(),
        totalEpisodes: media['episodes']?.toString(),
        totalChapters: media['chapters']?.toString(),
        status: media['status']?.toString(),
      ));
    }

    Logger.i('Fetched ${results.length} AniList recommendations');
    return results;
  } catch (e) {
    Logger.i('AniList recommendations error: $e');
    return [];
  }
}

Future<List<Media>> _fetchMalRecommendations({
  required bool isManga,
  required int page,
  required bool isAdult,
}) async {
  try {
    final type = isManga ? 'manga' : 'anime';
    final url = 'https://api.jikan.moe/v4/recommendations/$type?page=$page';

    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
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
      final entries = rec['entry'] as List<dynamic>?;
      if (entries == null) continue;

      for (final entry in entries) {
        final malId = entry['mal_id']?.toString();
        if (malId == null || !seen.add(malId)) continue;

        if (!isAdult) {
          final genres = entry['genres'] as List? ?? [];
          final isNsfw = genres.any((g) => 
            ['Hentai', 'Erotica'].contains(g['name']));
          if (isNsfw) continue;
        }

        final title = entry['title'] as String? ?? 'Unknown';
        final imageUrl = (entry['images'] as Map?)?['jpg']?['large_image_url'] as String?;
        final synopsis = entry['synopsis'] as String?;

        results.add(Media(
          id: malId,
          malId: int.tryParse(malId),
          title: title,
          poster: imageUrl ?? '',
          description: synopsis ?? '',
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
