import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

enum SlotType { booked, open, blocked, peak }

class SlotItem extends StatelessWidget {
  final String time;
  final String subtitle;
  final SlotType type;

  const SlotItem({
    super.key,
    required this.time,
    required this.subtitle,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (type) {
      case SlotType.booked:
        bgColor = const Color(0xFFF5F6FA);
        borderColor = const Color(0xFFE0E0E0);
        textColor = const Color(0xFF9E9E9E);
        break;
      case SlotType.open:
        bgColor = const Color(0xFFE8F5E9);
        borderColor = const Color(0xFF81C784);
        textColor = const Color(0xFF388E3C);
        break;
      case SlotType.blocked:
        bgColor = const Color(0xFFFFF0F0);
        borderColor = const Color(0xFFFFCDD2);
        textColor = const Color(0xFFE53935);
        break;
      case SlotType.peak:
        bgColor = const Color(0xFFFFF8E1);
        borderColor = const Color(0xFFFFB300);
        textColor = const Color(0xFFF57C00);
        break;
    }

    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 1,
          style: type == SlotType.peak ? BorderStyle.solid : BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText(
            text: time,
            size: 12,
            weight: FontWeight.bold,
            color: type == SlotType.booked ? const Color(0xFF757575) : textColor,
          ),
          const SizedBox(height: 4),
          AppText(
            text: subtitle,
            size: 10,
            color: type == SlotType.booked ? const Color(0xFFBDBDBD) : textColor,
            align: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
