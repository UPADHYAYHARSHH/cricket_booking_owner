import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

abstract class SlotState {}

class SlotInitial extends SlotState {}
class SlotLoading extends SlotState {}
class SlotLoaded extends SlotState {
  final List<dynamic> slots;
  SlotLoaded(this.slots);
}
class SlotError extends SlotState {
  final String message;
  SlotError(this.message);
}

class SlotCubit extends Cubit<SlotState> {
  SlotCubit() : super(SlotInitial());

  Future<void> fetchSlots(String groundId, DateTime date) async {
    emit(SlotLoading());
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    try {
      final data = await Supabase.instance.client
          .from('slots')
          .select()
          .eq('ground_id', groundId)
          .eq('date', dateStr);
      
      if (data.isEmpty) {
        // If no slots exist for this date, we might need to generate them
        // or show a message.
      }
      
      emit(SlotLoaded(data));
    } catch (e) {
      emit(SlotError(e.toString()));
    }
  }

  Future<void> toggleSlotStatus(String slotId, bool isBlocked) async {
    try {
      await Supabase.instance.client
          .from('slots')
          .update({'status': isBlocked ? 'blocked' : 'available'})
          .eq('id', slotId);
    } catch (e) {
      emit(SlotError(e.toString()));
    }
  }
}
