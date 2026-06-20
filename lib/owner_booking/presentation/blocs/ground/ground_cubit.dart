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

  Future<void> registerGround({
    required String name,
    required String category,
    required String description,
    required String openingTime,
    required String closingTime,
    required List<String> imageUrls,
    required List<String> amenities,
    Map<String, int>? pricingOverrides,
    List<String>? allCategories,
    Map<String, int>? sportsConfig,
  }) async {
    emit(GroundLoading());
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final groundId = await _groundRepository.registerGround(
        ownerId: userId,
        name: name,
        category: category,
        description: description,
        openingTime: openingTime,
        closingTime: closingTime,
        imageUrls: imageUrls,
        amenities: amenities,
        address: '',
        latitude: 0.0,
        longitude: 0.0,
        pricingOverrides: pricingOverrides,
        allCategories: allCategories,
        sportsConfig: sportsConfig,
      );

      await _groundRepository.insertGroundImages(groundId, imageUrls);
      await _groundRepository.generateSlots(
        groundId,
        openingTime,
        closingTime,
        pricingOverrides ?? {},
      );

      await fetchOwnerGrounds();
    } catch (e) {
      emit(GroundError(e.toString()));
    }
  }
}
