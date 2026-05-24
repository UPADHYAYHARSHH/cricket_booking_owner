import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/core/text_theme.dart';
import 'package:toastification/toastification.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String? nameError;
  String? emailError;
  String? phoneError;
  String? passwordError;
  String? confirmPasswordError;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _validateFields() {
    setState(() {
      nameError = null;
      emailError = null;
      phoneError = null;
      passwordError = null;
      confirmPasswordError = null;
    });

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    bool isValid = true;

    if (name.isEmpty) {
      setState(() => nameError = "Full name is required");
      isValid = false;
    }

    if (email.isEmpty) {
      setState(() => emailError = "Email address is required");
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => emailError = "Please enter a valid email address");
      isValid = false;
    }

    if (phone.isEmpty) {
      setState(() => phoneError = "Phone number is required");
      isValid = false;
    } else if (phone.length != 10 || int.tryParse(phone) == null) {
      setState(() => phoneError = "Enter a valid 10-digit number");
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() => passwordError = "Password is required");
      isValid = false;
    } else if (password.length < 6) {
      setState(() => passwordError = "Password must be at least 6 characters");
      isValid = false;
    }

    if (confirmPassword.isEmpty) {
      setState(() => confirmPasswordError = "Please confirm your password");
      isValid = false;
    } else if (password != confirmPassword) {
      setState(() => confirmPasswordError = "Passwords do not match");
      isValid = false;
    }

    return isValid;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => ModalRoute.of(context)?.isCurrent == true,
      listener: (context, state) {
        if (state is AuthEmailUnverified) {
          toastification.show(
            context: context,
            type: ToastificationType.info,
            style: ToastificationStyle.flatColored,
            title: const Text("Verification Link Sent"),
            description: const Text("Please check your email to verify your account."),
            autoCloseDuration: const Duration(seconds: 5),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/email-verification',
            (route) => false,
          );
        }

        if (state is AuthError) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flatColored,
            title: const Text("Signup Failed"),
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
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
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
                        /// Title
                        const AppText(
                          text: "Register Owner",
                          size: 26,
                          weight: FontWeight.w700,
                          textStyle: AppTextTheme.black17,
                        ),

                        const AppSizedBox(height: 6),

                        const AppText(
                          text: "Create an account to register your turf",
                          size: 14,
                          color: Colors.grey,
                        ),

                        const AppSizedBox(height: 24),

                        /// Register Card
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
                                text: "Full Name",
                                size: 12,
                                weight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              const AppSizedBox(height: 6),
                              TextField(
                                controller: nameController,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: "e.g. Rajesh Patel",
                                  hintStyle: const TextStyle(color: Colors.black38),
                                  errorText: nameError,
                                  prefixIcon: const Icon(Icons.person_outline, color: Colors.black45),
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

                              const AppSizedBox(height: 16),

                              const AppText(
                                text: "Email Address",
                                size: 12,
                                weight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              const AppSizedBox(height: 6),
                              TextField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: "e.g. rajesh@example.com",
                                  hintStyle: const TextStyle(color: Colors.black38),
                                  errorText: emailError,
                                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.black45),
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

                              const AppSizedBox(height: 16),

                              const AppText(
                                text: "Mobile Number",
                                size: 12,
                                weight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              const AppSizedBox(height: 6),
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
                                        color: Colors.black45,
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

                              const AppSizedBox(height: 16),

                              const AppText(
                                text: "Password",
                                size: 12,
                                weight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              const AppSizedBox(height: 6),
                              TextField(
                                controller: passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: "Min 6 characters",
                                  hintStyle: const TextStyle(color: Colors.black38),
                                  errorText: passwordError,
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.black45),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.black45,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
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

                              const AppSizedBox(height: 16),

                              const AppText(
                                text: "Confirm Password",
                                size: 12,
                                weight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                              const AppSizedBox(height: 6),
                              TextField(
                                controller: confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: "Re-enter password",
                                  hintStyle: const TextStyle(color: Colors.black38),
                                  errorText: confirmPasswordError,
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.black45),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.black45,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
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

                              const AppSizedBox(height: 26),

                              AppButton(
                                title: "Sign Up",
                                isLoading: isLoading,
                                onTap: () {
                                  if (_validateFields()) {
                                    context.read<AuthCubit>().signUpWithEmailAndPassword(
                                          emailController.text.trim(),
                                          passwordController.text.trim(),
                                          nameController.text.trim(),
                                          "+91${phoneController.text.trim()}",
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
                            const AppText(
                              text: "Already have an account? ",
                              size: 14,
                              color: Colors.black54,
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: AppText(
                                text: "Login",
                                size: 14,
                                weight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
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
