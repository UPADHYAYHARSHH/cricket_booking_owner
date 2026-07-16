import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/booking_repository.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/location_repository.dart';
import 'package:turfpro_owner/common/services/shared_prefs_service.dart';
import 'revenue_state.dart';

class RevenueCubit extends Cubit<RevenueState> {
  final BookingRepository _bookingRepository;
  final LocationRepository _locationRepository;

  RevenueCubit(this._bookingRepository, this._locationRepository)
      : super(RevenueInitial());

  Future<void> fetchRevenueData() async {
    emit(RevenueLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(RevenueError('User not logged in'));
        return;
      }

      final locations = await _locationRepository.getOwnerLocations(user.uid);
      final allBookings =
          await _bookingRepository.getOwnerBookingsWithDetails(user.uid);

      final locationId = SharedPrefsService.instance.selectedLocationId;
      var bookings = allBookings;

      if (locationId != null) {
        bookings = bookings.where((b) {
          final ground = b['grounds'];
          if (ground is Map) {
            return ground['location_id'] == locationId;
          }
          return false;
        }).toList();
      }

      emit(RevenueLoaded(bookings: bookings, locations: locations));
    } catch (e) {
      emit(RevenueError(e.toString()));
    }
  }
}
