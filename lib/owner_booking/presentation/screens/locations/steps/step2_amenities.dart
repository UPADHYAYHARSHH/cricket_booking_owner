import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_form_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/amenities_picker.dart';

class Step2Amenities extends StatefulWidget {
  const Step2Amenities({super.key});

  @override
  State<Step2Amenities> createState() => Step2AmenitiesState();
}

class Step2AmenitiesState extends State<Step2Amenities> {
  late Set<String> _selectedAmenities;

  @override
  void initState() {
    super.initState();
    final data = context.read<LocationFormCubit>().data;
    _selectedAmenities = Set.from(data.amenities);
  }

  bool validateAndSave() {
    final cubit = context.read<LocationFormCubit>();
    cubit.updateData(cubit.data.copyWith(
      amenities: _selectedAmenities.toList(),
    ));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          text: 'Select Amenities',
          size: 16,
          weight: FontWeight.w600,
        ),
        const SizedBox(height: AppSizes.xs),
        const AppText(
          text: 'These amenities apply to the whole location (venue)',
          size: 12,
          color: AppColors.textSecondaryLight,
        ),
        const SizedBox(height: AppSizes.lg),
        AmenitiesPicker(
          selected: _selectedAmenities,
          onChanged: (next) => setState(() => _selectedAmenities = next),
        ),
      ],
    );
  }
}
