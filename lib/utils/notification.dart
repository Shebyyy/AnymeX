import 'dart:convert';
import 'dart:io';
import 'package:anymex/services/commentum_service.dart';
import 'package:anymex/utils/deeplink.dart';
import 'package:anymex/utils/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService extends GetxController {
  static NotificationService get instance => Get.find<NotificationService>();

  FirebaseMessaging? _firebaseMessaging;
  FlutterLocalNotificationsPlugin? _localNotifications;

  final RxnString fcmToken = RxnString(null);
  final RxBool notificationsEnabled = true.obs;

  VoidCallback? onNotificationTap;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    try {
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

  Future<void> _setupLocalNotifications() async {
    final local = _localNotifications;
    if (local == null) return;

    const androidSettings = AndroidInitializationSettings('@drawable/ic_stat_anymex');
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
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        'mentions',
        'Mentions',
        description: 'When someone @mentions you in a comment',
        importance: Importance.high,
      ));
    }
  }

  Future<void> _setupFirebaseMessaging() async {
    final fm = _firebaseMessaging;
    if (fm == null) return;

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    try {
      final initialMessage = await fm.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      Logger.e('Error getting initial message: $e');
    }

    fm.onTokenRefresh.listen((newToken) {
      Logger.i('FCM token refreshed');
      fcmToken.value = newToken;
      _registerTokenWithBackend(newToken);
    });
  }

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
            icon: '@drawable/ic_stat_anymex',
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

  void _handleMessageOpenedApp(RemoteMessage message) {
    Logger.i('Notification tapped: ${message.data}');
    onNotificationTap?.call();
    _navigateFromNotification(message.data);
  }

  void _navigateFromNotification(Map<String, dynamic> data) {
    final clickAction = data['click_action'] as String?;

    if (clickAction != null && clickAction.isNotEmpty && clickAction.startsWith('anymex://')) {
      Logger.i('Navigating via deep link: $clickAction');
      Deeplink.handleDeepLink(Uri.parse(clickAction));
      return;
    }

    Logger.i('Notification has no navigable media info');
  }

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
      case 'mentions': return 'Mentions';
      default: return 'Comments';
    }
  }

  Importance _getChannelImportance(String channelId) {
    switch (channelId) {
      case 'comments':
      case 'moderation':
      case 'announcements':
      case 'mentions':
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }

  String? getToken() => fcmToken.value;

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

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background notification received: ${message.notification?.title}');
}
