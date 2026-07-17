import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/location/location_cubit.dart';

/// Per-location property/ownership documents — separate from the owner-level
/// KYC documents collected once during onboarding, since each venue address
/// may need its own ownership/lease/NOC proof.
class LocationDocumentsScreen extends StatefulWidget {
  final String locationId;
  final Map<String, dynamic>? locationData;

  const LocationDocumentsScreen({
    super.key,
    required this.locationId,
    this.locationData,
  });

  @override
  State<LocationDocumentsScreen> createState() => _LocationDocumentsScreenState();
}

class _LocationDocumentsScreenState extends State<LocationDocumentsScreen> {
  String _propertyStatus = 'Owned Property';
  File? _propertyFile;
  File? _nocFile;
  String? _propertyUrl;
  String? _nocUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.locationData;
    _propertyStatus = data?['property_status'] as String? ?? _propertyStatus;
    _propertyUrl = data?['property_document_url'] as String?;
    _nocUrl = data?['noc_url'] as String?;
  }

  Future<void> _pickFile(bool isNoc) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );
    if (result == null) return;
    setState(() {
      if (isNoc) {
        _nocFile = File(result.files.single.path!);
      } else {
        _propertyFile = File(result.files.single.path!);
      }
    });
  }

  Future<String?> _uploadFile(File file) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;
    final fileName =
        '$userId/locations/${widget.locationId}/${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
    try {
      await Supabase.instance.client.storage.from('venue_media').upload(fileName, file);
      return Supabase.instance.client.storage.from('venue_media').getPublicUrl(fileName);
    } catch (e) {
      return null;
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      String? propertyUrl = _propertyUrl;
      if (_propertyFile != null) propertyUrl = await _uploadFile(_propertyFile!);
      String? nocUrl = _nocUrl;
      if (_nocFile != null) nocUrl = await _uploadFile(_nocFile!);

      await context.read<LocationCubit>().updateLocation(
            locationId: widget.locationId,
            data: {
              'property_status': _propertyStatus,
              'property_document_url': propertyUrl,
              'noc_url': nocUrl,
            },
          );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('Could not save documents'),
          description: Text(e.toString()),
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _skip() => Navigator.pop(context);

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
                  onTap: _skip,
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
                    text: 'Venue Documents',
                    size: 20,
                    weight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                GestureDetector(
                  onTap: _isSaving ? null : _skip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.lg,
                      vertical: AppSizes.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const AppText(
                      text: 'Skip',
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.white,
                    ),
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
            // Info banner
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF0F7FF),
                    const Color(0xFFF0F7FF).withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(Icons.lock_outline, size: 18, color: Colors.blue),
                  ),
                  const AppSizedBox(width: AppSizes.md),
                  Expanded(
                    child: AppText(
                      text:
                          "Property documents for this venue help us verify it faster. You can add these later if you don't have them now.",
                      size: 13,
                      color: Colors.blue.shade800,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const AppSizedBox(height: AppSizes.xxl + 4),
            // Property status
            _label('PROPERTY STATUS'),
            _chips(
              options: const ['Owned Property', 'Lease / Rent Agreement', 'Society Permission'],
              selected: _propertyStatus,
              onSelected: (v) => setState(() => _propertyStatus = v),
            ),
            const AppSizedBox(height: AppSizes.xxl),
            // Upload fields
            _uploadField(
              label: 'PROPERTY DOCUMENT',
              hint: 'Ownership deed / Lease agreement • PDF, JPG or PNG',
              file: _propertyFile,
              existingUrl: _propertyUrl,
              onTap: () => _pickFile(false),
            ),
            const AppSizedBox(height: AppSizes.lg),
            _uploadField(
              label: 'LOCAL BODY / MUNICIPAL NOC (OPTIONAL)',
              hint: 'NOC from municipal corporation or panchayat',
              file: _nocFile,
              existingUrl: _nocUrl,
              onTap: () => _pickFile(true),
            ),
            const AppSizedBox(height: AppSizes.xxxxl),
            AppButton(
              title: 'Save Documents',
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
        padding: const EdgeInsets.only(bottom: AppSizes.md),
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

  Widget _chips({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: AppSizes.sm + 2,
      runSpacing: AppSizes.sm + 2,
      children: options.map((option) {
        final isSelected = selected == option;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg, vertical: AppSizes.md),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.inputFillLight : AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusRound),
              border: Border.all(
                color: isSelected ? AppColors.primaryDarkGreen : AppColors.borderLight,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDarkGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                ],
                AppText(
                  text: option,
                  size: 13,
                  weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryDarkGreen : AppColors.textSecondaryLight,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _uploadField({
    required String label,
    required String hint,
    required File? file,
    required String? existingUrl,
    required VoidCallback onTap,
  }) {
    final isUploaded = file != null || existingUrl != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                vertical: AppSizes.xxl, horizontal: AppSizes.lg),
            decoration: BoxDecoration(
              gradient: isUploaded
                  ? LinearGradient(
                      colors: [
                        AppColors.inputFillLight,
                        AppColors.inputFillLight.withValues(alpha: 0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isUploaded ? null : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(
                color: isUploaded
                    ? AppColors.primaryDarkGreen.withValues(alpha: 0.3)
                    : AppColors.primaryDarkGreen.withValues(alpha: 0.15),
                width: isUploaded ? 1.5 : 1,
              ),
            ),
            child: isUploaded
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSizes.sm),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryDarkGreen, Color(0xFF065B3C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: const Icon(Icons.description, color: AppColors.white, size: 22),
                      ),
                      const AppSizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              text: file != null ? path.basename(file.path) : 'Document uploaded',
                              size: 14,
                              weight: FontWeight.w600,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            AppText(
                              text: 'Ready to upload',
                              size: 11,
                              color: AppColors.textSecondaryLight,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(AppSizes.xs),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: AppColors.primaryDarkGreen,
                          size: 18,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarkGreen.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.upload_file_outlined,
                          size: 28,
                          color: AppColors.primaryDarkGreen,
                        ),
                      ),
                      const AppSizedBox(height: AppSizes.md),
                      const AppText(
                        text: 'Upload document',
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.primaryDarkGreen,
                      ),
                      const AppSizedBox(height: AppSizes.xs),
                      AppText(text: hint, size: 12, color: AppColors.textSecondaryLight),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
