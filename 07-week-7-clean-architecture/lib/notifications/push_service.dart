import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

import '../data/api_errors.dart';
import 'route_from_message.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushService extends ChangeNotifier {
  PushService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    this.onTokenChanged,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final Future<void> Function(String token)? onTokenChanged;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<String>? _tokenSubscription;
  void Function(String route)? _onRoute;

  static const channelId = 'campus-announcements';
  static const _channel = AndroidNotificationChannel(
    channelId,
    'Pengumuman Kampus',
    description: 'Notifikasi pengumuman untuk mahasiswa.',
    importance: Importance.high,
  );

  String? token;
  String permissionStatus = 'Belum diminta';
  String? statusMessage;
  bool isBusy = false;
  bool isSubscribedToTopic = false;

  String get tokenPreview {
    final currentToken = token;
    if (currentToken == null || currentToken.isEmpty) {
      return 'Token belum tersedia';
    }
    final visibleLength = currentToken.length < 12 ? currentToken.length : 12;
    return '${currentToken.substring(0, visibleLength)}...';
  }

  Future<void> initialize({
    required void Function(String route) onRoute,
  }) async {
    _onRoute = onRoute;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _initializeLocalNotifications();

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      (message) => unawaited(_showForegroundMessage(message)),
      onError: (Object error) {
        statusMessage = 'Gagal menerima pesan foreground: $error';
        notifyListeners();
      },
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _onRoute?.call(routeFromMessage(message.data)),
      onError: (Object error) {
        statusMessage = 'Gagal membuka notifikasi: $error';
        notifyListeners();
      },
    );
    _tokenSubscription = _messaging.onTokenRefresh.listen(
      (newToken) => unawaited(_processToken(newToken)),
      onError: (Object error) {
        statusMessage = 'Gagal memperbarui token FCM: $error';
        notifyListeners();
      },
    );

    final localLaunch = await _localNotifications
        .getNotificationAppLaunchDetails();
    final localRoute = localLaunch?.notificationResponse?.payload;
    if (localLaunch?.didNotificationLaunchApp == true &&
        localRoute != null &&
        localRoute.isNotEmpty) {
      _onRoute?.call(localRoute);
    }

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _onRoute?.call(routeFromMessage(initialMessage.data));
    }
  }

  Future<void> requestPermissionAndGetToken() async {
    isBusy = true;
    statusMessage = null;
    notifyListeners();
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );
      permissionStatus = switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized => 'Diizinkan',
        AuthorizationStatus.provisional => 'Diizinkan sementara',
        AuthorizationStatus.denied ||
        AuthorizationStatus.deniedPermanently => 'Ditolak',
        AuthorizationStatus.notDetermined => 'Belum diputuskan',
      };

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final currentToken = await _messaging.getToken();
        if (currentToken == null || currentToken.isEmpty) {
          token = null;
          statusMessage =
              'Izin diberikan, tetapi FCM belum mengembalikan token.';
        } else {
          await _processToken(currentToken);
        }
      } else {
        token = null;
        statusMessage = 'Izin notifikasi belum diberikan. Ubah izin di pengaturan perangkat.';
      }
    } on FirebaseException catch (error) {
      permissionStatus = 'Gagal';
      statusMessage = 'Firebase ${error.code}: ${error.message ?? 'gagal'}';
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _processToken(String value) async {
    token = value;
    statusMessage = 'Token perangkat berhasil dimuat.';
    notifyListeners();
    final callback = onTokenChanged;
    if (callback == null) {
      statusMessage = 'Token dimuat di aplikasi; endpoint backend POST /devices belum dikonfigurasi.';
      notifyListeners();
      return;
    }
    try {
      await callback(value);
      statusMessage = 'Token perangkat berhasil dikirim ke backend.';
    } on DioException catch (error) {
      statusMessage = 'Gagal mengirim token: ${apiErrorMessage(error)}';
    } on StateError catch (error) {
      statusMessage = 'Token belum dikirim: $error';
    }
    notifyListeners();
  }

  Future<void> subscribeToCampusAnnouncements() async {
    try {
      await _messaging.subscribeToTopic('pengumuman-kampus');
      isSubscribedToTopic = true;
      statusMessage = 'Berlangganan topik pengumuman-kampus.';
    } on FirebaseException catch (error) {
      statusMessage = 'Gagal subscribe (${error.code}): ${error.message}';
    } finally {
      notifyListeners();
    }
  }

  Future<void> unsubscribeFromCampusAnnouncements() async {
    try {
      await _messaging.unsubscribeFromTopic('pengumuman-kampus');
      isSubscribedToTopic = false;
      statusMessage = 'Berhenti berlangganan topik pengumuman-kampus.';
    } on FirebaseException catch (error) {
      statusMessage = 'Gagal unsubscribe (${error.code}): ${error.message}';
    } finally {
      notifyListeners();
    }
  }

  Future<void> _initializeLocalNotifications() async {
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _onRoute?.call(payload);
        }
      },
    );
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_channel);
  }

  Future<void> _showForegroundMessage(RemoteMessage message) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Pengumuman Kampus',
        channelDescription: 'Notifikasi pengumuman untuk mahasiswa.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    try {
      await _localNotifications.show(
        id: message.hashCode,
        title: message.notification?.title ?? 'Pengumuman Kampus',
        body: message.notification?.body ?? '',
        notificationDetails: details,
        payload: routeFromMessage(message.data),
      );
    } on PlatformException catch (error) {
      statusMessage = 'Gagal menampilkan notifikasi lokal (${error.code}).';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_foregroundSubscription?.cancel());
    unawaited(_openedSubscription?.cancel());
    unawaited(_tokenSubscription?.cancel());
    super.dispose();
  }
}
