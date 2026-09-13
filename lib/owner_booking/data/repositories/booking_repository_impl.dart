import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final SupabaseClient _supabase;

  BookingRepositoryImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getOwnerGrounds(String ownerId) async {
    // Only grounds whose location has been approved by the admin dashboard
    // and is currently active should count towards dashboard stats.
    final response = await _supabase
        .from('grounds')
        .select('id, name, location_id, locations!inner(documents_verified, is_active, deleted_at)')
        .eq('owner_id', ownerId)
        .eq('locations.is_active', true)
        .filter('locations.deleted_at', 'is', null);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchBookingsForGrounds(
      List<Object> groundIds) {
    return _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .inFilter('ground_id', groundIds)
        .order('created_at', ascending: false)
        .map((list) => List<Map<String, dynamic>>.from(list));
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUsers(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    try {
      // Use get_user_profile RPC to bypass RLS on the users table
      final List<Map<String, dynamic>> users = [];
      for (final id in userIds) {
        try {
          final data = await _supabase.rpc('get_user_profile', params: {'p_id': id});
          if (data != null) {
            // The RPC might return a Map or throw if not found
            if (data is Map) {
              final typedData = Map<String, dynamic>.from(data);
              // Ensure the id is included so userMap works
              typedData['id'] = id;
              users.add(typedData);
            }
          }
        } catch (e) {
          print('[fetchUsers] Error fetching profile for $id: $e');
        }
      }
      
      print('[fetchUsers] Success! Found ${users.length} users for IDs: $userIds');
      print('[fetchUsers] Data: $users');
      return users;
    } catch (e) {
      print('[fetchUsers] ERROR fetching users: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchUserPastBookings(
      List<String> userIds) async {
    if (userIds.isEmpty) return [];
    try {
      final response = await _supabase
          .from('bookings')
          .select('user_id')
          .inFilter('user_id', userIds);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getBookingForCheckIn(String bookingId) async {
    return await _supabase
        .from('bookings')
        .select('*, grounds(name, owner_id, category)')
        .eq('id', bookingId)
        .maybeSingle();
  }

  @override
  Future<void> checkInBooking(String bookingId) async {
    await _supabase.from('bookings').update({
      'checked_in': true,
      'checked_in_at': DateTime.now().toIso8601String(),
    }).eq('id', bookingId);
  }

  // TEMPORARILY DISABLED: Commented out to prevent duplicate push notifications.
  // The backend database trigger handles notification dispatch automatically,
  // or client invocation is silenced so only 1 notification is received.
  Future<void> _invokePushNotification(String notificationId) async {
    /*
    try {
      final res = await _supabase.functions.invoke('send-push-notification', body: {
        'notification_id': notificationId,
      });
      print('[BookingRepository] Push notification response: ${res.data}');
    } catch (e) {
      print('[BookingRepository] Push notification invoke error: $e');
    }
    */
  }

  @override
  Future<void> sendCheckInNotification({
    required String userId,
    required String bookingId,
    required String groundName,
    required String checkInTime,
    required String checkInDate,
  }) async {
    try {
      // Insert notification into the notifications table
      final notifInsert = await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': 'Check-In Confirmed',
        'message': 'Your booking at $groundName has been checked in at $checkInTime on $checkInDate.',
        'type': 'booking_checked_in',
        'data': {
          'booking_id': bookingId,
          'ground_name': groundName,
          'check_in_time': checkInTime,
          'check_in_date': checkInDate,
        },
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }).select('id').maybeSingle();

      final notifId = notifInsert?['id']?.toString();
      if (notifId != null) {
        _invokePushNotification(notifId);
      }
    } catch (e) {
      // Don't fail check-in if notification fails
      print('Failed to send check-in notification: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getOwnerBookingsWithDetails(
      String ownerId) async {
    // Scoped the same way as getOwnerGrounds: only count bookings whose
    // ground belongs to an approved/active/non-deleted location, so the
    // revenue report and the dashboard agree on the same set of bookings.
    final response = await _supabase
        .from('bookings')
        .select(
            '*, grounds!inner(name, category, location_id, owner_id, locations!inner(documents_verified, is_active, deleted_at))')
        .eq('grounds.owner_id', ownerId)
        .eq('grounds.locations.is_active', true)
        .filter('grounds.locations.deleted_at', 'is', null)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> approveBooking(String bookingId) async {
    Map<String, dynamic>? bookingData;

    try {
      print('[deleteOrExpireBooking] Fetching booking details...');
      final fetched = await _supabase.from('bookings').select('*, grounds(name, owner_id)').eq('id', bookingId).maybeSingle();
      if (fetched != null) {
        bookingData = Map<String, dynamic>.from(fetched);
        print('[deleteOrExpireBooking] Fetched bookingData: $bookingData');
      }
    } catch (e) {
      print('[deleteOrExpireBooking] Error fetching booking: $e');
    }



    try {
      final res = await _supabase.rpc('approve_booking', params: {
        'p_booking_id': bookingId,
      });
      if (res != null) {
        if (res is Map) {
          bookingData = Map<String, dynamic>.from(res);
        } else if (res is String) {
          try {
            final decoded = jsonDecode(res);
            if (decoded is Map) bookingData = Map<String, dynamic>.from(decoded);
          } catch (_) {}
        }
      }
    } catch (e) {
      print('[approveBooking] RPC failed, falling back to direct update: $e');
    }

    // Direct update fallback if RPC didn't return or failed
    if (bookingData == null) {
      try {
        final updated = await _supabase
            .from('bookings')
            .update({
              'status': 'approved',
              'approved_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', bookingId)
            .select('*, grounds(name)')
            .maybeSingle();
        if (updated != null) {
          bookingData = Map<String, dynamic>.from(updated);
        }
      } catch (e) {
        print('[approveBooking] Direct update failed: $e');
      }
    }

    // Ensure user notification and trigger push
    try {
      // If bookingData is still missing, fetch it directly
      if (bookingData == null) {
        final fetched = await _supabase
            .from('bookings')
            .select('*, grounds(name)')
            .eq('id', bookingId)
            .maybeSingle();
        if (fetched != null) {
          bookingData = Map<String, dynamic>.from(fetched);
        }
      }

      if (bookingData != null) {
        final userId = bookingData['user_id']?.toString();
        if (userId != null && userId.isNotEmpty) {
          String groundName = 'the venue';
          if (bookingData['grounds'] is Map && bookingData['grounds']['name'] != null) {
            groundName = bookingData['grounds']['name'];
          } else if (bookingData['ground_id'] != null) {
            try {
              final g = await _supabase.from('grounds').select('name').eq('id', bookingData['ground_id']).maybeSingle();
              if (g != null && g['name'] != null) groundName = g['name'];
            } catch (_) {}
          }

          // Check if notification was already inserted by RPC
          String? notifId;
          final existing = await _supabase
              .from('notifications')
              .select('id')
              .eq('user_id', userId)
              .eq('type', 'booking_approved')
              .contains('data', {'booking_id': bookingId})
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

          if (existing != null && existing['id'] != null) {
            notifId = existing['id'].toString();
          } else {
            // Insert notification row
            final inserted = await _supabase.from('notifications').insert({
              'user_id': userId,
              'title': 'Booking Approved! 🎉 Pay in 45 Mins',
              'message': 'Your booking request for $groundName has been approved! Please complete payment within 45 minutes.',
              'type': 'booking_approved',
              'data': {
                'booking_id': bookingId,
                'ground_id': bookingData['ground_id'],
                'amount': bookingData['amount'],
                'action': 'payment_required',
              },
              'is_read': false,
              'created_at': DateTime.now().toUtc().toIso8601String(),
            }).select('id').maybeSingle();

            if (inserted != null && inserted['id'] != null) {
              notifId = inserted['id'].toString();
            }
          }

          if (notifId != null) {
            _invokePushNotification(notifId);
          }
        }
      }
    } catch (e) {
      print('[approveBooking] Error in push notification flow: $e');
    }
  }

  @override
  Future<void> deleteOrExpireBooking(String bookingId, {String reason = 'declined_by_owner'}) async {
    String newStatus = 'declined';
    if (reason == 'expired_owner_timeout') {
      newStatus = 'expired';
    } else if (reason == 'expired_user_payment_timeout') {
      newStatus = 'cancelled';
    }

    Map<String, dynamic>? bookingData;

    try {
      print('[deleteOrExpireBooking] Fetching booking details...');
      final fetched = await _supabase.from('bookings').select('*, grounds(name, owner_id)').eq('id', bookingId).maybeSingle();
      if (fetched != null) {
        bookingData = Map<String, dynamic>.from(fetched);
        print('[deleteOrExpireBooking] Fetched bookingData: $bookingData');
      }
    } catch (e) {
      print('[deleteOrExpireBooking] Error fetching booking: $e');
    }

    try {
      final res = await _supabase.rpc('delete_or_expire_booking', params: {
        'p_booking_id': bookingId,
        'p_reason': reason,
      });
    } catch (e) {
      print('[deleteOrExpireBooking] RPC failed, falling back to direct update: $e');
      try {
        await _supabase.from('bookings').update({
          'status': newStatus,
          'notes': reason,
        }).eq('id', bookingId);
      } catch (e) {
        print('[deleteOrExpireBooking] Direct update error: $e');
      }
    }

    if (bookingData != null) {
      final groundId = bookingData['ground_id'];
      final slotTimeStr = bookingData['slot_time']?.toString();
      final periodStr = bookingData['period']?.toString();
      print('[deleteOrExpireBooking] Data to free slots -> groundId: $groundId, slotTimeStr: $slotTimeStr, periodStr: $periodStr');

      // Free slots
      if (slotTimeStr != null && groundId != null) {
        final slotDate = DateTime.tryParse(slotTimeStr)?.toLocal();
        print('[deleteOrExpireBooking] Parsed slotDate (local): $slotDate');
        if (slotDate != null) {
          final dateStr = "${slotDate.year}-${slotDate.month.toString().padLeft(2, '0')}-${slotDate.day.toString().padLeft(2, '0')}";
          print('[deleteOrExpireBooking] Formatted dateStr: $dateStr');

          // Free specific slots if period has slot start times (e.g. Day|6:00 AM,7:00 AM)
          if (periodStr != null && periodStr.contains('|')) {
            final parts = periodStr.split('|');
            if (parts.length > 1) {
              final startTimes = parts[1].split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
              final amount = double.tryParse(bookingData['amount']?.toString() ?? '0') ?? 0;
              final startTimesList = startTimes.toList();
              final slotPrice = startTimesList.isNotEmpty ? (amount / startTimesList.length).toInt() : 0;
              print('[deleteOrExpireBooking] startTimesList: $startTimesList, calculated slotPrice: $slotPrice');

              for (final startTime in startTimesList) {
                try {
                  print('[deleteOrExpireBooking] Calling upsert_slot for $startTime...');
                  final res = await _supabase.rpc('upsert_slot', params: {
                    'p_ground_id': groundId,
                    'p_date': dateStr,
                    'p_start_time': startTime,
                    'p_status': 'available',
                    'p_price': slotPrice,
                  });
                  print('[deleteOrExpireBooking] upsert_slot success for $startTime. Res: $res');
                } catch (e) {
                  print('[deleteOrExpireBooking] Error in upsert_slot for $startTime: $e');
                }
              }
            } else {
              print('[deleteOrExpireBooking] periodStr parts length <= 1');
            }
          } else {
            print('[deleteOrExpireBooking] periodStr does not contain |');
          }
        } else {
          print('[deleteOrExpireBooking] slotDate parsing failed for $slotTimeStr');
        }
      } else {
        print('[deleteOrExpireBooking] Missing slotTimeStr or groundId');
      }

      // Notify user
      final userId = bookingData['user_id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        String groundName = 'the ground';
        if (bookingData['grounds'] is Map && bookingData['grounds']['name'] != null) {
          groundName = bookingData['grounds']['name'];
        }

        String title = 'Booking Request Declined';
        String msg = 'Your booking request for $groundName was declined by the owner.';
        if (reason == 'expired_owner_timeout') {
          title = 'Booking Request Expired';
          msg = 'Your booking request for $groundName expired as the owner did not respond within 45 minutes.';
        } else if (reason == 'expired_user_payment_timeout') {
          title = 'Booking Cancelled (Payment Timeout)';
          msg = 'Your booking for $groundName was cancelled as payment was not completed within 45 minutes.';
        }

        try {
          final notifInsert = await _supabase.from('notifications').insert({
            'user_id': userId,
            'title': title,
            'message': msg,
            'type': 'booking_cancelled',
            'data': {
              'booking_id': bookingId,
              'ground_name': groundName,
              'reason': reason,
            },
            'is_read': false,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          }).select('id').maybeSingle();

          final notifId = notifInsert?['id']?.toString();
          if (notifId != null) {
            await _invokePushNotification(notifId);
          }
        } catch (e) {
          print('[deleteOrExpireBooking] Notification error: $e');
        }
      }
    }
  }
}
