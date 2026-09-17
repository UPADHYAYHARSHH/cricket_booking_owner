import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/owner_booking/di/get_it/get_it.dart';
import 'package:turfpro_owner/owner_booking/domain/repositories/ground_repository.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/ground/ground_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/steps/step1_sports.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/steps/step4_schedule.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/steps/step5_pricing.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/steps/step7_review.dart';

/// Entry point for the add / edit ground flow. A ground always belongs to a
/// [locationId]. Pass [groundData] (the full Supabase row including
/// `ground_images`) for edit mode. Leave it null for add mode.
class GroundFormFlow extends StatefulWidget {
  final String locationId;
  final Map<String, dynamic>? groundData;

  const GroundFormFlow({super.key, required this.locationId, this.groundData});

  @override
  State<GroundFormFlow> createState() => _GroundFormFlowState();
}

class _GroundFormFlowState extends State<GroundFormFlow> {
  late final PageController _pageController;
  late final GroundFormCubit _cubit;

  bool get _isEdit => widget.groundData != null;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _cubit = GroundFormCubit(getIt<GroundRepository>());
    if (_isEdit) {
      _cubit.initEdit(widget.groundData!);
    } else {
      _cubit.initAdd(widget.locationId);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _animateTo(int step) {
    final page = step - 1;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _getTitle(int step) {
    switch (step) {
      case 1: return 'Sport';
      case 2: return 'Schedule';
      case 3: return 'Pricing';
      case 4: return 'Review & Save';
      default: return '';
    }
  }

  String _getSubtitle(int step) {
    switch (step) {
      case 1: return 'Which single sport is this ground for?';
      case 2: return 'Set operating hours and booking window';
      case 3: return 'Set rates per 1-hour slot for this ground';
      case 4: return _isEdit ? 'Double-check changes before saving' : 'Double-check details before creating';
      default: return '';
    }
  }

  Widget _buildHeader(BuildContext context, int currentStep) {
    final topPadding = MediaQuery.of(context).padding.top;
    final int kGroundFormTotalSteps = 4;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 24, // AppSizes.lg
        bottom: 32, // AppSizes.xl
        left: 32, // AppSizes.xxl
        right: 32,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDarkGreen, Color(0xFF066B3E)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (currentStep > 1) {
                    _cubit.goToStep(currentStep - 1);
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8), // AppSizes.sm
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8), // AppSizes.radiusSm
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.white,
                    size: 20, // AppSizes.iconMd
                  ),
                ),
              ),
              const SizedBox(width: 16), // AppSizes.md
              Text(
                _isEdit ? 'Edit Ground' : 'Add New Ground',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24), // AppSizes.lg
          Row(
            children: List.generate(kGroundFormTotalSteps, (index) {
              final isCompleted = index < currentStep;
              final isCurrent = index == currentStep - 1;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  height: isCurrent ? 5 : 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    gradient: isCompleted
                        ? const LinearGradient(
                            colors: [AppColors.white, Color(0xFFB9F6CA)],
                          )
                        : null,
                    color: isCompleted
                        ? null
                        : AppColors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999), // AppSizes.radiusFull
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24), // AppSizes.lg
          Text(
            'Step $currentStep of $kGroundFormTotalSteps',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4), // AppSizes.xs
          Text(
            _getTitle(currentStep),
            style: const TextStyle(
              fontSize: 26,
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4), // AppSizes.xs
          Text(
            _getSubtitle(currentStep),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<GroundFormCubit, GroundFormState>(
        listener: (context, state) {
          if (state is GroundFormReady) {
            _animateTo(state.currentStep);
          }

          if (state is GroundFormSaved) {
            context.read<GroundCubit>().fetchGroundsForLocation(
              widget.locationId,
            );
            toastification.show(
              context: context,
              type: ToastificationType.success,
              title: Text(
                _isEdit ? 'Ground updated!' : 'Ground added successfully!',
              ),
              autoCloseDuration: const Duration(seconds: 4),
            );
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/splash');
            }
          }
        },
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            final state = _cubit.state;
            if (state is GroundFormReady && state.currentStep > 1) {
              _cubit.goToStep(state.currentStep - 1);
            } else {
              Navigator.pop(context);
            }
          },
          child: BlocBuilder<GroundFormCubit, GroundFormState>(
            builder: (context, state) {
              if (state is GroundFormLoading) {
                return const Scaffold(
                  backgroundColor: AppColors.bgLight,
                  body: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                );
              }

              final currentStep = (state is GroundFormReady) ? state.currentStep : 1;

              return Scaffold(
                backgroundColor: AppColors.bgLight,
                body: Column(
                  children: [
                    _buildHeader(context, currentStep),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          Step1Sports(isEdit: _isEdit),
                          Step4Schedule(isEdit: _isEdit),
                          Step5Pricing(isEdit: _isEdit),
                          Step7Review(isEdit: _isEdit),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
