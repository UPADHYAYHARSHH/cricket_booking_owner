import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';

class EditOwnerProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? ownerDetails;

  const EditOwnerProfileScreen({super.key, this.ownerDetails});

  @override
  State<EditOwnerProfileScreen> createState() => _EditOwnerProfileScreenState();
}

class _EditOwnerProfileScreenState extends State<EditOwnerProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _venueNameController;
  late TextEditingController _cityController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.ownerDetails;
    _nameController = TextEditingController(text: data?['owner_name'] as String? ?? '');
    _phoneController = TextEditingController(text: data?['phone'] as String? ?? '');
    _venueNameController = TextEditingController(text: data?['venue_name'] as String? ?? '');
    _cityController = TextEditingController(text: data?['city'] as String? ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _venueNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text('Name is required'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await Supabase.instance.client.from('owner_details').update({
        'owner_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'venue_name': _venueNameController.text.trim(),
        'city': _cityController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      if (!mounted) return;

      toastification.show(
        context: context,
        type: ToastificationType.success,
        title: const Text('Profile updated successfully'),
        autoCloseDuration: const Duration(seconds: 3),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('Failed to update profile'),
          description: Text(e.toString()),
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: AppSizes.lg,
            right: AppSizes.lg,
            bottom: AppSizes.lg,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B8457), Color(0xFF065B3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                const Expanded(
                  child: AppText(
                    text: 'Edit Profile',
                    size: 20,
                    weight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            _label('OWNER NAME *'),
            _field(
              _nameController,
              hint: 'Enter your full name',
              icon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: AppSizes.xxl),

            // Phone field
            _label('PHONE NUMBER'),
            _field(
              _phoneController,
              hint: 'Enter your phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSizes.xxl),

            // Venue Name field
            _label('VENUE NAME'),
            _field(
              _venueNameController,
              hint: 'Enter your venue name',
              icon: Icons.store_outlined,
            ),
            const SizedBox(height: AppSizes.xxl),

            // City field
            _label('CITY'),
            _field(
              _cityController,
              hint: 'Enter your city',
              icon: Icons.location_city_outlined,
            ),
            const SizedBox(height: AppSizes.xxxxl),

            // Save button
            AppButton(
              title: 'Save Changes',
              isLoading: _isSaving,
              onTap: _save,
              backgroundColor: AppColors.primaryDarkGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.sm),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primaryDarkGreen,
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        AppText(
          text: text,
          size: 12,
          weight: FontWeight.w700,
          color: AppColors.textSecondaryLight,
          letterSpacing: 0.4,
        ),
      ],
    ),
  );

  Widget _field(
    TextEditingController ctrl, {
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondaryLight.withValues(alpha: 0.4),
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppColors.inputFillLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        prefixIcon: icon != null
            ? Icon(
                icon,
                size: 20,
                color: AppColors.primaryDarkGreen.withValues(alpha: 0.6),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.primaryDarkGreen,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}
