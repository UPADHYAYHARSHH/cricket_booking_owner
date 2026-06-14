import 'package:flutter/material.dart';

enum SlotStatus { open, booked, blocked, peak, maintenance }

class VirtualSlot {
  final DateTime startTime;
  final DateTime endTime;
  final SlotStatus status;
  final int price;
  final String? bookedPlayerName;
  final int? bookedPlayersCount;
  final String? bookingId;

  VirtualSlot({
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.price,
    this.bookedPlayerName,
    this.bookedPlayersCount,
    this.bookingId,
  });
}

abstract class SlotState {}

class SlotInitial extends SlotState {}
class SlotLoading extends SlotState {}

class SlotLoaded extends SlotState {
  final String venueName;
  final List<Map<String, dynamic>> grounds;
  final String selectedGroundId;
  final DateTime selectedDate;
  final List<VirtualSlot> slots;
  final int bookedCount;
  final int totalSlots;
  final int todayRevenue;

  SlotLoaded({
    required this.venueName,
    required this.grounds,
    required this.selectedGroundId,
    required this.selectedDate,
    required this.slots,
    required this.bookedCount,
    required this.totalSlots,
    required this.todayRevenue,
  });

  SlotLoaded copyWith({
    String? venueName,
    List<Map<String, dynamic>>? grounds,
    String? selectedGroundId,
    DateTime? selectedDate,
    List<VirtualSlot>? slots,
    int? bookedCount,
    int? totalSlots,
    int? todayRevenue,
  }) {
    return SlotLoaded(
      venueName: venueName ?? this.venueName,
      grounds: grounds ?? this.grounds,
      selectedGroundId: selectedGroundId ?? this.selectedGroundId,
      selectedDate: selectedDate ?? this.selectedDate,
      slots: slots ?? this.slots,
      bookedCount: bookedCount ?? this.bookedCount,
      totalSlots: totalSlots ?? this.totalSlots,
      todayRevenue: todayRevenue ?? this.todayRevenue,
    );
  }
}

class SlotError extends SlotState {
  final String message;
  SlotError(this.message);
}
