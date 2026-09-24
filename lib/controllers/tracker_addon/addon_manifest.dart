import 'dart:convert';

/// Authentication strategy supported by a tracker add-on.
enum AuthType {
  oauth2,
  token,
  credentials;

  static AuthType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'oauth2':
        return AuthType.oauth2;
      case 'token':
      case 'api_key':
      case 'bearer':
        return AuthType.token;
      case 'credentials':
      case 'password':
      case 'oauth2_password':
        return AuthType.credentials;
      default:
        return AuthType.token;
    }
  }

  String get label {
    switch (this) {
      case AuthType.oauth2:
        return 'OAuth2';
      case AuthType.token:
        return 'API Token';
      case AuthType.credentials:
        return 'Username & Password';
    }
  }
}

/// Authentication configuration details.
class AuthConfig {
  final AuthType type;
  final String? authUrl;
  final String? tokenUrl;
  final String? clientId;
  final String? clientSecret;
  final String? redirectUri;
  final String? scopes;
  final String? tokenHeader;
  final String? tokenPrefix;
  final String? tokenResponsePath;
  final String? refreshTokenPath;
  final String? loginUrl;
  final Map<String, dynamic>? bodyTemplate;
  final String? instructionsUrl;

  const AuthConfig({
    required this.type,
    this.authUrl,
    this.tokenUrl,
    this.clientId,
    this.clientSecret,
    this.redirectUri,
    this.scopes,
    this.tokenHeader,
    this.tokenPrefix,
    this.tokenResponsePath,
    this.refreshTokenPath,
    this.loginUrl,
    this.bodyTemplate,
    this.instructionsUrl,
  });

  factory AuthConfig.fromJson(Map<String, dynamic> json) {
    return AuthConfig(
      type: AuthType.fromString(json['type'] as String?),
      authUrl: json['auth_url'] as String?,
      tokenUrl: json['token_url'] as String?,
      clientId: json['client_id'] as String?,
      clientSecret: json['client_secret'] as String?,
      redirectUri: json['redirect_uri'] as String?,
      scopes: json['scopes'] as String?,
      tokenHeader: json['token_header'] as String? ?? 'Authorization',
      tokenPrefix: json['token_prefix'] as String? ?? 'Bearer ',
      tokenResponsePath: json['token_response_path'] as String?,
      refreshTokenPath: json['refresh_token_path'] as String?,
      loginUrl: json['login_url'] as String?,
      bodyTemplate: json['body_template'] as Map<String, dynamic>?,
      instructionsUrl: json['instructions_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (authUrl != null) 'auth_url': authUrl,
        if (tokenUrl != null) 'token_url': tokenUrl,
        if (clientId != null) 'client_id': clientId,
        if (clientSecret != null) 'client_secret': clientSecret,
        if (redirectUri != null) 'redirect_uri': redirectUri,
        if (scopes != null) 'scopes': scopes,
        if (tokenHeader != null) 'token_header': tokenHeader,
        if (tokenPrefix != null) 'token_prefix': tokenPrefix,
        if (tokenResponsePath != null)
          'token_response_path': tokenResponsePath,
        if (refreshTokenPath != null)
          'refresh_token_path': refreshTokenPath,
        if (loginUrl != null) 'login_url': loginUrl,
        if (bodyTemplate != null) 'body_template': bodyTemplate,
        if (instructionsUrl != null) 'instructions_url': instructionsUrl,
      };
}

/// Global API configuration.
class ApiConfig {
  final String baseUrl;
  final Map<String, String>? headers;
  final String? contentType;

  const ApiConfig({
    required this.baseUrl,
    this.headers,
    this.contentType,
  });

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    return ApiConfig(
      baseUrl: json['base_url'] as String? ?? '',
      headers: _mapString(json['headers']),
      contentType: json['content_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'base_url': baseUrl,
        if (headers != null) 'headers': headers,
        if (contentType != null) 'content_type': contentType,
      };
}

/// A home carousel section description.
class HomeSectionConfig {
  final String title;
  final String url;
  final bool isAnime;
  final String variant; // 'regular', 'cover', 'big'
  final String? itemsPath;

  const HomeSectionConfig({
    required this.title,
    required this.url,
    this.isAnime = true,
    this.variant = 'regular',
    this.itemsPath,
  });

  factory HomeSectionConfig.fromJson(Map<String, dynamic> json) {
    return HomeSectionConfig(
      title: json['title'] as String? ?? 'Trending',
      url: json['url'] as String? ?? '',
      isAnime: json['is_anime'] as bool? ?? true,
      variant: json['variant'] as String? ?? 'regular',
      itemsPath: json['items_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'is_anime': isAnime,
        'variant': variant,
        if (itemsPath != null) 'items_path': itemsPath,
      };
}

/// Generic endpoint specification.
class EndpointConfig {
  final String url;
  final String method;
  final String? responsePath;
  final String? itemsPath;
  final int? limit;
  final Map<String, String>? mapping;
  final Map<String, dynamic>? bodyTemplate;

  const EndpointConfig({
    required this.url,
    this.method = 'GET',
    this.responsePath,
    this.itemsPath,
    this.limit,
    this.mapping,
    this.bodyTemplate,
  });

  factory EndpointConfig.fromJson(Map<String, dynamic> json) {
    return EndpointConfig(
      url: json['url'] as String? ?? '',
      method: (json['method'] as String?)?.toUpperCase() ?? 'GET',
      responsePath: json['response_path'] as String?,
      itemsPath: json['items_path'] as String?,
      limit: json['limit'] as int?,
      mapping: _mapString(json['mapping']),
      bodyTemplate: json['body_template'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'method': method,
        if (responsePath != null) 'response_path': responsePath,
        if (itemsPath != null) 'items_path': itemsPath,
        if (limit != null) 'limit': limit,
        if (mapping != null) 'mapping': mapping,
        if (bodyTemplate != null) 'body_template': bodyTemplate,
      };
}

/// Collection of all endpoint definitions for the add-on.
class EndpointsConfig {
  final List<HomeSectionConfig> homeSections;
  final EndpointConfig? search;
  final EndpointConfig? details;
  final EndpointConfig? userProfile;
  final EndpointConfig? userLibrary;
  final EndpointConfig? createEntry;
  final EndpointConfig? updateEntry;
  final EndpointConfig? deleteEntry;
  final EndpointConfig? calendar;

  const EndpointsConfig({
    this.homeSections = const [],
    this.search,
    this.details,
    this.userProfile,
    this.userLibrary,
    this.createEntry,
    this.updateEntry,
    this.deleteEntry,
    this.calendar,
  });

  factory EndpointsConfig.fromJson(Map<String, dynamic> json) {
    final sectionsRaw = json['home_sections'] as List<dynamic>?;
    final sections = sectionsRaw
            ?.map((e) => HomeSectionConfig.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return EndpointsConfig(
      homeSections: sections,
      search: _endpoint(json['search']),
      details: _endpoint(json['details']),
      userProfile: _endpoint(json['user_profile']),
      userLibrary: _endpoint(json['user_library']),
      createEntry: _endpoint(json['create_entry']),
      updateEntry: _endpoint(json['update_entry']),
      deleteEntry: _endpoint(json['delete_entry']),
      calendar: _endpoint(json['calendar']),
    );
  }

  static EndpointConfig? _endpoint(dynamic json) {
    if (json == null || json is! Map<String, dynamic>) return null;
    return EndpointConfig.fromJson(json);
  }

  Map<String, dynamic> toJson() => {
        'home_sections': homeSections.map((e) => e.toJson()).toList(),
        if (search != null) 'search': search!.toJson(),
        if (details != null) 'details': details!.toJson(),
        if (userProfile != null) 'user_profile': userProfile!.toJson(),
        if (userLibrary != null) 'user_library': userLibrary!.toJson(),
        if (createEntry != null) 'create_entry': createEntry!.toJson(),
        if (updateEntry != null) 'update_entry': updateEntry!.toJson(),
        if (deleteEntry != null) 'delete_entry': deleteEntry!.toJson(),
        if (calendar != null) 'calendar': calendar!.toJson(),
      };
}

/// Top-level Tracker Add-on Manifest.
class AddonManifest {
  final String id;
  final String name;
  final String version;
  final String? author;
  final String? description;
  final String color;
  final String? icon;
  final List<String> capabilities;
  final AuthConfig auth;
  final ApiConfig api;
  final EndpointsConfig endpoints;
  final Map<String, String> statusMap;
  final Map<String, String> reverseStatusMap;

  bool get supportsAnime =>
      capabilities.contains('anime') || capabilities.contains('all');
  bool get supportsManga =>
      capabilities.contains('manga') || capabilities.contains('all');
  bool get supportsNovel =>
      capabilities.contains('novel') || capabilities.contains('all');
  bool get supportsMovie =>
      capabilities.contains('movie') ||
      capabilities.contains('movies') ||
      capabilities.contains('all');
  bool get supportsTv =>
      capabilities.contains('tv') ||
      capabilities.contains('shows') ||
      capabilities.contains('all');

  const AddonManifest({
    required this.id,
    required this.name,
    required this.version,
    this.author,
    this.description,
    required this.color,
    this.icon,
    required this.capabilities,
    required this.auth,
    required this.api,
    required this.endpoints,
    required this.statusMap,
    required this.reverseStatusMap,
  });

  factory AddonManifest.fromJson(Map<String, dynamic> json) {
    final sMap = _mapString(json['status_map']) ?? <String, String>{};
    final revMap = _mapString(json['reverse_status_map']) ??
        {for (final e in sMap.entries) e.value: e.key};

    return AddonManifest(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
      author: json['author'] as String?,
      description: json['description'] as String?,
      color: json['color'] as String? ?? '#7E57C2',
      icon: json['icon'] as String?,
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['anime'],
      auth: AuthConfig.fromJson(
          json['auth'] as Map<String, dynamic>? ?? {}),
      api: ApiConfig.fromJson(
          json['api'] as Map<String, dynamic>? ?? {}),
      endpoints: EndpointsConfig.fromJson(
          json['endpoints'] as Map<String, dynamic>? ?? {}),
      statusMap: sMap,
      reverseStatusMap: revMap,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        if (author != null) 'author': author,
        if (description != null) 'description': description,
        'color': color,
        if (icon != null) 'icon': icon,
        'capabilities': capabilities,
        'auth': auth.toJson(),
        'api': api.toJson(),
        'endpoints': endpoints.toJson(),
        'status_map': statusMap,
        'reverse_status_map': reverseStatusMap,
      };

  static AddonManifest? tryParse(String jsonStr) {
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return AddonManifest.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

Map<String, String>? _mapString(dynamic json) {
  if (json == null) return null;
  if (json is Map<String, String>) return json;
  if (json is Map) {
    return json.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
  }
  return null;
}
