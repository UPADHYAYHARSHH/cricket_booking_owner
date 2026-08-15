import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/location_repository.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_form_data.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_form_state.dart';


class LocationFormCubit extends Cubit<LocationFormState> {
  final LocationRepository _repo;
  LocationFormData _data = LocationFormData.empty();

  LocationFormCubit(this._repo) : super(LocationFormInitial());

  LocationFormData get data => _data;

  void initAdd() {
    _data = LocationFormData.empty();
    emit(LocationFormReady(_data, currentStep: 1));
  }

  void initEdit(Map<String, dynamic> locationMap) {
    _data = LocationFormData.fromMap(locationMap);
    emit(LocationFormReady(_data, currentStep: 1));
  }

  void updateData(LocationFormData newData) {
    _data = newData;
    final step = state is LocationFormReady
        ? (state as LocationFormReady).currentStep
        : 1;
    emit(LocationFormReady(_data, currentStep: step));
  }

  void goToStep(int step) {
    emit(LocationFormReady(_data, currentStep: step));
  }

  Future<void> save() async {
    emit(LocationFormSaving());
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      emit(LocationFormError('Not authenticated'));
      return;
    }

    try {
      String locId = _data.locationId ?? '';
      bool isEdit = _data.locationId != null;

      if (isEdit) {
        // Edit: update existing location row.
        await _repo.updateLocation(
          locationId: locId,
          data: _data.toUpdateMap(),
        );
      } else {
        // Add: insert new location.
        locId = await _repo.registerLocation(
          ownerId: userId,
          address: _data.address,
          city: _data.city,
          description: _data.description,
          privacyPolicy: _data.privacyPolicy,
          googleMapsLink: _data.googleMapsLink,
          latitude: _data.latitude,
          longitude: _data.longitude,
          amenities: _data.amenities,
        );
      }
      
      // Handle Documents
      String? propDocUrl = _data.propertyDocumentUrl;
      String? nocUrl = _data.nocUrl;

      if (propDocUrl != null && !propDocUrl.startsWith('http')) {
        propDocUrl = await _repo.uploadLocationDocument(
            ownerId: userId, locationId: locId, filePath: propDocUrl);
      }
      if (nocUrl != null && !nocUrl.startsWith('http')) {
        nocUrl = await _repo.uploadLocationDocument(
            ownerId: userId, locationId: locId, filePath: nocUrl);
      }

      await _repo.updateLocation(locationId: locId, data: {
        'property_status': _data.propertyStatus,
        ? 'property_document_url': propDocUrl,
        ? 'noc_url': nocUrl,
      });

      // Handle Images
      List<String> newImagesToUpload = _data.images.where((img) => !img.startsWith('http')).toList();
      
      // Assuming _repo handles inserting into `location_images`
      // First we clear old images and reinsert or just append new ones. 
      // For simplicity let's do syncLocationImages.
      await _repo.syncLocationImages(
        ownerId: userId,
        locationId: locId,
        allImages: _data.images,
        newImagesToUpload: newImagesToUpload,
      );

      emit(LocationFormSaved(isEdit: isEdit, locationId: locId));
    } catch (e) {
      emit(LocationFormError(e.toString()));
    }
  }
}
