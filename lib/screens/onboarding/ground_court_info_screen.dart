import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:turfpro_owner/utils/auth_helper.dart';
import 'package:turfpro_owner/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/common/widgets/onboarding_layout.dart';
import 'package:toastification/toastification.dart';

class GroundCourtInfoScreen extends StatefulWidget {
  const GroundCourtInfoScreen({super.key});

  @override
  State<GroundCourtInfoScreen> createState() => _GroundCourtInfoScreenState();
}

class _GroundCourtInfoScreenState extends State<GroundCourtInfoScreen> {
  final Map<String, Map<String, dynamic>> _sportConfigs = {};
  List<String> _selectedSportIds = [];
  String? _activeSportId;
  bool _isLoadingData = true;

  final Map<String, String> _sportNames = {
    'box_cricket': 'Box Cricket',
    'volleyball': 'Volleyball',
    'pickleball': 'Pickleball',
    'football': 'Football',
    'badminton': 'Badminton',
    'tennis': 'Tennis',
  };

  final Map<String, IconData> _sportIcons = {
    'box_cricket': Icons.sports_cricket,
    'volleyball': Icons.sports_volleyball,
    'pickleball': Icons.sports_tennis,
    'football': Icons.sports_soccer,
    'badminton': Icons.sports_tennis,
    'tennis': Icons.sports_tennis,
  };

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final data = await Supabase.instance.client
          .from('owner_details')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        final Map<String, dynamic> sportsConfig = data['sports_config'] ?? {};
        final Map<String, dynamic> groundConfig = data['ground_config'] ?? {};

        setState(() {
          _selectedSportIds = sportsConfig.keys.toList();
          if (_selectedSportIds.isNotEmpty) {
            _activeSportId = _selectedSportIds.first;
          }

          for (var sportId in _selectedSportIds) {
            final existing = groundConfig[sportId] ?? {};
            _sportConfigs[sportId] = {
              'num_courts': existing['num_courts'] ?? sportsConfig[sportId] ?? 1,
              'players_per_side': existing['players_per_side'] ?? '6',
              'court_width': existing['court_width'] ?? '18 m',
              'court_length': existing['court_length'] ?? '35 m',
              'surface_type': existing['surface_type'] ?? 'Artificial Turf',
              'pitch_type': existing['pitch_type'] ?? 'Turf Pitch',
              'net_config': existing['net_config'] ?? '4-sided Enclosed',
              'stumps': existing['stumps'] ?? 'Permanent (Cemented)',
              'floodlights': existing['floodlights'] ?? 'Yes — Full LED',
              'equipment_rent': List<String>.from(existing['equipment_rent'] ?? ['Bat', 'Ball', 'Stumps']),
              'rules': existing['rules'] ?? 'Box Cricket Rules',
              'max_spectators': existing['max_spectators'] ?? '',
              'court_names': List<String>.from(existing['court_names'] ?? ['IPL Arena', 'T20 Zone']),
            };
          }
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
      setState(() => _isLoadingData = false);
    }
  }

  void _onSave() {
    // Validate that all sports have been "seen" or at least the active one is valid
    // For simplicity, we just save the current map
    context.read<AuthCubit>().saveGroundConfig(groundConfig: _sportConfigs);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: Text(state.message),
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return OnboardingLayout(
            currentStep: 4,
            title: "Ground / Court Info",
            subtitle: "Configure details per sport type",
            isLoading: state is AuthLoading,
            onNext: _onSave,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSportTabs(),
                const AppSizedBox(height: 24),
                if (_activeSportId != null) _buildConfigForm(_activeSportId!),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSportTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _selectedSportIds.map((id) {
          final isSelected = _activeSportId == id;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _activeSportId = id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryDarkGreen : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryDarkGreen : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.primaryDarkGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      _sportIcons[id] ?? Icons.sports,
                      color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                      size: 20,
                    ),
                    const AppSizedBox(width: 8),
                    AppText(
                      text: _sportNames[id] ?? id,
                      size: 14,
                      weight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConfigForm(String sportId) {
    final config = _sportConfigs[sportId]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_sportIcons[sportId] ?? Icons.sports, color: AppColors.primaryDarkGreen, size: 20),
            const AppSizedBox(width: 8),
            AppText(
              text: "${_sportNames[sportId]?.toUpperCase()} — COURT DETAILS",
              size: 12,
              weight: FontWeight.w800,
              color: AppColors.primaryDarkGreen,
              letterSpacing: 1.0,
            ),
          ],
        ),
        const AppSizedBox(height: 20),

        _buildLabel("NO. OF NETS / COURTS"),
        _buildSmallTextField(
          initialValue: config['num_courts'].toString(),
          onChanged: (v) => config['num_courts'] = v,
        ),
        const AppSizedBox(height: 20),

        _buildLabel("COURT DIMENSIONS"),
        Row(
          children: [
            Expanded(
              child: _buildSmallTextField(
                initialValue: config['court_length'],
                onChanged: (v) => config['court_length'] = v,
              ),
            ),
            const AppSizedBox(width: 16),
            Expanded(
              child: _buildSmallTextField(
                initialValue: config['court_width'],
                onChanged: (v) => config['court_width'] = v,
              ),
            ),
          ],
        ),
        const AppSizedBox(height: 20),

        _buildLabel("SURFACE TYPE *"),
        _buildChoiceChips(
          options: ['Artificial Turf', 'Concrete', 'Mat on Concrete', 'Rubber'],
          selected: config['surface_type'],
          onSelected: (v) => setState(() => config['surface_type'] = v),
        ),
        const AppSizedBox(height: 20),

        _buildLabel("PITCH TYPE"),
        _buildChoiceChips(
          options: ['Turf Pitch', 'Matting Pitch', 'Hard Pitch'],
          selected: config['pitch_type'],
          onSelected: (v) => setState(() => config['pitch_type'] = v),
        ),
        const AppSizedBox(height: 20),

        _buildLabel("NET CONFIGURATION"),
        _buildChoiceChips(
          options: ['4-sided Enclosed', '3-sided', 'Open Sides'],
          selected: config['net_config'],
          onSelected: (v) => setState(() => config['net_config'] = v),
        ),
        const AppSizedBox(height: 20),

        _buildLabel("STUMPS"),
        _buildChoiceChips(
          options: ['Permanent (Cemented)', 'Removable'],
          selected: config['stumps'],
          onSelected: (v) => setState(() => config['stumps'] = v),
        ),
        const AppSizedBox(height: 20),

        _buildLabel("FLOODLIGHTS"),
        _buildChoiceChips(
          options: ['Yes — Full LED', 'Partial', 'No'],
          selected: config['floodlights'],
          onSelected: (v) => setState(() => config['floodlights'] = v),
        ),
        const AppSizedBox(height: 20),

        _buildLabel("EQUIPMENT AVAILABLE FOR RENT"),
        _buildMultiSelectChips(
          options: ['Bat', 'Ball', 'Stumps', 'Batting Gloves', 'Batting Pads', 'Helmet', 'Wicket Keeping Gloves'],
          selected: config['equipment_rent'],
          onChanged: (v) => setState(() => config['equipment_rent'] = v),
        ),
        const AppSizedBox(height: 20),

        _buildLabel("RULES FOLLOWED"),
        _buildChoiceChips(
          options: ['Box Cricket Rules', 'Modified T10', 'Custom Rules'],
          selected: config['rules'],
          onSelected: (v) => setState(() => config['rules'] = v),
        ),
        const AppSizedBox(height: 20),



        _buildLabel("COURT NAME / LABEL (OPTIONAL)"),
        Row(
          children: [
            Expanded(
              child: _buildSmallTextField(
                initialValue: config['court_names'][0],
                hint: "IPL Arena",
                onChanged: (v) => config['court_names'][0] = v,
              ),
            ),
            const AppSizedBox(width: 16),
            Expanded(
              child: _buildSmallTextField(
                initialValue: config['court_names'][1],
                hint: "T20 Zone",
                onChanged: (v) => config['court_names'][1] = v,
              ),
            ),
          ],
        ),
        const AppSizedBox(height: 8),
        const AppText(
          text: "Custom names help players identify the court",
          size: 12,
          color: AppColors.textSecondaryLight,
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppText(
        text: label,
        size: 13,
        weight: FontWeight.w700,
        color: AppColors.textSecondaryLight,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildSmallTextField({String? initialValue, String? hint, Function(String)? onChanged}) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondaryLight.withOpacity(0.4)),
        filled: true,
        fillColor: const Color(0xFFF0F9F4).withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryDarkGreen, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildChoiceChips({required List<String> options, required String selected, required Function(String) onSelected}) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selected == option;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0F9F4) : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? AppColors.primaryDarkGreen : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: AppText(
              text: option,
              size: 14,
              weight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primaryDarkGreen : AppColors.textSecondaryLight,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultiSelectChips({required List<String> options, required List<String> selected, required Function(List<String>) onChanged}) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () {
            final newList = List<String>.from(selected);
            if (isSelected) {
              newList.remove(option);
            } else {
              newList.add(option);
            }
            onChanged(newList);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0F9F4) : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? AppColors.primaryDarkGreen : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: AppText(
              text: option,
              size: 14,
              weight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primaryDarkGreen : AppColors.textSecondaryLight,
            ),
          ),
        );
      }).toList(),
    );
  }
}
