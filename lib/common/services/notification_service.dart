import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/bookings/bookings_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/dashboard/dashboard_cubit.dart';

class NotificationService {
  static const String _fcmTokenKey = 'owner_fcm_token';
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  /// Global navigator key so foreground notifications can trigger in-app refreshes
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

    // 7. Handle notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // Check if app was opened from a notification
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
      try {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'owner_notifications',
            'Owner Notifications',
            description: 'General notifications for venue owners',
            importance: Importance.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('general_notification_sound'),
          ),
        );
      } catch (e) {
        debugPrint('Owner App - Failed to create owner_notifications channel: $e');
      }

      try {
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
      } catch (e) {
        debugPrint('Owner App - Failed to create new_booking_channel: $e');
      }

      try {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'new_booking_channel_v2',
            'New Booking Alert',
            description: 'Plays a cricket sound when a new booking arrives',
            importance: Importance.max,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('booking_confirmed'),
          ),
        );
      } catch (e) {
        debugPrint('Owner App - Failed to create new_booking_channel_v2: $e');
      }

      try {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'user_notifications',
            'User Notifications',
            description: 'User Notifications',
            importance: Importance.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('general_notification_sound'),
          ),
        );
      } catch (e) {
        debugPrint('Owner App - Failed to create user_notifications channel: $e');
      }
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

    final type = (message.data['type']?.toString() ?? '').toLowerCase();
    final isNewBooking = type == 'booking' ||
        type == 'new_booking' ||
        type == 'booking_confirmed' ||
        type == 'booking_request' ||
        type.contains('booking');

    // Trigger instant refresh of Bookings & Dashboard in the owner app
    if (isNewBooking) {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        try {
          context.read<BookingsCubit>().fetchBookings();
        } catch (_) {}
        try {
          context.read<DashboardCubit>().fetchDashboardData();
        } catch (_) {}
      }
    }

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
            'new_booking_channel_v2',
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
            sound: const RawResourceAndroidNotificationSound('general_notification_sound'),
            playSound: true,
            tag: tag,
            onlyAlertOnce: true,
          );

    final DarwinNotificationDetails iosDetails = isBookingSound
        ? const DarwinNotificationDetails(sound: 'booking_confirmation_ios.mp3')
        : const DarwinNotificationDetails(sound: 'general_notification_sound_ios.mp3');

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('Owner App - Error showing local notification with custom sound: $e. Retrying with system default sound.');
      try {
        final fallbackDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            'owner_notifications_fallback',
            'Owner Notifications',
            channelDescription: 'General notifications channel',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            tag: tag,
            onlyAlertOnce: true,
          ),
          iOS: const DarwinNotificationDetails(),
        );
        await _localNotifications.show(id, title, body, fallbackDetails, payload: payload);
      } catch (inner) {
        debugPrint('Owner App - Fallback notification display also failed: $inner');
      }
    }
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
