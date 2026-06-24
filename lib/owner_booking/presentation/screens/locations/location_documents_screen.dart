import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDarkGreen),
          onPressed: _skip,
        ),
        title: const AppText(text: 'Venue Documents', size: 18, weight: FontWeight.w700),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _skip,
            child: const AppText(text: 'Skip', size: 14, weight: FontWeight.w600, color: Colors.grey),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline, size: 20, color: Colors.blue),
                  const AppSizedBox(width: 12),
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
            const AppSizedBox(height: 28),
            _label('PROPERTY STATUS'),
            _chips(
              options: const ['Owned Property', 'Lease / Rent Agreement', 'Society Permission'],
              selected: _propertyStatus,
              onSelected: (v) => setState(() => _propertyStatus = v),
            ),
            const AppSizedBox(height: 24),
            _uploadField(
              label: 'PROPERTY DOCUMENT',
              hint: 'Ownership deed / Lease agreement • PDF, JPG or PNG',
              file: _propertyFile,
              existingUrl: _propertyUrl,
              onTap: () => _pickFile(false),
            ),
            const AppSizedBox(height: 16),
            _uploadField(
              label: 'LOCAL BODY / MUNICIPAL NOC (OPTIONAL)',
              hint: 'NOC from municipal corporation or panchayat',
              file: _nocFile,
              existingUrl: _nocUrl,
              onTap: () => _pickFile(true),
            ),
            const AppSizedBox(height: 40),
            AppButton(title: 'Save Documents', isLoading: _isSaving, onTap: _save),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppText(
          text: text,
          size: 12,
          weight: FontWeight.w700,
          color: AppColors.textSecondaryLight,
          letterSpacing: 0.4,
        ),
      );

  Widget _chips({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selected == option;
        return GestureDetector(
          onTap: () => onSelected(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0F9F4) : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? AppColors.primaryDarkGreen : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: AppText(
              text: option,
              size: 13,
              weight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primaryDarkGreen : AppColors.textSecondaryLight,
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
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: isUploaded ? const Color(0xFFF0F9F4).withOpacity(0.5) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUploaded
                    ? AppColors.primaryDarkGreen.withOpacity(0.3)
                    : AppColors.primaryDarkGreen.withOpacity(0.2),
              ),
            ),
            child: isUploaded
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarkGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.description, color: Colors.white, size: 24),
                      ),
                      const AppSizedBox(width: 12),
                      Expanded(
                        child: AppText(
                          text: file != null ? path.basename(file.path) : 'Document uploaded',
                          size: 14,
                          weight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.check_circle, color: AppColors.primaryDarkGreen, size: 20),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.upload_file_outlined, size: 36, color: AppColors.primaryDarkGreen),
                      const AppSizedBox(height: 8),
                      const AppText(
                        text: 'Upload document',
                        size: 14,
                        weight: FontWeight.w700,
                        color: AppColors.primaryDarkGreen,
                      ),
                      const AppSizedBox(height: 4),
                      AppText(text: hint, size: 12, color: Colors.grey),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
