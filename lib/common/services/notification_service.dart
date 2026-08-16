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

    // 5. Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Handle background tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // 7. Check if app opened from a notification
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
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Owner App - Foreground message: ${message.messageId}');

    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type']?.toString() ?? '';
    final isNewBooking = type == 'new_booking' || type == 'booking_confirmed';

    // Show local notification
    _showLocalNotification(
      id: notification.hashCode,
      title: notification.title ?? '',
      body: notification.body ?? '',
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
    required String title,
    required String body,
    String? payload,
    bool isBookingSound = false,
  }) async {
    // New booking → cricket bat sound on dedicated channel
    // Other notifications → default channel
    final AndroidNotificationDetails androidDetails = isBookingSound
        ? const AndroidNotificationDetails(
            'new_booking_channel',
            'New Booking Alert',
            channelDescription: 'Plays a cricket sound when a new booking arrives',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('booking_confirmed'),
            playSound: true,
          )
        : const AndroidNotificationDetails(
            'owner_notifications',
            'Owner Notifications',
            channelDescription: 'General notifications for venue owners',
            importance: Importance.high,
            priority: Priority.high,
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

      // Check if token already exists to bypass strict unique constraints on upsert
      final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
      final nowUtc = DateTime.now().toUtc().toIso8601String();

      final existingTokens = await Supabase.instance.client
          .from('fcm_tokens')
          .select('id')
          .eq('user_id', user.uid)
          .limit(1);

      if (existingTokens.isNotEmpty) {
        await Supabase.instance.client.from('fcm_tokens').update({
          'token': token,
          'platform': platform,
          'last_used_at': nowUtc,
          'updated_at': nowUtc,
        }).eq('user_id', user.uid);
      } else {
        await Supabase.instance.client.from('fcm_tokens').insert({
          'user_id': user.uid,
          'token': token,
          'platform': platform,
          'last_used_at': nowUtc,
          'updated_at': nowUtc,
        });
      }
    } catch (e) {
      debugPrint("Owner App - Failed to update token in Supabase: $e");
      try {
        final user = FirebaseAuth.instance.currentUser;
        await Supabase.instance.client.from('fcm_tokens').insert({
          'user_id': user?.uid ?? 'unknown',
          'token': 'ERROR: ${e.toString().substring(0, e.toString().length > 200 ? 200 : e.toString().length)}',
          'platform': 'error_log',
          'last_used_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
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
