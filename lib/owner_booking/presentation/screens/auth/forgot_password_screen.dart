import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/core/text_theme.dart';
import 'package:toastification/toastification.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  String? emailError;

  bool _validateFields() {
    setState(() {
      emailError = null;
    });

    final email = emailController.text.trim();
    bool isValid = true;

    if (email.isEmpty) {
      setState(() => emailError = "Email address is required");
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => emailError = "Please enter a valid email address");
      isValid = false;
    }

    return isValid;
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => ModalRoute.of(context)?.isCurrent == true,
      listener: (context, state) {
        if (state is AuthPasswordResetSent) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flatColored,
            title: const Text("Reset Link Sent"),
            description: const Text("Check your email inbox to reset your password."),
            autoCloseDuration: const Duration(seconds: 5),
          );
          Navigator.pop(context); // Go back to login screen
        }

        if (state is AuthError) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flatColored,
            title: const Text("Error"),
            description: Text(state.message),
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Scaffold(
            backgroundColor: AppColors.bgLight,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryLight),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        /// Logo/Image placeholder
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryDarkGreen,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.lock_reset,
                              size: 60,
                              color: AppColors.white,
                            ),
                          ),
                        ),

                        const AppSizedBox(height: 30),

                        /// Title
                        const AppText(
                          text: "Reset Password",
                          size: 26,
                          weight: FontWeight.w700,
                          textStyle: AppTextTheme.black17,
                        ),

                        const AppSizedBox(height: 6),

                        const AppText(
                          text: "Enter your registered email to receive a recovery link",
                          size: 14,
                          color: AppColors.textSecondaryLight,
                          align: TextAlign.center,
                        ),

                        const AppSizedBox(height: 24),

                        /// Form Card
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 10,
                                color: AppColors.black.withValues(alpha: 0.05),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppText(
                                text: "Email Address",
                                size: 12,
                                weight: FontWeight.w600,
                                color: AppColors.textSecondaryLight,
                              ),

                              const AppSizedBox(height: 6),

                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: AppColors.textPrimaryLight),
                                decoration: InputDecoration(
                                  hintText: "e.g. rajesh@example.com",
                                  hintStyle: const TextStyle(color: Colors.black38),
                                  errorText: emailError,
                                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondaryLight),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.borderLight),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.borderLight),
                                  ),
                                ),
                              ),

                              const AppSizedBox(height: 24),

                              AppButton(
                                title: "Send Link",
                                isLoading: isLoading,
                                onTap: () {
                                  if (_validateFields()) {
                                    context.read<AuthCubit>().sendPasswordResetEmail(
                                          emailController.text.trim(),
                                        );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        const AppSizedBox(height: 40),
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
