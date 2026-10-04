import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/common/utils/booking_financial_util.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final SupabaseClient _supabase;

  BookingRepositoryImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getOwnerGrounds(String ownerId) async {
    // Only exclude grounds if their location has been soft-deleted.
    // Active/inactive status toggles public booking availability, but owners
    // must always be able to view their grounds and manage existing bookings.
    final response = await _supabase
        .from('grounds')
        .select('id, name, location_id, locations(documents_verified, is_active, deleted_at)')
        .eq('owner_id', ownerId)
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
      'checked_in_at': DateTime.now().toUtc().toIso8601String(),
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
    // Only exclude bookings if their ground's location has been soft-deleted.
    final response = await _supabase
        .from('bookings')
        .select(
            '*, grounds!inner(name, category, location_id, owner_id, locations(documents_verified, is_active, deleted_at))')
        .eq('grounds.owner_id', ownerId)
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

  
  Future<void> notifyUserToPay(String bookingId) async {
    try {
      final fetched = await _supabase.from('bookings').select('*, grounds(name, owner_id)').eq('id', bookingId).maybeSingle();
      if (fetched == null) return;
      
      final bookingData = Map<String, dynamic>.from(fetched);
      final userId = bookingData['user_id']?.toString();
      if (userId == null || userId.isEmpty) return;

      String groundName = 'the venue';
      if (bookingData['grounds'] is Map && bookingData['grounds']['name'] != null) {
        groundName = bookingData['grounds']['name'];
      }

      final inserted = await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': 'Payment Reminder ⏰',
        'message': 'Friendly reminder: Please complete payment for your booking at $groundName within the 45-minute window to secure your slot!',
        'type': 'booking_approved',
        'data': {
          'booking_id': bookingId,
          'ground_id': bookingData['ground_id'],
          'amount': bookingData['amount'],
          'action': 'payment_required'
        },
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }).select('id').maybeSingle();

      if (inserted != null && inserted['id'] != null) {
        _invokePushNotification(inserted['id'].toString());
      }
    } catch (e) {
      print('[notifyUserToPay] Error: $e');
    }
  }

  @override
  Future<void> deleteOrExpireBooking(
String bookingId, {String reason = 'declined_by_owner'}) async {
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
      await _supabase.rpc('delete_or_expire_booking', params: {
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

      // Record in cancellation_history for audit trail
      try {
        final groundName = (bookingData['grounds'] is Map && bookingData['grounds']['name'] != null)
            ? bookingData['grounds']['name'].toString()
            : (bookingData['ground_name']?.toString() ?? 'Venue');
        final nowUtc = DateTime.now().toUtc();
        await _supabase.from('cancellation_history').insert({
          'booking_id': bookingId,
          'user_id': bookingData['user_id']?.toString(),
          'ground_id': bookingData['ground_id'],
          'ground_name': groundName,
          'sport_name': bookingData['sport_name'] ?? bookingData['sport'],
          'slot_time': bookingData['slot_time'],
          'cancelled_by': reason.contains('owner') ? 'owner' : (reason.contains('timeout') ? 'timeout' : 'user'),
          'cancellation_reason': reason,
          'refund_percent': 0.0,
          'coins_issued': 0.0,
          'owner_compensation': 0.0,
          'total_booking_amount': (bookingData['amount'] as num?)?.toDouble() ?? 0.0,
          'cancelled_at': nowUtc.toIso8601String(),
        });
      } catch (histErr) {
        print('[deleteOrExpireBooking] cancellation_history insert error: $histErr');
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getOwnerCancellations(String ownerId) async {
    try {
      // 1. Get owner's ground IDs
      final grounds = await getOwnerGrounds(ownerId);
      final groundIds = grounds.map((g) => g['id'].toString()).toList();
      if (groundIds.isEmpty) return [];

      // 2. Query cancellation_history for these grounds
      try {
        final hist = await _supabase
            .from('cancellation_history')
            .select('*')
            .inFilter('ground_id', groundIds)
            .order('cancelled_at', ascending: false);

        if (hist.isNotEmpty) {
          final userIds = hist
              .map((h) => h['user_id']?.toString())
              .where((u) => u != null && u.isNotEmpty)
              .cast<String>()
              .toSet()
              .toList();

          Map<String, Map<String, dynamic>> userMap = {};
          if (userIds.isNotEmpty) {
            try {
              final users = await fetchUsers(userIds);
              for (final u in users) {
                if (u['id'] != null) userMap[u['id'].toString()] = u;
              }
            } catch (_) {}
          }

          return List<Map<String, dynamic>>.from(hist.map((h) {
            final m = Map<String, dynamic>.from(h as Map);
            final uid = m['user_id']?.toString();
            if (uid != null && userMap.containsKey(uid)) {
              m['player_name'] = userMap[uid]!['name'] ?? userMap[uid]!['displayName'] ?? 'Player';
              m['player_phone'] = userMap[uid]!['phone'] ?? userMap[uid]!['phoneNumber'] ?? '';
            }
            return m;
          }));
        }
      } catch (e) {
        print('[getOwnerCancellations] cancellation_history query error: $e');
      }

      // 3. Fallback: Query bookings table for cancelled / declined bookings
      final bRes = await _supabase
          .from('bookings')
          .select('*, grounds(name, sport_category)')
          .inFilter('ground_id', groundIds)
          .inFilter('status', ['cancelled', 'declined', 'expired'])
          .order('created_at', ascending: false);

      if (bRes.isNotEmpty) {
        final userIds = bRes
            .map((b) => b['user_id']?.toString())
            .where((u) => u != null && u.isNotEmpty)
            .cast<String>()
            .toSet()
            .toList();

        Map<String, Map<String, dynamic>> userMap = {};
        if (userIds.isNotEmpty) {
          try {
            final users = await fetchUsers(userIds);
            for (final u in users) {
              if (u['id'] != null) userMap[u['id'].toString()] = u;
            }
          } catch (_) {}
        }

        return List<Map<String, dynamic>>.from(bRes.map((b) {
          final m = Map<String, dynamic>.from(b as Map);
          final uid = m['user_id']?.toString();
          String playerName = 'Player';
          String playerPhone = '';
          if (uid != null && userMap.containsKey(uid)) {
            playerName = userMap[uid]!['name'] ?? userMap[uid]!['displayName'] ?? 'Player';
            playerPhone = userMap[uid]!['phone'] ?? userMap[uid]!['phoneNumber'] ?? '';
          }

          final gName = (m['grounds'] is Map ? m['grounds']['name'] : null) ?? m['ground_name'] ?? 'Court';

          return {
            'id': m['id']?.toString() ?? '',
            'booking_id': m['id']?.toString() ?? '',
            'ground_id': m['ground_id']?.toString() ?? '',
            'ground_name': gName,
            'sport_name': m['sport_name'] ?? m['sport'] ?? 'Sport',
            'player_name': playerName,
            'player_phone': playerPhone,
            'slot_time': m['slot_time'],
            'status': m['status'] ?? 'cancelled',
            'cancelled_by': m['cancelled_by'] ?? (m['status'] == 'declined' ? 'owner' : 'user'),
            'cancellation_reason': m['cancellation_reason'] ?? m['notes'] ?? 'Cancelled',
            'refund_percent': m['refund_percent'] ?? 0,
            'coins_issued': (m['cancellation_coins_issued'] as num?)?.toDouble() ?? 0.0,
            'total_booking_amount': (m['amount'] as num?)?.toDouble() ?? 0.0,
            'cancelled_at': m['cancelled_at'] ?? m['created_at'],
          };
        }));
      }
    } catch (e) {
      print('[getOwnerCancellations] Error: $e');
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> cancelBookingByOwner({
    required String bookingId,
    required String reason,
    bool reopenSlot = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final ownerId = user?.uid ?? '';

    // 1. Try invoking the dedicated Postgres RPC cancel_booking_by_owner
    try {
      final res = await _supabase.rpc('cancel_booking_by_owner', params: {
        'p_booking_id': bookingId,
        'p_owner_id': ownerId,
        'p_reason': reason,
        'p_reopen_slot': reopenSlot,
      });

      if (res != null) {
        final Map<String, dynamic> resultMap = res is String
            ? jsonDecode(res)
            : Map<String, dynamic>.from(res as Map);
        if (resultMap['success'] == true) {
          // Zero out owner_earnings on the cancelled booking in DB
          try {
            await _supabase.from('bookings').update({
              'owner_earnings': 0.0,
              'owner_compensation': 0.0,
            }).eq('id', bookingId);
          } catch (_) {}

          // Deduct from owner_wallets in case DB trigger/RPC didn't
          try {
            final fetched = await _supabase
                .from('bookings')
                .select('amount, total_amount, base_amount, notes, ground_id, grounds(owner_id)')
                .eq('id', bookingId)
                .maybeSingle();
            final gOwnerId = (fetched?['grounds'] is Map && fetched?['grounds']['owner_id'] != null)
                ? fetched!['grounds']['owner_id'].toString()
                : ownerId;
            final double deductAmount = (resultMap['coins_issued'] as num?)?.toDouble() ??
                (fetched?['amount'] as num?)?.toDouble() ??
                0.0;
            if (gOwnerId.isNotEmpty && deductAmount > 0) {
              final ow = await _supabase
                  .from('owner_wallets')
                  .select()
                  .eq('owner_id', gOwnerId)
                  .maybeSingle();
              if (ow != null) {
                final curTot = (ow['total_earnings'] as num?)?.toDouble() ?? 0.0;
                final curAvail = (ow['available_balance'] as num?)?.toDouble() ?? 0.0;
                await _supabase.from('owner_wallets').update({
                  'total_earnings': (curTot - deductAmount).clamp(0.0, double.infinity),
                  'available_balance': (curAvail - deductAmount).clamp(0.0, double.infinity),
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                }).eq('owner_id', gOwnerId);
              }
            }
          } catch (_) {}

          // Trigger push notification if available
          try {
            final notif = await _supabase
                .from('notifications')
                .select('id')
                .eq('type', 'cancellation_coins_credited')
                .contains('data', {'booking_id': bookingId})
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();
            if (notif != null && notif['id'] != null) {
              await _invokePushNotification(notif['id'].toString());
            }
          } catch (_) {}
          return resultMap;
        } else if (resultMap['error'] != null) {
          print('[cancelBookingByOwner] RPC error: ${resultMap['error']}, falling back to direct operations');
        }
      }
    } catch (e) {
      print('[cancelBookingByOwner] RPC failed: $e, falling back to direct operations');
    }

    // 2. Direct Fallback: Client-side atomic orchestration
    Map<String, dynamic>? bookingData;
    try {
      final fetched = await _supabase
          .from('bookings')
          .select('*, grounds(name, owner_id)')
          .eq('id', bookingId)
          .maybeSingle();
      if (fetched != null) {
        bookingData = Map<String, dynamic>.from(fetched);
      }
    } catch (e) {
      print('[cancelBookingByOwner] Error fetching booking: $e');
    }

    if (bookingData == null) {
      throw Exception('Booking not found');
    }

    final nowUtc = DateTime.now().toUtc();
    final double rawAmount = (bookingData['amount'] as num?)?.toDouble() ??
        (bookingData['total_amount'] as num?)?.toDouble() ??
        (bookingData['base_amount'] as num?)?.toDouble() ??
        0.0;
    final refundCoins = rawAmount;
    final double previousOwnerEarnings = (bookingData['owner_earnings'] as num?)?.toDouble() ??
        BookingFinancialUtil.getOwnerEarnings(bookingData);

    // A. Update booking status to cancelled
    try {
      await _supabase.from('bookings').update({
        'status': 'cancelled',
        'cancelled_at': nowUtc.toIso8601String(),
        'cancelled_by': 'owner',
        'cancellation_reason': reason,
        'cancellation_coins_issued': refundCoins,
        'owner_compensation': 0.0,
        'owner_earnings': 0.0,
      }).eq('id', bookingId);
    } catch (updateErr) {
      print('[cancelBookingByOwner] Detailed update failed, trying minimal update: $updateErr');
      await _supabase.from('bookings').update({
        'status': 'cancelled',
        'owner_earnings': 0.0,
        'notes': 'Cancelled by owner: $reason',
      }).eq('id', bookingId);
    }

    // B. Reopen slots if requested
    if (reopenSlot) {
      final groundId = bookingData['ground_id'];
      final slotTimeStr = bookingData['slot_time']?.toString();
      final periodStr = bookingData['period']?.toString();

      if (slotTimeStr != null && groundId != null) {
        final slotDate = DateTime.tryParse(slotTimeStr)?.toLocal();
        if (slotDate != null) {
          final dateStr =
              "${slotDate.year}-${slotDate.month.toString().padLeft(2, '0')}-${slotDate.day.toString().padLeft(2, '0')}";
          if (periodStr != null && periodStr.contains('|')) {
            final parts = periodStr.split('|');
            if (parts.length > 1) {
              final startTimes = parts[1]
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              final slotPrice = startTimes.isNotEmpty
                  ? (refundCoins / startTimes.length).toInt()
                  : refundCoins.toInt();

              for (final startTime in startTimes) {
                try {
                  await _supabase.rpc('upsert_slot', params: {
                    'p_ground_id': groundId,
                    'p_date': dateStr,
                    'p_start_time': startTime,
                    'p_status': 'available',
                    'p_price': slotPrice,
                  });
                } catch (e) {
                  print('[cancelBookingByOwner] Error upserting slot: $e');
                }
              }
            }
          }
        }
      }
    }

    // C. Credit user's wallet with 100% refund in Playora Coins
    final userId = bookingData['user_id']?.toString();
    String groundName = 'the venue';
    if (bookingData['grounds'] is Map && bookingData['grounds']['name'] != null) {
      groundName = bookingData['grounds']['name'].toString();
    } else if (bookingData['ground_name'] != null) {
      groundName = bookingData['ground_name'].toString();
    }

    if (userId != null && userId.isNotEmpty && refundCoins > 0) {
      try {
        final existingWallet = await _supabase
            .from('wallets')
            .select('balance')
            .eq('user_id', userId)
            .maybeSingle();

        final currentBal =
            (existingWallet?['balance'] as num?)?.toDouble() ?? 0.0;
        final newBal = currentBal + refundCoins;

        try {
          await _supabase.from('wallets').upsert({
            'user_id': userId,
            'balance': newBal,
            'updated_at': nowUtc.toIso8601String(),
          }, onConflict: 'user_id');
        } catch (_) {
          await _supabase.from('wallets').upsert({
            'user_id': userId,
            'balance': newBal,
          }, onConflict: 'user_id');
        }

        await _supabase.from('wallet_transactions').insert({
          'user_id': userId,
          'amount': refundCoins,
          'type': 'cancellation_credit',
          'description':
              'Booking cancelled by venue owner: 100% refund for $groundName',
          'reference_id': bookingId,
          'created_at': nowUtc.toIso8601String(),
        });
      } catch (wErr) {
        print('[cancelBookingByOwner] Wallet update error: $wErr');
      }
    }

    // C2. Deduct previous earnings from owner_wallets
    String? groundOwnerId;
    if (bookingData['grounds'] is Map && bookingData['grounds']['owner_id'] != null) {
      groundOwnerId = bookingData['grounds']['owner_id'].toString();
    } else {
      groundOwnerId = ownerId;
    }

    if (groundOwnerId.isNotEmpty && previousOwnerEarnings > 0) {
      try {
        final existingOwnerWallet = await _supabase
            .from('owner_wallets')
            .select()
            .eq('owner_id', groundOwnerId)
            .maybeSingle();

        if (existingOwnerWallet != null) {
          final double curTotal = (existingOwnerWallet['total_earnings'] as num?)?.toDouble() ?? 0.0;
          final double curAvail = (existingOwnerWallet['available_balance'] as num?)?.toDouble() ?? 0.0;

          final double newTotal = (curTotal - previousOwnerEarnings).clamp(0.0, double.infinity);
          final double newAvail = (curAvail - previousOwnerEarnings).clamp(0.0, double.infinity);

          await _supabase.from('owner_wallets').update({
            'total_earnings': newTotal,
            'available_balance': newAvail,
            'updated_at': nowUtc.toIso8601String(),
          }).eq('owner_id', groundOwnerId);
        }
      } catch (owErr) {
        print('[cancelBookingByOwner] Error deducting from owner_wallets: $owErr');
      }
    }

    // D. Notification to player & Push
    if (userId != null && userId.isNotEmpty) {
      try {
        final notifInsert = await _supabase.from('notifications').insert({
          'user_id': userId,
          'title': 'Booking Cancelled by Venue',
          'message':
              'Your booking for $groundName was cancelled by the venue owner (Reason: $reason). ₹${refundCoins.toStringAsFixed(0)} Playora Coins have been refunded to your wallet.',
          'type': 'cancellation_coins_credited',
          'data': {
            'booking_id': bookingId,
            'ground_name': groundName,
            'coins_issued': refundCoins,
            'refund_percent': 100.0,
            'cancelled_by': 'owner',
            'reason': reason,
          },
          'is_read': false,
          'created_at': nowUtc.toIso8601String(),
        }).select('id').maybeSingle();

        final notifId = notifInsert?['id']?.toString();
        if (notifId != null) {
          await _invokePushNotification(notifId);
        }
      } catch (nErr) {
        print('[cancelBookingByOwner] Notification error: $nErr');
      }
    }

    // E. Record in cancellation_history
    try {
      await _supabase.from('cancellation_history').insert({
        'booking_id': bookingId,
        'user_id': userId,
        'ground_id': bookingData['ground_id'],
        'ground_name': groundName,
        'sport_name': bookingData['sport_name'] ?? bookingData['sport'],
        'slot_time': bookingData['slot_time'],
        'cancelled_by': 'owner',
        'cancellation_reason': reason,
        'refund_percent': 100.0,
        'coins_issued': refundCoins,
        'owner_compensation': 0.0,
        'total_booking_amount': refundCoins,
        'cancelled_at': nowUtc.toIso8601String(),
      });
    } catch (hErr) {
      print('[cancelBookingByOwner] cancellation_history error: $hErr');
    }

    return {
      'success': true,
      'booking_id': bookingId,
      'status': 'cancelled',
      'refund_percent': 100.0,
      'coins_issued': refundCoins,
      'owner_compensation': 0.0,
      'reason': reason,
    };
  }
}
