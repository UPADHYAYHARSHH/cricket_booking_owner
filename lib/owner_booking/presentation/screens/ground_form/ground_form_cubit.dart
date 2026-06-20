import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/ground_repository.dart';
import 'ground_form_data.dart';
import 'ground_form_state.dart';

class GroundFormCubit extends Cubit<GroundFormState> {
  final GroundRepository _repo;
  GroundFormData _data = GroundFormData.empty();

  GroundFormCubit(this._repo) : super(GroundFormInitial());

  GroundFormData get data => _data;

  void initAdd() {
    _data = GroundFormData.empty();
    emit(GroundFormReady(_data, currentStep: 1));
  }

  void initEdit(Map<String, dynamic> groundMap) {
    _data = GroundFormData.fromMap(groundMap);
    emit(GroundFormReady(_data, currentStep: 1));
  }

  void updateData(GroundFormData newData) {
    _data = newData;
    final step = state is GroundFormReady ? (state as GroundFormReady).currentStep : 1;
    emit(GroundFormReady(_data, currentStep: step));
  }

  void goToStep(int step) {
    emit(GroundFormReady(_data, currentStep: step));
  }

  Future<void> save() async {
    emit(GroundFormSaving());
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      emit(GroundFormError('Not authenticated'));
      return;
    }

    try {
      if (_data.groundId != null) {
        // Edit: update existing ground row; slot regeneration runs separately.
        await _repo.updateGround(
          groundId: _data.groundId!,
          data: _data.toUpdateMap(),
        );
        emit(GroundFormSaved(isEdit: true));
      } else {
        // Add: insert new ground + generate initial slots.
        final groundId = await _repo.registerGround(
          ownerId: userId,
          name: _data.name,
          category: _data.categories.isNotEmpty ? _data.categories.first : 'box_cricket',
          description: _data.description,
          openingTime: _data.openingTime,
          closingTime: _data.closingTime,
          imageUrls: _data.imageUrls,
          amenities: _data.amenities,
          address: _data.address,
          latitude: _data.latitude,
          longitude: _data.longitude,
          pricingOverrides: _data.pricingConfig,
          // Pass full categories so multi-sport is stored correctly.
          allCategories: _data.categories,
          sportsConfig: _data.sportsConfig,
        );

        // Generate slots for 14 days from today.
        await _repo.generateSlots(
          groundId,
          _data.openingTime,
          _data.closingTime,
          _data.pricingConfig,
        );

        emit(GroundFormSaved(isEdit: false));
      }
    } catch (e) {
      emit(GroundFormError(e.toString()));
    }
  }
}
