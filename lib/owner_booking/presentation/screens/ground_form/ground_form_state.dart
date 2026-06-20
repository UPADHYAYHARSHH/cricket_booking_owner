import 'ground_form_data.dart';

abstract class GroundFormState {}

class GroundFormInitial extends GroundFormState {}

class GroundFormLoading extends GroundFormState {}

class GroundFormReady extends GroundFormState {
  final GroundFormData data;
  final int currentStep; // 1–7
  GroundFormReady(this.data, {this.currentStep = 1});
}

class GroundFormSaving extends GroundFormState {}

class GroundFormSaved extends GroundFormState {
  final bool isEdit;
  GroundFormSaved({required this.isEdit});
}

class GroundFormError extends GroundFormState {
  final String message;
  GroundFormError(this.message);
}
