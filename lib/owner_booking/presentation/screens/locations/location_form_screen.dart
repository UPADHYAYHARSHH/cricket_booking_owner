import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_state.dart';

/// All amenity IDs paired with display labels and icons, grouped by section.
const List<Map<String, dynamic>> _kAmenities = [
  // Basic
  {'id': 'parking', 'label': 'Parking', 'group': 'Basic', 'icon': HugeIcons.strokeRoundedCarParking01},
  {'id': 'washrooms', 'label': 'Washrooms', 'group': 'Basic', 'icon': HugeIcons.strokeRoundedToilet01},
  {'id': 'changing_rooms', 'label': 'Changing Rooms', 'group': 'Basic', 'icon': HugeIcons.strokeRoundedLocker01},
  {'id': 'drinking_water', 'label': 'Drinking Water', 'group': 'Basic', 'icon': HugeIcons.strokeRoundedDroplet},
  {'id': 'waiting_area', 'label': 'Waiting / Seating Area', 'group': 'Basic', 'icon': HugeIcons.strokeRoundedSofa01},
  // Food
  {'id': 'cafeteria', 'label': 'Cafeteria / Canteen', 'group': 'Food & Beverages', 'icon': HugeIcons.strokeRoundedCafe},
  {'id': 'vending_machine', 'label': 'Vending Machine', 'group': 'Food & Beverages', 'icon': HugeIcons.strokeRoundedSoftDrink01},
  {'id': 'water_dispenser', 'label': 'Water Dispenser', 'group': 'Food & Beverages', 'icon': HugeIcons.strokeRoundedWaterPump},
  // Safety
  {'id': 'cctv', 'label': 'CCTV Surveillance', 'group': 'Safety', 'icon': HugeIcons.strokeRoundedCctvCamera},
  {'id': 'first_aid', 'label': 'First Aid Kit', 'group': 'Safety', 'icon': HugeIcons.strokeRoundedFirstAidKit},
  {'id': 'fire_safety', 'label': 'Fire Safety Equipment', 'group': 'Safety', 'icon': HugeIcons.strokeRoundedFireExtinguisher},
  {'id': 'security_guard', 'label': 'Security Guard', 'group': 'Safety', 'icon': HugeIcons.strokeRoundedUserShield01},
  // Equipment
  {'id': 'bat_rental', 'label': 'Bat Rental', 'group': 'Equipment', 'icon': HugeIcons.strokeRoundedCricketBat},
  {'id': 'ball_provided', 'label': 'Ball Provided', 'group': 'Equipment', 'icon': HugeIcons.strokeRoundedBaseball},
  {'id': 'batting_pads', 'label': 'Batting Pads', 'group': 'Equipment', 'icon': HugeIcons.strokeRoundedShield01},
  {'id': 'helmet', 'label': 'Helmet Rental', 'group': 'Equipment', 'icon': HugeIcons.strokeRoundedCricketHelmet},
  {'id': 'stumps_permanent', 'label': 'Permanent Stumps', 'group': 'Equipment', 'icon': HugeIcons.strokeRoundedUtilityPole},
  {'id': 'football_rental', 'label': 'Football Rental', 'group': 'Equipment', 'icon': HugeIcons.strokeRoundedFootball},
  {'id': 'goal_nets', 'label': 'Goal Nets', 'group': 'Equipment', 'icon': HugeIcons.strokeRoundedFootballPitch},
  {'id': 'bibs', 'label': 'Bibs / Jerseys', 'group': 'Equipment', 'icon': HugeIcons.strokeRoundedTShirt},
  // Tech & Services
  {'id': 'wifi', 'label': 'WiFi', 'group': 'Tech & Services', 'icon': HugeIcons.strokeRoundedWifi01},
  {'id': 'live_scoring', 'label': 'Live Scoring Support', 'group': 'Tech & Services', 'icon': HugeIcons.strokeRoundedAnalyticsUp},
  {'id': 'coaching', 'label': 'Coaching Available', 'group': 'Tech & Services', 'icon': HugeIcons.strokeRoundedWhistle},
  {'id': 'video_recording', 'label': 'Video Recording', 'group': 'Tech & Services', 'icon': HugeIcons.strokeRoundedCameraVideo},
  {'id': 'score_display', 'label': 'LED Score Display', 'group': 'Tech & Services', 'icon': HugeIcons.strokeRoundedModernTv},
  {'id': 'floodlights', 'label': 'Floodlights (LED)', 'group': 'Tech & Services', 'icon': HugeIcons.strokeRoundedSpotlight},
];

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
  late final TextEditingController _mapsCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;

  final _searchCtrl = TextEditingController();
  String _cityValue = '';
  List<Map<String, String>> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;
  bool _isSaving = false;
  late Set<String> _selectedAmenities;

  @override
  void initState() {
    super.initState();
    final data = widget.locationData;
    _addressCtrl = TextEditingController(text: data?['address'] as String? ?? '');
    _mapsCtrl = TextEditingController(text: data?['google_maps_link'] as String? ?? '');
    final lat = (data?['latitude'] as num?)?.toDouble() ?? 0.0;
    final lng = (data?['longitude'] as num?)?.toDouble() ?? 0.0;
    _latCtrl = TextEditingController(text: lat != 0.0 ? lat.toString() : '');
    _lngCtrl = TextEditingController(text: lng != 0.0 ? lng.toString() : '');
    _selectedAmenities = Set.from((data?['amenities'] as List?) ?? const []);

    final city = data?['city'] as String? ?? '';
    if (city.isNotEmpty) {
      _cityValue = city;
      _searchCtrl.text = city;
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _mapsCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _cityValue = '';
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      final results = await _fetchCities(query.trim());
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    });
  }

  Future<List<Map<String, String>>> _fetchCities(String query) async {
    final url =
        'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(query)}&count=10&language=en&format=json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final res = data['results'] as List?;
        if (res == null) return [];
        final List<Map<String, String>> out = [];
        for (final e in res) {
          if (e is! Map) continue;
          if ((e['country_code'] as String? ?? '') != 'IN') continue;
          final city = e['name'] as String? ?? '';
          final state = e['admin1'] as String? ?? '';
          if (city.isEmpty || state.isEmpty) continue;
          final dup = out.any((r) =>
              r['city']!.toLowerCase() == city.toLowerCase() &&
              r['state']!.toLowerCase() == state.toLowerCase());
          if (!dup) out.add({'city': city, 'state': state});
        }
        return out;
      }
    } catch (_) {}
    return [];
  }

  void _selectCity(Map<String, String> item) {
    setState(() {
      _cityValue = item['city']!;
      _searchCtrl.text = '${item['city']}, ${item['state']}';
      _suggestions = [];
    });
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cityValue.isEmpty) {
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
    final mapsLink = _mapsCtrl.text.trim();
    final lat = double.tryParse(_latCtrl.text.trim()) ?? 0.0;
    final lng = double.tryParse(_lngCtrl.text.trim()) ?? 0.0;

    String? newLocationId;
    if (widget.isEdit) {
      await cubit.updateLocation(
        locationId: widget.locationData!['id'] as String,
        data: {
          'address': address,
          'city': _cityValue,
          'google_maps_link': mapsLink,
          'latitude': lat,
          'longitude': lng,
          'amenities': _selectedAmenities.toList(),
        },
      );
    } else {
      newLocationId = await cubit.registerLocation(
        address: address,
        city: _cityValue,
        googleMapsLink: mapsLink,
        latitude: lat,
        longitude: lng,
        amenities: _selectedAmenities.toList(),
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context, newLocationId);
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
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryDarkGreen),
            onPressed: () => Navigator.pop(context),
          ),
          title: AppText(
            text: widget.isEdit ? 'Edit Location' : 'Add New Location',
            size: 18,
            weight: FontWeight.w700,
          ),
          centerTitle: true,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('FULL ADDRESS *'),
                _field(
                  _addressCtrl,
                  hint: 'Plot 42, Prahlad Nagar, Near ISCON Cross Roads',
                  maxLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                ),
                const AppSizedBox(height: 20),
                _label('CITY *'),
                _citySearchField(),
                const AppSizedBox(height: 20),
                _label('GOOGLE MAPS LINK (Optional)'),
                _field(_mapsCtrl, hint: 'Paste Google Maps URL here'),
                const AppSizedBox(height: 20),
                _label('GPS COORDINATES (Optional)'),
                Row(
                  children: [
                    Expanded(
                      child: _field(_latCtrl,
                          hint: 'Latitude (e.g. 23.0225)',
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true)),
                    ),
                    const AppSizedBox(width: 12),
                    Expanded(
                      child: _field(_lngCtrl,
                          hint: 'Longitude (e.g. 72.5714)',
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true)),
                    ),
                  ],
                ),
                const AppSizedBox(height: 28),
                _label('AMENITIES'),
                const AppSizedBox(height: 4),
                const AppText(
                  text: 'Shared by every ground at this venue',
                  size: 11,
                  color: AppColors.textSecondaryLight,
                ),
                const AppSizedBox(height: 16),
                _amenitiesPicker(),
                const AppSizedBox(height: 40),
                AppButton(
                  title: widget.isEdit ? 'Save Changes' : 'Add Location',
                  isLoading: _isSaving,
                  onTap: _onSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _citySearchField() {
    return Column(
      children: [
        TextFormField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: 'Type at least 3 letters to search…',
            hintStyle: TextStyle(
                color: AppColors.textSecondaryLight.withOpacity(0.4), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF0F9F4),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: const Icon(Icons.search, color: AppColors.primaryDarkGreen),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primaryDarkGreen),
                    ),
                  )
                : _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _cityValue = '';
                          _suggestions = [];
                        }),
                      )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryDarkGreen, width: 2),
            ),
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          const AppSizedBox(height: 4),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
              border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.15)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AppColors.primaryDarkGreen.withOpacity(0.1)),
                itemBuilder: (context, i) {
                  final item = _suggestions[i];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.location_on, color: AppColors.primaryDarkGreen),
                    title: AppText(
                      text: '${item['city']}, ${item['state']}',
                      size: 15,
                      weight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                    subtitle: const AppText(text: 'India', size: 12, color: Colors.grey),
                    hoverColor: const Color(0xFFF0F9F4),
                    onTap: () => _selectCity(item),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _amenitiesPicker() {
    final seen = <String>{};
    final groups = <String>[];
    for (final a in _kAmenities) {
      final g = a['group'] as String;
      if (seen.add(g)) groups.add(g);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.map((group) {
        final items = _kAmenities.where((a) => a['group'] == group).toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: group.toUpperCase(),
                size: 11,
                weight: FontWeight.w800,
                color: AppColors.textSecondaryLight.withOpacity(0.75),
                letterSpacing: 0.5,
              ),
              const AppSizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((amenity) {
                  final id = amenity['id'] as String;
                  final label = amenity['label'] as String;
                  final icon = amenity['icon'];
                  final isSel = _selectedAmenities.contains(id);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (isSel) {
                        _selectedAmenities.remove(id);
                      } else {
                        _selectedAmenities.add(id);
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFF0F9F4) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSel ? AppColors.primaryDarkGreen : Colors.grey.shade300,
                          width: isSel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: icon,
                            size: 16,
                            color: isSel ? AppColors.primaryDarkGreen : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 6),
                          AppText(
                            text: label,
                            size: 13,
                            weight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? AppColors.primaryDarkGreen : AppColors.textSecondaryLight,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppText(
          text: text,
          size: 12,
          weight: FontWeight.w700,
          color: AppColors.textSecondaryLight,
          letterSpacing: 0.4,
        ),
      );

  Widget _field(
    TextEditingController ctrl, {
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: AppColors.textSecondaryLight.withOpacity(0.4), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF0F9F4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryDarkGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}
