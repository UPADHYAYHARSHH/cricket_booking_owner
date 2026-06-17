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
  final bool isSettingsMode;
  
  const AmenitiesScreen({super.key, this.isSettingsMode = false});

  @override
  State<AmenitiesScreen> createState() => _AmenitiesScreenState();
}

class _AmenitiesScreenState extends State<AmenitiesScreen> {
  final Map<String, bool> _amenities = {
    // Basic
    'parking': true,
    'washrooms': true,
    'changing_rooms': false,
    'drinking_water': true,
    'waiting_area': false,
    // Food
    'cafeteria': true,
    'vending_machine': false,
    'water_dispenser': true,
    // Safety
    'cctv': true,
    'security_guard': false,
    'first_aid': true,
    'fire_safety': false,
    // Tech
    'wifi': false,
    'live_scoring': true,
    'coaching': false,
    'video_recording': false,
    'score_display': false,
    // Cricket Equipment
    'bat_rental': false,
    'ball_provided': false,
    'stumps_permanent': false,
    'batting_pads': false,
    'gloves': false,
    'helmet': false,
    'wicket_keeping_set': false,
    // Football Equipment
    'football_rental': false,
    'goal_nets': false,
    'bibs': false,
  };

  String _parkingCharge = 'Free';
  bool _isLoadingData = true;
  Map<String, dynamic> _sportsConfig = {};

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

      if (data != null) {
        if (data['sports_config'] != null) {
          _sportsConfig = data['sports_config'];
        }
        if (data['amenities_config'] != null) {
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

    if (widget.isSettingsMode) {
      // Direct supabase update or custom cubit method
      Supabase.instance.client.from('owner_details').update({
        'amenities_config': config,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUserId!).then((_) {
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            title: const Text("Amenities updated successfully!"),
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      }).catchError((e) {
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: Text("Error: $e"),
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      });
    } else {
      context.read<AuthCubit>().saveAmenities(amenitiesConfig: config);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(text: "💡 ", size: 14),
                      Expanded(
                        child: AppText(
                          text: "Venues with 8+ amenities get 2x more bookings on CricBook",
                          size: 13,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    AppText(
                      text: "Last updated: Today • ",
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    AppText(
                      text: "Changes sync instantly",
                      size: 12,
                      color: Colors.teal.shade700,
                      weight: FontWeight.w600,
                    ),
                  ],
                ),
                const AppSizedBox(height: 32),

                _buildSectionHeader("🏠 BASIC", _getGroupKeys('basic')),
                _buildAmenityTile('parking', "Parking"),
                _buildAmenityTile('washrooms', "Washrooms"),
                _buildAmenityTile('changing_rooms', "Changing Rooms"),
                _buildAmenityTile('drinking_water', "Drinking Water"),
                _buildAmenityTile('waiting_area', "Waiting / Seating Area"),
                
                const AppSizedBox(height: 32),
                _buildSectionHeader("🍽️ FOOD & BEVERAGES", _getGroupKeys('food')),
                _buildAmenityTile('cafeteria', "Cafeteria / Canteen"),
                _buildAmenityTile('vending_machine', "Vending Machine"),
                _buildAmenityTile('water_dispenser', "Water Dispenser"),

                const AppSizedBox(height: 32),
                _buildSectionHeader("🔐 SAFETY", _getGroupKeys('safety')),
                _buildAmenityTile('cctv', "CCTV Surveillance"),
                _buildAmenityTile('security_guard', "Security Guard"),
                _buildAmenityTile('first_aid', "First Aid Kit"),
                _buildAmenityTile('fire_safety', "Fire Safety"),

                // Dynamic Equipment based on sports
                if (_hasCricket()) ...[
                  const AppSizedBox(height: 32),
                  _buildSectionHeader("🏏 CRICKET EQUIPMENT", _getGroupKeys('cricket')),
                  _buildAmenityTile('bat_rental', "Bat Rental"),
                  _buildAmenityTile('ball_provided', "Ball (Tennis/Leather)"),
                  _buildAmenityTile('stumps_permanent', "Stumps (Permanent)"),
                  _buildAmenityTile('batting_pads', "Batting Pads Rental"),
                  _buildAmenityTile('gloves', "Gloves Rental"),
                  _buildAmenityTile('helmet', "Helmet Rental"),
                  _buildAmenityTile('wicket_keeping_set', "Wicket Keeping Set"),
                ],

                if (_hasFootball()) ...[
                  const AppSizedBox(height: 32),
                  _buildSectionHeader("⚽ FOOTBALL EQUIPMENT", _getGroupKeys('football')),
                  _buildAmenityTile('football_rental', "Football Rental"),
                  _buildAmenityTile('goal_nets', "Goal Nets"),
                  _buildAmenityTile('bibs', "Bibs"),
                ],

                const AppSizedBox(height: 32),
                _buildSectionHeader("📶 TECH & SERVICES", _getGroupKeys('tech')),
                _buildAmenityTile('wifi', "WiFi"),
                _buildAmenityTile('live_scoring', "Live Scoring App Support"),
                _buildAmenityTile('coaching', "Coaching Available"),
                _buildAmenityTile('video_recording', "Video Recording"),
                _buildAmenityTile('score_display', "Score Display / LED Board"),
                _buildSectionHeader("🅿️ PARKING DETAILS"),
                _buildLabel("PARKING CHARGE"),
                _buildChargeSelector(),
              ],
            );

    if (widget.isSettingsMode) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: AppColors.primaryDarkGreen,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const AppText(
            text: "Manage Amenities", 
            size: 16, 
            weight: FontWeight.w600, 
            color: Colors.white,
          ),
          titleSpacing: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: content,
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const AppText(text: "Save Changes", size: 16, weight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      );
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
            child: content,
          );
        },
      ),
    );
  }

  List<String> _getGroupKeys(String group) {
    switch (group) {
      case 'basic': return ['parking', 'washrooms', 'changing_rooms', 'drinking_water', 'waiting_area'];
      case 'food': return ['cafeteria', 'vending_machine', 'water_dispenser'];
      case 'safety': return ['cctv', 'security_guard', 'first_aid', 'fire_safety'];
      case 'tech': return ['wifi', 'live_scoring', 'coaching', 'video_recording', 'score_display'];
      case 'cricket': return ['bat_rental', 'ball_provided', 'stumps_permanent', 'batting_pads', 'gloves', 'helmet', 'wicket_keeping_set'];
      case 'football': return ['football_rental', 'goal_nets', 'bibs'];
      default: return [];
    }
  }

  bool _hasCricket() {
    return _sportsConfig.containsKey('box_cricket') || _sportsConfig.containsKey('cricket');
  }

  bool _hasFootball() {
    return _sportsConfig.containsKey('football') || _sportsConfig.containsKey('futsal');
  }

  int _getActiveCount(List<String> keys) {
    return keys.where((k) => _amenities[k] == true).length;
  }

  Widget _buildSectionHeader(String title, [List<String>? keys]) {
    String displayTitle = title;
    if (keys != null) {
      final active = _getActiveCount(keys);
      final total = keys.length;
      displayTitle = "$title ($active/$total ACTIVE)";
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppText(
        text: displayTitle.toUpperCase(),
        size: 13,
        weight: FontWeight.w800,
        color: AppColors.textSecondaryLight.withOpacity(0.8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAmenityTile(String key, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: AppText(text: title, size: 15, weight: FontWeight.w600, color: AppColors.textPrimaryLight),
        value: _amenities[key] ?? false,
        onChanged: (val) => setState(() => _amenities[key] = val),
        activeColor: AppColors.primaryLightGreen,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.grey.shade300,
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
