import 'dart:convert';
import 'package:anymex/controllers/network/network_manager.dart';
import 'package:anymex/controllers/service_handler/params.dart';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/controllers/services/widgets/widgets_builders.dart';
import 'package:anymex/controllers/tracker_addon/addon_manifest.dart';
import 'package:anymex/controllers/tracker_addon/addon_mapper.dart';
import 'package:anymex/database/data_keys/keys.dart';
import 'package:anymex/models/Anilist/anilist_media_user.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/models/Media/media.dart';
import 'package:anymex/models/Service/base_service.dart';
import 'package:anymex/models/Service/online_service.dart';
import 'package:anymex/utils/function.dart';
import 'package:anymex/utils/logger.dart';
import 'package:anymex/utils/oauth_helper.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_dialog.dart';
import 'package:anymex/widgets/anymex_widgets/anymex_text.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

/// A dynamic tracker client driving any installed Tracker Add-on JSON manifest.
class AddonService extends GetxController
    implements BaseService, OnlineService {
  final AddonManifest manifest;

  AddonService({required this.manifest});

  http.Client get _client => NetworkManager.instance.compatibleClient;

  // ── OnlineService State ──────────────────────────────────────────
  @override
  final RxList<TrackedMedia> animeList = <TrackedMedia>[].obs;

  @override
  final RxList<TrackedMedia> mangaList = <TrackedMedia>[].obs;

  @override
  final Rx<TrackedMedia> currentMedia = TrackedMedia().obs;

  @override
  final RxBool isLoggedIn = false.obs;

  @override
  final Rx<Profile> profileData = Profile(name: 'Guest').obs;

  // ── BaseService State ────────────────────────────────────────────
  final Map<String, RxList<Media>> sectionData = {};
  final RxBool _isDataLoaded = false.obs;

  @override
  bool get isDataLoaded => _isDataLoaded.value;

  String? get token =>
      DynamicKeys.trackerAddonToken.get<String>(manifest.id);

  Map<String, String> get _headers {
    final map = <String, String>{
      'Content-Type': manifest.api.contentType ?? 'application/json',
      ...?manifest.api.headers,
    };
    final currentToken = token;
    if (currentToken != null && currentToken.isNotEmpty) {
      final headerName = manifest.auth.tokenHeader ?? 'Authorization';
      final prefix = manifest.auth.tokenPrefix ?? 'Bearer ';
      map[headerName] = '$prefix$currentToken';
    }
    return map;
  }

  String _interpolate(String template, Map<String, String> vars) {
    var result = template;
    for (final entry in vars.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  String _buildFullUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = manifest.api.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.replaceAll(RegExp(r'^/+'), '');
    return '$base/$cleanPath';
  }

  // ── Auth Implementation ──────────────────────────────────────────
  @override
  Future<void> autoLogin() async {
    final savedToken = token;
    if (savedToken != null && savedToken.isNotEmpty) {
      isLoggedIn.value = true;
      final rawProfile =
          DynamicKeys.trackerAddonProfile.get<String>(manifest.id, '');
      if (rawProfile.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawProfile) as Map<String, dynamic>;
          profileData.value = Profile(
            id: decoded['id']?.toString(),
            name: decoded['name']?.toString() ?? 'User',
            avatar: decoded['avatar']?.toString() ?? '',
            cover: decoded['cover']?.toString() ?? '',
          );
        } catch (_) {}
      }
      fetchProfile().then((_) => fetchLibrary());
    }
  }

  @override
  Future<void> login(BuildContext context) async {
    switch (manifest.auth.type) {
      case AuthType.oauth2:
        await _loginOAuth2(context);
        break;
      case AuthType.token:
        await _loginToken(context);
        break;
      case AuthType.credentials:
        await _loginCredentials(context);
        break;
    }
  }

  Future<void> _loginOAuth2(BuildContext context) async {
    final authUrl = manifest.auth.authUrl;
    final defaultCallback =
        dotenv.env['CALLBACK_SCHEME'] ?? 'anymex://callback';
    final redirectUri = (manifest.auth.redirectUri?.isNotEmpty ?? false)
        ? manifest.auth.redirectUri!
        : defaultCallback;
    final callbackScheme = Uri.tryParse(redirectUri)?.scheme ?? 'anymex';

    if (authUrl == null || authUrl.isEmpty) {
      Get.snackbar('Login Error', 'OAuth2 URL not configured for ${manifest.name}');
      return;
    }

    final formattedUrl = _interpolate(authUrl, {
      'client_id': manifest.auth.clientId ?? '',
      'redirect_uri': redirectUri,
      'scopes': manifest.auth.scopes ?? '',
    });

    final result = await OauthHelper.authenticate(
      context: context,
      url: formattedUrl,
      callbackUrlScheme: callbackScheme,
    );

    if (result != null && result.isNotEmpty) {
      String? extractedToken;
      if (result.contains('access_token=')) {
        final uri = Uri.parse(result.replaceFirst('#', '?'));
        extractedToken = uri.queryParameters['access_token'];
      } else if (result.contains('code=')) {
        final uri = Uri.parse(result);
        final code = uri.queryParameters['code'];
        if (code != null) {
          extractedToken = await _exchangeCodeForToken(code);
        }
      }

      if (extractedToken != null && extractedToken.isNotEmpty) {
        _setToken(extractedToken);
      }
    }
  }

  Future<String?> _exchangeCodeForToken(String code) async {
    final tokenUrl = manifest.auth.tokenUrl;
    if (tokenUrl == null || tokenUrl.isEmpty) return null;

    final defaultCallback =
        dotenv.env['CALLBACK_SCHEME'] ?? 'anymex://callback';
    final redirectUri = (manifest.auth.redirectUri?.isNotEmpty ?? false)
        ? manifest.auth.redirectUri!
        : defaultCallback;

    try {
      final userAgent =
          manifest.api.headers?['User-Agent'] ?? 'AnymeX-Client';
      final resp = await _client.post(
        Uri.parse(tokenUrl),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': userAgent,
        },
        body: jsonEncode({
          'grant_type': 'authorization_code',
          if (manifest.auth.clientId != null)
            'client_id': manifest.auth.clientId,
          if (manifest.auth.clientSecret != null)
            'client_secret': manifest.auth.clientSecret,
          'code': code,
          'redirect_uri': redirectUri,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final path = manifest.auth.tokenResponsePath ?? 'access_token';
        return AddonMapper.getPath(data, path)?.toString();
      }
    } catch (e) {
      Logger.e('OAuth code exchange failed: $e');
    }
    return null;
  }

  Future<void> _loginToken(BuildContext context) async {
    final controller = TextEditingController(text: token ?? '');

    await showDialog(
      context: context,
      builder: (dialogCtx) => AnymeXDialog(
        title: 'Sign in to ${manifest.name}',
        confirmText: 'Save & Login',
        onConfirm: () {
          final text = controller.text.trim();
          if (text.isNotEmpty) {
            _setToken(text);
          }
        },
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnymeXText(
              'Enter your ${manifest.name} Personal Access Token / API Key:',
              size: 13,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Paste token here...',
                border: OutlineInputBorder(),
              ),
            ),
            if (manifest.auth.instructionsUrl != null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () =>
                    launchUrlString(manifest.auth.instructionsUrl!),
                child: AnymeXText(
                  'How to get API token ↗',
                  size: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loginCredentials(BuildContext context) async {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogCtx) => AnymeXDialog(
        title: 'Sign in to ${manifest.name}',
        confirmText: 'Login',
        onConfirm: () async {
          final user = userCtrl.text.trim();
          final pass = passCtrl.text;
          if (user.isNotEmpty && pass.isNotEmpty) {
            await _performCredentialsLogin(user, pass);
          }
        },
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(
                labelText: 'Username or Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performCredentialsLogin(String username, String password) async {
    final loginUrl = manifest.auth.loginUrl;
    if (loginUrl == null || loginUrl.isEmpty) return;

    try {
      final template = manifest.auth.bodyTemplate ??
          {'username': '{username}', 'password': '{password}'};

      final bodyMap = <String, dynamic>{};
      for (final entry in template.entries) {
        if (entry.value is String) {
          bodyMap[entry.key] = entry.value
              .replaceAll('{username}', username)
              .replaceAll('{password}', password);
        } else {
          bodyMap[entry.key] = entry.value;
        }
      }

      final resp = await _client.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyMap),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final path = manifest.auth.tokenResponsePath ?? 'access_token';
        final extractedToken = AddonMapper.getPath(data, path)?.toString();
        if (extractedToken != null && extractedToken.isNotEmpty) {
          _setToken(extractedToken);
          Get.snackbar('Success', 'Logged in to ${manifest.name}');
          return;
        }
      }
      Get.snackbar('Login Failed', 'Invalid credentials or server error (${resp.statusCode})');
    } catch (e) {
      Logger.e('Credentials login failed: $e');
      Get.snackbar('Login Error', e.toString());
    }
  }

  void _setToken(String newToken) {
    DynamicKeys.trackerAddonToken.set(manifest.id, newToken);
    isLoggedIn.value = true;
    fetchProfile().then((_) => fetchLibrary());
    fetchHomePage();
    serviceHandler.changeToAddon(manifest.id);
  }

  @override
  Future<void> logout() async {
    DynamicKeys.trackerAddonToken.delete(manifest.id);
    DynamicKeys.trackerAddonRefreshToken.delete(manifest.id);
    DynamicKeys.trackerAddonProfile.delete(manifest.id);

    isLoggedIn.value = false;
    profileData.value = Profile(name: 'Guest');
    animeList.clear();
    mangaList.clear();
  }

  @override
  Future<void> refresh() async {
    if (isLoggedIn.value) {
      await Future.wait([
        fetchProfile(),
        fetchLibrary(),
      ]);
    }
    await fetchHomePage();
  }

  Future<void> fetchProfile() async {
    final endpoint = manifest.endpoints.userProfile;
    if (endpoint == null || token == null) return;

    try {
      final url = _buildFullUrl(endpoint.url);
      final resp = await _client.get(Uri.parse(url), headers: _headers);
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final targetData = endpoint.responsePath != null
            ? AddonMapper.getPath(decoded, endpoint.responsePath!)
            : decoded;

        if (targetData is Map) {
          final profile = AddonMapper.mapToProfile(
              Map<String, dynamic>.from(targetData), manifest);
          profileData.value = profile;

          DynamicKeys.trackerAddonProfile.set(
            manifest.id,
            jsonEncode({
              if (profile.id != null) 'id': profile.id,
              'name': profile.name,
              'avatar': profile.avatar,
              'cover': profile.cover,
            }),
          );
        }
      }
    } catch (e) {
      Logger.e('Failed to fetch profile for ${manifest.name}: $e');
    }
  }

  Future<void> fetchLibrary() async {
    final endpoint = manifest.endpoints.userLibrary;
    if (endpoint == null || token == null) return;

    if (profileData.value.id == null || profileData.value.id!.isEmpty) {
      await fetchProfile();
    }

    try {
      final userId = (profileData.value.id?.isNotEmpty == true)
          ? profileData.value.id!
          : (profileData.value.name ?? 'me');
      final animeResults = <TrackedMedia>[];
      final mangaResults = <TrackedMedia>[];

      // Fetch for anime
      if (manifest.supportsAnime) {
        final url = _buildFullUrl(_interpolate(endpoint.url, {
          'userId': userId,
          'type': 'anime',
          'status': 'current',
          'targetType': 'Anime',
        }));

        final resp = await _client.get(Uri.parse(url), headers: _headers);
        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          final items = (endpoint.itemsPath != null
                  ? AddonMapper.getPath(decoded, endpoint.itemsPath!)
                  : decoded) as List<dynamic>? ??
              [];
          final included = (decoded is Map && decoded['included'] is List)
              ? (decoded['included'] as List)
              : [];

          for (final item in items) {
            if (item is Map) {
              final map = _resolveJsonApi(
                Map<String, dynamic>.from(item),
                included,
              );
              animeResults.add(AddonMapper.mapToTrackedMedia(
                map,
                manifest,
                isAnime: true,
              ));
            }
          }
        }
      }

      // Fetch for manga
      if (manifest.supportsManga) {
        final url = _buildFullUrl(_interpolate(endpoint.url, {
          'userId': userId,
          'type': 'manga',
          'status': 'current',
          'targetType': 'Manga',
        }));

        final resp = await _client.get(Uri.parse(url), headers: _headers);
        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          final items = (endpoint.itemsPath != null
                  ? AddonMapper.getPath(decoded, endpoint.itemsPath!)
                  : decoded) as List<dynamic>? ??
              [];
          final included = (decoded is Map && decoded['included'] is List)
              ? (decoded['included'] as List)
              : [];

          for (final item in items) {
            if (item is Map) {
              final map = _resolveJsonApi(
                Map<String, dynamic>.from(item),
                included,
              );
              mangaResults.add(AddonMapper.mapToTrackedMedia(
                map,
                manifest,
                isAnime: false,
              ));
            }
          }
        }
      }

      animeList.value = animeResults;
      mangaList.value = mangaResults;
    } catch (e) {
      Logger.e('Failed to fetch user library for ${manifest.name}: $e');
    }
  }

  /// Generic JSON:API relationship resolution for compound documents.
  Map<String, dynamic> _resolveJsonApi(
    Map<String, dynamic> item,
    List<dynamic> included,
  ) {
    if (included.isEmpty || item['relationships'] is! Map) return item;
    final map = Map<String, dynamic>.from(item);
    final relationships =
        Map<String, dynamic>.from(item['relationships'] as Map);

    relationships.forEach((relKey, relVal) {
      if (relVal is Map && relVal['data'] is Map) {
        final relData = Map<String, dynamic>.from(relVal['data'] as Map);
        final relId = relData['id']?.toString();
        final relType = relData['type']?.toString();
        if (relId != null) {
          final match = included.firstWhere(
            (inc) =>
                inc is Map &&
                inc['id']?.toString() == relId &&
                (relType == null || inc['type']?.toString() == relType),
            orElse: () => null,
          );
          if (match is Map) {
            relData['attributes'] = match['attributes'];
            relationships[relKey] = {'data': relData};
          }
        }
      }
    });

    map['relationships'] = relationships;
    return map;
  }

  @override
  void setCurrentMedia(String id, {bool isManga = false}) {
    final list = isManga ? mangaList : animeList;
    try {
      currentMedia.value = list.firstWhere(
        (m) => m.id == id || m.mediaListId == id,
      );
    } catch (_) {
      currentMedia.value = TrackedMedia();
    }
  }

  @override
  Future<void> updateListEntry(UpdateListEntryParams params) async {
    final endpoint = manifest.endpoints.updateEntry;
    if (endpoint == null || token == null) return;

    try {
      final statusVal = params.status;
      final remoteStatus = manifest.reverseStatusMap[statusVal] ??
          statusVal?.toLowerCase() ??
          'current';

      final url = _buildFullUrl(_interpolate(endpoint.url, {
        'entryId': params.listId,
        'id': params.listId,
        'progress': params.progress.toString(),
        'status': remoteStatus,
        'score': (params.score ?? 0).toString(),
      }));

      final method = endpoint.method.toUpperCase();
      final bodyTemplate = endpoint.bodyTemplate;

      Map<String, String> vars = {
        'entryId': params.listId,
        'progress': params.progress.toString(),
        'status': remoteStatus,
        'score': (params.score ?? 0).toString(),
      };

      String? bodyStr;
      if (bodyTemplate != null) {
        bodyStr = _interpolateJson(bodyTemplate, vars);
      }

      http.Response resp;
      if (method == 'POST') {
        resp = await _client.post(Uri.parse(url), headers: _headers, body: bodyStr);
      } else if (method == 'PUT') {
        resp = await _client.put(Uri.parse(url), headers: _headers, body: bodyStr);
      } else if (method == 'PATCH') {
        resp = await _client.patch(Uri.parse(url), headers: _headers, body: bodyStr);
      } else {
        resp = await _client.post(Uri.parse(url), headers: _headers, body: bodyStr);
      }

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        fetchLibrary();
      }
    } catch (e) {
      Logger.e('Failed to update list entry for ${manifest.name}: $e');
    }
  }

  String _interpolateJson(Map<String, dynamic> template, Map<String, String> vars) {
    var raw = jsonEncode(template);
    for (final entry in vars.entries) {
      raw = raw.replaceAll('"{${entry.key}}"', jsonEncode(entry.value));
      raw = raw.replaceAll('{${entry.key}}', entry.value);
    }
    return raw;
  }

  @override
  Future<void> deleteListEntry(String listId, {bool isAnime = true}) async {
    final endpoint = manifest.endpoints.deleteEntry;
    if (endpoint == null || token == null) return;

    try {
      final url = _buildFullUrl(_interpolate(endpoint.url, {'entryId': listId, 'id': listId}));
      await _client.delete(Uri.parse(url), headers: _headers);
      fetchLibrary();
    } catch (e) {
      Logger.e('Failed to delete list entry: $e');
    }
  }

  // ── BaseService Implementation ───────────────────────────────────
  @override
  Future<void> fetchHomePage() async {
    final sections = manifest.endpoints.homeSections;
    if (sections.isEmpty) {
      _isDataLoaded = true;
      return;
    }

    await Future.wait(sections.map((section) async {
      sectionData.putIfAbsent(section.title, () => <Media>[].obs);
      try {
        final url = _buildFullUrl(section.url);
        final resp = await _client.get(Uri.parse(url), headers: _headers);
        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          final items = (section.itemsPath != null
                  ? AddonMapper.getPath(decoded, section.itemsPath!)
                  : decoded) as List<dynamic>? ??
              [];

          final mediaList = <Media>[];
          for (final item in items) {
            if (item is Map) {
              mediaList.add(AddonMapper.mapToMedia(
                Map<String, dynamic>.from(item),
                manifest,
                isAnime: section.isAnime,
              ));
            }
          }
          sectionData[section.title]!.value = mediaList;
        }
      } catch (e) {
        Logger.e('Failed to load section "${section.title}": $e');
      }
    }));

    _isDataLoaded = true;
  }

  @override
  Future<List<Media>> search(SearchParams params) async {
    final endpoint = manifest.endpoints.search;
    if (endpoint == null) return [];

    try {
      final mediaTypeStr = params.isManga ? 'manga' : 'anime';
      final limit = endpoint.limit ?? 20;
      final offset = (params.page - 1) * limit;

      final url = _buildFullUrl(_interpolate(endpoint.url, {
        'query': Uri.encodeComponent(params.query),
        'page': params.page.toString(),
        'offset': offset.toString(),
        'limit': limit.toString(),
        'type': mediaTypeStr,
      }));

      final resp = await _client.get(Uri.parse(url), headers: _headers);
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final items = (endpoint.itemsPath != null
                ? AddonMapper.getPath(decoded, endpoint.itemsPath!)
                : decoded) as List<dynamic>? ??
            [];

        final results = <Media>[];
        for (final item in items) {
          if (item is Map) {
            results.add(AddonMapper.mapToMedia(
              Map<String, dynamic>.from(item),
              manifest,
              isAnime: !params.isManga,
              customMapping: endpoint.mapping,
            ));
          }
        }
        return results;
      }
    } catch (e) {
      Logger.e('Search failed for ${manifest.name}: $e');
    }
    return [];
  }

  @override
  Future<Media> fetchDetails(FetchDetailsParams params) async {
    final endpoint = manifest.endpoints.details;
    if (endpoint == null) {
      return Media(
        id: params.id.toString(),
        title: 'Details not available',
        serviceType: ServicesType.addon,
      );
    }

    try {
      final isManga = params.type == ItemType.manga;
      final mediaTypeStr = isManga ? 'manga' : 'anime';
      final url = _buildFullUrl(_interpolate(endpoint.url, {
        'id': params.id.toString(),
        'type': mediaTypeStr,
      }));

      final resp = await _client.get(Uri.parse(url), headers: _headers);
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final targetData = endpoint.responsePath != null
            ? AddonMapper.getPath(decoded, endpoint.responsePath!)
            : decoded;

        if (targetData is Map) {
          return AddonMapper.mapToMedia(
            Map<String, dynamic>.from(targetData),
            manifest,
            isAnime: !isManga,
            customMapping: endpoint.mapping,
          );
        }
      }
    } catch (e) {
      Logger.e('Fetch details failed for ${manifest.name}: $e');
    }

    return Media(
      id: params.id.toString(),
      title: 'Failed to load details',
      serviceType: ServicesType.addon,
    );
  }

  @override
  RxList<Widget> homeWidgets(BuildContext context) {
    return _buildSections(manifest.endpoints.homeSections);
  }

  @override
  RxList<Widget> animeWidgets(BuildContext context) {
    final filtered =
        manifest.endpoints.homeSections.where((s) => s.isAnime).toList();
    return _buildSections(filtered);
  }

  @override
  RxList<Widget> mangaWidgets(BuildContext context) {
    final filtered =
        manifest.endpoints.homeSections.where((s) => !s.isAnime).toList();
    return _buildSections(filtered);
  }

  @override
  RxList<Widget> novelWidgets(BuildContext context) {
    return <Widget>[].obs;
  }

  RxList<Widget> _buildSections(List<HomeSectionConfig> sections) {
    final list = <Widget>[].obs;
    for (final sec in sections) {
      sectionData.putIfAbsent(sec.title, () => <Media>[].obs);
      final rxList = sectionData[sec.title]!;

      const variant = DataVariant.regular;

      list.add(Obx(() => buildSection(
            sec.title,
            rxList.toList(),
            variant: variant,
            type: sec.isAnime ? ItemType.anime : ItemType.manga,
            isLoading: !_isDataLoaded && rxList.isEmpty,
          )));
    }
    return list;
  }

  @override
  void clearState() {
    sectionData.clear();
    _isDataLoaded = false;
  }
}
