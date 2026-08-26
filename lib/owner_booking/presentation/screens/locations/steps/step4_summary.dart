import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_form_cubit.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/amenities_picker.dart';

class Step4Summary extends StatelessWidget {
  const Step4Summary({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.read<LocationFormCubit>().data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          text: 'Summary',
          size: 20,
          weight: FontWeight.w700,
        ),
        const SizedBox(height: AppSizes.xl),
        _summaryItem('Address', data.address),
        _summaryItem('City', data.city),
        _summaryItem('Description', data.description),
        _buildAmenities(data.amenities),
        _summaryItem('Property Status', data.propertyStatus),
        _summaryItem('Images', '${data.images.length} added'),
        const SizedBox(height: AppSizes.xl),
        if (data.images.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.images.length,
              separatorBuilder: (context, index) => const SizedBox(width: AppSizes.sm),
              itemBuilder: (context, index) {
                final path = data.images[index];
                final isNetworkOrBlob = path.startsWith('http') || path.startsWith('blob:');
                return Container(
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    image: DecorationImage(
                      image: isNetworkOrBlob ? NetworkImage(path) : FileImage(File(path)) as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _summaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: label,
            size: 12,
            color: AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 4),
          AppText(
            text: value.isEmpty ? 'N/A' : value,
            size: 15,
            weight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities(List<String> amenities) {
    if (amenities.isEmpty) {
      return _summaryItem('Amenities', 'N/A');
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: 'Amenities',
            size: 12,
            color: AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: amenities.map((id) {
              final amenity = kVenueAmenities.firstWhere(
                (a) => a['id'] == id,
                orElse: () => {'label': id, 'icon': null},
              );
              final label = amenity['label'] as String;
              final icon = amenity['icon'];
              
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputFillLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                  border: Border.all(
                    color: AppColors.primaryDarkGreen,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      HugeIcon(
                        icon: icon,
                        size: 14,
                        color: AppColors.primaryDarkGreen,
                      ),
                      const SizedBox(width: AppSizes.sm),
                    ],
                    AppText(
                      text: label,
                      size: 12,
                      weight: FontWeight.w600,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
