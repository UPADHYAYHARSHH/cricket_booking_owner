import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/owner_booking/data/models/sport_model.dart';
import 'package:turfpro_owner/owner_booking/data/repositories/sport_repository.dart';
import 'sport_state.dart';

class SportCubit extends Cubit<SportState> {
  final SportRepository _repository;

  SportCubit(this._repository) : super(SportInitial());

  Future<void> fetchSports() async {
    emit(SportLoading());
    try {
      final sports = await _repository.fetchSports();
      debugPrint('[SportCubit] Loaded ${sports.length} sports');
      emit(SportLoaded(sports));
    } catch (e) {
      debugPrint('[SportCubit] ERROR: $e');
      emit(SportError(e.toString()));
    }
  }

  SportModel? getSportBySlug(String slug) {
    final state = this.state;
    if (state is SportLoaded) {
      try {
        return state.sports.firstWhere((s) => s.slug == slug);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
