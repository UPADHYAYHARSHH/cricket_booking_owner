import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as f_auth;
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  StreamSubscription<List<Map<String, dynamic>>>? _bookingsSubscription;

  DashboardCubit() : super(DashboardInitial());

  @override
  Future<void> close() {
    _bookingsSubscription?.cancel();
    return super.close();
  }

  Future<void> fetchDashboardData() async {
    emit(DashboardLoading());
    try {
      final user = f_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(DashboardError("User not logged in"));
        return;
      }

      // Fetch Owner Details
      final ownerData = await Supabase.instance.client
          .from('owner_details')
          .select()
          .eq('id', user.uid)
          .maybeSingle();

      if (ownerData == null) {
        emit(DashboardError("Owner details not found"));
        return;
      }

      final ownerName = ownerData['owner_name'] ?? 'Owner';
      final venueName = ownerData['venue_name'] ?? 'Your Venue';
      
      int activeCourts = 0;
      final groundConfig = ownerData['ground_config'] as Map<String, dynamic>?;
      if (groundConfig != null) {
        // Iterate through each sport in ground_config and add up num_courts
        groundConfig.forEach((sportName, sportDetails) {
          if (sportDetails is Map<String, dynamic>) {
            final numCourts = sportDetails['num_courts'];
            if (numCourts is int) {
              activeCourts += numCourts;
            } else if (numCourts is String) {
              activeCourts += int.tryParse(numCourts) ?? 0;
            }
          }
        });
      }

      // Fetch Bookings Data
      double todayRevenue = 0;
      int todayBookingsCount = 0;
      int pendingAcceptCount = 0;
      String occupancy = "0%";
      List<dynamic> todaySlots = [];
      List<dynamic> pendingApprovals = [];

      try {
        // 1. Fetch grounds owned by this owner
        final groundsData = await Supabase.instance.client
            .from('grounds')
            .select('id, name')
            .eq('owner_id', user.uid);

        if (groundsData.isNotEmpty) {
          final List<Object> groundIds = groundsData.map((g) => g['id'] as Object).toList();
          final groundMap = {for (var g in groundsData) g['id']: g['name']};

          // 2. Cancel existing subscription if any
          await _bookingsSubscription?.cancel();

          // 3. Subscribe to bookings for those grounds
          _bookingsSubscription = Supabase.instance.client
              .from('bookings')
              .stream(primaryKey: ['id'])
              .inFilter('ground_id', groundIds)
              .order('created_at', ascending: false)
              .listen((bookings) {
                
                double todayRevenue = 0;
                int todayBookingsCount = 0;
                int pendingAcceptCount = 0;
                String occupancy = "0%";
                List<dynamic> todaySlots = [];
                List<dynamic> pendingApprovals = [];

                for (var b in bookings) {
                  final status = b['status']?.toString().toLowerCase() ?? '';
                  final bookingDateStr = b['booking_date'] ?? b['created_at'];
                  
                  if (bookingDateStr != null) {
                    try {
                      final bDate = DateTime.parse(bookingDateStr).toLocal();
                      final now = DateTime.now();
                      if (bDate.year == now.year && bDate.month == now.month && bDate.day == now.day) {
                        todayBookingsCount++;
                        if (status == 'confirmed' || status == 'completed') {
                          todayRevenue += (b['amount'] ?? b['total_amount'] ?? 0).toDouble();
                        }
                        
                        todaySlots.add({
                          ...b,
                          'ground_name': groundMap[b['ground_id']] ?? 'Unknown Ground',
                        });
                      }
                    } catch (_) {}
                  }

                  if (status == 'pending') {
                    pendingAcceptCount++;
                    pendingApprovals.add({
                      ...b,
                      'ground_name': groundMap[b['ground_id']] ?? 'Unknown Ground',
                    });
                  }
                }
                
                if (activeCourts > 0) {
                   occupancy = "${(todayBookingsCount / (activeCourts * 10) * 100).clamp(0, 100).toInt()}%";
                }

                emit(DashboardLoaded(
                  ownerName: ownerName,
                  venueName: venueName,
                  activeCourts: activeCourts > 0 ? activeCourts : 3,
                  todayRevenue: "₹${todayRevenue.toInt()}",
                  todayBookingsCount: todayBookingsCount,
                  pendingAcceptCount: pendingAcceptCount,
                  occupancyPercentage: occupancy,
                  todaySlots: todaySlots,
                  pendingApprovals: pendingApprovals,
                ));
              });
        }
      } catch (e) {
        print("Error setting up dashboard stream: $e");
      }

    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
