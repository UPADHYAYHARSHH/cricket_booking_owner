import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:turfpro_owner/utils/auth_helper.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/common/widgets/onboarding_layout.dart';
import 'package:toastification/toastification.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class KycDocumentationScreen extends StatefulWidget {
  const KycDocumentationScreen({super.key});

  @override
  State<KycDocumentationScreen> createState() => _KycDocumentationScreenState();
}

class _KycDocumentationScreenState extends State<KycDocumentationScreen> {
  final _panController = TextEditingController();
  final _aadharController = TextEditingController();
  final _gstController = TextEditingController();
  final _accHolderController = TextEditingController();
  final _accNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchController = TextEditingController();
  final _upiController = TextEditingController();

  String _businessType = 'Individual / Proprietorship';
  String _propertyStatus = 'Owned Property';
  String _payoutPreference = 'Weekly (every Monday)';

  final Map<String, File?> _files = {
    'pan': null,
    'aadhar': null,
    'gst': null,
    'property': null,
    'noc': null,
    'cheque': null,
  };

  final Map<String, String?> _uploadUrls = {
    'pan': null,
    'aadhar': null,
    'gst': null,
    'property': null,
    'noc': null,
    'cheque': null,
  };

  bool _isLoadingData = true;
  bool _isUploading = false;

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

      if (data != null && data['kyc_config'] != null) {
        final config = data['kyc_config'];
        setState(() {
          _panController.text = config['pan_number'] ?? '';
          _aadharController.text = config['aadhar_number'] ?? '';
          _gstController.text = config['gst_number'] ?? '';
          _accHolderController.text = config['acc_holder'] ?? '';
          _accNumberController.text = config['acc_number'] ?? '';
          _ifscController.text = config['ifsc'] ?? '';
          _bankNameController.text = config['bank_name'] ?? '';
          _branchController.text = config['branch'] ?? '';
          _upiController.text = config['upi_id'] ?? '';

          _businessType = config['business_type'] ?? _businessType;
          _propertyStatus = config['property_status'] ?? _propertyStatus;
          _payoutPreference = config['payout_preference'] ?? _payoutPreference;

          _uploadUrls['pan'] = config['pan_url'];
          _uploadUrls['aadhar'] = config['aadhar_url'];
          _uploadUrls['gst'] = config['gst_url'];
          _uploadUrls['property'] = config['property_url'];
          _uploadUrls['noc'] = config['noc_url'];
          _uploadUrls['cheque'] = config['cheque_url'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _pickFile(String key) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );

    if (result != null) {
      setState(() => _files[key] = File(result.files.single.path!));
    }
  }

  Future<String?> _uploadFile(String key, File file) async {
    final userId = currentUserId;
    if (userId == null) return null;

    final fileName = "${userId}/${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}";
    
    try {
      await Supabase.instance.client.storage
          .from('kyc_documents')
          .upload(fileName, file);

      final url = Supabase.instance.client.storage
          .from('kyc_documents')
          .getPublicUrl(fileName);
      
      return url;
    } catch (e) {
      debugPrint("Upload error for $key: $e");
      return null;
    }
  }

  void _onSave() async {
    if (_panController.text.isEmpty || _aadharController.text.isEmpty || _accNumberController.text.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text("Please fill all required fields"),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final Map<String, String?> finalUrls = Map.from(_uploadUrls);
      
      for (var entry in _files.entries) {
        if (entry.value != null) {
          final url = await _uploadFile(entry.key, entry.value!);
          if (url != null) finalUrls[entry.key] = url;
        }
      }

      final config = {
        'pan_number': _panController.text.trim(),
        'aadhar_number': _aadharController.text.trim(),
        'gst_number': _gstController.text.trim(),
        'acc_holder': _accHolderController.text.trim(),
        'acc_number': _accNumberController.text.trim(),
        'ifsc': _ifscController.text.trim(),
        'bank_name': _bankNameController.text.trim(),
        'branch': _branchController.text.trim(),
        'upi_id': _upiController.text.trim(),
        'business_type': _businessType,
        'property_status': _propertyStatus,
        'payout_preference': _payoutPreference,
        'pan_url': finalUrls['pan'],
        'aadhar_url': finalUrls['aadhar'],
        'gst_url': finalUrls['gst'],
        'property_url': finalUrls['property'],
        'noc_url': finalUrls['noc'],
        'cheque_url': finalUrls['cheque'],
      };

      context.read<AuthCubit>().saveKycConfig(kycConfig: config);
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: Text("Upload failed: $e"),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
            currentStep: 8,
            title: "Documentation & KYC",
            subtitle: "Required for payouts & compliance",
            isLoading: state is AuthLoading || _isUploading,
            onNext: _onSave,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSecurityNotice(),
                const AppSizedBox(height: 32),
                
                _buildSectionHeader("IDENTITY DOCUMENTS"),
                _buildLabel("PAN CARD NUMBER *"),
                _buildTextField(_panController, "ABCDE1234F", helper: "Required for TDS compliance on payouts above ₹30,000"),
                const AppSizedBox(height: 16),
                _buildUploadField("pan", "PAN CARD (UPLOAD)", "JPG, PNG or PDF • Max 5MB"),

                const AppSizedBox(height: 32),
                _buildLabel("AADHAR NUMBER *"),
                _buildTextField(_aadharController, "XXXX XXXX XXXX", helper: "Last 4 digits shown only"),
                const AppSizedBox(height: 16),
                _buildUploadField("aadhar", "AADHAR CARD (UPLOAD)", "Upload front & back • JPG, PNG or PDF • Max 5MB"),

                const AppSizedBox(height: 32),
                _buildSectionHeader("BUSINESS / GST"),
                _buildLabel("GST NUMBER"),
                _buildTextField(_gstController, "e.g. 24ABCDE1234F1Z5", helper: "Optional — if GST registered"),
                const AppSizedBox(height: 16),
                _buildUploadField("gst", "GST CERTIFICATE (UPLOAD)", "PDF only • Max 5MB"),
                const AppSizedBox(height: 24),
                _buildLabel("BUSINESS TYPE"),
                _buildChoiceChips(
                  options: ['Individual / Proprietorship', 'Partnership Firm', 'LLP / Pvt Ltd'],
                  selected: _businessType,
                  onSelected: (v) => setState(() => _businessType = v),
                ),

                const AppSizedBox(height: 32),
                _buildSectionHeader("PROPERTY OWNERSHIP"),
                _buildLabel("PROPERTY STATUS *"),
                _buildChoiceChips(
                  options: ['Owned Property', 'Lease / Rent Agreement', 'Society Permission'],
                  selected: _propertyStatus,
                  onSelected: (v) => setState(() => _propertyStatus = v),
                ),
                const AppSizedBox(height: 16),
                _buildUploadField("property", "PROPERTY DOCUMENT (UPLOAD)", "Ownership deed / Lease agreement / NOC • PDF only • Max 10MB"),
                const AppSizedBox(height: 16),
                _buildUploadField("noc", "LOCAL BODY / MUNICIPAL NOC", "NOC from municipal corporation or panchayat • Optional but recommended"),

                const AppSizedBox(height: 32),
                _buildSectionHeader("BANK DETAILS (FOR PAYOUTS)"),
                _buildLabel("ACCOUNT HOLDER NAME *"),
                _buildTextField(_accHolderController, "Enter name as in bank"),
                const AppSizedBox(height: 16),
                _buildLabel("ACCOUNT NUMBER *"),
                _buildTextField(_accNumberController, ".... .... 4521"),
                const AppSizedBox(height: 16),
                _buildLabel("IFSC CODE *"),
                _buildTextField(_ifscController, "SBIN0001234"),
                const AppSizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("BANK NAME"), _buildTextField(_bankNameController, "State Bank of India")])),
                    const AppSizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildLabel("BRANCH"), _buildTextField(_branchController, "Prahlad Nagar")])),
                  ],
                ),
                const AppSizedBox(height: 16),
                _buildUploadField("cheque", "CANCELLED CHEQUE (UPLOAD)", "Cancelled cheque or bank passbook front page • JPG or PDF • Max 3MB"),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
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
              text: "All documents are encrypted & stored securely. Used only for KYC verification & payouts. Not shared publicly.",
              size: 13,
              color: Colors.blue.shade800,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppText(
        text: title,
        size: 13,
        weight: FontWeight.w800,
        color: AppColors.textSecondaryLight.withOpacity(0.8),
        letterSpacing: 0.5,
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
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {String? helper}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF0F9F4).withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
        if (helper != null) ...[
          const AppSizedBox(height: 4),
          AppText(text: helper, size: 11, color: Colors.grey),
        ],
      ],
    );
  }

  Widget _buildUploadField(String key, String label, String hint) {
    final file = _files[key];
    final url = _uploadUrls[key];
    final isUploaded = file != null || url != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        GestureDetector(
          onTap: () => _pickFile(key),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: isUploaded ? const Color(0xFFF0F9F4).withOpacity(0.5) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUploaded ? AppColors.primaryDarkGreen.withOpacity(0.3) : AppColors.primaryDarkGreen.withOpacity(0.2),
                style: isUploaded ? BorderStyle.solid : BorderStyle.none,
              ),
            ),
            child: isUploaded 
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primaryDarkGreen, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.description, color: Colors.white, size: 24),
                    ),
                    const AppSizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            text: file != null ? path.basename(file.path) : "Document uploaded",
                            size: 14,
                            weight: FontWeight.w600,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          AppText(text: "Verified ✓", size: 12, color: AppColors.primaryDarkGreen, weight: FontWeight.w600),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: AppColors.primaryDarkGreen, size: 20),
                  ],
                )
              : Column(
                  children: [
                    const Icon(Icons.upload_file_outlined, size: 40, color: AppColors.primaryDarkGreen),
                    const AppSizedBox(height: 8),
                    AppText(text: "Upload document", size: 15, weight: FontWeight.w700, color: AppColors.primaryDarkGreen),
                    const AppSizedBox(height: 4),
                    AppText(text: hint, size: 12, color: Colors.grey),
                  ],
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChips({required List<String> options, required String selected, required Function(String) onSelected}) {
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
              border: Border.all(color: isSelected ? AppColors.primaryDarkGreen : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
            ),
            child: AppText(text: option, size: 13, weight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppColors.primaryDarkGreen : AppColors.textSecondaryLight),
          ),
        );
      }).toList(),
    );
  }
}
