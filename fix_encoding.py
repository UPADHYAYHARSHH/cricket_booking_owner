import os

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    # 0xE2 0x82 0xB9 is the UTF-8 for Rupee symbol
    content = content.replace('\u00e2\u201a\u00b9', '\u20b9')
    
    old_logic = """    final rawPeriod = (booking['period'] ?? 'Time').toString();
    String period = rawPeriod;
    if (rawPeriod.contains('|')) {
      final parts = rawPeriod.split('|');
      final times = parts[1].replaceAll(',', ', ');
      period = "${parts[0]} - $times";
    } else {
      period = _simplifyPeriod(rawPeriod);
    }"""
    
    new_logic = """    final rawPeriod = (booking['period'] ?? 'Time').toString();
    String period = rawPeriod;
    
    String dateLabel = "Date";
    final slotTimeStr = booking['slot_time']?.toString() ?? booking['created_at']?.toString() ?? '';
    if (slotTimeStr.isNotEmpty) {
      try {
        final d = DateTime.parse(slotTimeStr).toLocal();
        dateLabel = DateFormat('d MMM').format(d);
      } catch (_) {}
    }

    if (rawPeriod.contains('|')) {
      final parts = rawPeriod.split('|');
      final times = parts[1].replaceAll(',', ', ');
      period = "$dateLabel - $times";
    } else {
      String simplified = _simplifyPeriod(rawPeriod);
      simplified = simplified.replaceAll(RegExp(r'^(Day|Night|Midnight)\\s*-\\s*'), '');
      period = "$dateLabel - $simplified";
    }"""
    
    content = content.replace(old_logic, new_logic)
    
    old_logic2 = """    final rawPeriod = (widget.booking['period'] ?? 'Time').toString();
    String period = rawPeriod;
    if (rawPeriod.contains('|')) {
      final parts = rawPeriod.split('|');
      final times = parts[1].replaceAll(',', ', ');
      period = "${parts[0]} - $times";
    } else {
      period = _simplifyPeriod(rawPeriod);
    }"""
    
    new_logic2 = """    final rawPeriod = (widget.booking['period'] ?? 'Time').toString();
    String period = rawPeriod;
    
    String dateLabel = "Date";
    final slotTimeStr = widget.booking['slot_time']?.toString() ?? widget.booking['created_at']?.toString() ?? '';
    if (slotTimeStr.isNotEmpty) {
      try {
        final d = DateTime.parse(slotTimeStr).toLocal();
        dateLabel = DateFormat('d MMM').format(d);
      } catch (_) {}
    }

    if (rawPeriod.contains('|')) {
      final parts = rawPeriod.split('|');
      final times = parts[1].replaceAll(',', ', ');
      period = "$dateLabel - $times";
    } else {
      String simplified = _simplifyPeriod(rawPeriod);
      simplified = simplified.replaceAll(RegExp(r'^(Day|Night|Midnight)\\s*-\\s*'), '');
      period = "$dateLabel - $simplified";
    }"""
    
    content = content.replace(old_logic2, new_logic2)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

fix_file('lib/owner_booking/presentation/screens/dashboard/widgets/pending_approval_card.dart')
fix_file('lib/owner_booking/presentation/screens/dashboard/widgets/today_booking_card.dart')
print("Encoding and logic fixed")
