import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/ground_repository.dart';
import 'ground_state.dart';

class GroundCubit extends Cubit<GroundState> {
  final GroundRepository _groundRepository;

  GroundCubit(this._groundRepository) : super(GroundInitial());

  Future<void> fetchOwnerGrounds() async {
    emit(GroundLoading());
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final grounds = await _groundRepository.getOwnerGrounds(userId);
      emit(GroundLoaded(grounds));
    } catch (e) {
      emit(GroundError(e.toString()));
    }
  }

  Future<void> fetchGroundsForLocation(String locationId) async {
    emit(GroundLoading());

    try {
      final grounds = await _groundRepository.getGroundsForLocation(locationId);
      emit(GroundLoaded(grounds));
    } catch (e) {
      emit(GroundError(e.toString()));
    }
  }

  /// Pass [locationId] to refresh a single location's grounds, or omit it
  /// (e.g. when viewing "All Locations") to refresh the owner's full list.
  Future<void> setGroundAvailability(
    String groundId,
    bool isAvailable, {
    String? locationId,
  }) async {
    try {
      await _groundRepository.updateGround(
        groundId: groundId,
        data: {'is_available': isAvailable},
      );
      if (locationId != null) {
        await fetchGroundsForLocation(locationId);
      } else {
        await fetchOwnerGrounds();
      }
    } catch (e) {
      emit(GroundError(e.toString()));
    }
  }
}
