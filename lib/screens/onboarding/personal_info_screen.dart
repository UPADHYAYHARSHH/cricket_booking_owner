import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:turfpro_owner/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/common/widgets/onboarding_layout.dart';
import 'package:toastification/toastification.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  
  late String _phone;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _phone = user?.phone ?? "";
    _fetchExistingDetails();
  }

  Future<void> _fetchExistingDetails() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('owner_details')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      if (data != null) {
        setState(() {
          _nameController.text = data['owner_name'] ?? '';
          _emailController.text = data['business_email'] ?? '';
          _cityController.text = data['city'] ?? '';
          _stateController.text = data['state'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().savePersonalInfo(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: Text(state.message),
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return OnboardingLayout(
            currentStep: 1,
            title: "Personal Information",
            subtitle: "Tell us about yourself — the account owner",
            isLoading: state is AuthLoading,
            showBackButton: false,
            onNext: _onSave,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("FULL NAME *"),
                  _buildTextField(_nameController, "e.g. Rajesh Patel"),
                  const AppSizedBox(height: 20),
                  
                  _buildLabel("MOBILE NUMBER *"),
                  _buildPhoneField(),
                  const AppSizedBox(height: 4),
                  const AppText(
                    text: "Verified ✓ — linked to your account",
                    size: 12,
                    color: AppColors.primaryDarkGreen,
                    weight: FontWeight.w500,
                  ),
                  const AppSizedBox(height: 20),
                  
                  _buildLabel("EMAIL ADDRESS"),
                  _buildTextField(_emailController, "rajesh@example.com", keyboardType: TextInputType.emailAddress),
                  const AppSizedBox(height: 4),
                  const AppText(
                    text: "For booking confirmations & reports",
                    size: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                  const AppSizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("CITY *"),
                            _buildTextField(_cityController, "Ahmedabad"),
                          ],
                        ),
                      ),
                      const AppSizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("STATE *"),
                            _buildTextField(_stateController, "Gujarat"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppText(
        text: label,
        size: 12,
        weight: FontWeight.w700,
        color: AppColors.textSecondaryLight,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          if (hint.contains("Rajesh") || hint.contains("Ahmedabad") || hint.contains("Gujarat")) {
             return "Required field";
          }
        }
        return null;
      },
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondaryLight.withOpacity(0.4)),
        filled: true,
        fillColor: const Color(0xFFF0F9F4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryDarkGreen, width: 2),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.1)),
      ),
      child: AppText(
        text: _phone,
        size: 16,
        weight: FontWeight.w600,
        color: AppColors.textPrimaryLight.withOpacity(0.6),
      ),
    );
  }
}
