import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_form_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/city_search_field.dart';

class Step1BasicInfo extends StatefulWidget {
  const Step1BasicInfo({super.key});

  @override
  State<Step1BasicInfo> createState() => Step1BasicInfoState();
}

class Step1BasicInfoState extends State<Step1BasicInfo> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController addressCtrl;
  late final TextEditingController descriptionCtrl;
  late final TextEditingController privacyPolicyCtrl;
  late final TextEditingController mapsCtrl;
  late final TextEditingController latCtrl;
  late final TextEditingController lngCtrl;
  
  final cityFieldKey = GlobalKey<CitySearchFieldState>();
  String cityValue = '';

  @override
  void initState() {
    super.initState();
    final data = context.read<LocationFormCubit>().data;
    addressCtrl = TextEditingController(text: data.address);
    descriptionCtrl = TextEditingController(text: data.description);
    privacyPolicyCtrl = TextEditingController(text: data.privacyPolicy);
    mapsCtrl = TextEditingController(text: data.googleMapsLink);
    latCtrl = TextEditingController(text: data.latitude != 0.0 ? data.latitude.toString() : '');
    lngCtrl = TextEditingController(text: data.longitude != 0.0 ? data.longitude.toString() : '');
    cityValue = data.city;
  }

  @override
  void dispose() {
    addressCtrl.dispose();
    descriptionCtrl.dispose();
    privacyPolicyCtrl.dispose();
    mapsCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    super.dispose();
  }

  bool validateAndSave() {
    if (!formKey.currentState!.validate()) return false;
    final city = cityFieldKey.currentState?.selectedCity ?? cityValue;
    if (city.isEmpty) {
      return false; // Could show toast here
    }
    
    final cubit = context.read<LocationFormCubit>();
    cubit.updateData(cubit.data.copyWith(
      address: addressCtrl.text.trim(),
      description: descriptionCtrl.text.trim(),
      privacyPolicy: privacyPolicyCtrl.text.trim(),
      city: city,
      googleMapsLink: mapsCtrl.text.trim(),
      latitude: double.tryParse(latCtrl.text.trim()) ?? 0.0,
      longitude: double.tryParse(lngCtrl.text.trim()) ?? 0.0,
    ));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('FULL ADDRESS *'),
          _field(
            addressCtrl,
            hint: 'Plot 42, Prahlad Nagar, Near ISCON Cross Roads',
            maxLines: 2,
            icon: Icons.location_on_outlined,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Address is required'
                : null,
          ),
          const SizedBox(height: AppSizes.xxl),
          _label('DESCRIPTION'),
          _field(
            descriptionCtrl,
            hint: 'Describe what makes this venue special...',
            maxLines: 4,
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: AppSizes.xxl),
          _label('RULES & PRIVACY POLICY'),
          _field(
            privacyPolicyCtrl,
            hint: 'List out the rules, cancellation, and privacy policies...',
            maxLines: 4,
            icon: Icons.policy_outlined,
          ),
          const SizedBox(height: AppSizes.xxl),
          _label('CITY *'),
          CitySearchField(
            key: cityFieldKey,
            initialCity: cityValue.isNotEmpty ? cityValue : null,
            onCityChanged: (city) => cityValue = city ?? '',
          ),
          const SizedBox(height: AppSizes.xxl),
          _label('GOOGLE MAPS LINK (Optional)'),
          _field(
            mapsCtrl,
            hint: 'Paste Google Maps URL here',
            icon: Icons.link,
          ),
          const SizedBox(height: AppSizes.xxl),
          _label('GPS COORDINATES (Optional)'),
          Row(
            children: [
              Expanded(
                child: _field(
                  latCtrl,
                  hint: 'Latitude (e.g. 23.0225)',
                  icon: Icons.my_location,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: _field(
                  lngCtrl,
                  hint: 'Longitude (e.g. 72.5714)',
                  icon: Icons.explore_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.sm),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primaryDarkGreen,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        AppText(
          text: text,
          size: 12,
          weight: FontWeight.w700,
          color: AppColors.textSecondaryLight,
          letterSpacing: 0.4,
        ),
      ],
    ),
  );

  Widget _field(
    TextEditingController ctrl, {
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondaryLight.withValues(alpha: 0.4),
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppColors.inputFillLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        prefixIcon: icon != null
            ? Icon(
                icon,
                size: 20,
                color: AppColors.primaryDarkGreen.withValues(alpha: 0.6),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.primaryDarkGreen,
            width: 2,
          ),
        ),
      ),
    );
  }
}
