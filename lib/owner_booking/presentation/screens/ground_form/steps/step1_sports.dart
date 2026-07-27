import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_layout.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/sport/sport_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/sport/sport_state.dart';
import 'package:turfpro_owner/owner_booking/data/models/sport_model.dart';

class Step1Sports extends StatefulWidget {
  final bool isEdit;
  const Step1Sports({super.key, required this.isEdit});

  @override
  State<Step1Sports> createState() => _Step1SportsState();
}

class _Step1SportsState extends State<Step1Sports> with TickerProviderStateMixin {
  String _selectedSport = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _selectedSport = context.read<GroundFormCubit>().data.category.toLowerCase();
    _initialized = true;
  }

  void _select(String id) {
    setState(() => _selectedSport = id);
  }

  void _onNext() {
    if (_selectedSport.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text('Select a sport for this ground'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }
    final cubit = context.read<GroundFormCubit>();
    cubit.updateData(cubit.data.copyWith(category: _selectedSport));
    cubit.goToStep(2);
  }

  @override
  Widget build(BuildContext context) {
    return GroundFormLayout(
      isEdit: widget.isEdit,
      currentStep: 1,
      title: 'Sport',
      subtitle: 'Which single sport is this ground for?',
      onNext: _onNext,
      onBack: () => Navigator.pop(context),
      child: BlocBuilder<SportCubit, SportState>(
        builder: (context, sportState) {
          final sports = sportState is SportLoaded ? sportState.sports : <SportModel>[];
          if (sports.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: List.generate(sports.length, (index) {
              final sport = sports[index];
              final id = sport.slug;
              final isSelected = _selectedSport == id;

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 350 + index * 60),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: () => _select(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: AppSizes.md),
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.slotAvailableBg : AppColors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryDarkGreen
                        : AppColors.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryDarkGreen.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    // Icon container with gradient on select
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryDarkGreen,
                                  Color(0xFF066B3E),
                                ],
                              )
                            : null,
                        color: isSelected ? null : AppColors.slotAvailableBg,
                        shape: BoxShape.circle,
                      ),
                      child: sport.iconUrl.isNotEmpty
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: sport.iconUrl,
                                width: AppSizes.iconLg,
                                height: AppSizes.iconLg,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => SizedBox(
                                  width: AppSizes.iconLg,
                                  height: AppSizes.iconLg,
                                ),
                                errorWidget: (_, _, _) => Icon(
                                  Icons.sports,
                                  color: isSelected ? AppColors.white : AppColors.primaryDarkGreen,
                                  size: AppSizes.iconLg,
                                ),
                              ),
                            )
                          : sport.localAsset.isNotEmpty
                              ? ClipOval(
                                  child: Image.asset(
                                    sport.localAsset,
                                    width: AppSizes.iconLg,
                                    height: AppSizes.iconLg,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Icon(
                                      Icons.sports,
                                      color: isSelected ? AppColors.white : AppColors.primaryDarkGreen,
                                      size: AppSizes.iconLg,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.sports,
                                  color: isSelected ? AppColors.white : AppColors.primaryDarkGreen,
                                  size: AppSizes.iconLg,
                                ),
                    ),
                    const SizedBox(width: AppSizes.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text: sport.name,
                            size: 15,
                            weight: FontWeight.w700,
                          ),
                          const SizedBox(height: AppSizes.xxs),
                          AppText(
                            text: 'Sport Configuration',
                            size: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ],
                      ),
                    ),
                    // Animated checkmark indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [
                                  AppColors.primaryDarkGreen,
                                  Color(0xFF066B3E),
                                ],
                              )
                            : null,
                        color: isSelected ? null : AppColors.borderLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.white,
                                  size: 16,
                                  key: ValueKey('check'),
                                )
                              : const SizedBox(key: ValueKey('empty')),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      );
        },
      ),
    );
  }
}
