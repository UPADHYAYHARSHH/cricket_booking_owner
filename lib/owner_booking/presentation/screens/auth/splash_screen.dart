import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/splash/owner_minimal_splash.dart';
import 'package:turfpro_owner/splash/slottix_splash.dart' show SplashSound;
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/services/app_config_service.dart';
import 'package:turfpro_owner/utils/auth_navigation_helper.dart';

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
    if (state is AuthError) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text(state.message),
        autoCloseDuration: const Duration(seconds: 5),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
      return;
    }
    AuthNavigationHelper.navigateForAuthState(context, state);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        _pendingState = state;
      },
      child: OwnerMinimalSplash(
        sound: SplashSound.classicCourt, // same sound as before
        onReady: _onReady,
        onDone: _onDone,
      ),
    );
  }
}
