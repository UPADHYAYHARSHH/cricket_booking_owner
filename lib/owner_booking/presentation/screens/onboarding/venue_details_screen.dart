import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:turfpro_owner/utils/auth_helper.dart';
import 'package:turfpro_owner/utils/form_util.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/common/widgets/onboarding_layout.dart';
import 'package:toastification/toastification.dart';

class VenueDetailsScreen extends StatefulWidget {
  const VenueDetailsScreen({super.key});

  @override
  State<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends State<VenueDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _mapsLinkController = TextEditingController();
  final _contactController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchExistingDetails();
  }

  Future<void> _fetchExistingDetails() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final data = await Supabase.instance.client
          .from('owner_details')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _nameController.text = data['venue_name'] ?? '';
          _taglineController.text = data['venue_tagline'] ?? '';
          _addressController.text = data['address'] ?? '';
          _cityController.text = data['city'] ?? '';
          _pincodeController.text = data['pincode'] ?? '';
          _mapsLinkController.text = data['google_maps_link'] ?? '';
          _contactController.text = data['venue_contact'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _mapsLinkController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().saveVenueDetails(
        venueName: _nameController.text.trim(),
        tagline: _taglineController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        pincode: _pincodeController.text.trim(),
        mapsLink: _mapsLinkController.text.trim(),
        contact: _contactController.text.trim(),
      );
    } else {
      FormUtil.scrollToError(context);
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
            currentStep: 3,
            title: "Venue Details",
            subtitle: "Your venue's identity & location",
            isLoading: state is AuthLoading,
            onNext: _onSave,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("VENUE / GROUND NAME *"),
                  _buildTextField(_nameController, "Champions Box Cricket Arena"),
                  const AppSizedBox(height: 4),
                  const AppText(text: "This will be shown to players on the app", size: 11, color: AppColors.textSecondaryLight),
                  const AppSizedBox(height: 20),

                  _buildLabel("VENUE TAGLINE"),
                  _buildTextField(_taglineController, "e.g. Ahmedabad's Premier Box Cricket Hub"),
                  const AppSizedBox(height: 20),

                  _buildLabel("FULL ADDRESS *"),
                  _buildTextField(_addressController, "Plot 42, Prahlad Nagar, Near ISCON Cross Roads", maxLines: 2),
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
                            _buildLabel("PINCODE *"),
                            _buildTextField(_pincodeController, "380015", keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const AppSizedBox(height: 20),

                  _buildLabel("GOOGLE MAPS LINK / COORDINATES"),
                  _buildTextField(_mapsLinkController, "Paste Google Maps URL or lat,long"),
                  const AppSizedBox(height: 20),

                  _buildLabel("VENUE CONTACT NUMBER *"),
                  _buildTextField(_contactController, "+91 98765 43210", keyboardType: TextInputType.phone),
                  const AppSizedBox(height: 4),
                  const AppText(text: "Displayed to players for ground-level queries", size: 11, color: AppColors.textSecondaryLight),
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

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (value) {
        if (hint.contains("*") || hint.contains("Arena") || hint.contains("Cross") || hint.contains("Ahmedabad") || hint.contains("380015") || hint.contains("+91")) {
           if (value == null || value.isEmpty) return "Required field";
        }
        return null;
      },
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondaryLight.withValues(alpha: 0.4)),
        filled: true,
        fillColor: AppColors.slotAvailableBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDarkGreen.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDarkGreen.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryDarkGreen, width: 2),
        ),
      ),
    );
  }
}
