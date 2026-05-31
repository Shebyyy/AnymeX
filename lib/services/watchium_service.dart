import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/models/Anilist/anilist_profile.dart';
import 'package:anymex/utils/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Data Models
// ---------------------------------------------------------------------------

/// A single video URL entry inside [WatchiumRoom.videoUrls].
class WatchiumVideoUrl {
  final String url;
  final String quality;
  final String? originalUrl;

  WatchiumVideoUrl({
    required this.url,
    required this.quality,
    this.originalUrl,
  });

  factory WatchiumVideoUrl.fromJson(Map<String, dynamic> json) =>
      WatchiumVideoUrl(
        url: json['url']?.toString() ?? '',
        quality: json['quality']?.toString() ?? '',
        originalUrl: json['originalUrl']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'quality': quality,
        if (originalUrl != null) 'originalUrl': originalUrl,
      };
}

/// Represents a Watchium watch-together room.
class WatchiumRoom {
  final String? roomId;
  final String? title;
  final String? animeId;
  final String? animeTitle;
  final int? episodeNumber;
  final String? videoUrl;
  final List<WatchiumVideoUrl> videoUrls;
  final String? sourceId;
  final String? anilistId;
  final String? malId;
  final String? simklId;
  final String? hostUserId;
  final String? hostUsername;
  final bool? isPublic;
  final String? accessKey;
  final String? realtimeChannel;
  final String? presenceKey;
  final double? currentTime;
  final bool? isPlaying;
  final int? memberCount;
  final String? createdAt;
  final String? updatedAt;

  WatchiumRoom({
    this.roomId,
    this.title,
    this.animeId,
    this.animeTitle,
    this.episodeNumber,
    this.videoUrl,
    this.videoUrls = const [],
    this.sourceId,
    this.anilistId,
    this.malId,
    this.simklId,
    this.hostUserId,
    this.hostUsername,
    this.isPublic,
    this.accessKey,
    this.realtimeChannel,
    this.presenceKey,
    this.currentTime,
    this.isPlaying,
    this.memberCount,
    this.createdAt,
    this.updatedAt,
  });

  factory WatchiumRoom.fromJson(Map<String, dynamic> json) {
    return WatchiumRoom(
      roomId: json['room_id']?.toString(),
      title: json['title']?.toString(),
      animeId: json['anime_id']?.toString(),
      animeTitle: json['anime_title']?.toString(),
      episodeNumber: (json['episode_number'] as num?)?.toInt(),
      videoUrl: json['video_url']?.toString(),
      videoUrls: (json['video_urls'] as List<dynamic>?)
              ?.map((e) => WatchiumVideoUrl.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sourceId: json['source_id']?.toString(),
      anilistId: json['anilist_id']?.toString(),
      malId: json['mal_id']?.toString(),
      simklId: json['simkl_id']?.toString(),
      hostUserId: json['host_user_id']?.toString(),
      hostUsername: json['host_username']?.toString(),
      isPublic: json['is_public'] as bool?,
      accessKey: json['access_key']?.toString(),
      realtimeChannel: json['realtime_channel']?.toString(),
      presenceKey: json['presence_key']?.toString(),
      currentTime: (json['current_time'] as num?)?.toDouble(),
      isPlaying: json['is_playing'] as bool?,
      memberCount: (json['member_count'] as num?)?.toInt(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (roomId != null) 'room_id': roomId,
        if (title != null) 'title': title,
        if (animeId != null) 'anime_id': animeId,
        if (animeTitle != null) 'anime_title': animeTitle,
        if (episodeNumber != null) 'episode_number': episodeNumber,
        if (videoUrl != null) 'video_url': videoUrl,
        if (videoUrls.isNotEmpty) 'video_urls': videoUrls.map((e) => e.toJson()).toList(),
        if (sourceId != null) 'source_id': sourceId,
        if (anilistId != null) 'anilist_id': anilistId,
        if (malId != null) 'mal_id': malId,
        if (simklId != null) 'simkl_id': simklId,
        if (hostUserId != null) 'host_user_id': hostUserId,
        if (hostUsername != null) 'host_username': hostUsername,
        if (isPublic != null) 'is_public': isPublic,
        if (accessKey != null) 'access_key': accessKey,
        if (realtimeChannel != null) 'realtime_channel': realtimeChannel,
        if (presenceKey != null) 'presence_key': presenceKey,
        if (currentTime != null) 'current_time': currentTime,
        if (isPlaying != null) 'is_playing': isPlaying,
        if (memberCount != null) 'member_count': memberCount,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };

  WatchiumRoom copyWith({
    String? roomId,
    String? title,
    String? animeId,
    String? animeTitle,
    int? episodeNumber,
    String? videoUrl,
    List<WatchiumVideoUrl>? videoUrls,
    String? sourceId,
    String? anilistId,
    String? malId,
    String? simklId,
    String? hostUserId,
    String? hostUsername,
    bool? isPublic,
    String? accessKey,
    String? realtimeChannel,
    String? presenceKey,
    double? currentTime,
    bool? isPlaying,
    int? memberCount,
    String? createdAt,
    String? updatedAt,
  }) {
    return WatchiumRoom(
      roomId: roomId ?? this.roomId,
      title: title ?? this.title,
      animeId: animeId ?? this.animeId,
      animeTitle: animeTitle ?? this.animeTitle,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      videoUrl: videoUrl ?? this.videoUrl,
      videoUrls: videoUrls ?? this.videoUrls,
      sourceId: sourceId ?? this.sourceId,
      anilistId: anilistId ?? this.anilistId,
      malId: malId ?? this.malId,
      simklId: simklId ?? this.simklId,
      hostUserId: hostUserId ?? this.hostUserId,
      hostUsername: hostUsername ?? this.hostUsername,
      isPublic: isPublic ?? this.isPublic,
      accessKey: accessKey ?? this.accessKey,
      realtimeChannel: realtimeChannel ?? this.realtimeChannel,
      presenceKey: presenceKey ?? this.presenceKey,
      currentTime: currentTime ?? this.currentTime,
      isPlaying: isPlaying ?? this.isPlaying,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Represents a member inside a Watchium room.
class WatchiumMember {
  final String? userId;
  final String? username;
  final String? avatarUrl;
  final String? roomId;
  final bool? isHost;
  final double? currentPlaybackTime;
  final bool? isSynced;
  final String? joinedAt;
  final String? lastActiveAt;

  WatchiumMember({
    this.userId,
    this.username,
    this.avatarUrl,
    this.roomId,
    this.isHost,
    this.currentPlaybackTime,
    this.isSynced,
    this.joinedAt,
    this.lastActiveAt,
  });

  factory WatchiumMember.fromJson(Map<String, dynamic> json) {
    return WatchiumMember(
      userId: json['user_id']?.toString(),
      username: json['username']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      roomId: json['room_id']?.toString(),
      isHost: json['is_host'] as bool?,
      currentPlaybackTime: (json['current_playback_time'] as num?)?.toDouble(),
      isSynced: json['is_synced'] as bool?,
      joinedAt: json['joined_at']?.toString(),
      lastActiveAt: json['last_active_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (userId != null) 'user_id': userId,
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (roomId != null) 'room_id': roomId,
        if (isHost != null) 'is_host': isHost,
        if (currentPlaybackTime != null)
          'current_playback_time': currentPlaybackTime,
        if (isSynced != null) 'is_synced': isSynced,
        if (joinedAt != null) 'joined_at': joinedAt,
        if (lastActiveAt != null) 'last_active_at': lastActiveAt,
      };
}

/// Represents a comment in a Watchium room or episode thread.
class WatchiumComment {
  final String? id;
  final String? animeId;
  final String? roomId;
  final int? episodeNumber;
  final String? parentId;
  final String? userId;
  final String? username;
  final String? avatarUrl;
  final String? message;
  final double? videoTimestamp;
  final String? createdAt;

  WatchiumComment({
    this.id,
    this.animeId,
    this.roomId,
    this.episodeNumber,
    this.parentId,
    this.userId,
    this.username,
    this.avatarUrl,
    this.message,
    this.videoTimestamp,
    this.createdAt,
  });

  factory WatchiumComment.fromJson(Map<String, dynamic> json) {
    return WatchiumComment(
      id: json['id']?.toString(),
      animeId: json['anime_id']?.toString(),
      roomId: json['room_id']?.toString(),
      episodeNumber: (json['episode_number'] as num?)?.toInt(),
      parentId: json['parent_id']?.toString(),
      userId: json['user_id']?.toString(),
      username: json['username']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      message: json['message']?.toString(),
      videoTimestamp: (json['video_timestamp'] as num?)?.toDouble(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (animeId != null) 'anime_id': animeId,
        if (roomId != null) 'room_id': roomId,
        if (episodeNumber != null) 'episode_number': episodeNumber,
        if (parentId != null) 'parent_id': parentId,
        if (userId != null) 'user_id': userId,
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (message != null) 'message': message,
        if (videoTimestamp != null) 'video_timestamp': videoTimestamp,
        if (createdAt != null) 'created_at': createdAt,
      };
}

/// Tracks the client's current playback sync state.
class WatchiumSyncState {
  double currentTime;
  bool isPlaying;
  double playbackSpeed;
  DateTime? lastSyncedAt;
  bool isSynced;

  WatchiumSyncState({
    this.currentTime = 0.0,
    this.isPlaying = false,
    this.playbackSpeed = 1.0,
    this.lastSyncedAt,
    this.isSynced = false,
  });

  WatchiumSyncState copyWith({
    double? currentTime,
    bool? isPlaying,
    double? playbackSpeed,
    DateTime? lastSyncedAt,
    bool? isSynced,
  }) {
    return WatchiumSyncState(
      currentTime: currentTime ?? this.currentTime,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  void reset() {
    currentTime = 0.0;
    isPlaying = false;
    playbackSpeed = 1.0;
    lastSyncedAt = null;
    isSynced = false;
  }

  /// Returns the time difference between client and host in seconds.
  /// Positive means client is ahead, negative means behind.
  /// Returns null if no sync has happened yet.
  double? get syncDifference {
    if (lastSyncedAt == null) return null;
    return currentTime;
  }
}

/// Result wrapper returned by operations that may fail.
class WatchiumResult<T> {
  final T? data;
  final String? error;
  final bool success;

  WatchiumResult({this.data, this.error, this.success = true});

  factory WatchiumResult.success(T data) =>
      WatchiumResult(data: data, success: true);

  factory WatchiumResult.failure(String error) =>
      WatchiumResult(error: error, success: false);
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class WatchiumService extends GetxController {
  // ---------------------------------------------------------------------------
  // Reactive state
  // ---------------------------------------------------------------------------
  final Rx<WatchiumRoom?> currentRoom = Rx<WatchiumRoom?>(null);
  final RxList<WatchiumMember> members = RxList<WatchiumMember>([]);
  final Rx<WatchiumSyncState> syncState =
      Rx<WatchiumSyncState>(WatchiumSyncState());
  final RxBool isInRoom = false.obs;
  final RxBool isHost = false.obs;
  final RxString currentRoomId = ''.obs;
  final RxList<WatchiumComment> roomComments = RxList<WatchiumComment>([]);
  final RxString error = ''.obs;
  final RxBool isLoading = false.obs;

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------
  Timer? _heartbeatTimer;
  static const double _syncThreshold = 2.0; // seconds
  static const double _clientSyncThreshold = 0.1; // seconds
  static const Duration _heartbeatInterval = Duration(seconds: 3);

  /// Persistent anonymous user id (generated once per session).
  static String? _anonymousUserId;

  /// Callback invoked when the service detects a remote playback change that
  /// the player should adopt (position, playing state).
  void Function(double position, bool playing)? onRemotePlaybackChanged;

  /// Callback invoked when the host changes episode. The player should load
  /// the new episode with the given [episodeNumber], [videoUrl], and [sourceId].
  void Function(int episodeNumber, String videoUrl, String? sourceId)? onRemoteEpisodeChanged;

  // ---------------------------------------------------------------------------
  // Identity helpers
  // ---------------------------------------------------------------------------

  Profile? get _currentUser => serviceHandler.profileData.value;

  String get _userId {
    final id = _currentUser?.id;
    if (id != null && id.isNotEmpty) return id;
    _anonymousUserId ??= _generateUuid();
    return _anonymousUserId!;
  }

  String? get _username => _currentUser?.name;

  String? get _avatarUrl => _currentUser?.avatar;

  // ---------------------------------------------------------------------------
  // Network helpers
  // ---------------------------------------------------------------------------

  String get _baseUrl {
    final envBase = (dotenv.env['WATCHIUM_BASE_URL'] ?? '').trim();
    final fallback =
        'https://fzxmrnyepxkdnfuyveaj.supabase.co/functions/v1';
    final raw = envBase.isEmpty ? fallback : envBase;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Performs a POST request and returns the decoded JSON body, or `null`
  /// on failure (errors are logged and optionally surfaced via [error]).
  Future<Map<String, dynamic>?> _post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$path');
      Logger.i('[Watchium] POST $uri');
      final response = await http
          .post(uri, headers: _jsonHeaders, body: json.encode(body ?? {}));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final msg = _tryExtractErrorMessage(response.body);
        final message =
            '[Watchium] POST $path failed (${response.statusCode}): $msg';
        Logger.i(message);
        error.value = message;
        return null;
      }
    } catch (e, st) {
      final message = '[Watchium] POST $path error: $e';
      Logger.e(message, error: e, stackTrace: st);
      error.value = message;
      return null;
    }
  }

  /// Performs a GET request and returns the decoded JSON body, or `null`.
  Future<Map<String, dynamic>?> _get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$path').replace(
          queryParameters: queryParameters != null
              ? {...queryParameters}
              : <String, String>{});
      Logger.i('[Watchium] GET $uri');
      final response = await http.get(uri, headers: _jsonHeaders);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final msg = _tryExtractErrorMessage(response.body);
        final message =
            '[Watchium] GET $path failed (${response.statusCode}): $msg';
        Logger.i(message);
        error.value = message;
        return null;
      }
    } catch (e, st) {
      final message = '[Watchium] GET $path error: $e';
      Logger.e(message, error: e, stackTrace: st);
      error.value = message;
      return null;
    }
  }

  /// Performs a DELETE request and returns the decoded JSON body, or `null`.
  Future<Map<String, dynamic>?> _delete(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$path');
      Logger.i('[Watchium] DELETE $uri');
      final response = await http.delete(uri,
          headers: _jsonHeaders, body: json.encode(body ?? {}));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final msg = _tryExtractErrorMessage(response.body);
        final message =
            '[Watchium] DELETE $path failed (${response.statusCode}): $msg';
        Logger.i(message);
        error.value = message;
        return null;
      }
    } catch (e, st) {
      final message = '[Watchium] DELETE $path error: $e';
      Logger.e(message, error: e, stackTrace: st);
      error.value = message;
      return null;
    }
  }

  String _tryExtractErrorMessage(String body) {
    try {
      final parsed = json.decode(body) as Map<String, dynamic>;
      return parsed['error']?.toString() ??
          parsed['message']?.toString() ??
          body;
    } catch (_) {
      return body;
    }
  }

  // ---------------------------------------------------------------------------
  // UUID helper (no external dependency)
  // ---------------------------------------------------------------------------

  static final Random _rng = Random();

  static String _generateUuid() {
    const hex = '0123456789abcdef';
    final chars = List.generate(36, (i) {
      if (i == 8 || i == 13 || i == 18 || i == 23) return '-';
      if (i == 14) return '4';
      if (i == 19) {
        final n = _rng.nextInt(16);
        return (n < 8 ? hex[n] : hex[n + 4]);
      }
      return hex[_rng.nextInt(16)];
    });
    return chars.join();
  }

  // ---------------------------------------------------------------------------
  // Room CRUD
  // ---------------------------------------------------------------------------

  /// Creates a new Watchium room.
  ///
  /// Returns a [WatchiumResult] containing the created [WatchiumRoom] on
  /// success, or an error message on failure. The caller should use
  /// `result.data?.roomId` and `result.data?.accessKey` for sharing.
  Future<WatchiumResult<WatchiumRoom>> createRoom({
    required String title,
    required String animeId,
    required String animeTitle,
    required int episodeNumber,
    required String videoUrl,
    List<WatchiumVideoUrl>? videoUrls,
    String? sourceId,
    String? anilistId,
    String? malId,
    String? simklId,
    bool isPublic = true,
  }) async {
    isLoading.value = true;
    error.value = '';

    try {
      final body = <String, dynamic>{
        'title': title,
        'anime_id': animeId,
        'anime_title': animeTitle,
        'episode_number': episodeNumber,
        'video_url': videoUrl,
        'host_user_id': _userId,
        'host_username': _username ?? 'Anonymous',
        'is_public': isPublic,
      };
      if (videoUrls != null && videoUrls.isNotEmpty) {
        body['video_urls'] = videoUrls.map((e) => e.toJson()).toList();
      }
      if (sourceId != null && sourceId.isNotEmpty) {
        body['source_id'] = sourceId;
      }
      if (anilistId != null && anilistId.isNotEmpty) {
        body['anilist_id'] = anilistId;
      }
      if (malId != null && malId.isNotEmpty) {
        body['mal_id'] = malId;
      }
      if (simklId != null && simklId.isNotEmpty) {
        body['simkl_id'] = simklId;
      }

      final data = await _post('rooms-create', body: body);
      if (data == null) {
        return WatchiumResult.failure('Failed to create room');
      }

      final roomJson = data['room'] as Map<String, dynamic>?;
      final accessKey = data['access_key']?.toString();
      final realtimeChannel = data['realtime_channel']?.toString();
      final presenceKey = data['presence_key']?.toString();

      final room = WatchiumRoom.fromJson({
        ...?roomJson,
        if (accessKey != null) 'access_key': accessKey,
        if (realtimeChannel != null) 'realtime_channel': realtimeChannel,
        if (presenceKey != null) 'presence_key': presenceKey,
      });

      // Update local state
      currentRoom.value = room;
      currentRoomId.value = room.roomId ?? '';
      isInRoom.value = true;
      isHost.value = true;
      syncState.value = WatchiumSyncState();

      _startHeartbeat();
      Logger.i('[Watchium] Room created: ${room.roomId}');

      return WatchiumResult.success(room);
    } catch (e, st) {
      final msg = '[Watchium] createRoom error: $e';
      Logger.e(msg, error: e, stackTrace: st);
      error.value = msg;
      return WatchiumResult.failure(msg);
    } finally {
      isLoading.value = false;
    }
  }

  /// Joins an existing room by [roomId]. Optionally provide [accessKey]
  /// for private rooms.
  Future<WatchiumResult<WatchiumRoom>> joinRoom(
    String roomId, {
    String? accessKey,
  }) async {
    isLoading.value = true;
    error.value = '';

    try {
      final body = <String, dynamic>{
        'room_id': roomId,
        'user_id': _userId,
        'username': _username ?? 'Anonymous',
        if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
          'avatar_url': _avatarUrl,
      };
      if (accessKey != null && accessKey.isNotEmpty) {
        body['access_key'] = accessKey;
      }

      final data = await _post('rooms-join', body: body);
      if (data == null) {
        return WatchiumResult.failure('Failed to join room');
      }

      final memberJson = data['member'] as Map<String, dynamic>?;
      final roomJson = data['room'] as Map<String, dynamic>?;

      final room = WatchiumRoom.fromJson({
        'room_id': roomId,
        ...?roomJson,
        'access_key': accessKey,
      });

      // Determine if the joining user is the host
      final isUserHost = room.hostUserId != null && room.hostUserId == _userId;

      // Update local state
      currentRoom.value = room;
      currentRoomId.value = roomId;
      isInRoom.value = true;
      isHost.value = isUserHost;
      syncState.value = WatchiumSyncState(
        currentTime: room.currentTime ?? 0.0,
        isPlaying: room.isPlaying ?? false,
      );

      // Fetch members list
      await fetchMembers();

      _startHeartbeat();
      Logger.i('[Watchium] Joined room: $roomId (host=$isUserHost)');

      return WatchiumResult.success(room);
    } catch (e, st) {
      final msg = '[Watchium] joinRoom error: $e';
      Logger.e(msg, error: e, stackTrace: st);
      error.value = msg;
      return WatchiumResult.failure(msg);
    } finally {
      isLoading.value = false;
    }
  }

  /// Leaves the current room. Safe to call even if not in a room.
  Future<bool> leaveRoom() async {
    if (!isInRoom.value || currentRoomId.value.isEmpty) {
      return true;
    }

    _stopHeartbeat();

    try {
      final data = await _post('rooms-leave', body: {
        'room_id': currentRoomId.value,
        'user_id': _userId,
      });

      if (data != null) {
        final wasHost = data['was_host'] as bool? ?? false;
        Logger.i(
            '[Watchium] Left room: ${currentRoomId.value} (was_host=$wasHost)');

        if (wasHost) {
          Logger.i('[Watchium] User was host – room may be deleted or transferred');
        }
      } else {
        Logger.i('[Watchium] Leave room request returned no data (may have already left)');
      }
    } catch (e, st) {
      Logger.e('[Watchium] leaveRoom error: $e', error: e, stackTrace: st);
    }

    _resetState();
    return true;
  }

  /// Deletes the current room entirely. Only the host should call this.
  Future<bool> deleteRoom() async {
    if (currentRoomId.value.isEmpty) {
      Logger.i('[Watchium] deleteRoom: no room to delete');
      return false;
    }

    _stopHeartbeat();

    try {
      final data = await _delete('rooms-delete', body: {
        'room_id': currentRoomId.value,
        'user_id': _userId,
      });

      if (data != null) {
        Logger.i(
            '[Watchium] Room deleted: ${data['room_id'] ?? currentRoomId.value}');
      } else {
        Logger.i('[Watchium] deleteRoom returned no data');
      }
    } catch (e, st) {
      Logger.e('[Watchium] deleteRoom error: $e', error: e, stackTrace: st);
    }

    _resetState();
    return true;
  }

  /// Resets all reactive state to defaults.
  void _resetState() {
    currentRoom.value = null;
    currentRoomId.value = '';
    isInRoom.value = false;
    isHost.value = false;
    members.clear();
    roomComments.clear();
    syncState.value = WatchiumSyncState();
    error.value = '';
  }

  // ---------------------------------------------------------------------------
  // Sync / Playback Control
  // ---------------------------------------------------------------------------

  /// Sends a play/pause/seek control command. Only succeeds when the local
  /// user is the room host.
  ///
  /// [action] must be `'play'`, `'pause'`, or `'seek'`.
  /// [currentTime] is required when [action] is `'seek'`.
  Future<bool> sendPlayControl(
    String action, {
    double? currentTime,
  }) async {
    if (!isInRoom.value) {
      error.value = 'Not in a room';
      return false;
    }
    if (!isHost.value) {
      error.value = 'Only the host can control playback';
      Logger.i('[Watchium] sendPlayControl rejected – not host');
      return false;
    }

    final validActions = ['play', 'pause', 'seek'];
    if (!validActions.contains(action)) {
      error.value = 'Invalid action: $action';
      return false;
    }
    if (action == 'seek' && currentTime == null) {
      error.value = 'current_time is required for seek action';
      return false;
    }

    try {
      final body = <String, dynamic>{
        'room_id': currentRoomId.value,
        'user_id': _userId,
        'action': action,
      };
      if (currentTime != null) {
        body['current_time'] = currentTime;
      }

      final data = await _post('sync-control', body: body);
      if (data == null) return false;

      final roomJson = data['room'] as Map<String, dynamic>?;
      if (roomJson != null) {
        syncState.value = syncState.value.copyWith(
          currentTime: (roomJson['current_playback_time'] as num?)?.toDouble() ??
              syncState.value.currentTime,
          isPlaying: roomJson['is_playing'] as bool? ?? syncState.value.isPlaying,
          lastSyncedAt: DateTime.now(),
        );

        // Update the currentRoom with latest playback info
        currentRoom.value = currentRoom.value?.copyWith(
          currentTime: syncState.value.currentTime,
          isPlaying: syncState.value.isPlaying,
        );
      }

      Logger.i('[Watchium] Sync control sent: $action at ${currentTime ?? syncState.value.currentTime}');
      return true;
    } catch (e, st) {
      Logger.e('[Watchium] sendPlayControl error: $e', error: e, stackTrace: st);
      return false;
    }
  }

  /// Notifies all room members that the host changed to a new episode.
  ///
  /// Updates the room on the server, resets playback to 0, and triggers a
  /// realtime broadcast so other users can switch to the new episode.
  ///
  /// [episodeNumber] is the new episode number (1-based).
  /// [videoUrl] is the stream URL for the new episode.
  /// [sourceId] is the streaming source identifier (optional).
  Future<bool> changeEpisode({
    required int episodeNumber,
    required String videoUrl,
    List<WatchiumVideoUrl>? videoUrls,
    String? sourceId,
    String? title,
    String? animeTitle,
  }) async {
    if (!isInRoom.value) {
      error.value = 'Not in a room';
      return false;
    }
    if (!isHost.value) {
      error.value = 'Only the host can change episodes';
      Logger.i('[Watchium] changeEpisode rejected – not host');
      return false;
    }
    if (episodeNumber < 1) {
      error.value = 'Episode number must be >= 1';
      return false;
    }
    if (videoUrl.isEmpty) {
      error.value = 'Video URL is required';
      return false;
    }

    try {
      final body = <String, dynamic>{
        'room_id': currentRoomId.value,
        'user_id': _userId,
        'action': 'change_episode',
        'episode_number': episodeNumber,
        'video_url': videoUrl,
      };
      if (videoUrls != null && videoUrls.isNotEmpty) {
        body['video_urls'] = videoUrls.map((e) => e.toJson()).toList();
      }
      if (sourceId != null && sourceId.isNotEmpty) {
        body['source_id'] = sourceId;
      }
      if (title != null) {
        body['title'] = title;
      }
      if (animeTitle != null) {
        body['anime_title'] = animeTitle;
      }

      final data = await _post('sync-control', body: body);
      if (data == null) return false;

      // Update local state
      final roomJson = data['room'] as Map<String, dynamic>?;
      if (roomJson != null) {
        final newVideoUrls = (roomJson['video_urls'] as List<dynamic>?)
            ?.map((e) => WatchiumVideoUrl.fromJson(e as Map<String, dynamic>))
            .toList();
        currentRoom.value = currentRoom.value?.copyWith(
          episodeNumber: (roomJson['episode_number'] as num?)?.toInt() ?? episodeNumber,
          videoUrl: roomJson['video_url']?.toString() ?? videoUrl,
          videoUrls: newVideoUrls ?? videoUrls ?? currentRoom.value?.videoUrls,
          sourceId: roomJson['source_id']?.toString() ?? sourceId,
          currentTime: 0.0,
          isPlaying: false,
        );
      } else {
        currentRoom.value = currentRoom.value?.copyWith(
          episodeNumber: episodeNumber,
          videoUrl: videoUrl,
          videoUrls: videoUrls ?? currentRoom.value?.videoUrls,
          sourceId: sourceId,
          currentTime: 0.0,
          isPlaying: false,
        );
      }

      syncState.value = WatchiumSyncState(
        currentTime: 0.0,
        isPlaying: false,
        isSynced: true,
        lastSyncedAt: DateTime.now(),
      );

      // Clear comments and fetch new episode's comments
      roomComments.clear();
      fetchRoomComments();

      Logger.i('[Watchium] Episode changed to $episodeNumber');
      return true;
    } catch (e, st) {
      Logger.e('[Watchium] changeEpisode error: $e', error: e, stackTrace: st);
      return false;
    }
  }

  /// Fetches the host's current playback time and sync status.
  ///
  /// Returns the raw response map on success, or `null` on failure.
  /// Also updates local [syncState] based on the response.
  Future<Map<String, dynamic>?> fetchHostTime() async {
    if (!isInRoom.value) return null;

    try {
      final data = await _get('sync-get-host-time', queryParameters: {
        'room_id': currentRoomId.value,
        'user_id': _userId,
      });
      if (data == null) return null;

      // Parse host time
      final hostTimeJson = data['host_time'] as Map<String, dynamic>?;
      if (hostTimeJson != null) {
        final hostCurrentTime =
            (hostTimeJson['current_time'] as num?)?.toDouble() ?? 0.0;
        final hostIsPlaying = hostTimeJson['is_playing'] as bool? ?? false;
        final hostPlaybackSpeed =
            (hostTimeJson['playback_speed'] as num?)?.toDouble() ?? 1.0;

        syncState.value = syncState.value.copyWith(
          currentTime: hostCurrentTime,
          isPlaying: hostIsPlaying,
          playbackSpeed: hostPlaybackSpeed,
          lastSyncedAt: DateTime.now(),
        );

        // Update room model
        currentRoom.value = currentRoom.value?.copyWith(
          currentTime: hostCurrentTime,
          isPlaying: hostIsPlaying,
        );

        Logger.i(
            '[Watchium] Host time fetched: $hostCurrentTime playing=$hostIsPlaying');
      }

      // Parse sync status
      final syncStatusJson =
          data['user_sync_status'] as Map<String, dynamic>?;
      if (syncStatusJson != null) {
        syncState.value = syncState.value.copyWith(
          isSynced: syncStatusJson['is_synced'] as bool? ?? false,
        );
      }

      return data;
    } catch (e, st) {
      Logger.e('[Watchium] fetchHostTime error: $e', error: e, stackTrace: st);
      return null;
    }
  }

  /// Checks if the user's local playback is in sync with the host.
  bool isUserSynced() {
    return syncState.value.isSynced;
  }

  /// Computes the current time difference between this client and the host.
  ///
  /// Returns `null` if we haven't fetched host time yet.
  double? getTimeDifference() {
    if (currentRoom.value?.currentTime == null) return null;
    return (syncState.value.currentTime -
            (currentRoom.value?.currentTime ?? 0.0))
        .abs();
  }

  // ---------------------------------------------------------------------------
  // Members
  // ---------------------------------------------------------------------------

  /// Fetches the member list for the current room.
  Future<List<WatchiumMember>> fetchMembers() async {
    if (!isInRoom.value) return [];

    try {
      final data = await _get('members-get-list', queryParameters: {
        'room_id': currentRoomId.value,
      });
      if (data == null) return members.toList();

      final membersList = data['members'] as List<dynamic>? ?? [];
      members.assignAll(
        membersList
            .map((m) => WatchiumMember.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

      Logger.i('[Watchium] Fetched ${members.length} members');
      return members.toList();
    } catch (e, st) {
      Logger.e('[Watchium] fetchMembers error: $e', error: e, stackTrace: st);
      return members.toList();
    }
  }

  /// Updates the current user's playback status on the server (heartbeat).
  Future<bool> _updateMemberStatus() async {
    if (!isInRoom.value) return false;

    try {
      await _post('members-update-status', body: {
        'room_id': currentRoomId.value,
        'user_id': _userId,
        'updates': {
          'current_playback_time': syncState.value.currentTime,
          'is_synced': syncState.value.isSynced,
        },
      });
      return true;
    } catch (_) {
      // Heartbeat failures are non-critical
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Public rooms listing
  // ---------------------------------------------------------------------------

  /// Lists public rooms, optionally filtered by [animeId].
  ///
  /// [limit] defaults to 50, [offset] defaults to 0.
  Future<WatchiumResult<List<WatchiumRoom>>> listPublicRooms({
    String? animeId,
    int limit = 50,
    int offset = 0,
  }) async {
    isLoading.value = true;
    error.value = '';

    try {
      final params = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      if (animeId != null && animeId.isNotEmpty) {
        params['anime_id'] = animeId;
      }

      final data = await _get('rooms-list-public', queryParameters: params);
      if (data == null) {
        return WatchiumResult.failure('Failed to list public rooms');
      }

      final roomsList = data['rooms'] as List<dynamic>? ?? [];
      final rooms = roomsList
          .map((r) => WatchiumRoom.fromJson(r as Map<String, dynamic>))
          .toList();

      Logger.i('[Watchium] Listed ${rooms.length} public rooms');
      return WatchiumResult.success(rooms);
    } catch (e, st) {
      final msg = '[Watchium] listPublicRooms error: $e';
      Logger.e(msg, error: e, stackTrace: st);
      error.value = msg;
      return WatchiumResult.failure(msg);
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Comments
  // ---------------------------------------------------------------------------

  /// Fetches comments for the current room's episode (or a given anime/ep).
  ///
  /// If [animeId] and [episodeNumber] are not provided, falls back to the
  /// values from [currentRoom].
  Future<List<WatchiumComment>> fetchRoomComments({
    String? animeId,
    int? episodeNumber,
  }) async {
    final aid = animeId ?? currentRoom.value?.animeId;
    final ep = episodeNumber ?? currentRoom.value?.episodeNumber;
    if (aid == null || ep == null) {
      Logger.i('[Watchium] fetchRoomComments: missing animeId or episodeNumber');
      return roomComments.toList();
    }

    try {
      final params = <String, String>{
        'anime_id': aid,
        'episode_number': ep.toString(),
      };
      if (isInRoom.value && currentRoomId.value.isNotEmpty) {
        params['room_id'] = currentRoomId.value;
      }

      final data = await _get('comments-get-by-episode', queryParameters: params);
      if (data == null) return roomComments.toList();

      final commentsList = data['comments'] as List<dynamic>? ?? [];
      roomComments.assignAll(
        commentsList
            .map((c) => WatchiumComment.fromJson(c as Map<String, dynamic>))
            .toList(),
      );

      Logger.i('[Watchium] Fetched ${roomComments.length} comments');
      return roomComments.toList();
    } catch (e, st) {
      Logger.e(
          '[Watchium] fetchRoomComments error: $e', error: e, stackTrace: st);
      return roomComments.toList();
    }
  }

  /// Sends a comment to the current room.
  ///
  /// [videoTimestamp] is optional and allows attaching a timestamp to the
  /// comment so it appears at the right moment in the episode timeline.
  Future<WatchiumResult<WatchiumComment>> sendComment(
    String message, {
    double? videoTimestamp,
    String? parentId,
  }) async {
    final animeId = currentRoom.value?.animeId;
    final episodeNumber = currentRoom.value?.episodeNumber;

    if (animeId == null || episodeNumber == null) {
      return WatchiumResult.failure('No active episode to comment on');
    }
    if (message.trim().isEmpty) {
      return WatchiumResult.failure('Comment message cannot be empty');
    }

    try {
      final body = <String, dynamic>{
        'anime_id': animeId,
        'episode_number': episodeNumber,
        'user_id': _userId,
        'username': _username ?? 'Anonymous',
        if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
          'avatar_url': _avatarUrl,
        'message': message.trim(),
      };
      if (isInRoom.value && currentRoomId.value.isNotEmpty) {
        body['room_id'] = currentRoomId.value;
      }
      if (videoTimestamp != null) {
        body['video_timestamp'] = videoTimestamp;
      }
      if (parentId != null && parentId.isNotEmpty) {
        body['parent_id'] = parentId;
      }

      final data = await _post('comments-create', body: body);
      if (data == null) {
        return WatchiumResult.failure('Failed to send comment');
      }

      final commentJson = data['comment'] as Map<String, dynamic>?;
      final comment = commentJson != null
          ? WatchiumComment.fromJson(commentJson)
          : null;

      if (comment != null) {
        roomComments.insert(0, comment);
        Logger.i('[Watchium] Comment sent: ${comment.id}');
      }

      return comment != null
          ? WatchiumResult.success(comment)
          : WatchiumResult.failure('Unexpected response format');
    } catch (e, st) {
      final msg = '[Watchium] sendComment error: $e';
      Logger.e(msg, error: e, stackTrace: st);
      error.value = msg;
      return WatchiumResult.failure(msg);
    }
  }

  // ---------------------------------------------------------------------------
  // Heartbeat
  // ---------------------------------------------------------------------------

  /// Starts a periodic timer that sends member status updates.
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _updateMemberStatus();
    });
    Logger.i('[Watchium] Heartbeat started (${_heartbeatInterval.inSeconds}s interval)');
  }

  /// Cancels the heartbeat timer.
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ---------------------------------------------------------------------------
  // Player integration callbacks
  // ---------------------------------------------------------------------------

  /// Should be called by the video player whenever playback state changes
  /// locally. For non-host users this is used to report status back to the
  /// server; for the host it triggers a sync control broadcast.
  void onPlaybackStateChanged(Duration position, bool playing) {
    final currentTimeSeconds = position.inMilliseconds / 1000.0;
    syncState.value = syncState.value.copyWith(
      currentTime: currentTimeSeconds,
      isPlaying: playing,
    );

    if (isHost.value && isInRoom.value) {
      // Host broadcasts changes to all members
      sendPlayControl(playing ? 'play' : 'pause',
          currentTime: currentTimeSeconds);
    }
  }

  /// Called when the service receives a remote playback change (e.g. from
  /// fetchHostTime or a realtime event). This invokes the
  /// [onRemotePlaybackChanged] callback so the player UI can adjust.
  void _onRemotePlaybackChanged(double position, bool playing) {
    syncState.value = syncState.value.copyWith(
      currentTime: position,
      isPlaying: playing,
      lastSyncedAt: DateTime.now(),
      isSynced: true,
    );

    currentRoom.value = currentRoom.value?.copyWith(
      currentTime: position,
      isPlaying: playing,
    );

    onRemotePlaybackChanged?.call(position, playing);
    Logger.i(
        '[Watchium] Remote playback changed → $position s, playing=$playing');
  }

  // ---------------------------------------------------------------------------
  // Convenience getters
  // ---------------------------------------------------------------------------

  /// Whether the user is the host of the current room.
  bool get canControlPlayback => isHost.value && isInRoom.value;

  /// The current room ID, or empty string if not in a room.
  String get roomId => currentRoomId.value;

  /// The current access key for sharing private rooms, or `null`.
  String? get accessKey => currentRoom.value?.accessKey;

  /// Number of members currently in the room.
  int get memberCount => members.length;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    Logger.i('[Watchium] Service initialized (userId=$_userId)');
  }

  @override
  void onClose() {
    _stopHeartbeat();
    leaveRoom();
    super.onClose();
    Logger.i('[Watchium] Service disposed');
  }
}
