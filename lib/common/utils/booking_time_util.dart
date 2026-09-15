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
  /// a unified contiguous display range (e.g. "08:00 PM – 10:00 PM").
  static String mergeSlotRange(String slotCsv) {
    if (slotCsv.trim().isEmpty) return '';

    final rawSlots = slotCsv
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (rawSlots.isEmpty) return '';

    final parsedRanges = <Map<String, String>>[];
    for (final slot in rawSlots) {
      if (slot.contains('-')) {
        final parts = slot.split('-').map((s) => s.trim()).toList();
        if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
          parsedRanges.add({'start': parts[0], 'end': parts[1]});
          continue;
        }
      }
      final start = slot;
      final end = calculateEndTime(start);
      parsedRanges.add({'start': start, 'end': end.isNotEmpty ? end : start});
    }

    if (parsedRanges.isEmpty) return '';
    if (parsedRanges.length == 1) {
      final item = parsedRanges.first;
      if (item['start'] == item['end']) return item['start']!;
      return '${item['start']} – ${item['end']}';
    }

    // Merge contiguous blocks
    final mergedBlocks = <String>[];
    String currentStart = parsedRanges.first['start']!;
    String currentEnd = parsedRanges.first['end']!;

    for (int i = 1; i < parsedRanges.length; i++) {
      final nextStart = parsedRanges[i]['start']!;
      final nextEnd = parsedRanges[i]['end']!;

      if (_normalizeTime(currentEnd) == _normalizeTime(nextStart)) {
        currentEnd = nextEnd;
      } else {
        mergedBlocks.add('$currentStart – $currentEnd');
        currentStart = nextStart;
        currentEnd = nextEnd;
      }
    }
    mergedBlocks.add('$currentStart – $currentEnd');

    return mergedBlocks.join(', ');
  }

  static String _normalizeTime(String time) {
    return time.replaceAll(' ', '').toUpperCase();
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

    if (mergedTime.isNotEmpty && displayLabel.isNotEmpty) {
      return '$displayLabel · $mergedTime';
    } else if (mergedTime.isNotEmpty) {
      return mergedTime;
    } else if (displayLabel.isNotEmpty) {
      return displayLabel;
    } else if (periodStr.isNotEmpty) {
      return periodStr;
    }
    return 'N/A';
  }
}
