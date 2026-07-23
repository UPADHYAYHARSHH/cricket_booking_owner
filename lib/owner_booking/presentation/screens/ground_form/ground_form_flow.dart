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
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/steps/step2_basic_info.dart';
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
              description: _isEdit
                  ? null
                  : const Text('It will be reviewed within 24–48 hours.'),
              autoCloseDuration: const Duration(seconds: 4),
            );
            Navigator.pop(context);
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

              return Scaffold(
                backgroundColor: AppColors.bgLight,
                body: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    Step1Sports(isEdit: _isEdit),
                    Step2BasicInfo(isEdit: _isEdit),
                    Step4Schedule(isEdit: _isEdit),
                    Step5Pricing(isEdit: _isEdit),
                    Step7Review(isEdit: _isEdit),
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
