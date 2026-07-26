import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:toastification/toastification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? emailError;
  String? passwordError;
  bool _obscurePassword = true;

  bool _validateFields() {
    setState(() {
      emailError = null;
      passwordError = null;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    bool isValid = true;

    if (email.isEmpty) {
      setState(() => emailError = "Email address is required");
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => emailError = "Please enter a valid email address");
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() => passwordError = "Password is required");
      isValid = false;
    } else if (password.length < 6) {
      setState(() => passwordError = "Password must be at least 6 characters");
      isValid = false;
    }

    return isValid;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          ModalRoute.of(context)?.isCurrent == true,
      listener: (context, state) {
        if (state is AuthSuccess) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flatColored,
            title: const Text("Success"),
            description: const Text("Login Successful!"),
            autoCloseDuration: const Duration(seconds: 4),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          );
        }

        if (state is AuthEmailUnverified) {
          Navigator.pushNamed(context, '/email-verification');
        }

        if (state is AuthLocationRequired || state is AuthGroundRequired ||
            state is AuthPendingApproval ||
            state is AuthStep1Required ||
            state is AuthStep2Required ||
            state is AuthStep3Required) {
          // Let splash route to the correct step
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/splash',
            (route) => false,
          );
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
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        /// Logo/Image placeholder
                        Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusLg,
                            ),
                            color: AppColors.primaryDarkGreen,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.stadium_outlined,
                              size: 80,
                              color: AppColors.white,
                            ),
                          ),
                        ),

                        const AppSizedBox(height: 30),

                        /// Title
                        const AppText(
                          text: "Owner Portal",
                          size: 26,
                          weight: FontWeight.w700,
                        ),

                        const AppSizedBox(height: 6),

                        AppText(
                          text: "Manage your turfs and bookings",
                          size: 14,
                          color: AppColors.textSecondaryLight,
                        ),

                        const AppSizedBox(height: 24),

                        /// Login Card
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusXl,
                            ),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 10,
                                color: AppColors.black.withValues(alpha: 0.05),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                text: "Email Address",
                                size: 12,
                                weight: FontWeight.w600,
                                color: AppColors.textSecondaryLight,
                              ),

                              const AppSizedBox(height: 6),

                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: "e.g. rajesh@example.com",
                                  errorText: emailError,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                              ),

                              const AppSizedBox(height: 20),

                              AppText(
                                text: "Password",
                                size: 12,
                                weight: FontWeight.w600,
                                color: AppColors.textSecondaryLight,
                              ),

                              const AppSizedBox(height: 6),

                              TextField(
                                controller: passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: "Enter password",
                                  errorText: passwordError,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),

                              const AppSizedBox(height: 10),

                              Align(
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/forgot-password',
                                    );
                                  },
                                  child: AppText(
                                    text: "Forgot Password?",
                                    size: 13,
                                    weight: FontWeight.w600,
                                    color: AppColors.primaryDarkGreen,
                                  ),
                                ),
                              ),

                              const AppSizedBox(height: 24),

                              AppButton(
                                title: "Login",
                                isLoading: isLoading,
                                onTap: () {
                                  if (_validateFields()) {
                                    context
                                        .read<AuthCubit>()
                                        .signInWithEmailAndPassword(
                                          emailController.text.trim(),
                                          passwordController.text.trim(),
                                        );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        const AppSizedBox(height: 30),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppText(
                              text: "Don't have an account? ",
                              size: 14,
                              color: AppColors.textSecondaryLight,
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              child: AppText(
                                text: "Sign Up",
                                size: 14,
                                weight: FontWeight.bold,
                                color: AppColors.primaryDarkGreen,
                              ),
                            ),
                          ],
                        ),

                        const AppSizedBox(height: 24),

                        AppText(
                          text:
                              "By continuing, you agree to our Terms of Service",
                          size: 12,
                          color: AppColors.textSecondaryLight,
                          align: TextAlign.center,
                        ),
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
