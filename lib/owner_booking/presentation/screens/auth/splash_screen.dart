import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_flow.dart';
import 'package:turfpro_owner/common/services/app_config_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check maintenance mode first
    if (AppConfigService.instance.ownerAppMaintenance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/maintenance');
      });
      return;
    }
    // Trigger auth check
    context.read<AuthCubit>().init();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        void clearAndGo(String route) {
          Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
        }

        if (state is AuthInitial || state is AuthUnauthenticated) {
          print('DEBUG [SplashScreen]: State is ${state.runtimeType} -> routing to / (login)');
          clearAndGo('/');
        } else if (state is AuthSuccess) {
          print('DEBUG [SplashScreen]: AuthSuccess -> routing to /dashboard');
          clearAndGo('/dashboard');
        } else if (state is AuthLocationRequired) {
          print('DEBUG [SplashScreen]: AuthLocationRequired -> routing to /add-location');
          clearAndGo('/add-location');
        } else if (state is AuthStep1Required) {
          print('DEBUG [SplashScreen]: AuthStep1Required -> routing to /onboarding/step1');
          clearAndGo('/onboarding/step1');
        } else if (state is AuthStep2Required) {
          print('DEBUG [SplashScreen]: AuthStep2Required -> routing to /onboarding/step2');
          clearAndGo('/onboarding/step2');
        } else if (state is AuthStep3Required) {
          print('DEBUG [SplashScreen]: AuthStep3Required -> routing to /onboarding/step3');
          clearAndGo('/onboarding/step3');
        } else if (state is AuthGroundRequired) {
          print('DEBUG [SplashScreen]: AuthGroundRequired -> routing to GroundFormFlow (Add Sport)');
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
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryDarkGreen,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/pngs/app_logo.jpg',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const AppText(
                text: "TurfPro Owner",
                size: 32,
                weight: FontWeight.w700,
                color: AppColors.white,
              ),
              const SizedBox(height: 8),
              AppText(
                text: "Your turf, managed professionally",
                size: 16,
                color: AppColors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: AppColors.white),
            ],
          ),
        ),
      ),
    );
  }
}
