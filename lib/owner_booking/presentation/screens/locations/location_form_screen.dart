import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/owner_booking/di/get_it/get_it.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_form_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_form_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_form_layout.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/steps/step1_basic_info.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/steps/step2_amenities.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/steps/step3_media.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/steps/step4_summary.dart';

class LocationFormScreen extends StatefulWidget {
  final Map<String, dynamic>? locationData;

  const LocationFormScreen({super.key, this.locationData});

  @override
  State<LocationFormScreen> createState() => _LocationFormScreenState();
}

class _LocationFormScreenState extends State<LocationFormScreen> {
  late LocationFormCubit _cubit;
  final GlobalKey<Step1BasicInfoState> _step1Key = GlobalKey<Step1BasicInfoState>();
  final GlobalKey<Step2AmenitiesState> _step2Key = GlobalKey<Step2AmenitiesState>();
  final GlobalKey<Step3MediaState> _step3Key = GlobalKey<Step3MediaState>();

  @override
  void initState() {
    super.initState();
    _cubit = getIt<LocationFormCubit>();
    if (widget.locationData != null) {
      _cubit.initEdit(widget.locationData!);
    } else {
      _cubit.initAdd();
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _onNext(int currentStep) {
    if (currentStep == 1) {
      if (_step1Key.currentState?.validateAndSave() ?? false) {
        _cubit.goToStep(2);
      }
    } else if (currentStep == 2) {
      if (_step2Key.currentState?.validateAndSave() ?? false) {
        _cubit.goToStep(3);
      }
    } else if (currentStep == 3) {
      if (_step3Key.currentState?.validateAndSave() ?? false) {
        _cubit.goToStep(4);
      }
    } else if (currentStep == 4) {
      _cubit.save();
    }
  }

  void _onBack(int currentStep) {
    if (currentStep > 1) {
      _cubit.goToStep(currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<LocationFormCubit, LocationFormState>(
        listener: (context, state) {
          if (state is LocationFormSaved) {
            toastification.show(
              context: context,
              type: ToastificationType.success,
              title: const Text('Location Saved'),
              autoCloseDuration: const Duration(seconds: 3),
            );
            context.read<LocationCubit>().fetchOwnerLocations();
            if (Navigator.canPop(context)) {
              Navigator.pop(context, state.locationId);
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          } else if (state is LocationFormError) {
            toastification.show(
              context: context,
              type: ToastificationType.error,
              title: const Text('Error saving location'),
              description: Text(state.message),
              autoCloseDuration: const Duration(seconds: 4),
            );
          }
        },
        builder: (context, state) {
          if (state is LocationFormInitial) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final isSaving = state is LocationFormSaving;
          final readyState = state is LocationFormReady 
              ? state 
              : (isSaving ? LocationFormReady(_cubit.data, currentStep: 4) : LocationFormReady(_cubit.data));
          
          final int step = readyState.currentStep;
          final bool isEdit = widget.locationData != null;

          Widget stepWidget = const SizedBox();
          String title = '';
          String subtitle = '';

          switch (step) {
            case 1:
              title = 'Basic Details';
              subtitle = 'Address and Maps location';
              stepWidget = Step1BasicInfo(key: _step1Key);
              break;
            case 2:
              title = 'Amenities';
              subtitle = 'Select facilities provided';
              stepWidget = Step2Amenities(key: _step2Key);
              break;
            case 3:
              title = 'Media & Documents';
              subtitle = 'Upload images and verifications';
              stepWidget = Step3Media(key: _step3Key);
              break;
            case 4:
              title = 'Review';
              subtitle = 'Check the details before saving';
              stepWidget = const Step4Summary();
              break;
          }

          return LocationFormLayout(
            isEdit: isEdit,
            currentStep: step,
            title: title,
            subtitle: subtitle,
            isLoading: isSaving,
            onNext: () => _onNext(step),
            onBack: () => _onBack(step),
            child: stepWidget,
          );
        },
      ),
    );
  }
}
