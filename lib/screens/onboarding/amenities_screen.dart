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

class AmenitiesScreen extends StatefulWidget {
  const AmenitiesScreen({super.key});

  @override
  State<AmenitiesScreen> createState() => _AmenitiesScreenState();
}

class _AmenitiesScreenState extends State<AmenitiesScreen> {
  final Map<String, bool> _amenities = {
    'parking': true,
    'washrooms': true,
    'changing_rooms': false,
    'drinking_water': true,
    'waiting_area': false,
    'cafeteria': true,
    'vending_machine': false,
    'water_dispenser': true,
    'cctv': true,
    'security_guard': false,
    'first_aid': true,
    'fire_safety': false,
    'wifi': false,
    'live_scoring': true,
    'coaching': false,
    'video_recording': false,
    'score_display': false,
  };

  String _parkingCharge = 'Free';
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _fetchExistingDetails();
  }

  Future<void> _fetchExistingDetails() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final data = await Supabase.instance.client
          .from('owner_details')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null && data['amenities_config'] != null) {
        final config = data['amenities_config'];
        setState(() {
          _amenities.forEach((key, value) {
            if (config.containsKey(key)) {
              _amenities[key] = config[key] ?? false;
            }
          });
          _parkingCharge = config['parking_charge'] ?? 'Free';
        });
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  void _onSave() {
    final Map<String, dynamic> config = Map.from(_amenities);
    config['two_wheeler_spots'] = "";
    config['four_wheeler_spots'] = "";
    config['parking_charge'] = _parkingCharge;

    context.read<AuthCubit>().saveAmenities(amenitiesConfig: config);
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
            currentStep: 5,
            title: "Amenities",
            subtitle: "What facilities do you offer players?",
            isLoading: state is AuthLoading,
            onNext: _onSave,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("🏠 BASIC FACILITIES"),
                _buildAmenityTile('parking', "Parking", "Two-wheeler & four-wheeler"),
                _buildAmenityTile('washrooms', "Washrooms", "Clean toilets available"),
                _buildAmenityTile('changing_rooms', "Changing Rooms", "With lockers"),
                _buildAmenityTile('drinking_water', "Drinking Water", "Water cooler / RO"),
                _buildAmenityTile('waiting_area', "Waiting Area / Seating", "Bench seating for spectators"),
                
                const AppSizedBox(height: 32),
                _buildSectionHeader("🍽️ FOOD & REFRESHMENTS"),
                _buildAmenityTile('cafeteria', "Cafeteria / Canteen", "Snacks, beverages"),
                _buildAmenityTile('vending_machine', "Vending Machine", ""),
                _buildAmenityTile('water_dispenser', "Water Dispenser", ""),

                const AppSizedBox(height: 32),
                _buildSectionHeader("🔐 SAFETY & SECURITY"),
                _buildAmenityTile('cctv', "CCTV Surveillance", "24x7 monitoring"),
                _buildAmenityTile('security_guard', "Security Guard", ""),
                _buildAmenityTile('first_aid', "First Aid Kit", ""),
                _buildAmenityTile('fire_safety', "Fire Safety Equipment", ""),

                const AppSizedBox(height: 32),
                _buildSectionHeader("📶 TECH & SERVICES"),
                _buildAmenityTile('wifi', "WiFi", "Free for players"),
                _buildAmenityTile('live_scoring', "Live Scoring App Support", ""),
                _buildAmenityTile('coaching', "Coaching Available", "Paid coaching sessions"),
                _buildAmenityTile('video_recording', "Video Recording", "Match recording available"),
                _buildAmenityTile('score_display', "Score Display / LED Board", ""),

                const AppSizedBox(height: 32),
                _buildSectionHeader("🅿️ PARKING DETAILS"),
                _buildLabel("PARKING CHARGE"),
                _buildChargeSelector(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppText(
        text: title,
        size: 13,
        weight: FontWeight.w800,
        color: AppColors.textSecondaryLight.withOpacity(0.8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAmenityTile(String key, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: AppText(text: title, size: 15, weight: FontWeight.w600, color: AppColors.textPrimaryLight),
        subtitle: subtitle.isNotEmpty ? AppText(text: subtitle, size: 12, color: AppColors.textSecondaryLight) : null,
        value: _amenities[key] ?? false,
        onChanged: (val) => setState(() => _amenities[key] = val),
        activeColor: AppColors.primaryLightGreen,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade200,
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppText(
        text: label,
        size: 12,
        weight: FontWeight.w700,
        color: AppColors.textSecondaryLight,
      ),
    );
  }


  Widget _buildChargeSelector() {
    return Row(
      children: ['Free', 'Paid'].map((type) {
        final isSelected = _parkingCharge == type;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => setState(() => _parkingCharge = type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0F9F4) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? AppColors.primaryDarkGreen : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: AppText(
                text: type,
                size: 14,
                weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryDarkGreen : AppColors.textSecondaryLight,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
