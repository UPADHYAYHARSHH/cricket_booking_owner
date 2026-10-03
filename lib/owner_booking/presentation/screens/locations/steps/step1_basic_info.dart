import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_form_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/map_picker_screen.dart';
import 'package:file_picker/file_picker.dart';

class Step1BasicInfo extends StatefulWidget {
  const Step1BasicInfo({super.key});

  @override
  State<Step1BasicInfo> createState() => Step1BasicInfoState();
}

class Step1BasicInfoState extends State<Step1BasicInfo> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameCtrl;
  late final TextEditingController addressCtrl;
  late final TextEditingController descriptionCtrl;
  late final TextEditingController privacyPolicyCtrl;
  late final TextEditingController latCtrl;
  late final TextEditingController lngCtrl;
  bool _isLocationFromMap = false;
  bool _showPolicyPreview = false;
  String? _refundPolicyUrl;
  bool _showRefundPolicyError = false;

  void _insertBullet() {
    final text = privacyPolicyCtrl.text;
    final sel = privacyPolicyCtrl.selection;
    final int start = sel.start >= 0 ? sel.start : text.length;
    final int end = sel.end >= 0 ? sel.end : text.length;
    final prefix = (start == 0 || text[start - 1] == '\n') ? '• ' : '\n• ';
    final newText = text.replaceRange(start, end, prefix);
    privacyPolicyCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + prefix.length),
    );
    if (_showPolicyPreview) setState(() {});
  }

  void _wrapBold() {
    final text = privacyPolicyCtrl.text;
    final sel = privacyPolicyCtrl.selection;
    if (sel.start >= 0 && sel.end > sel.start) {
      final selectedStr = text.substring(sel.start, sel.end);
      final newText = text.replaceRange(sel.start, sel.end, '**$selectedStr**');
      privacyPolicyCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: sel.start + 2,
          extentOffset: sel.end + 2,
        ),
      );
    } else {
      final pos = sel.start >= 0 ? sel.start : text.length;
      final newText = text.replaceRange(pos, pos, '**bold text**');
      privacyPolicyCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: pos + 2,
          extentOffset: pos + 11,
        ),
      );
    }
    if (_showPolicyPreview) setState(() {});
  }

  Future<void> _pickRefundPolicyFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _refundPolicyUrl = result.files.single.path;
        privacyPolicyCtrl.clear();
        _showRefundPolicyError = false;
      });
    }
  }

  Widget _formatButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryDarkGreen
              : AppColors.primaryLightGreen.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? Colors.white : AppColors.primaryDarkGreen,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.primaryDarkGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyPreview() {
    final text = privacyPolicyCtrl.text.trim();
    if (text.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Nothing to preview yet. Enter some text in the field.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          String cleanLine = line;
          if (cleanLine.startsWith('•') ||
              cleanLine.startsWith('-') ||
              cleanLine.startsWith('*')) {
            cleanLine = cleanLine.substring(1).trim();
          }

          final parts = cleanLine.split('**');
          final spans = <TextSpan>[];
          for (int i = 0; i < parts.length; i++) {
            if (parts[i].isEmpty) continue;
            if (i % 2 == 1) {
              spans.add(TextSpan(
                text: parts[i],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ));
            } else {
              spans.add(TextSpan(
                text: parts[i],
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF4B5563),
                ),
              ));
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2.0, right: 6.0),
                  child: Text(
                    '•',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12.5, height: 1.4),
                      children: spans,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final data = context.read<LocationFormCubit>().data;
    nameCtrl = TextEditingController(text: data.name);
    addressCtrl = TextEditingController(text: data.address);
    descriptionCtrl = TextEditingController(text: data.description);
    privacyPolicyCtrl = TextEditingController(text: data.privacyPolicy);
    latCtrl = TextEditingController(
      text: data.latitude != 0.0 ? data.latitude.toString() : '',
    );
    lngCtrl = TextEditingController(
      text: data.longitude != 0.0 ? data.longitude.toString() : '',
    );
    _isLocationFromMap = data.latitude != 0.0 && data.longitude != 0.0;
    _refundPolicyUrl = data.refundPolicyUrl;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    descriptionCtrl.dispose();
    privacyPolicyCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    super.dispose();
  }

  bool validateAndSave() {
    if (!formKey.currentState!.validate()) return false;

    final cubit = context.read<LocationFormCubit>();
    cubit.updateData(
      cubit.data.copyWith(
        name: nameCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        description: descriptionCtrl.text.trim(),
        privacyPolicy: privacyPolicyCtrl.text.trim(),
        refundPolicyUrl: _refundPolicyUrl,
        city: '',
        googleMapsLink: '',
        latitude: double.tryParse(latCtrl.text.trim()) ?? 0.0,
        longitude: double.tryParse(lngCtrl.text.trim()) ?? 0.0,
      ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('LOCATION NAME *'),
          _field(
            nameCtrl,
            hint: 'E.g. TurfPro Arena',
            icon: Icons.store_outlined,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: AppSizes.xxl),
          _label('GPS COORDINATES *'),
          const SizedBox(height: 4),
          // Map picker button
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (_) => MapPickerScreen(
                    initialLatitude: double.tryParse(latCtrl.text) ?? 0.0,
                    initialLongitude: double.tryParse(lngCtrl.text) ?? 0.0,
                  ),
                ),
              );
              if (result != null) {
                setState(() {
                  _isLocationFromMap = true;
                  final LatLng loc = result['location'];
                  latCtrl.text = loc.latitude.toStringAsFixed(6);
                  lngCtrl.text = loc.longitude.toStringAsFixed(6);
                  final String address = result['address'] ?? '';
                  if (address.isNotEmpty &&
                      address != 'Location selected' &&
                      address != 'Move the pin to select your venue location') {
                    addressCtrl.text = address;
                  }
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryDarkGreen.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: AppColors.primaryDarkGreen.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDarkGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          latCtrl.text.isNotEmpty && lngCtrl.text.isNotEmpty
                              ? 'Location Pinned ✓'
                              : 'Pick Location on Map',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ),
                        if (latCtrl.text.isNotEmpty && lngCtrl.text.isNotEmpty)
                          Text(
                            '${latCtrl.text}, ${lngCtrl.text}',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryLight,
                            ),
                          )
                        else
                          Text(
                            'Tap to open map and drop a pin on your venue',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryDarkGreen,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSizes.xxl),
          _label('FULL ADDRESS *'),
          _field(
            addressCtrl,
            hint: 'Plot 42, Prahlad Nagar, Near ISCON Cross Roads',
            maxLines: 2,
            icon: Icons.location_on_outlined,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Address is required' : null,
          ),
          const SizedBox(height: AppSizes.xxl),
          _label('DESCRIPTION'),
          _field(
            descriptionCtrl,
            hint: 'Describe what makes this venue special...',
            maxLines: 4,
            icon: Icons.description_outlined,
          ),
          const SizedBox(height: AppSizes.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label('REFUND POLICY *'),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _formatButton(
                    label: '• Bullet',
                    icon: Icons.format_list_bulleted_rounded,
                    onTap: _insertBullet,
                  ),
                  const SizedBox(width: 6),
                  _formatButton(
                    label: 'Bold',
                    icon: Icons.format_bold_rounded,
                    onTap: _wrapBold,
                  ),
                  const SizedBox(width: 6),
                  _formatButton(
                    label: _showPolicyPreview ? 'Edit' : 'Preview',
                    icon: _showPolicyPreview
                        ? Icons.edit_outlined
                        : Icons.visibility_outlined,
                    isActive: _showPolicyPreview,
                    onTap: () {
                      setState(() {
                        _showPolicyPreview = !_showPolicyPreview;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          if (_showPolicyPreview) ...[
            const SizedBox(height: 6),
            _buildPolicyPreview(),
            const SizedBox(height: 10),
          ] else ...[
            _field(
              privacyPolicyCtrl,
              hint:
                  '• Bookings can be cancelled only if requested **more than 6 hours** before slot time.\n• **No cancellation or refund** within 6 hours of slot time.',
              maxLines: 5,
              icon: Icons.assignment_return_outlined,
              readOnly: _refundPolicyUrl != null,
              errorText: _showRefundPolicyError ? 'Remove uploaded file to type here.' : null,
              onTap: _refundPolicyUrl != null ? () {
                setState(() => _showRefundPolicyError = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please remove the uploaded file first to add text.')),
                );
              } : null,
              validator: (v) => ((v == null || v.trim().isEmpty) && _refundPolicyUrl == null)
                  ? 'Refund Policy text or document is required'
                  : null,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Tip: Use [• Bullet] for points, or wrap words in **bold** to highlight.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('OR', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          _refundPolicyUrl != null
              ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryDarkGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: AppColors.primaryDarkGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _refundPolicyUrl!.split('/').last.split('\\').last,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 20),
                        onPressed: () => setState(() {
                          _refundPolicyUrl = null;
                          _showRefundPolicyError = false;
                        }),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: _pickRefundPolicyFile,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload Photo or PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryDarkGreen,
                    side: const BorderSide(color: AppColors.primaryDarkGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
        ],
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
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    IconData? icon,
    bool readOnly = false,
    String? errorText,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
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
      ),
    );
  }
}
