import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_routes.dart';

enum PushAuthorizationStatus { notDetermined, denied, authorized, provisional }

class NotificationTap {
  const NotificationTap({this.notificationId});

  final String? notificationId;

  String get location => notificationId == null
      ? AppRoutes.notifications
      : AppRoutes.notification(notificationId!);
}

abstract interface class PushNotificationClient {
  Future<PushAuthorizationStatus> authorizationStatus();

  Future<PushAuthorizationStatus> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  Stream<NotificationTap> get notificationTaps;

  NotificationTap? takeInitialNotificationTap();
}

const _notificationChannelId = 'push_notifications';
const _notificationChannelName = 'Notifications';
const _notificationChannelDescription = 'App notifications';

final pushNotificationClientProvider = Provider<PushNotificationClient>((ref) {
  final service = PushNotificationService();
  ref.onDispose(service.dispose);
  return service;
});

final pushNotificationAuthorizationProvider =
    FutureProvider<PushAuthorizationStatus>((ref) {
      return ref.read(pushNotificationClientProvider).authorizationStatus();
    });

class PushNotificationService implements PushNotificationClient {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final StreamController<NotificationTap> _notificationTaps =
      StreamController<NotificationTap>.broadcast();
  StreamSubscription<RemoteMessage>? _foregroundMessages;
  StreamSubscription<RemoteMessage>? _openedMessages;
  NotificationTap? _initialNotificationTap;

  Future<void> initialize() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _handleLocalNotificationTap,
      );
      final launchDetails = await _localNotifications
          .getNotificationAppLaunchDetails();
      final localPayload = launchDetails?.notificationResponse?.payload;
      if (launchDetails?.didNotificationLaunchApp == true) {
        _initialNotificationTap = _tapForId(localPayload);
      }
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _notificationChannelId,
          _notificationChannelName,
          description: _notificationChannelDescription,
          importance: Importance.high,
        ),
      );
    }

    _foregroundMessages ??= FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    _openedMessages ??= FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedMessage,
    );
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _initialNotificationTap = _tapFromData(initialMessage.data);
    }
  }

  @override
  Future<PushAuthorizationStatus> authorizationStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return _mapAuthorizationStatus(settings.authorizationStatus);
  }

  @override
  Future<PushAuthorizationStatus> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return _mapAuthorizationStatus(settings.authorizationStatus);
  }

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<NotificationTap> get notificationTaps => _notificationTaps.stream;

  @override
  NotificationTap? takeInitialNotificationTap() {
    final tap = _initialNotificationTap;
    _initialNotificationTap = null;
    return tap;
  }

  PushAuthorizationStatus _mapAuthorizationStatus(AuthorizationStatus status) {
    return switch (status) {
      AuthorizationStatus.notDetermined =>
        PushAuthorizationStatus.notDetermined,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently => PushAuthorizationStatus.denied,
      AuthorizationStatus.authorized => PushAuthorizationStatus.authorized,
      AuthorizationStatus.provisional => PushAuthorizationStatus.provisional,
    };
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if (title == null && body == null) return;

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      payload: message.data['notificationId']?.toString(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _notificationChannelId,
          _notificationChannelName,
          channelDescription: _notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    _emitTap(_tapFromData(message.data));
  }

  void _handleLocalNotificationTap(NotificationResponse response) {
    _emitTap(_tapForId(response.payload));
  }

  NotificationTap _tapFromData(Map<String, dynamic> data) {
    return _tapForId(data['notificationId']?.toString());
  }

  NotificationTap _tapForId(String? notificationId) {
    return NotificationTap(
      notificationId:
          notificationId?.isEmpty == true ||
              notificationId?.contains('/') == true
          ? null
          : notificationId,
    );
  }

  void _emitTap(NotificationTap tap) {
    if (_notificationTaps.hasListener) {
      _notificationTaps.add(tap);
    } else {
      _initialNotificationTap = tap;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    unawaited(
      _showForegroundNotification(message).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint(
          'Could not display foreground push notification: '
          '$error\n$stackTrace',
        );
      }),
    );
  }

  Future<void> dispose() async {
    await _foregroundMessages?.cancel();
    await _openedMessages?.cancel();
    await _notificationTaps.close();
  }
}
