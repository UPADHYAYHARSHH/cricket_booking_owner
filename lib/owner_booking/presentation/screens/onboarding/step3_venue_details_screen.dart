import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/common/widgets/app_text_field.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/amenities_picker.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/city_search_field.dart';
import 'package:turfpro_owner/utils/auth_helper.dart';
import 'onboarding_step_indicator.dart';

class Step3VenueDetailsScreen extends StatefulWidget {
  const Step3VenueDetailsScreen({super.key});

  @override
  State<Step3VenueDetailsScreen> createState() =>
      _Step3VenueDetailsScreenState();
}

class _Step3VenueDetailsScreenState extends State<Step3VenueDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cityFieldKey = GlobalKey<CitySearchFieldState>();
  final _venueNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _mapsCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  String _cityValue = '';
  String? _initialCity;
  Set<String> _selectedAmenities = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _prefillExistingData();
  }

  @override
  void dispose() {
    _venueNameCtrl.dispose();
    _addressCtrl.dispose();
    _mapsCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefillExistingData() async {
    final userId = currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('owner_details')
          .select(
            'venue_name, address, city, google_maps_link, latitude, longitude',
          )
          .eq('id', userId)
          .maybeSingle();
      if (mounted && data != null) {
        _venueNameCtrl.text = data['venue_name'] ?? '';
        _addressCtrl.text = data['address'] ?? '';
        _mapsCtrl.text = data['google_maps_link'] ?? '';
        final lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
        final lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
        _latCtrl.text = lat != 0.0 ? lat.toString() : '';
        _lngCtrl.text = lng != 0.0 ? lng.toString() : '';
        final city = (data['city'] as String? ?? '').trim();
        if (city.isNotEmpty) {
          _cityValue = city;
          _initialCity = city;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final city = _cityFieldKey.currentState?.selectedCity ?? _cityValue;
    if (city.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text('Please search and select a city'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    context.read<AuthCubit>().saveStep3(
      venueName: _venueNameCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      city: city,
      googleMapsLink: _mapsCtrl.text.trim(),
      latitude: double.tryParse(_latCtrl.text.trim()) ?? 0.0,
      longitude: double.tryParse(_lngCtrl.text.trim()) ?? 0.0,
      amenities: _selectedAmenities.toList(),
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthStep1Required) {
          Navigator.pushReplacementNamed(context, '/onboarding/step1');
        } else if (state is AuthStep2Required) {
          Navigator.pushReplacementNamed(context, '/onboarding/step2');
        } else if (state is AuthPendingApproval) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text('Application Submitted!'),
            description: const Text(
              'Your application is under review. We\'ll notify you once it\'s approved.',
            ),
            autoCloseDuration: const Duration(seconds: 5),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/pending-approval',
            (r) => false,
          );
        } else if (state is AuthSuccess) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (r) => false,
          );
        } else if (state is AuthError) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: const Text('Error'),
            description: Text(state.message),
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryDarkGreen,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSizes.lg),
                        buildOnboardingHeader(
                          currentStep: 3,
                          onBack: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/onboarding/step2',
                            );
                          },
                        ),
                        const SizedBox(height: AppSizes.xl),
                        const AppText(
                          text: 'Venue Details',
                          size: 24,
                          weight: FontWeight.w700,
                        ),
                        const SizedBox(height: AppSizes.xs),
                        const AppText(
                          text:
                              'Add your venue the same way you would from Locations — then submit for approval.',
                          size: 14,
                          color: AppColors.textSecondaryLight,
                        ),
                        const SizedBox(height: AppSizes.xxl),

                        AppTextField(
                          label: 'Venue Name',
                          controller: _venueNameCtrl,
                          prefixIcon: Icons.stadium_outlined,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Venue name is required'
                              : null,
                        ),
                        const SizedBox(height: AppSizes.xxl),

                        _label('FULL ADDRESS *'),
                        AppTextField(
                          hint:
                              'Plot 42, Prahlad Nagar, Near ISCON Cross Roads',
                          controller: _addressCtrl,
                          prefixIcon: Icons.location_on_outlined,
                          maxLines: 2,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Address is required'
                              : null,
                        ),
                        const SizedBox(height: AppSizes.xxl),

                        _label('CITY *'),
                        CitySearchField(
                          key: _cityFieldKey,
                          initialCity: _initialCity,
                          onCityChanged: (city) => _cityValue = city ?? '',
                        ),
                        const SizedBox(height: AppSizes.xxl),

                        _label('GOOGLE MAPS LINK (Optional)'),
                        AppTextField(
                          hint: 'Paste Google Maps URL here',
                          controller: _mapsCtrl,
                          prefixIcon: Icons.link,
                        ),
                        const SizedBox(height: AppSizes.xxl),

                        _label('GPS COORDINATES (Optional)'),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                hint: 'Latitude (e.g. 23.0225)',
                                controller: _latCtrl,
                                prefixIcon: Icons.my_location,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                            const AppSizedBox(width: AppSizes.md),
                            Expanded(
                              child: AppTextField(
                                hint: 'Longitude (e.g. 72.5714)',
                                controller: _lngCtrl,
                                prefixIcon: Icons.explore_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.xxl),

                        _label('AMENITIES'),
                        const AppSizedBox(height: AppSizes.xs),
                        const AppText(
                          text: 'Shared by every ground at this venue',
                          size: 11,
                          color: AppColors.textSecondaryLight,
                        ),
                        const AppSizedBox(height: AppSizes.lg),
                        AmenitiesPicker(
                          selected: _selectedAmenities,
                          onChanged: (next) =>
                              setState(() => _selectedAmenities = next),
                        ),
                        const SizedBox(height: AppSizes.xxl),

                        Container(
                          padding: const EdgeInsets.all(AppSizes.lg),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDarkGreen.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                            border: Border.all(
                              color: AppColors.primaryDarkGreen.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.primaryDarkGreen,
                                size: 20,
                              ),
                              SizedBox(width: AppSizes.sm),
                              Expanded(
                                child: AppText(
                                  text:
                                      'After submission, our team will review your application within 24–48 hours.',
                                  size: 13,
                                  color: AppColors.primaryDarkGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.xxl),

                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) => AppButton(
                            title: 'Submit Application',
                            isLoading: state is AuthLoading,
                            onTap: _submit,
                            showArrow: false,
                          ),
                        ),
                        const SizedBox(height: AppSizes.lg),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
