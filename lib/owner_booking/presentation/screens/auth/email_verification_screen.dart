import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/core/text_theme.dart';
import 'package:toastification/toastification.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => ModalRoute.of(context)?.isCurrent == true,
      listener: (context, state) {
        if (state is AuthSuccess) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flatColored,
            title: const Text("Verified Successfully"),
            description: const Text("Welcome! Let's get your turf set up."),
            autoCloseDuration: const Duration(seconds: 4),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          );
        }

        if (state is AuthProfileIncomplete) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flatColored,
            title: const Text("Verified Successfully"),
            description: const Text("Let's complete your onboarding profile."),
            autoCloseDuration: const Duration(seconds: 4),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/splash',
            (route) => false,
          );
        }

        if (state is AuthUnauthenticated) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          );
        }

        if (state is AuthError && !state.message.contains("not verified yet")) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flatColored,
            title: const Text("Verification Check Failed"),
            description: Text(state.message),
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          
          String userEmail = "";
          if (state is AuthEmailUnverified) {
            userEmail = state.email;
          }

          return Scaffold(
            backgroundColor: const Color(0xffECECEC),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        /// Verification Pending Icon
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.shade700,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.mark_email_unread_outlined,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const AppSizedBox(height: 30),

                        /// Title
                        const AppText(
                          text: "Verify Your Email",
                          size: 26,
                          weight: FontWeight.w700,
                          textStyle: AppTextTheme.black17,
                        ),

                        const AppSizedBox(height: 12),

                        const AppText(
                          text: "A verification link has been sent to your email address:",
                          size: 14,
                          color: Colors.grey,
                          align: TextAlign.center,
                        ),

                        if (userEmail.isNotEmpty) ...[
                          const AppSizedBox(height: 8),
                          AppText(
                            text: userEmail,
                            size: 16,
                            weight: FontWeight.bold,
                            color: Colors.black87,
                            align: TextAlign.center,
                          ),
                        ],

                        const AppSizedBox(height: 16),

                        const AppText(
                          text: "Please click on the link in your email to complete registration.",
                          size: 13,
                          color: Colors.grey,
                          align: TextAlign.center,
                        ),

                        const AppSizedBox(height: 30),

                        /// Form Card
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 10,
                                color: Colors.black.withOpacity(.05),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              AppButton(
                                title: "I've Verified My Email",
                                isLoading: isLoading,
                                onTap: () {
                                  context.read<AuthCubit>().checkEmailVerification();
                                },
                              ),

                              const AppSizedBox(height: 16),

                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  side: BorderSide(color: Colors.green.shade700, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        await context.read<AuthCubit>().resendVerificationEmail();
                                        toastification.show(
                                          context: context,
                                          type: ToastificationType.success,
                                          style: ToastificationStyle.flatColored,
                                          title: const Text("Resent Verification Email"),
                                          description: const Text("A new link has been sent."),
                                          autoCloseDuration: const Duration(seconds: 4),
                                        );
                                      },
                                child: AppText(
                                  text: "Resend Verification Email",
                                  size: 14,
                                  weight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const AppSizedBox(height: 30),

                        InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text("Log Out"),
                                content: const Text("Are you sure you want to log out?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      context.read<AuthCubit>().logout();
                                    },
                                    child: const Text(
                                      "Log Out",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: AppText(
                            text: "Use a different email / Log Out",
                            size: 14,
                            weight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),

                        const AppSizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
