import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/sport/sport_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/sport/sport_state.dart';
import 'package:turfpro_owner/owner_booking/data/models/sport_model.dart';

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

/// Turns a stored sport slug (e.g. "box_cricket") into a display label
/// (e.g. "Box Cricket").
String formatSportName(String? sport) {
  final slug = sport ?? '';
  if (slug.isEmpty) return slug;
  return slug
      .split('_')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ');
}

SportModel? findSportModel(List<SportModel> sports, String sportName) {
  if (sports.isEmpty || sportName.trim().isEmpty) return null;
  final clean = sportName.trim().toLowerCase();
  final normalized = clean.replaceAll(RegExp(r'[^a-z0-9]'), '');

  // 1. Exact match by slug or name
  for (final s in sports) {
    if (s.slug.toLowerCase() == clean || s.name.toLowerCase() == clean) {
      return s;
    }
  }

  // 2. Normalized match
  for (final s in sports) {
    final sSlugNorm = s.slug.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final sNameNorm = s.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (sSlugNorm == normalized || sNameNorm == normalized) {
      return s;
    }
  }
  
  // 3. Substring
  for (final s in sports) {
    final sSlugNorm = s.slug.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final sNameNorm = s.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (sSlugNorm.isNotEmpty && (normalized.contains(sSlugNorm) || sSlugNorm.contains(normalized))) {
      return s;
    }
    if (sNameNorm.isNotEmpty && (normalized.contains(sNameNorm) || sNameNorm.contains(normalized))) {
      return s;
    }
  }

  return null;
}

/// Reusable widget that renders the correct sport icon for [sport].
/// If [iconUrl] is provided and non-empty, shows the network image.
/// Otherwise, falls back to a HugeIcon based on the sport slug.
class SportIcon extends StatelessWidget {
  final String? sport;
  final String? iconUrl;
  final double size;
  final Color? color;

  const SportIcon({
    super.key,
    required this.sport,
    this.iconUrl,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildFallback() {
      return HugeIcon(
        icon: sportIcon(sport),
        size: size,
        color: color ?? Colors.grey.shade700,
      );
    }

    Widget buildImage(String url) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) => SizedBox(width: size, height: size),
          errorWidget: (_, _, _) => buildFallback(),
        ),
      );
    }

    if (iconUrl != null && iconUrl!.isNotEmpty) {
      return buildImage(iconUrl!);
    }
    
    return BlocBuilder<SportCubit, SportState>(
      builder: (context, state) {
        if (state is SportLoaded) {
          final sportModel = findSportModel(state.sports, sport ?? '');
          if (sportModel != null && sportModel.iconUrl.isNotEmpty) {
            return buildImage(sportModel.iconUrl);
          }
        }
        return buildFallback();
      }
    );
  }
}
