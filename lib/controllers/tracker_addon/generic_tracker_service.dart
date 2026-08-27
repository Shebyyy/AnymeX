import 'dart:convert';

import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/tracker_addon/response_mapper.dart';
import 'package:anymex/controllers/tracker_addon/tracker_manifest.dart';
import 'package:anymex/controllers/tracker_addon/tracker_registry.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/widgets/non_widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// A fully functional [OnlineService] implementation driven entirely
/// by a [TrackerManifest]. No hardcoded logic — everything (auth, search,
/// user list, update progress, profile) is read from the manifest's
/// endpoint configs and field mappings.
class GenericTrackerService extends GetxController implements OnlineService {
  final TrackerManifest manifest;

  GenericTrackerService({required this.manifest});

  // ── Auth State ───────────────────────────────────────────────────

  String? _accessToken;
  String? _refreshToken;
  String? _userId;

  String? get accessToken => _accessToken;
  bool get hasToken => _accessToken != null && _accessToken!.isNotEmpty;

  // ── OnlineService reactive fields ────────────────────────────────

  @override
  final RxList<TrackedMedia> animeList = <TrackedMedia>[].obs;

  @override
  final RxList<TrackedMedia> mangaList = <TrackedMedia>[].obs;

  @override
  final Rx<TrackedMedia> currentMedia = TrackedMedia(
    id: '',
    title: '',
    episodeCount: '0',
  ).obs;

  @override
  final RxBool isLoggedIn = false.obs;

  @override
  final Rx<Profile> profileData = Rx<Profile>(Profile(name: 'Guest'));

  // ── Lifecycle ────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _loadAuthFromStorage();
    if (hasToken) {
      isLoggedIn.value = true;
      _loadUserProfile();
    }
  }

  // ── Auth Storage ─────────────────────────────────────────────────

  void _loadAuthFromStorage() {
    _accessToken = AddonKeys.authToken.get<String>(manifest.id);
    _refreshToken = AddonKeys.authRefreshToken.get<String>(manifest.id);
    _userId = AddonKeys.authUserId.get<String>(manifest.id);

    // Load cached profile data
    final cachedProfile = AddonKeys.authUserData.get<String>(manifest.id);
    if (cachedProfile != null && cachedProfile.isNotEmpty) {
      try {
        final map = jsonDecode(cachedProfile) as Map<String, dynamic>;
        final statsMap = map['stats'] as Map?;
        final animeCount = (statsMap?['anime_count'] as num?)?.toInt() ?? 0;
        final mangaCount = (statsMap?['manga_count'] as num?)?.toInt() ?? 0;
        profileData.value = Profile(
          name: map['name'] as String? ?? 'User',
          avatar: map['avatar'] as String?,
          cover: map['banner'] as String?,
          about: map['about'] as String?,
          stats: ProfileStatistics(
            animeStats: AnimeStats(animeCount: animeCount.toString()),
            mangaStats: MangaStats(mangaCount: mangaCount.toString()),
          ),
        );
      } catch (_) {}
    }
  }

  void _saveAuthToStorage() {
    if (_accessToken != null) {
      AddonKeys.authToken.set<String>(manifest.id, _accessToken!);
    } else {
      AddonKeys.authToken.delete(manifest.id);
    }
    if (_refreshToken != null) {
      AddonKeys.authRefreshToken.set<String>(manifest.id, _refreshToken!);
    } else {
      AddonKeys.authRefreshToken.delete(manifest.id);
    }
    if (_userId != null) {
      AddonKeys.authUserId.set<String>(manifest.id, _userId!);
    } else {
      AddonKeys.authUserId.delete(manifest.id);
    }
  }

  void _saveProfileToStorage() {
    final p = profileData.value;
    AddonKeys.authUserData.set<String>(
      manifest.id,
      jsonEncode({
        'name': p.name,
        'avatar': p.avatar,
        'cover': p.cover,
        'about': p.about,
        'stats': p.stats,
      }),
    );
  }

  // ── Auth: Login ──────────────────────────────────────────────────

  @override
  Future<void> login(BuildContext context) async {
    switch (manifest.auth.type) {
      case AuthType.oauth2:
        await _loginOAuth2(context);
        break;
      case AuthType.apiKey:
        await _loginApiKey(context);
        break;
      case AuthType.basic:
        await _loginBasicAuth(context);
        break;
      case AuthType.token:
        await _loginTokenOnly(context);
        break;
    }
  }

  Future<void> _loginOAuth2(BuildContext context) async {
    try {
      final auth = manifest.auth;
      final redirectUri =
          auth.redirectUri ?? 'anymex://auth/addon/${manifest.id}';

      final authUrl = ResponseMapper.buildUrl(
        auth.authorizeUrl!,
        params: {
          'client_id': auth.clientId ?? '',
          'redirect_uri': redirectUri,
          'response_type': 'code',
          'scope': auth.scopes ?? 'public',
        },
      );

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'anymex',
      );

      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];
      if (code == null) {
        errorSnackBar('Authorization failed: no code received');
        return;
      }

      // Exchange code for token
      final tokenResponse = await http.post(
        Uri.parse(auth.tokenUrl!),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'client_id': auth.clientId ?? '',
          'client_secret': auth.clientSecret ?? '',
          'redirect_uri': redirectUri,
        },
      );

      final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      _accessToken = tokenData['access_token'] as String?;
      _refreshToken = tokenData['refresh_token'] as String?;
      isLoggedIn.value = hasToken;
      _saveAuthToStorage();

      if (hasToken) {
        await _loadUserProfile();
        successSnackBar('Logged into ${manifest.name}');
      } else {
        errorSnackBar('Failed to get access token');
      }
    } catch (e) {
      Logger.e('${manifest.id} OAuth login failed: $e');
      errorSnackBar('Login failed: $e');
    }
  }

  Future<void> _loginApiKey(BuildContext context) async {
    final apiKeyController = TextEditingController();
    final auth = manifest.auth;

    final apiKey = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Connect ${manifest.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (manifest.description != null)
              Text(manifest.description!,
                  style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: apiKeyController,
              decoration: InputDecoration(
                labelText: auth.usernamePlaceholder ?? 'API Key',
                hintText: 'Enter your ${auth.usernamePlaceholder ?? "API Key"}',
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (apiKeyController.text.isNotEmpty) {
                Navigator.pop(ctx, apiKeyController.text.trim());
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );

    if (apiKey != null && apiKey.isNotEmpty) {
      _accessToken = apiKey;
      isLoggedIn.value = true;
      _saveAuthToStorage();
      await _loadUserProfile();
      successSnackBar('Logged into ${manifest.name}');
    }
  }

  Future<void> _loginBasicAuth(BuildContext context) async {
    final userController = TextEditingController();
    final passController = TextEditingController();
    final auth = manifest.auth;

    final credentials = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Connect ${manifest.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userController,
              decoration: InputDecoration(
                labelText: auth.usernamePlaceholder ?? 'Username',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: auth.passwordPlaceholder ?? 'Password',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (userController.text.isNotEmpty) {
                Navigator.pop(ctx, {
                  'username': userController.text.trim(),
                  'password': passController.text,
                });
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );

    if (credentials != null) {
      // Store as base64 basic auth token
      _accessToken =
          base64Encode(utf8.encode('${credentials["username"]}:${credentials["password"]}'));
      isLoggedIn.value = true;
      _saveAuthToStorage();
      await _loadUserProfile();
      successSnackBar('Logged into ${manifest.name}');
    }
  }

  Future<void> _loginTokenOnly(BuildContext context) async {
    final tokenController = TextEditingController();
    final auth = manifest.auth;

    final token = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Connect ${manifest.name}'),
        content: TextField(
          controller: tokenController,
          decoration: InputDecoration(
            labelText: auth.usernamePlaceholder ?? 'Access Token',
            hintText: 'Paste your access token',
            border: const OutlineInputBorder(),
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (tokenController.text.isNotEmpty) {
                Navigator.pop(ctx, tokenController.text.trim());
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );

    if (token != null && token.isNotEmpty) {
      _accessToken = token;
      isLoggedIn.value = true;
      _saveAuthToStorage();
      await _loadUserProfile();
      successSnackBar('Logged into ${manifest.name}');
    }
  }

  // ── Auth: Logout ─────────────────────────────────────────────────

  @override
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _userId = null;
    isLoggedIn.value = false;
    profileData.value = Profile(name: 'Guest');
    animeList.clear();
    mangaList.clear();
    _saveAuthToStorage();
    AddonKeys.authUserData.delete(manifest.id);
    Logger.i('Logged out from ${manifest.name}');
  }

  @override
  Future<void> autoLogin() async {
    _loadAuthFromStorage();
    if (hasToken) {
      isLoggedIn.value = true;
    }
  }

  // ── Profile ──────────────────────────────────────────────────────

  Future<void> _loadUserProfile() async {
    final endpoint = manifest.endpoints.userProfile;
    if (endpoint == null) return;

    try {
      final response = await _apiRequest(endpoint);
      if (response != null) {
        final data = _resolveResponse(response, endpoint.responsePath);

        final profileEndpoint = manifest.endpoints.userProfile!;
        final mapping = profileEndpoint.mapping;

        profileData.value = Profile(
          name: mapping != null
              ? (ResponseMapper.resolveString(data, mapping['name'] ?? '') ??
                  'User')
              : 'User',
          avatar: mapping != null
              ? ResponseMapper.resolveString(data, mapping['avatar'] ?? '')
              : null,
          cover: mapping != null
              ? ResponseMapper.resolveString(data, mapping['banner'] ?? '')
              : null,
          about: mapping != null
              ? ResponseMapper.resolveString(data, mapping['about'] ?? '')
              : null,
          stats: _buildProfileStatistics(data, mapping),
        );

        // Extract and store user ID
        if (endpoint.idPath != null) {
          _userId = ResponseMapper.resolveString(data, endpoint.idPath!);
          AddonKeys.authUserId.set<String>(manifest.id, _userId!);
        }

        _saveProfileToStorage();
      }
    } catch (e) {
      Logger.e('${manifest.id} failed to load profile: $e');
    }
  }

  ProfileStatistics? _buildProfileStatistics(
    dynamic data,
    Map<String, String>? mapping,
  ) {
    if (mapping == null) return null;
    final animeCount = ResponseMapper.resolveInt(data, mapping['anime_count'] ?? '') ?? 0;
    final mangaCount = ResponseMapper.resolveInt(data, mapping['manga_count'] ?? '') ?? 0;
    return ProfileStatistics(
      animeStats: AnimeStats(animeCount: animeCount.toString()),
      mangaStats: MangaStats(mangaCount: mangaCount.toString()),
    );
  }

  // ── User List ────────────────────────────────────────────────────

  @override
  Future<void> refresh() async {
    if (!isLoggedIn.value) return;
    await _loadUserList();
  }

  Future<void> _loadUserList() async {
    final endpoint = manifest.endpoints.userList;
    if (endpoint == null) return;

    try {
      final response = await _apiRequest(endpoint, params: {
        'user_id': _userId ?? '',
      });
      if (response == null) return;

      final items = ResponseMapper.mapList(
        response,
        endpoint.responsePath,
        endpoint.mapping ?? {},
      );

      final trackedItems = items.map((item) {
        final rawStatus = item['status']?.toString() ?? 'CURRENT';
        // Convert from remote status to AnymeX status
        final status =
            manifest.statusMap[rawStatus] ?? rawStatus;

        return TrackedMedia(
          id: item['remote_id']?.toString() ??
              item['id']?.toString() ??
              '',
          title: item['title']?.toString() ?? '',
          poster: item['poster'] as String?,
          score: (item['score'] as num?)?.toString() ?? '0',
          episodeCount:
              (item['total_episodes'] as num?)?.toString() ?? '?',
          watchingStatus: status,
          isPrivate: item['private'] as bool? ?? false,
          mediaListId: item['id']?.toString() ?? '',
        );
      }).toList();

      // If the manifest supports both, we'd need separate endpoints.
      // For now, put everything in animeList and let the manifest handle filtering.
      if (manifest.supportsAnime && manifest.supportsManga) {
        // If there's a query_param_map for type, we'd need to call twice
        animeList.assignAll(trackedItems);
        mangaList.assignAll(trackedItems);
      } else if (manifest.supportsManga) {
        mangaList.assignAll(trackedItems);
      } else {
        animeList.assignAll(trackedItems);
      }
    } catch (e) {
      Logger.e('${manifest.id} failed to load user list: $e');
    }
  }

  // ── Set Current Media ────────────────────────────────────────────

  @override
  void setCurrentMedia(String id, {bool isManga = false}) {
    final list = isManga ? mangaList : animeList;
    try {
      final found = list.firstWhere((m) =>
          m.id == id || m.mediaListId == id);
      currentMedia.value = found;
    } catch (_) {
      currentMedia.value = TrackedMedia(
        id: id,
        title: '',
        episodeCount: '0',
      );
    }
  }

  // ── Update List Entry ────────────────────────────────────────────

  @override
  Future<void> updateListEntry(UpdateListEntryParams params) async {
    if (!isLoggedIn.value) return;

    // Check if we need to add first (no list_id means not on list yet)
    if (params.listId.isEmpty && manifest.endpoints.addEntry != null) {
      await _addNewEntry(params);
      return;
    }

    final endpoint = manifest.endpoints.updateEntry;
    if (endpoint == null) {
      Logger.w('${manifest.id}: no update_entry endpoint configured');
      return;
    }

    try {
      // Build status conversion (AnymeX internal → remote)
      final remoteStatus = params.status != null
          ? (manifest.reverseStatusMap?[params.status!] ??
              params.status!)
          : null;

      final bodyParams = <String, dynamic>{};
      if (params.progress != null) bodyParams['progress'] = params.progress;
      if (params.score != null) bodyParams['score'] = params.score;
      if (remoteStatus != null) bodyParams['status'] = remoteStatus;
      bodyParams['list_id'] = params.listId;

      Map<String, dynamic>? body;
      if (endpoint.bodyTemplate != null) {
        body = ResponseMapper.buildBody(endpoint.bodyTemplate!,
            params: bodyParams);
      }

      await _apiRequest(endpoint,
          params: {'list_id': params.listId}, body: body);

      // Update local list
      _updateLocalEntry(params);
      Logger.i(
          '${manifest.id}: updated ${params.listId} progress=${params.progress}');
    } catch (e) {
      Logger.e('${manifest.id} update failed: $e');
    }
  }

  Future<void> _addNewEntry(UpdateListEntryParams params) async {
    final endpoint = manifest.endpoints.addEntry;
    if (endpoint == null) return;

    try {
      final remoteStatus = params.status != null
          ? (manifest.reverseStatusMap?[params.status!] ?? params.status!)
          : 'CURRENT';

      final bodyParams = <String, dynamic>{
        'media_id': params.listId,
        'progress': params.progress ?? 0,
        'status': remoteStatus,
        'score': params.score ?? 0,
      };

      Map<String, dynamic>? body;
      if (endpoint.bodyTemplate != null) {
        body = ResponseMapper.buildBody(endpoint.bodyTemplate!,
            params: bodyParams);
      }

      await _apiRequest(endpoint, body: body);
      Logger.i('${manifest.id}: added new entry ${params.listId}');
    } catch (e) {
      Logger.e('${manifest.id} add entry failed: $e');
    }
  }

  void _updateLocalEntry(UpdateListEntryParams params) {
    final list = params.isAnime ? animeList : mangaList;
    final idx = list.indexWhere(
        (m) => m.id == params.listId || m.mediaListId == params.listId);
    if (idx != -1) {
      final updated = list[idx];
      list[idx] = TrackedMedia(
        id: updated.id,
        title: updated.title,
        poster: updated.poster,
        score: params.score?.toString() ?? updated.score,
        episodeCount: updated.episodeCount,
        watchingStatus: params.status ?? updated.watchingStatus,
        isPrivate: params.isPrivate ?? updated.isPrivate,
        mediaListId: updated.mediaListId,
      );
    }
  }

  // ── Delete List Entry ────────────────────────────────────────────

  @override
  Future<void> deleteListEntry(String listId, {bool isAnime = true}) async {
    if (!isLoggedIn.value) return;

    final endpoint = manifest.endpoints.deleteEntry;
    if (endpoint == null) {
      Logger.w('${manifest.id}: no delete_entry endpoint configured');
      return;
    }

    try {
      await _apiRequest(endpoint, params: {'list_id': listId});
      final list = isAnime ? animeList : mangaList;
      list.removeWhere((m) =>
          m.id == listId || m.mediaListId == listId);
      Logger.i('${manifest.id}: deleted entry $listId');
    } catch (e) {
      Logger.e('${manifest.id} delete failed: $e');
    }
  }

  // ── Search (for track binding) ───────────────────────────────────

  Future<List<Media>> search(String query, {bool isManga = false}) async {
    final endpoint = manifest.endpoints.search;
    if (endpoint == null) return [];

    try {
      final extraParams = <String, String>{};
      if (endpoint.queryParamMap != null) {
        if (isManga && endpoint.queryParamMap!.containsKey('type_manga')) {
          extraParams['type'] =
              endpoint.queryParamMap!['type_manga'] ?? '';
        } else if (!isManga &&
            endpoint.queryParamMap!.containsKey('type_anime')) {
          extraParams['type'] =
              endpoint.queryParamMap!['type_anime'] ?? '';
        }
      }

      final response = await _apiRequest(endpoint, params: {
        'query': query,
        'offset': '0',
        ...extraParams,
      });

      if (response == null) return [];

      final items = ResponseMapper.mapList(
        response,
        endpoint.responsePath,
        endpoint.mapping ?? {},
      );

      return items.map((item) {
        return Media(
          id: item['id']?.toString() ?? '0',
          title: (item['title'] as String?) ?? '?',
          poster: item['poster'] as String? ?? '?',
          totalEpisodes:
              (item['total_episodes'] as num?)?.toString() ?? '?',
          rating: (item['score'] as num?)?.toString() ?? '?',
          status: item['status'] as String? ?? 'UNKNOWN',
          serviceType: ServicesType.extensions,
        );
      }).toList();
    } catch (e) {
      Logger.e('${manifest.id} search failed: $e');
      return [];
    }
  }

  // ── HTTP Layer ───────────────────────────────────────────────────

  /// Make an API request using the manifest's config.
  /// Handles URL building, header injection, and auth.
  Future<Map<String, dynamic>?> _apiRequest(
    EndpointConfig endpoint, {
    Map<String, String> params = const {},
    Map<String, dynamic>? body,
  }) async {
    try {
      // Build URL
      String url = ResponseMapper.buildUrl(
        endpoint.url,
        params: {
          'query': params['query'] ?? '',
          'offset': params['offset'] ?? '0',
          'user_id': params['user_id'] ?? _userId ?? '',
          'list_id': params['list_id'] ?? '',
          'media_id': params['media_id'] ?? '',
          ...params,
        },
        baseUrl: manifest.api.baseUrl,
      );

      // Build headers
      final headers = ResponseMapper.buildHeaders(
        manifest.api.headers,
        accessToken: _accessToken,
        apiKey: _accessToken,
        apiKeyHeader: manifest.auth.apiKeyHeader,
      );

      // Set content type for body requests
      if (body != null) {
        headers['Content-Type'] =
            manifest.api.contentType ?? 'application/json';
      }

      final uri = Uri.parse(url);
      http.Response response;

      switch (endpoint.method) {
        case 'POST':
          response = await http.post(uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null);
          break;
        case 'PUT':
          response = await http.put(uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null);
          break;
        case 'PATCH':
          response = await http.patch(uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default: // GET
          response = await http.get(uri, headers: headers);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        Logger.e(
            '${manifest.id} API ${endpoint.method} $url returned ${response.statusCode}');
        return null;
      }
    } catch (e) {
      Logger.e('${manifest.id} API request failed: $e');
      return null;
    }
  }

  /// Resolve response data using responsePath.
  dynamic _resolveResponse(
      Map<String, dynamic> response, String? path) {
    if (path == null || path.isEmpty) return response;
    return ResponseMapper.resolve(response, path);
  }
}
