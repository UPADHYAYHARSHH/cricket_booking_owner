import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:toastification/toastification.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
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
          clearAndGo('/');
        } else if (state is AuthSuccess) {
          clearAndGo('/dashboard');
        } else if (state is AuthProfileIncomplete) {
          String route = '/personal-info';
          if (state.step == 2) route = '/venue-type';
          if (state.step == 3) route = '/venue-details';
          if (state.step == 4) route = '/ground-court-info';
          if (state.step == 5) route = '/amenities';
          if (state.step == 6) route = '/slot-config';
          if (state.step == 7) route = '/pricing-setup';
          if (state.step == 8) route = '/kyc-documentation';
          if (state.step == 9) route = '/photos-media';
          if (state.step == 10) route = '/review-submit';
          clearAndGo(route);
        } else if (state is AuthDocumentsRequired) {
          clearAndGo('/upload-documents');
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
              const CircularProgressIndicator(
                color: AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
