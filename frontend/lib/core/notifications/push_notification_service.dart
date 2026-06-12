import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../api/api_client.dart';
import '../api/api_endpoints.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Background delivery should never crash if Firebase is not configured.
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiClient _apiClient = ApiClient();

  bool _isInitialized = false;
  bool _isFirebaseAvailable = false;
  String? _lastRegisteredToken;

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) {
      return;
    }

    _isInitialized = true;

    try {
      await Firebase.initializeApp();
      _isFirebaseAvailable = true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Firebase initialization skipped: $error');
      }
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _initializeLocalNotifications();
    await _requestPermission();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageTap);
    _messaging.onTokenRefresh.listen((token) {
      registerDeviceToken(token: token);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleRemoteMessageTap(initialMessage);
      });
    }
  }

  Future<void> registerDeviceToken({String? token}) async {
    if (!_isFirebaseAvailable || kIsWeb) {
      return;
    }

    try {
      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        return;
      }

      final result = await _apiClient.post(
        ApiEndpoints.deviceTokens,
        data: {
          'token': fcmToken,
          'platform': 'android',
          'device_name': 'Android device',
        },
      );

      if (result.isSuccess) {
        _lastRegisteredToken = fcmToken;
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Unable to register FCM token: $error');
      }
    }
  }

  Future<void> unregisterDeviceToken() async {
    if (!_isFirebaseAvailable || kIsWeb) {
      return;
    }

    try {
      final fcmToken = _lastRegisteredToken ?? await _messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        return;
      }

      await _apiClient.delete(
        ApiEndpoints.deviceTokens,
        data: {'token': fcmToken},
      );
      _lastRegisteredToken = null;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Unable to unregister FCM token: $error');
      }
    }
  }

  void routeFromData(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      return;
    }

    final route = _routeForPayload(data);
    context.go(route);
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          routeFromData(const {});
          return;
        }

        try {
          final data = jsonDecode(payload);
          if (data is Map<String, dynamic>) {
            routeFromData(data);
          } else {
            routeFromData(const {});
          }
        } catch (_) {
          routeFromData(const {});
        }
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'snapcircle_activity',
        'SnapCircle activity',
        description: 'Likes, comments, follows, requests, and messages.',
        importance: Importance.high,
      ),
    );
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? 'SnapCircle';
    final body = notification?.body ?? 'You have a new notification.';
    final payload = jsonEncode(message.data);

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      payload: payload,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'snapcircle_activity',
          'SnapCircle activity',
          channelDescription:
              'Likes, comments, follows, requests, and messages.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    routeFromData(message.data);
  }

  String _routeForPayload(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final postId = _stringValue(data['post_id']);
    final userId = _stringValue(data['user_id']);
    final conversationId = _stringValue(data['conversation_id']);

    switch (type) {
      case 'like':
      case 'comment':
        if (postId != null) {
          return '/posts/$postId';
        }
        break;
      case 'follow':
      case 'follow_request_approved':
        if (userId != null) {
          return '/users/$userId';
        }
        break;
      case 'follow_request':
        return '/follow-requests';
      case 'message':
        if (conversationId != null) {
          return '/messages/$conversationId';
        }
        return '/messages';
    }

    return '/notifications';
  }

  String? _stringValue(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}
