import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/common/widgets/app_text_field.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'onboarding_step_indicator.dart';

class Step2DocumentsScreen extends StatefulWidget {
  const Step2DocumentsScreen({super.key});

  @override
  State<Step2DocumentsScreen> createState() => _Step2DocumentsScreenState();
}

class _Step2DocumentsScreenState extends State<Step2DocumentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController();
  final _accNameCtrl = TextEditingController();
  final _accNumberCtrl = TextEditingController();
  final _confirmAccCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();

  File? _panFile;
  File? _aadharFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _accNameCtrl.dispose();
    _accNumberCtrl.dispose();
    _confirmAccCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile(bool isPan) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(ctx);
                final img = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );
                if (img != null) {
                  setState(() {
                    if (isPan) {
                      _panFile = File(img.path);
                    } else {
                      _aadharFile = File(img.path);
                    }
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final img = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (img != null) {
                  setState(() {
                    if (isPan) {
                      _panFile = File(img.path);
                    } else {
                      _aadharFile = File(img.path);
                    }
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF Document'),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );
                if (result != null && result.files.single.path != null) {
                  final f = File(result.files.single.path!);
                  setState(() {
                    if (isPan) {
                      _panFile = f;
                    } else {
                      _aadharFile = f;
                    }
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _fileExtension(File file) {
    final name = file.path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return 'jpg';
    return name.substring(dot + 1).toLowerCase();
  }

  String _contentTypeFor(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  Future<String> _uploadFile(File file, String docType) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('Not authenticated. Please log in again.');
    }
    if (!await file.exists()) {
      throw Exception(
        'Selected $docType file was not found. Please pick it again.',
      );
    }

    final ext = _fileExtension(file);
    final fileName =
        '$uid/kyc/${docType}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('$docType file is empty. Please pick another file.');
    }

    final supabase = Supabase.instance.client;
    try {
      await supabase.storage
          .from('venue_media')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _contentTypeFor(ext),
            ),
          );
    } on StorageException catch (e) {
      throw Exception(
        'Could not upload $docType: ${e.message}. '
        'Check that the venue_media storage bucket allows uploads.',
      );
    } catch (e) {
      throw Exception('Could not upload $docType: $e');
    }

    return supabase.storage.from('venue_media').getPublicUrl(fileName);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_panFile == null || _aadharFile == null) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('Error'),
        description: const Text('Please upload both PAN and Aadhar.'),
        autoCloseDuration: const Duration(seconds: 4),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final panUrl = await _uploadFile(_panFile!, 'pan');
      final aadharUrl = await _uploadFile(_aadharFile!, 'aadhar');

      if (mounted) {
        await context.read<AuthCubit>().saveStep2(
          businessName: _businessNameCtrl.text.trim(),
          panUrl: panUrl,
          aadharUrl: aadharUrl,
          bankDetails: {
            'account_name': _accNameCtrl.text.trim(),
            'account_number': _accNumberCtrl.text.trim(),
            'ifsc_code': _ifscCtrl.text.trim().toUpperCase(),
          },
        );
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: const Text('Upload failed'),
          description: Text(e.toString().replaceFirst('Exception: ', '')),
          autoCloseDuration: const Duration(seconds: 6),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthStep1Required) {
          Navigator.pushReplacementNamed(context, '/onboarding/step1');
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.lg),
                  buildOnboardingHeader(
                    currentStep: 2,
                    onBack: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/onboarding/step1',
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.xl),

                  const AppText(
                    text: 'KYC & Documents',
                    size: 24,
                    weight: FontWeight.w700,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  const AppText(
                    text:
                        'We need your business details and documents to verify your identity.',
                    size: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                  const SizedBox(height: AppSizes.xxl),

                  const AppText(
                    text: 'Business Information',
                    size: 14,
                    weight: FontWeight.w600,
                  ),
                  const SizedBox(height: AppSizes.md),
                  AppTextField(
                    label: 'Business / Entity Name',
                    controller: _businessNameCtrl,
                    prefixIcon: Icons.store_outlined,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Business name is required'
                        : null,
                  ),
                  const SizedBox(height: AppSizes.xl),

                  const AppText(
                    text: 'KYC Documents',
                    size: 14,
                    weight: FontWeight.w600,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDocCard(
                          'PAN Card',
                          _panFile,
                          () => _pickFile(true),
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: _buildDocCard(
                          'Aadhar Card',
                          _aadharFile,
                          () => _pickFile(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xl),

                  const AppText(
                    text: 'Bank Details (For Payouts)',
                    size: 14,
                    weight: FontWeight.w600,
                  ),
                  const SizedBox(height: AppSizes.md),
                  AppTextField(
                    label: 'Account Holder Name',
                    controller: _accNameCtrl,
                    prefixIcon: Icons.person_outline,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Account holder name is required'
                        : null,
                  ),
                  const SizedBox(height: AppSizes.md),
                  AppTextField(
                    label: 'Account Number',
                    controller: _accNumberCtrl,
                    prefixIcon: Icons.credit_card_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Account number is required';
                      if (v.trim().length < 9)
                        return 'Account number must be at least 9 digits';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.md),
                  AppTextField(
                    label: 'Confirm Account Number',
                    controller: _confirmAccCtrl,
                    prefixIcon: Icons.credit_card_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Please confirm your account number';
                      if (v.trim() != _accNumberCtrl.text.trim())
                        return 'Account numbers do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.md),
                  AppTextField(
                    label: 'IFSC Code',
                    controller: _ifscCtrl,
                    prefixIcon: Icons.account_balance_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'IFSC code is required';
                      if (!RegExp(
                        r'^[A-Z0-9]{11}$',
                      ).hasMatch(v.trim().toUpperCase()))
                        return 'Enter a valid 11-character IFSC';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.xxl),

                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) => AppButton(
                      title: 'Continue',
                      isLoading: _isUploading || state is AuthLoading,
                      onTap: _submit,
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocCard(String label, File? file, VoidCallback onTap) {
    final isPdf = file?.path.toLowerCase().endsWith('.pdf') ?? false;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null
                ? AppColors.primaryDarkGreen
                : AppColors.borderLight,
            width: 2,
          ),
        ),
        child: file != null
            ? (isPdf
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          color: AppColors.primaryDarkGreen,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        AppText(
                          text: 'PDF Uploaded',
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppColors.primaryDarkGreen,
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        file,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.upload_file,
                    color: AppColors.textSecondaryLight,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    text: label,
                    size: 13,
                    color: AppColors.textPrimaryLight,
                  ),
                ],
              ),
      ),
    );
  }
}
