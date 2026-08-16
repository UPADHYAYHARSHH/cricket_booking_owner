import 'package:flutter/material.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:hugeicons/hugeicons.dart';

/// Shared "All Locations / pick one" selector used to scope dashboard and
/// revenue data to a single location. Keeping it in one place ensures both
/// screens look and behave identically. Tapping it opens a bottom sheet,
/// matching the location picker pattern used in the customer booking app.
class LocationDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> locations;
  final String? selectedLocationId;
  final ValueChanged<String?> onSelected;

  const LocationDropdown({
    super.key,
    required this.locations,
    required this.selectedLocationId,
    required this.onSelected,
  });

  static String titleFor(Map<String, dynamic> location) {
    final name = location['name'] as String?;
    if (name != null && name.isNotEmpty) return name;
    return '---';
  }

  static String? subtitleFor(Map<String, dynamic> location) {
    final address = location['address'] as String?;
    if (address != null && address.isNotEmpty) return address;
    return null;
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _LocationPickerSheet(
        locations: locations,
        selectedLocationId: selectedLocationId,
        onSelected: (id) {
          Navigator.pop(sheetContext);
          onSelected(id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = selectedLocationId == null
        ? null
        : locations.firstWhere(
            (l) => l['id'] == selectedLocationId,
            orElse: () => const {},
          );
    final selectedTitle = selectedLocation == null ? 'All Locations' : titleFor(selectedLocation);
    final selectedSubtitle = selectedLocation == null ? null : subtitleFor(selectedLocation);

    return GestureDetector(
      onTap: () => _openPicker(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F8F5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedLocation01,
                  color: AppColors.primaryDarkGreen,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: selectedSubtitle ?? 'Location',
                    size: 11,
                    weight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    text: selectedTitle,
                    size: 14,
                    weight: FontWeight.w700,
                    color: Colors.black87,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500, size: 24),
          ],
        ),
      ),
    );
  }
}

class _LocationPickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>> locations;
  final String? selectedLocationId;
  final ValueChanged<String?> onSelected;

  const _LocationPickerSheet({
    required this.locations,
    required this.selectedLocationId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppText(
                  text: 'Select Location',
                  size: 16,
                  weight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 12),
                shrinkWrap: true,
                children: [
                  _LocationRow(
                    icon: Icons.layers_rounded,
                    title: 'All Locations',
                    subtitle: null,
                    selected: selectedLocationId == null,
                    onTap: () => onSelected(null),
                  ),
                  for (final location in locations)
                    _LocationRow(
                      icon: Icons.location_on_rounded,
                      title: LocationDropdown.titleFor(location),
                      subtitle: LocationDropdown.subtitleFor(location),
                      selected: selectedLocationId == location['id'],
                      onTap: () => onSelected(location['id'] as String),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LocationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: selected ? const Color(0xFFF1F8F5) : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? AppColors.primaryDarkGreen : Colors.grey.shade500),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: title,
                    size: 14,
                    weight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.primaryDarkGreen : Colors.black87,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    AppText(
                      text: subtitle!,
                      size: 12,
                      color: Colors.grey.shade500,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_rounded, size: 20, color: AppColors.primaryDarkGreen),
          ],
        ),
      ),
    );
  }
}
