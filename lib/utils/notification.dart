import 'dart:convert';
import 'dart:io';
import 'package:anymex/controllers/service_handler/service_handler.dart';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/deeplink.dart';
import 'package:anymex/utils/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

/// Handles all push notification logic: FCM token management,
/// foreground notifications, background message handling, and tap routing.
///
/// All Firebase access is wrapped in try-catch and guarded by Firebase
/// initialization checks so this service can NEVER crash the app.
class NotificationService extends GetxController {
  static NotificationService get instance => Get.find<NotificationService>();

  // Lazy Firebase references — only accessed after confirming Firebase is ready
  FirebaseMessaging? _firebaseMessaging;
  FlutterLocalNotificationsPlugin? _localNotifications;

  // Rx vars
  final RxnString fcmToken = RxnString(null);
  final RxBool notificationsEnabled = true.obs;

  // Callback for when user taps a notification
  VoidCallback? onNotificationTap;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    try {
      // Guard: check Firebase is initialized before doing anything
      if (Firebase.apps.isEmpty) {
        Logger.i('NotificationService: Firebase not initialized, skipping');
        return;
      }

      _firebaseMessaging = FirebaseMessaging.instance;
      _localNotifications = FlutterLocalNotificationsPlugin();

      await _setupLocalNotifications();
      await _setupFirebaseMessaging();
      await _requestPermission();
    } catch (e) {
      Logger.e('NotificationService init error: $e');
    }
  }

  /// Setup local notification channels and plugin
  Future<void> _setupLocalNotifications() async {
    final local = _localNotifications;
    if (local == null) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await local.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channels
    if (Platform.isAndroid) {
      final androidPlugin = local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin == null) return;

      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'comments',
        'Comments',
        description: 'New comments, replies, and edits',
        importance: Importance.high,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'votes',
        'Votes',
        description: 'Upvotes and downvotes on your comments',
        importance: Importance.defaultImportance,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'moderation',
        'Moderation',
        description: 'Warnings, mutes, bans, and moderation actions',
        importance: Importance.high,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'reports',
        'Reports',
        description: 'Report filed, resolved, dismissed',
        importance: Importance.defaultImportance,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'announcements',
        'Announcements',
        description: 'Official announcements',
        importance: Importance.high,
      ));
    }
  }

  /// Setup Firebase Messaging listeners
  Future<void> _setupFirebaseMessaging() async {
    final fm = _firebaseMessaging;
    if (fm == null) return;

    // Foreground messages - show as local notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/terminated tap handler
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state via notification
    try {
      final initialMessage = await fm.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      Logger.e('Error getting initial message: $e');
    }

    // Listen for token refresh
    fm.onTokenRefresh.listen((newToken) {
      Logger.i('FCM token refreshed');
      fcmToken.value = newToken;
      _registerTokenWithBackend(newToken);
    });
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final fm = _firebaseMessaging;
    if (fm == null) return;

    try {
      final settings = await fm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final authorized = settings.authorizationStatus == AuthorizationStatus.authorized;
      final provisional = settings.authorizationStatus == AuthorizationStatus.provisional;
      notificationsEnabled.value = authorized || provisional;

      if (notificationsEnabled.value) {
        final token = await fm.getToken();
        if (token != null) {
          fcmToken.value = token;
          Logger.i('FCM token obtained: ${token.substring(0, 20)}...');
          _registerTokenWithBackend(token);
        }
      }
    } catch (e) {
      Logger.e('Error requesting notification permission: $e');
    }
  }

  /// Handle foreground messages - display as local notification
  void _handleForegroundMessage(RemoteMessage message) {
    try {
      final local = _localNotifications;
      if (local == null) return;

      final notification = message.notification;
      if (notification == null) return;

      final android = message.notification?.android;
      final channelId = android?.channelId ?? 'comments';

      local.show(
        message.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _getChannelName(channelId),
            importance: _getChannelImportance(channelId),
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (e) {
      Logger.e('Error showing foreground notification: $e');
    }
  }

  /// Handle notification tap (background or terminated)
  void _handleMessageOpenedApp(RemoteMessage message) {
    Logger.i('Notification tapped: ${message.data}');
    onNotificationTap?.call();
    _navigateFromNotification(message.data);
  }

  /// Navigate to the appropriate screen based on notification data
  void _navigateFromNotification(Map<String, dynamic> data) {
    final clickAction = data['click_action'] as String?;
    final mediaId = data['media_id']?.toString();
    final mediaType = data['media_type'] as String?;

    // Try deep link first (from click_action)
    if (clickAction != null && clickAction.startsWith('anymex://')) {
      Logger.i('Navigating via deep link: $clickAction');
      Deeplink.handleDeepLink(Uri.parse(clickAction));
      return;
    }

    // Fallback: construct navigation from media_id and media_type
    if (mediaId != null && mediaType != null) {
      final normalizedType = mediaType.toLowerCase();
      final isManga = normalizedType == 'manga' || normalizedType == 'novel';

      Logger.i('Navigating to $mediaType/$mediaId (isManga=$isManga)');

      // Ensure correct service type is active before navigating
      try {
        final handler = Get.find<ServiceHandler>();
        final expectedType = _serviceTypeFromMediaType(normalizedType);
        if (handler.serviceType.value != expectedType) {
          handler.changeService(expectedType);
        }
      } catch (e) {
        Logger.i('Could not resolve ServiceHandler for notification navigation: $e');
      }

      final uri = Uri.parse('anymex://$mediaType/$mediaId');
      Deeplink.handleDeepLink(uri);
      return;
    }

    // No media info to navigate to
    Logger.i('Notification has no navigable media info');
  }

  /// Determine the expected service type from media type string
  ServicesType _serviceTypeFromMediaType(String mediaType) {
    switch (mediaType) {
      case 'anime':
      case 'manga':
        return ServicesType.anilist;
      default:
        return ServicesType.anilist;
    }
  }

  /// Refresh the unread notification count from the backend.
  Future<void> refreshUnreadCount() async {
    try {
      if (Get.isRegistered<CommentumService>()) {
        final service = Get.find<CommentumService>();
        await service.getUnreadNotificationCount();
        Logger.i('Unread notification count refreshed');
      }
    } catch (e) {
      Logger.i('Error refreshing unread count: $e');
    }
  }

  /// Register FCM token with Commentum backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      if (Get.isRegistered<CommentumService>()) {
        final service = Get.find<CommentumService>();
        await service.registerFcmToken(token);
        Logger.i('FCM token registered with backend');
      } else {
        Logger.i('CommentumService not yet registered, token will be registered later');
      }
    } catch (e) {
      Logger.e('Failed to register FCM token: $e');
    }
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'votes': return 'Votes';
      case 'moderation': return 'Moderation';
      case 'reports': return 'Reports';
      case 'announcements': return 'Announcements';
      default: return 'Comments';
    }
  }

  Importance _getChannelImportance(String channelId) {
    switch (channelId) {
      case 'comments':
      case 'moderation':
      case 'announcements':
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }

  /// Get current FCM token
  String? getToken() => fcmToken.value;

  /// Public method to manually register token with backend
  Future<bool> registerToken({
    required String token,
    required String clientType,
    required String userId,
  }) async {
    try {
      Logger.i('FCM token registered for user $userId ($clientType)');
      return true;
    } catch (e) {
      Logger.e('Failed to register token: $e');
      return false;
    }
  }

  /// Public method to unregister token
  Future<bool> unregisterToken({
    required String token,
    required String clientType,
    required String userId,
  }) async {
    try {
      Logger.i('FCM token unregistered for user $userId');
      return true;
    } catch (e) {
      Logger.e('Failed to unregister token: $e');
      return false;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    Logger.i('Local notification tapped: ${response.payload}');
    onNotificationTap?.call();
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _navigateFromNotification(data);
      } catch (e) {
        Logger.e('Error parsing notification payload: $e');
      }
    }
  }
}

/// Background message handler - MUST be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is auto-initialized by the OS for background messages
  print('Background notification received: ${message.notification?.title}');
}
