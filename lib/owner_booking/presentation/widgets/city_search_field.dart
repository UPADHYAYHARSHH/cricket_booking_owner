import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

/// Searchable city field backed by Open-Meteo geocoding (India only).
/// The user must pick a suggestion — free-typed text is not accepted as a value.
class CitySearchField extends StatefulWidget {
  final String? initialCity;
  final String? label;
  final ValueChanged<String?>? onCityChanged;

  const CitySearchField({
    super.key,
    this.initialCity,
    this.label,
    this.onCityChanged,
  });

  @override
  State<CitySearchField> createState() => CitySearchFieldState();
}

class CitySearchFieldState extends State<CitySearchField> {
  final _searchCtrl = TextEditingController();
  String _cityValue = '';
  List<Map<String, String>> _suggestions = [];
  bool _isSearching = false;
  bool _suppressSearch = false;
  Timer? _debounce;

  /// Currently selected city name, or empty if none selected from results.
  String get selectedCity => _cityValue;

  bool get hasSelection => _cityValue.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final city = widget.initialCity?.trim() ?? '';
    if (city.isNotEmpty) {
      _cityValue = city;
      _searchCtrl.text = city;
    }
  }

  @override
  void didUpdateWidget(covariant CitySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialCity?.trim() ?? '';
    final prev = oldWidget.initialCity?.trim() ?? '';
    if (next != prev && next.isNotEmpty && _cityValue.isEmpty) {
      _cityValue = next;
      _searchCtrl.text = next;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _notify(String? city) => widget.onCityChanged?.call(city);

  void _onSearchChanged(String query) {
    if (_suppressSearch) return;
    _debounce?.cancel();
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _cityValue = '';
      });
      _notify(null);
      return;
    }
    // Typing after a selection invalidates until a new pick
    if (_cityValue.isNotEmpty) {
      setState(() => _cityValue = '');
      _notify(null);
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);
      final results = await _fetchCities(query.trim());
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    });
  }

  Future<List<Map<String, String>>> _fetchCities(String query) async {
    final url =
        'https://geocoding-api.open-meteo.com/v1/search'
        '?name=${Uri.encodeComponent(query)}'
        '&count=15'
        '&language=en'
        '&format=json'
        '&countryCode=IN';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final res = data['results'] as List?;
        if (res == null) return [];
        final List<Map<String, String>> out = [];
        for (final e in res) {
          if (e is! Map) continue;
          final city = e['name'] as String? ?? '';
          final state = e['admin1'] as String? ?? '';
          if (city.isEmpty || state.isEmpty) continue;
          final dup = out.any(
            (r) =>
                r['city']!.toLowerCase() == city.toLowerCase() &&
                r['state']!.toLowerCase() == state.toLowerCase(),
          );
          if (!dup) out.add({'city': city, 'state': state});
        }
        return out;
      }
    } catch (_) {}
    return [];
  }

  void _selectCity(Map<String, String> item) {
    _debounce?.cancel();
    _suppressSearch = true;
    final city = item['city']!;
    final state = item['state']!;
    setState(() {
      _cityValue = city;
      _suggestions = [];
      _isSearching = false;
      _searchCtrl.value = TextEditingValue(
        text: '$city, $state',
        selection: TextSelection.collapsed(offset: '$city, $state'.length),
      );
    });
    _notify(city);
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _suppressSearch = false;
    });
  }

  void _clear() {
    setState(() {
      _searchCtrl.clear();
      _cityValue = '';
      _suggestions = [];
    });
    _notify(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          AppText(
            text: widget.label!,
            size: 13,
            weight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
          const AppSizedBox(height: AppSizes.sm),
        ],
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
              color: AppColors.textSecondaryLight.withValues(alpha: 0.4),
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppColors.inputFillLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.primaryDarkGreen,
            ),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ),
                  )
                : _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear,
                      color: AppColors.textSecondaryLight,
                    ),
                    onPressed: _clear,
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
          validator: (_) =>
              _cityValue.isEmpty ? 'Please search and select a city' : null,
        ),
        if (_suggestions.isNotEmpty) ...[
          const AppSizedBox(height: AppSizes.xs),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppColors.primaryDarkGreen.withValues(alpha: 0.15),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                ),
                itemBuilder: (context, i) {
                  final item = _suggestions[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(AppSizes.xs),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDarkGreen.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primaryDarkGreen,
                        size: 18,
                      ),
                    ),
                    title: AppText(
                      text: '${item['city']}, ${item['state']}',
                      size: 15,
                      weight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                    subtitle: const AppText(
                      text: 'India',
                      size: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                    hoverColor: AppColors.inputFillLight,
                    onTap: () => _selectCity(item),
                  );
                },
              ),
            ),
          ),
        ] else if (_searchCtrl.text.trim().length >= 3 &&
            !_isSearching &&
            _cityValue.isEmpty) ...[
          const AppSizedBox(height: AppSizes.xs),
          const AppText(
            text:
                'No cities found. Try a different spelling, then tap a result.',
            size: 12,
            color: AppColors.textSecondaryLight,
          ),
        ],
        if (_cityValue.isNotEmpty) ...[
          const AppSizedBox(height: AppSizes.xs),
          AppText(
            text: 'Selected: $_cityValue',
            size: 12,
            weight: FontWeight.w600,
            color: AppColors.primaryDarkGreen,
          ),
        ],
      ],
    );
  }
}
