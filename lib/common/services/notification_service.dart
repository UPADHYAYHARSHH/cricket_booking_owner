import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static const String _fcmTokenKey = 'owner_fcm_token';
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) {
      await updateFcmToken();
      return;
    }
    _isInitialized = true;
    // 1. Request permissions
    await _requestPermissions();

    // 2. Initialize local notifications
    await _initializeLocalNotifications();

    // 3. Initial token update
    await updateFcmToken();

    // 4. Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _updateTokenInSupabase(newToken);
    });

    // 5. Keep token synced when auth state changes (e.g. login)
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await updateFcmToken();
      }
    });

    // 6. Handle foreground messages
    if (!kIsWeb) {
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    }

    // 7. Handle background tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // 8. Check if app opened from a notification
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  static Future<void> _requestPermissions() async {
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
    debugPrint(
      'Owner App - User granted permission: ${settings.authorizationStatus}',
    );
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle local notification tap
        debugPrint('Local notification tapped: ${details.payload}');
      },
    );

    // Explicitly create notification channels on Android
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'owner_notifications',
          'Owner Notifications',
          description: 'General notifications for venue owners',
          importance: Importance.high,
          playSound: true,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'new_booking_channel',
          'New Booking Alert',
          description: 'Plays a cricket sound when a new booking arrives',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('booking_confirmed'),
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'user_notifications',
          'User Notifications',
          description: 'User Notifications',
          importance: Importance.high,
          playSound: true,
        ),
      );
    }
  }

  static final Map<String, DateTime> _recentNotificationKeys = {};

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Owner App - Foreground message: ${message.messageId} data: ${message.data}');

    final notification = message.notification;
    String title = notification?.title ?? message.data['title']?.toString() ?? '';
    String body = notification?.body ?? message.data['message']?.toString() ?? message.data['body']?.toString() ?? '';

    if (title.isEmpty && body.isEmpty) return;

    // Deduplicate rapid duplicate foreground pushes for the same notification/booking
    final notifKey = message.data['notification_id']?.toString() ??
        message.data['booking_id']?.toString() ??
        '${title}_$body';

    final now = DateTime.now();
    _recentNotificationKeys.removeWhere((k, t) => now.difference(t).inSeconds > 30);
    if (_recentNotificationKeys.containsKey(notifKey)) {
      debugPrint('Owner App - Skipping duplicate foreground notification for key: $notifKey');
      return;
    }
    _recentNotificationKeys[notifKey] = now;

    final type = message.data['type']?.toString() ?? '';
    final isNewBooking = type == 'new_booking' || type == 'booking_confirmed' || type == 'booking_request';

    final int localId = notifKey.hashCode & 0x7FFFFFFF;

    // Show local notification
    _showLocalNotification(
      id: localId,
      tag: notifKey,
      title: title,
      body: body,
      payload: message.data.toString(),
      isBookingSound: isNewBooking,
    );
  }

  static void _handleMessageTap(RemoteMessage message) {
    debugPrint('Owner App - Message tapped: ${message.data}');
    // Navigation will be handled by the app's router based on notification type
  }

  static Future<void> _showLocalNotification({
    required int id,
    String? tag,
    required String title,
    required String body,
    String? payload,
    bool isBookingSound = false,
  }) async {
    // New booking → cricket bat sound on dedicated channel
    // Other notifications → default channel
    final AndroidNotificationDetails androidDetails = isBookingSound
        ? AndroidNotificationDetails(
            'new_booking_channel',
            'New Booking Alert',
            channelDescription: 'Plays a cricket sound when a new booking arrives',
            importance: Importance.max,
            priority: Priority.high,
            sound: const RawResourceAndroidNotificationSound('booking_confirmed'),
            playSound: true,
            tag: tag,
            onlyAlertOnce: true,
          )
        : AndroidNotificationDetails(
            'owner_notifications',
            'Owner Notifications',
            channelDescription: 'General notifications for venue owners',
            importance: Importance.high,
            priority: Priority.high,
            tag: tag,
            onlyAlertOnce: true,
          );

    final DarwinNotificationDetails iosDetails = isBookingSound
        ? const DarwinNotificationDetails(sound: 'booking_confirmed.mp3')
        : const DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  static Future<void> updateFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get FCM Token (not on web)
      String? token;
      if (!kIsWeb) {
        token = await FirebaseMessaging.instance.getToken();
      }

      if (token == null) return;

      debugPrint("Owner App - FCM Token: $token");

      await _updateTokenInSupabase(token);
    } catch (e) {
      debugPrint("Owner App - Error updating token: $e");
    }
  }

  static Future<void> _updateTokenInSupabase(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Store locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, token);

      final platform = 'owner_${kIsWeb ? 'web' : defaultTargetPlatform.name}';

      // 1. Remove stale mappings for this device token
      await Supabase.instance.client
          .from('fcm_tokens')
          .delete()
          .eq('token', token);

      // 2. Remove any previous token for this owner (respects unique user_id constraint)
      await Supabase.instance.client
          .from('fcm_tokens')
          .delete()
          .eq('user_id', user.uid);

      // 3. Insert fresh token directly into Supabase
      await Supabase.instance.client.from('fcm_tokens').insert({
        'user_id': user.uid,
        'token': token,
        'platform': platform,
        'last_used_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint("DEBUG: [NotificationService] Owner token updated successfully in Supabase for owner: ${user.uid}");
    } catch (e) {
      debugPrint("DEBUG: [NotificationService] Failed to update token in Supabase: $e");
    }
  }

  static Future<String?> getLocalToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  static Future<void> clearFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_fcmTokenKey);

      if (user != null && token != null) {
        await Supabase.instance.client.from('fcm_tokens').delete().match({
          'user_id': user.uid,
          'token': token,
        });
      }

      await prefs.remove(_fcmTokenKey);
      debugPrint("DEBUG: [NotificationService] FCM token cleared");
    } catch (e) {
      debugPrint("DEBUG: [NotificationService] Failed to clear token: $e");
    }
  }
}
