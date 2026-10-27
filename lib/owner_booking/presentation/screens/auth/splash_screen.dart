import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/splash/slottix_splash.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_flow.dart';
import 'package:turfpro_owner/common/services/app_config_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AuthState? _pendingState;

  Future<void> _onReady() async {
    if (AppConfigService.instance.ownerAppMaintenance) {
      return;
    }

    final authCubit = context.read<AuthCubit>();
    authCubit.init();

    if (_isFinalState(authCubit.state)) {
      _pendingState = authCubit.state;
      return;
    }

    try {
      _pendingState = await authCubit.stream
          .firstWhere((s) => _isFinalState(s))
          .timeout(const Duration(milliseconds: 4000));
    } catch (_) {
      _pendingState = authCubit.state;
    }
  }

  bool _isFinalState(AuthState s) {
    return s is! AuthInitial && s is! AuthLoading;
  }

  void _onDone() {
    if (!mounted) return;
    if (AppConfigService.instance.ownerAppMaintenance) {
      Navigator.pushReplacementNamed(context, '/maintenance');
      return;
    }
    final state = _pendingState ?? context.read<AuthCubit>().state;
    _performNavigation(state);
  }

  void _performNavigation(AuthState state) {
    void clearAndGo(String route) {
      Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
    }

    if (state is AuthInitial || state is AuthUnauthenticated) {
      clearAndGo('/');
    } else if (state is AuthSuccess) {
      clearAndGo('/dashboard');
    } else if (state is AuthLocationRequired) {
      clearAndGo('/add-location');
    } else if (state is AuthStep1Required) {
      clearAndGo('/onboarding/step1');
    } else if (state is AuthStep2Required) {
      clearAndGo('/onboarding/step2');
    } else if (state is AuthStep3Required) {
      clearAndGo('/onboarding/step3');
    } else if (state is AuthGroundRequired) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => GroundFormFlow(locationId: state.locationId),
        ),
        (r) => false,
      );
    } else if (state is AuthPendingApproval) {
      clearAndGo('/pending-approval');
    } else if (state is AuthError) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(state.message),
        autoCloseDuration: const Duration(seconds: 5),
      );
      clearAndGo('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        _pendingState = state;
      },
      child: SlottixSplash(
        variant: SplashVariant.user, // Using 1st variant for both apps
        sound: SplashSound.classicCourt,
        onReady: _onReady,
        onDone: _onDone,
      ),
    );
  }
}
