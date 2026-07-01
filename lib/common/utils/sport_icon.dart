import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Resolves a HugeIcon icon for a given sport name/slug (e.g. "box_cricket",
/// "Football / Futsal", "volleyball"). Falls back to the cricket bat icon
/// when the sport is unrecognized, since cricket is this app's default sport.
dynamic sportIcon(String? sport) {
  final normalized = (sport ?? '').toLowerCase();

  if (normalized.contains('cricket')) {
    return HugeIcons.strokeRoundedCricketBat;
  }
  if (normalized.contains('football') ||
      normalized.contains('soccer') ||
      normalized.contains('futsal')) {
    return HugeIcons.strokeRoundedFootball;
  }
  if (normalized.contains('badminton')) {
    return HugeIcons.strokeRoundedBadminton;
  }
  if (normalized.contains('volleyball')) {
    return HugeIcons.strokeRoundedVolleyball;
  }
  if (normalized.contains('basketball')) {
    return HugeIcons.strokeRoundedBasketball01;
  }
  if (normalized.contains('tennis') || normalized.contains('pickleball')) {
    return HugeIcons.strokeRoundedTennisRacket;
  }
  return HugeIcons.strokeRoundedCricketBat;
}

/// Reusable widget that renders the correct sport icon for [sport].
class SportIcon extends StatelessWidget {
  final String? sport;
  final double size;
  final Color? color;

  const SportIcon({
    super.key,
    required this.sport,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: sportIcon(sport),
      size: size,
      color: color ?? Colors.grey.shade700,
    );
  }
}
