enum SlotStatus { open, booked, blocked, peak, maintenance }

class VirtualSlot {
  final DateTime startTime;
  final DateTime endTime;
  final SlotStatus status;
  final int price;
  final String? bookedPlayerName;
  final int? bookedPlayersCount;
  final String? bookingId;
  final String? blockedSlotId;
  final String? blockReason;

  VirtualSlot({
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.price,
    this.bookedPlayerName,
    this.bookedPlayersCount,
    this.bookingId,
    this.blockedSlotId,
    this.blockReason,
  });
}
