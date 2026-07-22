import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/common/widgets/app_text_field.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/city_search_field.dart';
import 'package:turfpro_owner/utils/auth_helper.dart';
import 'onboarding_step_indicator.dart';

class Step1PersonalInfoScreen extends StatefulWidget {
  const Step1PersonalInfoScreen({super.key});

  @override
  State<Step1PersonalInfoScreen> createState() =>
      _Step1PersonalInfoScreenState();
}

class _Step1PersonalInfoScreenState extends State<Step1PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cityFieldKey = GlobalKey<CitySearchFieldState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _initialCity;
  String _selectedCity = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _prefillExistingData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefillExistingData() async {
    final userId = currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('owner_details')
          .select('owner_name, phone, city')
          .eq('id', userId)
          .maybeSingle();
      if (mounted && data != null) {
        _nameCtrl.text = data['owner_name'] ?? '';
        _phoneCtrl.text = data['phone'] ?? '';
        final city = (data['city'] as String? ?? '').trim();
        _initialCity = city.isEmpty ? null : city;
        _selectedCity = city;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final city = _cityFieldKey.currentState?.selectedCity ?? _selectedCity;
    if (city.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text('Please search and select a city'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }
    context.read<AuthCubit>().saveStep1(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      city: city,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthStep2Required) {
          Navigator.pushReplacementNamed(context, '/onboarding/step2');
        } else if (state is AuthStep3Required) {
          Navigator.pushReplacementNamed(context, '/onboarding/step3');
        } else if (state is AuthPendingApproval) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/pending-approval',
            (r) => false,
          );
        } else if (state is AuthSuccess) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (r) => false,
          );
        } else if (state is AuthError) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: const Text('Error'),
            description: Text(state.message),
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryDarkGreen,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSizes.lg),
                        buildOnboardingHeader(
                          currentStep: 1,
                          onBack: () async {
                            await context.read<AuthCubit>().logout();
                            if (!context.mounted) return;
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/',
                              (route) => false,
                            );
                          },
                        ),
                        const SizedBox(height: AppSizes.xl),
                        const AppText(
                          text: 'Personal Details',
                          size: 24,
                          weight: FontWeight.w700,
                        ),
                        const SizedBox(height: AppSizes.xs),
                        const AppText(
                          text:
                              'Tell us about yourself so we can get you started.',
                          size: 14,
                          color: AppColors.textSecondaryLight,
                        ),
                        const SizedBox(height: AppSizes.xxl),
                        AppTextField(
                          label: 'Full Name',
                          controller: _nameCtrl,
                          prefixIcon: Icons.person_outline,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Full name is required'
                              : null,
                        ),
                        const SizedBox(height: AppSizes.md),
                        AppTextField(
                          label: 'Phone Number',
                          controller: _phoneCtrl,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Phone is required';
                            }
                            final digits = v.trim().replaceAll(
                              RegExp(r'\D'),
                              '',
                            );
                            if (digits.length < 10) {
                              return 'Enter a valid phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.md),
                        CitySearchField(
                          key: _cityFieldKey,
                          label: 'City',
                          initialCity: _initialCity,
                          onCityChanged: (city) {
                            _selectedCity = city ?? '';
                          },
                        ),
                        const SizedBox(height: AppSizes.xxl),
                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) => AppButton(
                            title: 'Continue',
                            isLoading: state is AuthLoading,
                            onTap: _submit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
