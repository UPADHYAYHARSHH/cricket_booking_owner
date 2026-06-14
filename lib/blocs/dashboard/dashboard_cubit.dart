import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as f_auth;
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(DashboardInitial());

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
          final groundIds = groundsData.map((g) => g['id']).toList();
          final groundMap = {for (var g in groundsData) g['id']: g['name']};

          // 2. Fetch bookings for those grounds
          final bookings = await Supabase.instance.client
              .from('bookings')
              .select()
              .filter('ground_id', 'in', groundIds)
              .order('created_at', ascending: false);

          for (var b in bookings) {
            final status = b['status']?.toString().toLowerCase() ?? '';
            final bookingDateStr = b['booking_date'] ?? b['created_at'];
            bool isToday = false;
            
            if (bookingDateStr != null) {
              try {
                final bDate = DateTime.parse(bookingDateStr).toLocal();
                final now = DateTime.now();
                if (bDate.year == now.year && bDate.month == now.month && bDate.day == now.day) {
                  isToday = true;
                  todayBookingsCount++;
                  if (status == 'confirmed' || status == 'completed') {
                    todayRevenue += (b['amount'] ?? b['total_amount'] ?? 0).toDouble();
                  }
                  
                  // Add to today's slots
                  todaySlots.add({
                    ...b,
                    'ground_name': groundMap[b['ground_id']] ?? 'Unknown Ground',
                  });
                }
              } catch (_) {}
            }

            // Pending Accept
            if (status == 'pending') {
              pendingAcceptCount++;
              pendingApprovals.add({
                ...b,
                'ground_name': groundMap[b['ground_id']] ?? 'Unknown Ground',
              });
            }
          }
          
          if (activeCourts > 0) {
            // Rough mock for occupancy based on total bookings
             occupancy = "${(todayBookingsCount / (activeCourts * 10) * 100).clamp(0, 100).toInt()}%";
          }
        }
      } catch (e) {
        print("Error fetching real bookings: $e");
        // We no longer fallback to dummy data! We just leave it as 0.
      }

      emit(DashboardLoaded(
        ownerName: ownerName,
        venueName: venueName,
        activeCourts: activeCourts > 0 ? activeCourts : 3, // fallback to 3 if none configured
        todayRevenue: "₹${todayRevenue.toInt()}",
        todayBookingsCount: todayBookingsCount,
        pendingAcceptCount: pendingAcceptCount,
        occupancyPercentage: occupancy,
        todaySlots: todaySlots,
        pendingApprovals: pendingApprovals,
      ));

    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
