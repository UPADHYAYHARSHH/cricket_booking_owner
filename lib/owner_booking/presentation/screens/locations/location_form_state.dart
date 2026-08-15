import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_form_data.dart';

abstract class LocationFormState {}

class LocationFormInitial extends LocationFormState {}

class LocationFormReady extends LocationFormState {
  final LocationFormData data;
  final int currentStep;

  LocationFormReady(this.data, {this.currentStep = 1});
}

class LocationFormSaving extends LocationFormState {}

class LocationFormSaved extends LocationFormState {
  final bool isEdit;
  final String locationId;

  LocationFormSaved({required this.isEdit, required this.locationId});
}

class LocationFormError extends LocationFormState {
  final String message;
  LocationFormError(this.message);
}
