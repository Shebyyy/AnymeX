import 'dart:convert';

/// Supported authentication types for tracker add-ons.
enum AuthType {
  oauth2,
  apiKey,
  basic,
  token,
}

/// Authentication configuration.
class AuthConfig {
  final AuthType type;
  final String? authorizeUrl;
  final String? tokenUrl;
  final String? redirectUri;
  final String? clientId;
  final String? clientSecret;
  final String? scopes;
  final String? apiKeyHeader;
  final Map<String, String>? tokenExchangeBody;

  const AuthConfig({
    required this.type,
    this.authorizeUrl,
    this.tokenUrl,
    this.redirectUri,
    this.clientId,
    this.clientSecret,
    this.scopes,
    this.apiKeyHeader,
    this.tokenExchangeBody,
  });

  factory AuthConfig.fromJson(Map<String, dynamic> json) {
    return AuthConfig(
      type: _parseAuthType(json['type'] as String?),
      authorizeUrl: json['authorize_url'] as String?,
      tokenUrl: json['token_url'] as String?,
      redirectUri: json['redirect_uri'] as String?,
      clientId: json['client_id'] as String?,
      clientSecret: json['client_secret'] as String?,
      scopes: json['scopes'] as String?,
      apiKeyHeader: json['api_key_header'] as String?,
      tokenExchangeBody: _mapFromStringDynamic(json['token_exchange_body']),
    );
  }

  static AuthType _parseAuthType(String? type) {
    switch (type?.toLowerCase()) {
      case 'oauth2':
        return AuthType.oauth2;
      case 'api_key':
      case 'apikey':
        return AuthType.apiKey;
      case 'basic':
        return AuthType.basic;
      case 'token':
        return AuthType.token;
      default:
        return AuthType.apiKey;
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        if (authorizeUrl != null) 'authorize_url': authorizeUrl,
        if (tokenUrl != null) 'token_url': tokenUrl,
        if (redirectUri != null) 'redirect_uri': redirectUri,
        if (clientId != null) 'client_id': clientId,
        if (clientSecret != null) 'client_secret': clientSecret,
        if (scopes != null) 'scopes': scopes,
        if (apiKeyHeader != null) 'api_key_header': apiKeyHeader,
        if (tokenExchangeBody != null)
          'token_exchange_body': tokenExchangeBody,
      };
}

/// API configuration (base URL, default headers, content type).
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
      headers: _mapFromString(json['headers']),
      contentType: json['content_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'base_url': baseUrl,
        if (headers != null) 'headers': headers,
        if (contentType != null) 'content_type': contentType,
      };
}

/// Configuration for a single API endpoint.
class EndpointConfig {
  final String url;
  final String method;
  final String? responsePath;
  final String? idPath;
  final Map<String, String>? mapping;
  final Map<String, String>? bodyTemplate;
  final bool? isAnime;

  const EndpointConfig({
    required this.url,
    this.method = 'GET',
    this.responsePath,
    this.idPath,
    this.mapping,
    this.bodyTemplate,
    this.isAnime,
  });

  factory EndpointConfig.fromJson(Map<String, dynamic> json) {
    return EndpointConfig(
      url: json['url'] as String? ?? '',
      method: (json['method'] as String?)?.toUpperCase() ?? 'GET',
      responsePath: json['response_path'] as String?,
      idPath: json['id_path'] as String?,
      mapping: _mapFromString(json['mapping']),
      bodyTemplate: _mapFromString(json['body_template']),
      isAnime: json['is_anime'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'method': method,
        if (responsePath != null) 'response_path': responsePath,
        if (idPath != null) 'id_path': idPath,
        if (mapping != null) 'mapping': mapping,
        if (bodyTemplate != null) 'body_template': bodyTemplate,
        if (isAnime != null) 'is_anime': isAnime,
      };
}

/// All endpoint configurations for a tracker.
class EndpointsConfig {
  final EndpointConfig? search;
  final EndpointConfig? userProfile;
  final EndpointConfig? userList;
  final EndpointConfig? updateEntry;
  final EndpointConfig? addEntry;
  final EndpointConfig? deleteEntry;

  const EndpointsConfig({
    this.search,
    this.userProfile,
    this.userList,
    this.updateEntry,
    this.addEntry,
    this.deleteEntry,
  });

  factory EndpointsConfig.fromJson(Map<String, dynamic> json) {
    return EndpointsConfig(
      search: _endpointFromJson(json['search']),
      userProfile: _endpointFromJson(json['user_profile']),
      userList: _endpointFromJson(json['user_list']),
      updateEntry: _endpointFromJson(json['update_entry']),
      addEntry: _endpointFromJson(json['add_entry']),
      deleteEntry: _endpointFromJson(json['delete_entry']),
    );
  }

  static EndpointConfig? _endpointFromJson(dynamic json) {
    if (json == null) return null;
    return EndpointConfig.fromJson(json as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
        if (search != null) 'search': search!.toJson(),
        if (userProfile != null) 'user_profile': userProfile!.toJson(),
        if (userList != null) 'user_list': userList!.toJson(),
        if (updateEntry != null) 'update_entry': updateEntry!.toJson(),
        if (addEntry != null) 'add_entry': addEntry!.toJson(),
        if (deleteEntry != null) 'delete_entry': deleteEntry!.toJson(),
      };
}

/// The top-level manifest that fully describes a tracker add-on.
///
/// Example JSON:
/// ```json
/// {
///   "id": "kitsu",
///   "name": "Kitsu",
///   "version": "1.0.0",
///   "description": "Track anime on Kitsu.io",
///   "color": "#FD6585",
///   "icon": "https://kitsu.io/favicon.ico",
///   "capabilities": ["anime", "manga"],
///   "auth": { ... },
///   "api": { ... },
///   "endpoints": { ... },
///   "status_map": { ... }
/// }
/// ```
class TrackerManifest {
  final String id;
  final String name;
  final String version;
  final String? description;
  final String color;
  final String? icon;
  final List<String> capabilities;
  final AuthConfig auth;
  final ApiConfig api;
  final EndpointsConfig endpoints;
  final Map<String, String> statusMap;
  final Map<String, String>? reverseStatusMap;

  bool get supportsAnime =>
      capabilities.contains('anime') || capabilities.contains('all');
  bool get supportsManga =>
      capabilities.contains('manga') || capabilities.contains('all');

  const TrackerManifest({
    required this.id,
    required this.name,
    required this.version,
    this.description,
    required this.color,
    this.icon,
    required this.capabilities,
    required this.auth,
    required this.api,
    required this.endpoints,
    required this.statusMap,
    this.reverseStatusMap,
  });

  factory TrackerManifest.fromJson(Map<String, dynamic> json) {
    final statusMap =
        _mapFromString(json['status_map']) ?? <String, String>{};
    Map<String, String>? reverseStatusMap;
    if (json['reverse_status_map'] != null) {
      reverseStatusMap =
          _mapFromString(json['reverse_status_map']);
    }

    return TrackerManifest(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
      description: json['description'] as String?,
      color: json['color'] as String? ?? '#666666',
      icon: json['icon'] as String?,
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      auth: AuthConfig.fromJson(
          json['auth'] as Map<String, dynamic>? ?? {}),
      api: ApiConfig.fromJson(
          json['api'] as Map<String, dynamic>? ?? {}),
      endpoints: EndpointsConfig.fromJson(
          json['endpoints'] as Map<String, dynamic>? ?? {}),
      statusMap: statusMap,
      reverseStatusMap: reverseStatusMap ?? _buildReverse(statusMap),
    );
  }

  /// Build the reverse status map automatically if not provided.
  static Map<String, String> _buildReverse(
      Map<String, String> statusMap) {
    final reverse = <String, String>{};
    for (final entry in statusMap.entries) {
      reverse[entry.value] = entry.key;
    }
    return reverse;
  }

  /// Serialize to a JSON string (for sharing/exporting manifests).
  String toJson() {
    return jsonEncode(toMap());
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'version': version,
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

  /// Parse a JSON string into a TrackerManifest.
  static TrackerManifest? tryParse(String jsonStr) {
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return TrackerManifest.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────

Map<String, String>? _mapFromString(dynamic json) {
  if (json == null) return null;
  if (json is Map<String, String>) return json;
  if (json is Map) {
    return json.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
  }
  return null;
}

Map<String, dynamic>? _mapFromStringDynamic(dynamic json) {
  if (json == null) return null;
  if (json is Map<String, dynamic>) return json;
  if (json is Map) {
    return json.map((k, v) => MapEntry(k.toString(), v));
  }
  return null;
}
