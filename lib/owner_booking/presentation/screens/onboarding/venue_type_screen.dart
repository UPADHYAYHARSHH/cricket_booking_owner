import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:turfpro_owner/utils/auth_helper.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
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
  // Map of sport ID to its category (Indoor, Outdoor, Both)
  final Map<String, String> _sportCategories = {};

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
        setState(() {
          if (data['sports_config'] != null && data['sports_config'] is Map) {
            final Map<String, dynamic> config = data['sports_config'];
            config.forEach((key, value) {
              _selectedSports[key] = value as int;
            });
          }

          final String? categoryRaw = data['venue_category'];
          if (categoryRaw != null && categoryRaw.isNotEmpty) {
            if (categoryRaw.startsWith('{')) {
              try {
                final Map<String, dynamic> decoded = jsonDecode(categoryRaw);
                decoded.forEach((key, value) {
                  _sportCategories[key] = value.toString();
                });
              } catch (_) {}
            } else {
              // Legacy/fallback: populate all loaded selected sports to the same category
              for (var key in _selectedSports.keys) {
                _sportCategories[key] = categoryRaw;
              }
            }
          }
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
        _sportCategories.remove(id);
      } else {
        _selectedSports[id] = 1;
        _sportCategories[id] = 'Indoor';
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

    final Map<String, String> cleanedCategories = {};
    for (var key in _selectedSports.keys) {
      cleanedCategories[key] = _sportCategories[key] ?? 'Indoor';
    }

    context.read<AuthCubit>().saveVenueType(
      sportsConfig: _selectedSports,
      category: jsonEncode(cleanedCategories),
    );
  }

  List<Map<String, dynamic>> get _allSports {
    final List<Map<String, dynamic>> list = List.from(_sports);
    for (var sportId in _selectedSports.keys) {
      if (!list.any((s) => s['id'] == sportId)) {
        list.add({
          'id': sportId,
          'name': sportId
              .replaceAll('_', ' ')
              .split(' ')
              .map(
                (str) => str.isNotEmpty
                    ? '${str[0].toUpperCase()}${str.substring(1)}'
                    : '',
              )
              .join(' '),
          'subtitle': 'Sport Configuration',
          'icon': Icons.sports,
        });
      }
    }
    return list;
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
            subtitle: "Select and configure your sports",
            isLoading: state is AuthLoading,
            onNext: _onSave,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel("SELECT & CONFIGURE SPORTS *"),
                const AppSizedBox(height: 16),
                _buildSportsList(),
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

  Widget _buildSportsList() {
    final sportsList = _allSports;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sportsList.length,
      itemBuilder: (context, index) {
        final sport = sportsList[index];
        final sportId = sport['id'] as String;
        final isSelected = _selectedSports.containsKey(sportId);
        final count = _selectedSports[sportId] ?? 1;
        final category = _sportCategories[sportId] ?? 'Indoor';

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.slotAvailableBg : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryDarkGreen
                  : AppColors.primaryDarkGreen.withValues(alpha: 0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryDarkGreen.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row (Icon, Name, Switch)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.white
                          : AppColors.slotAvailableBg.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryDarkGreen.withValues(alpha: 0.2)
                            : Colors.transparent,
                      ),
                    ),
                    child: Icon(
                      sport['icon'],
                      color: AppColors.primaryDarkGreen,
                      size: 24,
                    ),
                  ),
                  const AppSizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: sport['name'],
                          size: 15,
                          weight: FontWeight.w700,
                          color: AppColors.textPrimaryLight,
                        ),
                        const AppSizedBox(height: 2),
                        AppText(
                          text: sport['subtitle'],
                          size: 11,
                          color: AppColors.textSecondaryLight,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isSelected,
                    activeThumbColor: AppColors.primaryDarkGreen,
                    activeTrackColor: AppColors.slotAvailableBg,
                    inactiveThumbColor: AppColors.textSecondaryLight,
                    inactiveTrackColor: AppColors.borderLight,
                    onChanged: (val) => _onSportTap(sportId),
                  ),
                ],
              ),

              if (isSelected) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE0ECE5),
                  ),
                ),

                // Config Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category Options
                    Row(
                      children: ['Indoor', 'Outdoor', 'Both'].map((cat) {
                        final isSelectedCat = category == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _sportCategories[sportId] = cat;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelectedCat
                                    ? AppColors.primaryDarkGreen
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelectedCat
                                      ? AppColors.primaryDarkGreen
                                      : AppColors.primaryDarkGreen.withValues(
                                          alpha: 0.15,
                                        ),
                                ),
                              ),
                              child: AppText(
                                text: cat,
                                size: 12,
                                weight: isSelectedCat
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelectedCat
                                    ? AppColors.white
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Counter
                    _buildInlineCounter(sportId, count),
                  ],
                ),
              ],
            ],
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(icon, size: 14, color: AppColors.primaryDarkGreen),
      ),
    );
  }
}
