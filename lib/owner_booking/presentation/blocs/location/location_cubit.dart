import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/location_repository.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  final LocationRepository _locationRepository;

  LocationCubit(this._locationRepository) : super(LocationInitial());

  Future<void> fetchOwnerLocations() async {
    emit(LocationLoading());
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final locations = await _locationRepository.getOwnerLocations(userId);
      emit(LocationLoaded(locations));
    } catch (e) {
      emit(LocationError(e.toString()));
    }
  }

  Future<String?> registerLocation({
    required String address,
    required String city,
    required String description,
    required String privacyPolicy,
    required String googleMapsLink,
    required double latitude,
    required double longitude,
    required List<String> amenities,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    try {
      final locationId = await _locationRepository.registerLocation(
        ownerId: userId,
        address: address,
        city: city,
        description: description,
        privacyPolicy: privacyPolicy,
        googleMapsLink: googleMapsLink,
        latitude: latitude,
        longitude: longitude,
        amenities: amenities,
      );
      await fetchOwnerLocations();
      return locationId;
    } catch (e) {
      emit(LocationError(e.toString()));
      return null;
    }
  }

  Future<void> updateLocation({
    required String locationId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _locationRepository.updateLocation(locationId: locationId, data: data);
      await fetchOwnerLocations();
    } catch (e) {
      emit(LocationError(e.toString()));
    }
  }

  Future<void> deleteLocation(String locationId) async {
    try {
      await _locationRepository.softDeleteLocation(locationId);
      await fetchOwnerLocations();
    } catch (e) {
      emit(LocationError(e.toString()));
    }
  }
}
