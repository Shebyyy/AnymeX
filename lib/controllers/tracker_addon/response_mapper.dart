/// Utility for resolving dot-notation paths in API response maps.
///
/// Examples:
/// - `data` → `response['data']`
/// - `data[0].title` → `response['data'][0]['title']`
/// - `data.attributes.coverImage.large` → deep nested
/// - `data.user.name` → `response['data']['user']['name']`
class ResponseMapper {
  /// Resolve a value from a nested map using dot-notation path.
  /// Supports array index notation: `data[0].name`
  static dynamic resolve(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return data;

    final parts = _splitPath(path);
    dynamic current = data;

    for (final part in parts) {
      if (current == null) return null;

      // Handle array index: "items[0]"
      final arrayMatch = RegExp(r'^(.+?)\[(\d+)\]$').firstMatch(part);
      if (arrayMatch != null) {
        final key = arrayMatch.group(1)!;
        final index = int.parse(arrayMatch.group(2)!);
        if (current is Map) {
          current = current[key];
        }
        if (current is List && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  /// Resolve a string value from a path.
  static String? resolveString(dynamic data, String path) {
    final val = resolve(data is Map<String, dynamic> ? data : {}, path);
    return val?.toString();
  }

  /// Resolve an int value from a path.
  static int? resolveInt(dynamic data, String path) {
    final val = resolve(data is Map<String, dynamic> ? data : {}, path);
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }

  /// Resolve a double value from a path.
  static double? resolveDouble(dynamic data, String path) {
    final val = resolve(data is Map<String, dynamic> ? data : {}, path);
    if (val is double) return val;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  /// Resolve a bool value from a path.
  static bool? resolveBool(dynamic data, String path) {
    final val = resolve(data is Map<String, dynamic> ? data : {}, path);
    if (val is bool) return val;
    return null;
  }
  /// Map a list of items from a response using path + field mapping.
  ///
  /// [response] The parsed JSON response.
  /// [responsePath] Dot-notation path to the list (e.g. `data` or `data[0].relationships.entries`).
  /// [mapping] Maps output keys to input paths, e.g.
  ///   `{'title': 'attributes.canonicalTitle', 'poster': 'attributes.posterImage.medium'}`
  static List<Map<String, dynamic>> mapList(
    Map<String, dynamic> response,
    String? responsePath,
    Map<String, String> mapping,
  ) {
    // Navigate to the list
    dynamic listData;
    if (responsePath != null && responsePath.isNotEmpty) {
      listData = resolve(response, responsePath);
    } else {
      listData = response;
    }

    if (listData == null) return [];

    List items;
    if (listData is List) {
      items = listData;
    } else {
      return [];
    }

    return items.map((item) {
      if (item is! Map) return <String, dynamic>{};
      final itemMap = _toStringMap(item);
      return _applyMapping(itemMap, mapping);
    }).toList();
  }

  /// Build a URL with query parameter substitution.
  ///
  /// Replaces `{key}` placeholders in [urlTemplate] with values from [params].
  /// Prepends [baseUrl] if [urlTemplate] doesn't start with http.
  static String buildUrl(
    String urlTemplate, {
    Map<String, String> params = const {},
    String? baseUrl,
  }) {
    var url = urlTemplate;

    // Replace {param} placeholders
    for (final entry in params.entries) {
      url = url.replaceAll('{${entry.key}}', entry.value);
    }

    // Prepend base URL if needed
    if (baseUrl != null &&
        baseUrl.isNotEmpty &&
        !url.startsWith('http')) {
      url = '$baseUrl${url.startsWith('/') ? '' : '/'}$url';
    }

    return url;
  }

  /// Build headers with auth token injection.
  ///
  /// Merges [defaultHeaders] with auth headers.
  /// If [accessToken] is provided, uses Bearer token.
  /// If [apiKey] + [apiKeyHeader] are provided, uses custom header.
  static Map<String, String> buildHeaders(
    Map<String, String>? defaultHeaders, {
    String? accessToken,
    String? apiKey,
    String? apiKeyHeader,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (defaultHeaders != null) {
      headers.addAll(defaultHeaders);
    }

    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    if (apiKey != null &&
        apiKey.isNotEmpty &&
        apiKeyHeader != null &&
        apiKeyHeader.isNotEmpty) {
      headers[apiKeyHeader] = apiKey;
    }

    return headers;
  }

  /// Build a request body from a template.
  ///
  /// Replaces `{key}` placeholders in template values with params.
  static Map<String, dynamic> buildBody(
    Map<String, String> bodyTemplate, {
    Map<String, dynamic> params = const {},
  }) {
    final body = <String, dynamic>{};
    for (final entry in bodyTemplate.entries) {
      var value = entry.value;
      for (final param in params.entries) {
        value =
            value.replaceAll('{${param.key}}', param.value.toString());
      }
      // Try to parse as number or bool
      body[entry.key] = _parseValue(value);
    }
    return body;
  }

  // ── Internal helpers ──────────────────────────────────────────

  /// Split a dot-notation path, respecting array brackets.
  static List<String> _splitPath(String path) {
    final parts = <String>[];
    final buffer = StringBuffer();

    for (var i = 0; i < path.length; i++) {
      final ch = path[i];
      if (ch == '.') {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(ch);
      }
    }
    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }

    return parts;
  }

  /// Apply field mapping to a data item.
  static Map<String, dynamic> _applyMapping(
    Map<String, dynamic> data,
    Map<String, String> mapping,
  ) {
    final result = <String, dynamic>{};
    for (final entry in mapping.entries) {
      final outputPath = entry.key;
      final inputPath = entry.value;
      result[outputPath] = resolve(data, inputPath);
    }
    // Also include any direct fields from data that aren't in mapping
    // (for backward compatibility and raw access)
    for (final key in data.keys) {
      if (!result.containsKey(key)) {
        result[key] = data[key];
      }
    }
    return result;
  }

  /// Try to parse a string value to its appropriate type.
  static dynamic _parseValue(String value) {
    if (value == 'true') return true;
    if (value == 'false') return false;
    final asInt = int.tryParse(value);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(value);
    if (asDouble != null) return asDouble;
    return value;
  }

  /// Convert a dynamic Map to Map<String, dynamic>.
  static Map<String, dynamic> _toStringMap(dynamic map) {
    if (map is Map<String, dynamic>) return map;
    if (map is Map) {
      return map.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }
}
