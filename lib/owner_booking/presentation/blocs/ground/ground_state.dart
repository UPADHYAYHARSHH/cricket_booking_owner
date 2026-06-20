abstract class GroundState {}

class GroundInitial extends GroundState {}

class GroundLoading extends GroundState {}

class GroundLoaded extends GroundState {
  final List<dynamic> grounds;
  GroundLoaded(this.grounds);
}

class GroundError extends GroundState {
  final String message;
  GroundError(this.message);
}
