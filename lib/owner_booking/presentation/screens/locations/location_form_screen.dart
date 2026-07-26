import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/amenities_picker.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/city_search_field.dart';

/// Single-screen form to add/edit a venue Location (address/city/GPS,
/// amenities). Amenities live here rather than per-Ground since they're
/// shared across every sport offered at the same venue.
/// Pass [locationData] (the Supabase row) for edit mode.
class LocationFormScreen extends StatefulWidget {
  final Map<String, dynamic>? locationData;

  const LocationFormScreen({super.key, this.locationData});

  bool get isEdit => locationData != null;

  @override
  State<LocationFormScreen> createState() => _LocationFormScreenState();
}

class _LocationFormScreenState extends State<LocationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _addressCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _mapsCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;

  final _cityFieldKey = GlobalKey<CitySearchFieldState>();
  String _cityValue = '';
  String? _initialCity;
  bool _isSaving = false;
  late Set<String> _selectedAmenities;

  @override
  void initState() {
    super.initState();
    final data = widget.locationData;
    _addressCtrl = TextEditingController(
      text: data?['address'] as String? ?? '',
    );
    _descriptionCtrl = TextEditingController(
      text: data?['description'] as String? ?? '',
    );
    _mapsCtrl = TextEditingController(
      text: data?['google_maps_link'] as String? ?? '',
    );
    final lat = (data?['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (data?['longitude'] as num?)?.toDouble() ?? 0.0;
    _latCtrl = TextEditingController(text: lat != 0.0 ? lat.toString() : '');
    _lngCtrl = TextEditingController(text: lng != 0.0 ? lng.toString() : '');
    _selectedAmenities = Set.from((data?['amenities'] as List?) ?? const []);

    final city = data?['city'] as String? ?? '';
    if (city.isNotEmpty) {
      _cityValue = city;
      _initialCity = city;
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _descriptionCtrl.dispose();
    _mapsCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
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

    setState(() => _isSaving = true);
    final cubit = context.read<LocationCubit>();
    final address = _addressCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    final mapsLink = _mapsCtrl.text.trim();
    final lat = double.tryParse(_latCtrl.text.trim()) ?? 0.0;
    final lng = double.tryParse(_lngCtrl.text.trim()) ?? 0.0;

    String? newLocationId;
    if (widget.isEdit) {
      await cubit.updateLocation(
        locationId: widget.locationData!['id'] as String,
        data: {
          'address': address,
          'description': description,
          'city': city,
          'google_maps_link': mapsLink,
          'latitude': lat,
          'longitude': lng,
          'amenities': _selectedAmenities.toList(),
        },
      );
    } else {
      newLocationId = await cubit.registerLocation(
        address: address,
        city: city,
        description: description,
        googleMapsLink: mapsLink,
        latitude: lat,
        longitude: lng,
        amenities: _selectedAmenities.toList(),
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (Navigator.canPop(context)) {
      Navigator.pop(context, newLocationId);
    } else {
      Navigator.pushReplacementNamed(context, '/splash');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationCubit, LocationState>(
      listener: (context, state) {
        if (state is LocationError) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: const Text('Could not save location'),
            description: Text(state.message),
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: AppSizes.lg,
              right: AppSizes.lg,
              bottom: AppSizes.lg,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B8457), Color(0xFF065B3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.sm),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: AppText(
                      text: widget.isEdit
                          ? 'Edit Location'
                          : 'Add New Location',
                      size: 20,
                      weight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('FULL ADDRESS *'),
                _field(
                  _addressCtrl,
                  hint: 'Plot 42, Prahlad Nagar, Near ISCON Cross Roads',
                  maxLines: 2,
                  icon: Icons.location_on_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Address is required'
                      : null,
                ),
                const AppSizedBox(height: AppSizes.xxl),
                _label('DESCRIPTION'),
                _field(
                  _descriptionCtrl,
                  hint: 'Describe what makes this venue special — surface quality, lighting, rules, nearby landmarks...',
                  maxLines: 4,
                  icon: Icons.description_outlined,
                ),
                const AppSizedBox(height: AppSizes.xxl),
                _label('CITY *'),
                CitySearchField(
                  key: _cityFieldKey,
                  initialCity: _initialCity,
                  onCityChanged: (city) => _cityValue = city ?? '',
                ),
                const AppSizedBox(height: AppSizes.xxl),
                _label('GOOGLE MAPS LINK (Optional)'),
                _field(
                  _mapsCtrl,
                  hint: 'Paste Google Maps URL here',
                  icon: Icons.link,
                ),
                const AppSizedBox(height: AppSizes.xxl),
                _label('GPS COORDINATES (Optional)'),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        _latCtrl,
                        hint: 'Latitude (e.g. 23.0225)',
                        icon: Icons.my_location,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const AppSizedBox(width: AppSizes.md),
                    Expanded(
                      child: _field(
                        _lngCtrl,
                        hint: 'Longitude (e.g. 72.5714)',
                        icon: Icons.explore_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const AppSizedBox(height: AppSizes.xxl + 4),
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
                  onChanged: (next) => setState(() => _selectedAmenities = next),
                ),
                const AppSizedBox(height: AppSizes.xxxxl),
                AppButton(
                  title: widget.isEdit ? 'Save Changes' : 'Add Location',
                  isLoading: _isSaving,
                  onTap: _onSave,
                  backgroundColor: AppColors.primaryDarkGreen,
                ),
              ],
            ),
          ),
        ),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}
