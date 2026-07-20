import 'package:turfpro_owner/owner_booking/data/models/sport_model.dart';

abstract class SportState {}

class SportInitial extends SportState {}

class SportLoading extends SportState {}

class SportLoaded extends SportState {
  final List<SportModel> sports;
  SportLoaded(this.sports);
}

class SportError extends SportState {
  final String message;
  SportError(this.message);
}
