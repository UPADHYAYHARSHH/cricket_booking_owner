import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_layout.dart';

class Step3Location extends StatefulWidget {
  final bool isEdit;
  const Step3Location({super.key, required this.isEdit});

  @override
  State<Step3Location> createState() => _Step3LocationState();
}

class _Step3LocationState extends State<Step3Location> {
  final _formKey = GlobalKey<FormState>();

  // Address / maps / coordinates
  TextEditingController? _addressCtrl;
  TextEditingController? _mapsCtrl;
  TextEditingController? _latCtrl;
  TextEditingController? _lngCtrl;

  // City search
  final _searchCtrl = TextEditingController();
  String _cityValue = '';        // confirmed selected city
  List<Map<String, String>> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final data = context.read<GroundFormCubit>().data;
    _addressCtrl = TextEditingController(text: data.address);
    _mapsCtrl = TextEditingController(text: data.googleMapsLink);
    _latCtrl = TextEditingController(
        text: data.latitude != 0.0 ? data.latitude.toString() : '');
    _lngCtrl = TextEditingController(
        text: data.longitude != 0.0 ? data.longitude.toString() : '');

    // Pre-populate city if editing
    if (data.city.isNotEmpty) {
      _cityValue = data.city;
      _searchCtrl.text = data.city;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _addressCtrl?.dispose();
    _mapsCtrl?.dispose();
    _latCtrl?.dispose();
    _lngCtrl?.dispose();
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

  void _onNext() {
    if (!_initialized) return;
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
    final cubit = context.read<GroundFormCubit>();
    cubit.updateData(cubit.data.copyWith(
      address: _addressCtrl!.text.trim(),
      city: _cityValue,
      googleMapsLink: _mapsCtrl!.text.trim(),
      latitude: double.tryParse(_latCtrl!.text.trim()) ?? cubit.data.latitude,
      longitude: double.tryParse(_lngCtrl!.text.trim()) ?? cubit.data.longitude,
    ));
    cubit.goToStep(4);
  }

  @override
  Widget build(BuildContext context) {
    return GroundFormLayout(
      isEdit: widget.isEdit,
      currentStep: 3,
      title: 'Location',
      subtitle: 'Help players find your ground easily',
      onNext: _onNext,
      onBack: () => context.read<GroundFormCubit>().goToStep(2),
      child: !_initialized
          ? const SizedBox.shrink()
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('FULL ADDRESS *'),
                  _field(
                    _addressCtrl!,
                    hint: 'Plot 42, Prahlad Nagar, Near ISCON Cross Roads',
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Address is required'
                        : null,
                  ),
                  const AppSizedBox(height: 20),
                  _label('CITY *'),
                  _citySearchField(),
                  const AppSizedBox(height: 20),
                  _label('GOOGLE MAPS LINK (Optional)'),
                  _field(_mapsCtrl!, hint: 'Paste Google Maps URL here'),
                  const AppSizedBox(height: 6),
                  const AppText(
                    text: 'Players use this to navigate directly to your ground',
                    size: 11,
                    color: AppColors.textSecondaryLight,
                  ),
                  const AppSizedBox(height: 20),
                  _label('GPS COORDINATES (Optional)'),
                  Row(
                    children: [
                      Expanded(
                        child: _field(_latCtrl!,
                            hint: 'Latitude (e.g. 23.0225)',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true)),
                      ),
                      const AppSizedBox(width: 12),
                      Expanded(
                        child: _field(_lngCtrl!,
                            hint: 'Longitude (e.g. 72.5714)',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true)),
                      ),
                    ],
                  ),
                  const AppSizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.blue.shade700),
                        const AppSizedBox(width: 8),
                        Expanded(
                          child: AppText(
                            text:
                                'Tip: Open Google Maps, long-press your ground location, and copy the coordinates shown at the top.',
                            size: 12,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                color: AppColors.textSecondaryLight.withOpacity(0.4),
                fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF0F9F4),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon:
                const Icon(Icons.search, color: AppColors.primaryDarkGreen),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryDarkGreen),
                    ),
                  )
                : _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon:
                            const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _cityValue = '';
                          _suggestions = [];
                        }),
                      )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: AppColors.primaryDarkGreen.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: AppColors.primaryDarkGreen.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.primaryDarkGreen, width: 2),
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
              border: Border.all(
                  color: AppColors.primaryDarkGreen.withOpacity(0.15)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: AppColors.primaryDarkGreen.withOpacity(0.1)),
                itemBuilder: (context, i) {
                  final item = _suggestions[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.location_on,
                        color: AppColors.primaryDarkGreen),
                    title: AppText(
                      text: '${item['city']}, ${item['state']}',
                      size: 15,
                      weight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                    subtitle: const AppText(
                        text: 'India', size: 12, color: Colors.grey),
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
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: AppColors.textSecondaryLight.withOpacity(0.4),
            fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF0F9F4),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryDarkGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}
