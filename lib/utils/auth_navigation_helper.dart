import 'package:flutter/material.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_flow.dart';

class AuthNavigationHelper {
  /// Navigates cleanly to the appropriate screen based on the current [AuthState]
  /// without bouncing through the splash screen.
  static void navigateForAuthState(BuildContext context, AuthState state) {
    void clearAndGo(String route) {
      Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
    }

    if (state is AuthInitial || state is AuthUnauthenticated) {
      clearAndGo('/');
    } else if (state is AuthSuccess) {
      clearAndGo('/dashboard');
    } else if (state is AuthEmailUnverified) {
      clearAndGo('/email-verification');
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
    }
  }
}
