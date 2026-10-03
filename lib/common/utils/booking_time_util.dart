import 'package:intl/intl.dart';

class BookingTimeUtil {
  /// Resolves the canonical period label ('Morning', 'Afternoon', 'Evening', 'Night')
  /// based on the slot start time.
  static String resolvePeriodLabel(String? startTimeLabel) {
    if (startTimeLabel == null || startTimeLabel.trim().isEmpty) {
      return 'Night';
    }
    final t = startTimeLabel.trim().toUpperCase();
    final parts = t.split(' ');
    final hhmm = parts.first.split(':');
    int h;
    try {
      h = int.parse(hhmm.first);
    } catch (_) {
      return 'Night';
    }
    final ampm = parts.length > 1 ? parts[1] : '';
    if (ampm == 'PM' && h != 12) h += 12;
    if (ampm == 'AM' && h == 12) h = 0;
    if (h >= 6 && h < 12) return 'Morning';
    if (h >= 12 && h < 16) return 'Afternoon';
    if (h >= 16 && h < 20) return 'Evening';
    return 'Night';
  }

  /// Calculates a 1-hour end time given a start time string like "08:00 PM" or "8:00 PM"
  static String calculateEndTime(String startTime) {
    try {
      final cleanTime = startTime.trim();
      final parts = cleanTime.split(' ');
      if (parts.length != 2) return '';

      final timeParts = parts[0].split(':');
      if (timeParts.isEmpty) return '';

      int hour = int.parse(timeParts[0]);
      int minute = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;
      String amPm = parts[1].toUpperCase();

      hour += 1;
      if (hour == 12) {
        amPm = amPm == 'AM' ? 'PM' : 'AM';
      } else if (hour > 12) {
        hour -= 12;
      }

      final minuteStr = minute.toString().padLeft(2, '0');
      final hourStr = hour.toString().padLeft(2, '0');
      return '$hourStr:$minuteStr $amPm';
    } catch (_) {
      return '';
    }
  }

  /// Merges a list of comma-separated slot start times (e.g. "08:00 PM, 09:00 PM")
  /// or ranges (e.g. "08:00 PM - 09:00 PM, 09:00 PM - 10:00 PM") into
  /// a unified contiguous display range (e.g. "08:00 PM - 10:00 PM (2 slots)").
  static String mergeSlotRange(String slotCsv) {
    if (slotCsv.trim().isEmpty) return '';

    final rawSlots = slotCsv
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (rawSlots.isEmpty) return '';

    List<int> hours24 = [];
    for (String slot in rawSlots) {
      final startTimeStr = slot.contains('-') ? slot.split('-').first.trim() : slot;
      final timeParts = startTimeStr.split(':');
      if (timeParts.length >= 2) {
        int h = int.tryParse(timeParts[0]) ?? 0;
        final mPart = timeParts[1].trim().split(' ');
        final amPm = mPart.length > 1 ? mPart[1].toUpperCase() : '';
        if (amPm == 'PM' && h != 12) h += 12;
        if (amPm == 'AM' && h == 12) h = 0;
        hours24.add(h);
      }
    }

    if (hours24.isEmpty) return '';
    hours24.sort();

    List<String> ranges = [];
    int blockStart = hours24.first;
    int prevHour = hours24.first;

    String formatHour(int h) {
      int wrappedH = h % 24;
      final amPm = wrappedH >= 12 ? 'PM' : 'AM';
      int hour12 =
          wrappedH > 12 ? wrappedH - 12 : (wrappedH == 0 ? 12 : wrappedH);
      return '${hour12.toString().padLeft(2, '0')}:00 $amPm';
    }

    for (int i = 1; i < hours24.length; i++) {
      if (hours24[i] == prevHour + 1) {
        prevHour = hours24[i];
      } else {
        ranges.add('${formatHour(blockStart)} - ${formatHour(prevHour + 1)}');
        blockStart = hours24[i];
        prevHour = hours24[i];
      }
    }
    ranges.add('${formatHour(blockStart)} - ${formatHour(prevHour + 1)}');

    final count = hours24.length;
    final slotText = count == 1 ? '1 slot' : '$count slots';
    return '${ranges.join(', ')} ($slotText)';
  }

  /// Formats the complete display time for a booking given its DB period and slotTime
  static String formatBookingTime({
    required String? period,
    DateTime? slotTime,
  }) {
    final periodStr = (period ?? '').trim();
    String periodLabel = '';
    String slotCsv = '';

    if (periodStr.contains('|')) {
      final pipeIdx = periodStr.indexOf('|');
      periodLabel = periodStr.substring(0, pipeIdx).trim();
      if (pipeIdx < periodStr.length - 1) {
        slotCsv = periodStr.substring(pipeIdx + 1).trim();
      }
    } else if (periodStr.contains(',') || periodStr.contains('-')) {
      slotCsv = periodStr;
    } else {
      periodLabel = periodStr;
    }

    // Only keep valid period labels: 'Morning', 'Afternoon', 'Evening', 'Night', 'Midnight'
    final validLabels = {'morning', 'afternoon', 'evening', 'night', 'midnight'};
    final isCleanLabel = validLabels.contains(periodLabel.toLowerCase());
    final displayLabel = isCleanLabel
        ? '${periodLabel[0].toUpperCase()}${periodLabel.substring(1).toLowerCase()}'
        : '';

    String mergedTime = '';
    if (slotCsv.isNotEmpty) {
      mergedTime = mergeSlotRange(slotCsv);
    } else if (slotTime != null) {
      final start = DateFormat('h:mm a').format(slotTime);
      final end = DateFormat('h:mm a').format(slotTime.add(const Duration(hours: 1)));
      mergedTime = '$start – $end';
    }

    if (mergedTime.isNotEmpty) {
      return mergedTime;
    } else if (displayLabel.isNotEmpty) {
      return displayLabel;
    } else if (periodStr.isNotEmpty) {
      return periodStr;
    }
    return 'N/A';
  }
}
