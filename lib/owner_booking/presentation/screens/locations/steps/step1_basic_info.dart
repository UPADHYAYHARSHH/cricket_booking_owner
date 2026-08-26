import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_form_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/map_picker_screen.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/city_search_field.dart';

class Step1BasicInfo extends StatefulWidget {
  const Step1BasicInfo({super.key});

  @override
  State<Step1BasicInfo> createState() => Step1BasicInfoState();
}

class Step1BasicInfoState extends State<Step1BasicInfo> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameCtrl;
  late final TextEditingController addressCtrl;
  late final TextEditingController descriptionCtrl;
  late final TextEditingController privacyPolicyCtrl;
  late final TextEditingController latCtrl;
  late final TextEditingController lngCtrl;
  
  final cityFieldKey = GlobalKey<CitySearchFieldState>();
  String cityValue = '';

  @override
  void initState() {
    super.initState();
    final data = context.read<LocationFormCubit>().data;
    nameCtrl = TextEditingController(text: data.name);
    addressCtrl = TextEditingController(text: data.address);
    descriptionCtrl = TextEditingController(text: data.description);
    privacyPolicyCtrl = TextEditingController(text: data.privacyPolicy);
    latCtrl = TextEditingController(text: data.latitude != 0.0 ? data.latitude.toString() : '');
    lngCtrl = TextEditingController(text: data.longitude != 0.0 ? data.longitude.toString() : '');
    cityValue = data.city;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    descriptionCtrl.dispose();
    privacyPolicyCtrl.dispose();
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
      name: nameCtrl.text.trim(),
      address: addressCtrl.text.trim(),
      description: descriptionCtrl.text.trim(),
      privacyPolicy: privacyPolicyCtrl.text.trim(),
      city: city,
      googleMapsLink: '',
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
          _label('LOCATION NAME *'),
          _field(
            nameCtrl,
            hint: 'E.g. TurfPro Arena',
            icon: Icons.store_outlined,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Name is required'
                : null,
          ),
          const SizedBox(height: AppSizes.xxl),
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
          _label('RULES & PRIVACY POLICY *'),
          _field(
            privacyPolicyCtrl,
            hint: 'List out the rules, cancellation, and privacy policies...',
            maxLines: 4,
            icon: Icons.policy_outlined,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Rules & Privacy Policy is required'
                : null,
          ),
          const SizedBox(height: AppSizes.xxl),
          _label('CITY *'),
          CitySearchField(
            key: cityFieldKey,
            initialCity: cityValue.isNotEmpty ? cityValue : null,
            onCityChanged: (city) => cityValue = city ?? '',
          ),
          const SizedBox(height: AppSizes.xxl),
          _label('GPS COORDINATES *'),
          const SizedBox(height: 4),
          // Map picker button
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (_) => MapPickerScreen(
                    initialLatitude: double.tryParse(latCtrl.text) ?? 0.0,
                    initialLongitude: double.tryParse(lngCtrl.text) ?? 0.0,
                  ),
                ),
              );
              if (result != null) {
                setState(() {
                  final LatLng loc = result['location'];
                  latCtrl.text = loc.latitude.toStringAsFixed(6);
                  lngCtrl.text = loc.longitude.toStringAsFixed(6);
                  final String address = result['address'] ?? '';
                  if (address.isNotEmpty && 
                      address != 'Location selected' && 
                      address != 'Move the pin to select your venue location') {
                    addressCtrl.text = address;
                  }
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryDarkGreen.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: AppColors.primaryDarkGreen.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDarkGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.map_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          latCtrl.text.isNotEmpty && lngCtrl.text.isNotEmpty
                              ? 'Location Pinned ✓'
                              : 'Pick Location on Map',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ),
                        if (latCtrl.text.isNotEmpty && lngCtrl.text.isNotEmpty)
                          Text(
                            '${latCtrl.text}, ${lngCtrl.text}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryLight,
                            ),
                          )
                        else
                          Text(
                            'Tap to open map and drop a pin on your venue',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryDarkGreen,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          // Manual lat/lng fields as fallback
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
