import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pinput/pinput.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:toastification/toastification.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final TextEditingController pinController;
  late final FocusNode focusNode;
  int _secondsRemaining = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    pinController = TextEditingController();
    focusNode = FocusNode();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phone = ModalRoute.of(context)?.settings.arguments as String? ?? "";

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.primaryDarkGreen, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.primaryDarkGreen.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.primaryDarkGreen),
      ),
    );

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => ModalRoute.of(context)?.isCurrent == true,
      listener: (context, state) {
        debugPrint("DEBUG: OtpScreen received state: $state");
        if (state is AuthLocationRequired || state is AuthPendingApproval) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/splash',
            (route) => false,
          );
        }

        if (state is AuthSuccess) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          );
        }


        if (state is AuthError) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flatColored,
            title: const Text("Verification Error"),
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
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const AppSizedBox(height: 20),
                      const AppText(
                        text: "Verify OTP",
                        size: 26,
                        weight: FontWeight.w700,
                      ),
                      const AppSizedBox(height: 6),
                      AppText(
                        text: "Enter the code sent to $phone",
                        size: 14,
                        color: AppColors.textSecondaryLight,
                      ),
                      const AppSizedBox(height: 40),
                      Center(
                        child: Pinput(
                          length: 6,
                          controller: pinController,
                          focusNode: focusNode,
                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: focusedPinTheme,
                          submittedPinTheme: submittedPinTheme,
                          onCompleted: (pin) {
                            if (state is! AuthLoading) {
                              context.read<AuthCubit>().checkEmailVerification();
                            }
                          },
                        ),
                      ),
                      const AppSizedBox(height: 40),
                      AppButton(
                        title: "Verify & Continue",
                        isLoading: isLoading,
                        onTap: () {
                          final otpCode = pinController.text;
                          if (otpCode.length < 6) {
                            toastification.show(
                              context: context,
                              type: ToastificationType.warning,
                              style: ToastificationStyle.flatColored,
                              title: const Text("Invalid OTP"),
                              description: const Text("Please enter the 6-digit code"),
                              autoCloseDuration: const Duration(seconds: 4),
                            );
                            return;
                          }
                          if (state is! AuthLoading) {
                            context.read<AuthCubit>().checkEmailVerification();
                          }
                        },
                      ),
                      const AppSizedBox(height: 30),
                      Center(
                        child: Column(
                          children: [
                            const AppText(
                              text: "Didn't receive the code?",
                              size: 13,
                              color: AppColors.textSecondaryLight,
                            ),
                            const AppSizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                if (!isLoading && _secondsRemaining == 0) {
                                  context.read<AuthCubit>().resendVerificationEmail();
                                  _startTimer();
                                }
                              },
                              child: AppText(
                                text: "Resend OTP",
                                size: 14,
                                weight: FontWeight.w600,
                                color: (isLoading || _secondsRemaining > 0)
                                    ? AppColors.textSecondaryLight
                                    : AppColors.primaryDarkGreen,
                              ),
                            ),
                            if (_secondsRemaining > 0) ...[
                              const AppSizedBox(height: 6),
                              AppText(
                                text: "(00:${_secondsRemaining.toString().padLeft(2, '0')})",
                                size: 12,
                                color: AppColors.textSecondaryLight,
                              ),
                            ]
                          ],
                        ),
                      )
                    ],
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
