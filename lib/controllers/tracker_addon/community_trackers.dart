import 'package:anymex/controllers/tracker_addon/tracker_manifest.dart';

/// Pre-built tracker manifests for popular anime/manga trackers.
/// These are shown in the add-on store for one-tap install.
class CommunityTrackers {
  static List<TrackerManifest> get all => [
    _kitsu(),
    _shikimori(),
    _bangumi(),
    _animePlanet(),
    _annict(),
  ];

  // ── Kitsu ──────────────────────────────────────────────────────

  static TrackerManifest _kitsu() {
    return const TrackerManifest(
      id: 'kitsu',
      name: 'Kitsu',
      version: '1.0.0',
      description: 'Track anime & manga on Kitsu.io',
      color: '#FD6585',
      icon: 'https://kitsu.io/favicon.ico',
      capabilities: ['anime', 'manga'],
      auth: AuthConfig(
        type: AuthType.oauth2,
        authorizeUrl:
            'https://kitsu.io/api/oauth/authorize',
        tokenUrl:
            'https://kitsu.io/api/oauth/token',
        clientId: 'dd031b32d2f56c990b1425efe6c42ad847e7fe3ab46bf1299f05ecd856bdb7dd',
        redirectUri: 'anymex://auth/addon/kitsu',
        scopes: 'public',
      ),
      api: ApiConfig(
        baseUrl: 'https://kitsu.io/api/edge',
        headers: {
          'Accept': 'application/vnd.api+json',
        },
      ),
      endpoints: EndpointsConfig(
        search: EndpointConfig(
          url: '/anime?filter[text]={query}&page[offset]={offset}&page[limit]=10',
          responsePath: 'data',
          mapping: {
            'id': 'id',
            'title': 'attributes.canonicalTitle',
            'poster': 'attributes.posterImage.medium',
            'description': 'attributes.synopsis',
            'total_episodes': 'attributes.episodeCount',
            'score': 'attributes.averageRating',
            'status': 'attributes.status',
          },
        ),
        userProfile: EndpointConfig(
          url: '/users?filter[self]=true',
          responsePath: 'data[0]',
          idPath: 'id',
          mapping: {
            'name': 'attributes.name',
            'avatar': 'attributes.avatar.tiny',
            'banner': 'attributes.coverImage.original',
            'about': 'attributes.about',
          },
        ),
        userList: EndpointConfig(
          url: '/users/{user_id}/library-entries?include=anime,manga&sort=-updatedAt',
          responsePath: 'data',
          mapping: {
            'remote_id': 'id',
            'title': 'attributes',
            'poster': 'attributes',
            'status': 'attributes.status',
            'score': 'attributes.ratingTwenty',
            'progress': 'attributes.progress',
            'total_episodes': 'attributes',
          },
        ),
        updateEntry: EndpointConfig(
          url: '/library-entries/{list_id}',
          method: 'PATCH',
          bodyTemplate: {
            'data': '{"type":"libraryEntries","id":"{list_id}","attributes":{"progress":"{progress}","status":"{status}","ratingTwenty":"{score}"}}',
          },
        ),
        addEntry: EndpointConfig(
          url: '/library-entries',
          method: 'POST',
          bodyTemplate: {
            'data': '{"type":"libraryEntries","attributes":{"progress":"{progress}","status":"{status}","animeId":"{media_id}","mangaId":"{media_id}"}}',
          },
        ),
        deleteEntry: EndpointConfig(
          url: '/library-entries/{list_id}',
          method: 'DELETE',
        ),
      ),
      statusMap: {
        'current': 'CURRENT',
        'planned': 'PLANNING',
        'completed': 'COMPLETED',
        'dropped': 'DROPPED',
        'on_hold': 'PAUSED',
        'rewatched': 'REPEATING',
      },
    );
  }

  // ── Shikimori ──────────────────────────────────────────────────

  static TrackerManifest _shikimori() {
    return const TrackerManifest(
      id: 'shikimori',
      name: 'Shikimori',
      version: '1.0.0',
      description: 'Track anime & manga on Shikimori.one',
      color: '#4A90D9',
      icon: 'https://shikimori.one/favicon.ico',
      capabilities: ['anime', 'manga'],
      auth: AuthConfig(
        type: AuthType.oauth2,
        authorizeUrl:
            'https://shikimori.one/oauth/authorize',
        tokenUrl:
            'https://shikimori.one/oauth/token',
        clientId: '',
        redirectUri: 'anymex://auth/addon/shikimori',
        scopes: 'user_rates',
      ),
      api: ApiConfig(
        baseUrl: 'https://shikimori.one/api',
        headers: {
          'User-Agent': 'AnymeX',
        },
      ),
      endpoints: EndpointsConfig(
        search: EndpointConfig(
          url: '/animes/search?q={query}&limit=10&page=1',
          responsePath: '',
          mapping: {
            'id': 'id',
            'title': 'name',
            'poster': 'image.original',
            'description': 'description',
            'total_episodes': 'episodes',
            'score': 'score',
            'status': 'status',
          },
        ),
        userProfile: EndpointConfig(
          url: '/users/whoami',
          responsePath: '',
          idPath: 'id',
          mapping: {
            'name': 'nickname',
            'avatar': 'image.x160',
            'about': 'about',
          },
        ),
        userList: EndpointConfig(
          url: '/user_rates?user_id={user_id}&target_type=Anime&limit=50',
          responsePath: '',
          mapping: {
            'remote_id': 'id',
            'status': 'status',
            'score': 'score',
            'progress': 'episodes',
          },
        ),
        updateEntry: EndpointConfig(
          url: '/user_rates/{list_id}',
          method: 'PATCH',
          bodyTemplate: {
            'user_rate': '{"episodes":"{progress}","status":"{status}","score":"{score}"}',
          },
        ),
        addEntry: EndpointConfig(
          url: '/user_rates',
          method: 'POST',
          bodyTemplate: {
            'user_rate': '{"target_id":"{media_id}","target_type":"Anime","status":"{status}","episodes":"{progress}"}',
          },
        ),
        deleteEntry: EndpointConfig(
          url: '/user_rates/{list_id}',
          method: 'DELETE',
        ),
      ),
      statusMap: {
        'watching': 'CURRENT',
        'planned': 'PLANNING',
        'completed': 'COMPLETED',
        'dropped': 'DROPPED',
        'on_hold': 'PAUSED',
        'rewatching': 'REPEATING',
      },
    );
  }

  // ── Bangumi ───────────────────────────────────────────────────

  static TrackerManifest _bangumi() {
    return const TrackerManifest(
      id: 'bangumi',
      name: 'Bangumi',
      version: '1.0.0',
      description: 'Track anime & manga on Bangumi.tv',
      color: '#F09199',
      icon: 'https://bangumi.tv/favicon.ico',
      capabilities: ['anime', 'manga'],
      auth: AuthConfig(
        type: AuthType.oauth2,
        authorizeUrl:
            'https://bgm.tv/oauth/authorize',
        tokenUrl: 'https://bgm.tv/oauth/access_token',
        clientId: '',
        redirectUri: 'anymex://auth/addon/bangumi',
        scopes: '',
      ),
      api: ApiConfig(
        baseUrl: 'https://api.bgm.tv',
        headers: {
          'User-Agent': 'AnymeX/1.0',
        },
      ),
      endpoints: EndpointsConfig(
        search: EndpointConfig(
          url: '/search/subject/{query}?type=2&responseGroup=small&max_results=10',
          responsePath: 'list',
          mapping: {
            'id': 'id',
            'title': 'name',
            'poster': 'images.common',
            'description': 'summary',
            'total_episodes': 'eps',
            'score': 'rating.score',
            'status': 'air_date',
          },
        ),
        userProfile: EndpointConfig(
          url: '/v0/me',
          responsePath: '',
          idPath: 'id',
          mapping: {
            'name': 'username',
            'avatar': 'avatar.large',
            'about': 'sign',
          },
        ),
        userList: EndpointConfig(
          url: '/v0/users/{user_id}/collections?subject_type=2',
          responsePath: 'data',
          mapping: {
            'remote_id': 'subject_id',
            'status': 'type',
            'score': 'rate',
            'progress': 'ep',
          },
        ),
        updateEntry: EndpointConfig(
          url: '/v0/users/-/collections/{list_id}',
          method: 'PATCH',
          bodyTemplate: {
            'ep': '{progress}',
            'rate': '{score}',
            'type': '{status}',
          },
        ),
        addEntry: EndpointConfig(
          url: '/v0/users/-/collections/{media_id}',
          method: 'POST',
          bodyTemplate: {
            'subject_id': '{media_id}',
            'type': '{status}',
            'ep': '{progress}',
          },
        ),
        deleteEntry: EndpointConfig(
          url: '/v0/users/-/collections/{list_id}',
          method: 'DELETE',
        ),
      ),
      statusMap: {
        '1': 'PLANNING',
        '2': 'CURRENT',
        '3': 'COMPLETED',
        '4': 'DROPPED',
        '5': 'PAUSED',
      },
    );
  }

  // ── Anime-Planet ──────────────────────────────────────────────

  static TrackerManifest _animePlanet() {
    return const TrackerManifest(
      id: 'animeplanet',
      name: 'Anime-Planet',
      version: '1.0.0',
      description: 'Track anime on Anime-Planet.com',
      color: '#5C7CFA',
      icon: 'https://www.anime-planet.com/favicon.ico',
      capabilities: ['anime'],
      auth: AuthConfig(
        type: AuthType.apiKey,
        apiKeyHeader: 'X-API-Key',
      ),
      api: ApiConfig(
        baseUrl: 'https://www.anime-planet.com/api',
      ),
      endpoints: EndpointsConfig(
        search: EndpointConfig(
          url: '/anime?search={query}&limit=10',
          responsePath: 'results',
          mapping: {
            'id': 'id',
            'title': 'name',
            'poster': 'poster',
            'description': 'description',
            'total_episodes': 'episodes',
            'score': 'rating',
          },
        ),
        userProfile: EndpointConfig(
          url: '/users/me',
          responsePath: '',
          idPath: 'id',
          mapping: {
            'name': 'username',
            'avatar': 'avatar',
          },
        ),
        userList: EndpointConfig(
          url: '/users/me/anime',
          responsePath: 'list',
          mapping: {
            'remote_id': 'id',
            'status': 'status',
            'score': 'rating',
            'progress': 'episodes_watched',
          },
        ),
        updateEntry: EndpointConfig(
          url: '/users/me/anime/{list_id}',
          method: 'PUT',
          bodyTemplate: {
            'status': '{status}',
            'rating': '{score}',
            'episodes_watched': '{progress}',
          },
        ),
      ),
      statusMap: {
        'watching': 'CURRENT',
        'want_to_watch': 'PLANNING',
        'completed': 'COMPLETED',
        'dropped': 'DROPPED',
        'on_hold': 'PAUSED',
        'rewatched': 'REPEATING',
      },
    );
  }

  // ── Annict ─────────────────────────────────────────────────────

  static TrackerManifest _annict() {
    return const TrackerManifest(
      id: 'annict',
      name: 'Annict',
      version: '1.0.0',
      description: 'Track anime on Annict.jp',
      color: '#E8453C',
      icon: 'https://annict.com/favicon.ico',
      capabilities: ['anime'],
      auth: AuthConfig(
        type: AuthType.oauth2,
        authorizeUrl:
            'https://annict.com/oauth/authorize',
        tokenUrl:
            'https://annict.com/oauth/token',
        clientId: '',
        redirectUri: 'anymex://auth/addon/annict',
        scopes: 'read write',
      ),
      api: ApiConfig(
        baseUrl: 'https://api.annict.com/v1',
      ),
      endpoints: EndpointsConfig(
        search: EndpointConfig(
          url: '/works?filter_title={query}&per_page=10',
          responsePath: 'works',
          mapping: {
            'id': 'annictId',
            'title': 'title',
            'poster': 'images.recommendedUrl',
          },
        ),
        userProfile: EndpointConfig(
          url: '/me',
          responsePath: '',
          idPath: 'id',
          mapping: {
            'name': 'name',
            'avatar': 'avatarUrl',
            'about': 'description',
          },
        ),
        userList: EndpointConfig(
          url: '/me/statuses?filter_kind=anime',
          responsePath: '',
          mapping: {
            'remote_id': 'work.id',
            'status': 'kind',
            'progress': 'watchEpisodeCount',
          },
        ),
        updateEntry: EndpointConfig(
          url: '/me/statuses',
          method: 'POST',
          bodyTemplate: {
            'work_id': '{media_id}',
            'kind': '{status}',
          },
        ),
      ),
      statusMap: {
        'watching': 'CURRENT',
        'wanna_watch': 'PLANNING',
        'watched': 'COMPLETED',
        'on_hold': 'PAUSED',
        'stop_watching': 'DROPPED',
        'rewatching': 'REPEATING',
      },
    );
  }
}
