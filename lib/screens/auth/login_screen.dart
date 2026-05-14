import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/core/text_theme.dart';
import 'package:toastification/toastification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  String? phoneError;

  bool _validateFields() {
    setState(() {
      phoneError = null;
    });

    final phone = phoneController.text.trim();
    bool isValid = true;

    if (phone.isEmpty) {
      setState(() => phoneError = "Phone number is required");
      isValid = false;
    } else if (phone.length != 10) {
      setState(() => phoneError = "Enter a valid 10-digit number");
      isValid = false;
    }

    return isValid;
  }

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
            title: const Text("Success"),
            description: const Text("Login Successful!"),
            autoCloseDuration: const Duration(seconds: 4),
          );
        }

        if (state is AuthOtpRequired) {
          Navigator.pushNamed(
            context,
            '/otp',
            arguments: state.phone,
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
            backgroundColor: const Color(0xffECECEC),
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
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.green.shade700,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.stadium_outlined,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        const AppSizedBox(height: 30),

                        /// Title
                        const AppText(
                          text: "Owner Portal",
                          size: 26,
                          weight: FontWeight.w700,
                          textStyle: AppTextTheme.black17,
                        ),

                        const AppSizedBox(height: 6),

                        const AppText(
                          text: "Manage your turfs and bookings",
                          size: 14,
                          color: Colors.grey,
                        ),

                        const AppSizedBox(height: 30),

                        /// Login Card
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppText(
                                text: "Phone Number",
                                size: 12,
                                weight: FontWeight.w600,
                                color: Colors.black54,
                              ),

                              const AppSizedBox(height: 8),

                              TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  counterText: "",
                                  hintText: "Enter 10 digit number",
                                  hintStyle: const TextStyle(color: Colors.black38),
                                  errorText: phoneError,
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    child: Text(
                                      "+91",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                              ),

                              const AppSizedBox(height: 30),

                              AppButton(
                                title: "Send OTP",
                                isLoading: isLoading,
                                onTap: () {
                                  if (_validateFields()) {
                                    final phone = "+91${phoneController.text.trim()}";
                                    context.read<AuthCubit>().signInWithPhone(phone);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        const AppSizedBox(height: 40),

                        const AppText(
                          text: "By continuing, you agree to our Terms of Service",
                          size: 12,
                          color: Colors.grey,
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
