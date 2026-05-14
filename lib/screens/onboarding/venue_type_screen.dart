import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:turfpro_owner/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/common/widgets/onboarding_layout.dart';
import 'package:toastification/toastification.dart';

class VenueTypeScreen extends StatefulWidget {
  const VenueTypeScreen({super.key});

  @override
  State<VenueTypeScreen> createState() => _VenueTypeScreenState();
}

class _VenueTypeScreenState extends State<VenueTypeScreen> {
  // Map of sport ID to its ground count
  final Map<String, int> _selectedSports = {};
  String _selectedCategory = 'Indoor';

  @override
  void initState() {
    super.initState();
    _fetchExistingDetails();
  }

  Future<void> _fetchExistingDetails() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('owner_details')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          if (data['sports_config'] != null && data['sports_config'] is Map) {
            final Map<String, dynamic> config = data['sports_config'];
            config.forEach((key, value) {
              _selectedSports[key] = value as int;
            });
          }
          _selectedCategory = data['venue_category'] ?? 'Indoor';
        });
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
    }
  }

  final List<Map<String, dynamic>> _sports = [
    {
      'id': 'box_cricket',
      'name': 'Box Cricket',
      'subtitle': 'Enclosed cricket arena',
      'icon': Icons.sports_cricket,
    },
    {
      'id': 'volleyball',
      'name': 'Volleyball',
      'subtitle': 'Indoor / outdoor',
      'icon': Icons.sports_volleyball,
    },
    {
      'id': 'pickleball',
      'name': 'Pickleball',
      'subtitle': 'Paddle sport',
      'icon': Icons.sports_tennis,
    },
    {
      'id': 'football',
      'name': 'Football / Futsal',
      'subtitle': '5-a-side, 7-a-side',
      'icon': Icons.sports_soccer,
    },
    {
      'id': 'badminton',
      'name': 'Badminton',
      'subtitle': 'Single / double court',
      'icon': Icons.sports_tennis,
    },
    {
      'id': 'tennis',
      'name': 'Tennis',
      'subtitle': 'Hard / clay / grass',
      'icon': Icons.sports_tennis,
    },
  ];

  void _onSportTap(String id) {
    setState(() {
      if (_selectedSports.containsKey(id)) {
        _selectedSports.remove(id);
      } else {
        _selectedSports[id] = 1;
      }
    });
  }

  void _updateCount(String id, int delta) {
    setState(() {
      final current = _selectedSports[id] ?? 1;
      final newValue = current + delta;
      if (newValue >= 1) {
        _selectedSports[id] = newValue;
      }
    });
  }

  void _onSave() {
    if (_selectedSports.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text("Select at least one sport"),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }
    
    context.read<AuthCubit>().saveVenueType(
      sportsConfig: _selectedSports,
      category: _selectedCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
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
            currentStep: 2,
            title: "Venue Type",
            subtitle: "Set ground quantities for each sport",
            isLoading: state is AuthLoading,
            onNext: _onSave,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel("SELECT SPORTS & QUANTITY *"),
                const AppSizedBox(height: 16),
                _buildSportsGrid(),
                const AppSizedBox(height: 32),
                _buildLabel("VENUE CATEGORY"),
                const AppSizedBox(height: 12),
                _buildCategorySelector(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String label) {
    return AppText(
      text: label,
      size: 12,
      weight: FontWeight.w700,
      color: AppColors.textSecondaryLight,
      letterSpacing: 0.5,
    );
  }

  Widget _buildSportsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _sports.length,
      itemBuilder: (context, index) {
        final sport = _sports[index];
        final isSelected = _selectedSports.containsKey(sport['id']);
        final count = _selectedSports[sport['id']] ?? 0;
        
        return GestureDetector(
          onTap: () => _onSportTap(sport['id']),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0F9F4) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryDarkGreen
                    : AppColors.primaryDarkGreen.withOpacity(0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  sport['icon'],
                  color: isSelected
                      ? AppColors.primaryDarkGreen
                      : AppColors.textPrimaryLight,
                  size: 32,
                ),
                const AppSizedBox(height: 8),
                AppText(
                  text: sport['name'],
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppColors.textPrimaryLight,
                ),
                const AppSizedBox(height: 4),
                AppText(
                  text: sport['subtitle'],
                  size: 11,
                  color: AppColors.textSecondaryLight,
                ),
                if (isSelected) ...[
                  const AppSizedBox(height: 12),
                  _buildInlineCounter(sport['id'], count),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInlineCounter(String id, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCounterIcon(Icons.remove, () => _updateCount(id, -1)),
        const AppSizedBox(width: 12),
        AppText(
          text: count.toString(),
          size: 16,
          weight: FontWeight.w700,
          color: AppColors.primaryDarkGreen,
        ),
        const AppSizedBox(width: 12),
        _buildCounterIcon(Icons.add, () => _updateCount(id, 1)),
      ],
    );
  }

  Widget _buildCounterIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.2)),
        ),
        child: Icon(icon, size: 14, color: AppColors.primaryDarkGreen),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = ['Indoor', 'Outdoor', 'Both'];
    return Row(
      children: categories.map((cat) {
        final isSelected = _selectedCategory == cat;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0F9F4) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryDarkGreen
                      : AppColors.primaryDarkGreen.withOpacity(0.1),
                ),
              ),
              child: AppText(
                text: cat,
                size: 14,
                weight: FontWeight.w600,
                color: isSelected
                    ? AppColors.primaryDarkGreen
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
