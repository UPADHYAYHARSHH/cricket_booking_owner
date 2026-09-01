import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_form_cubit.dart';

class Step3Media extends StatefulWidget {
  const Step3Media({super.key});

  @override
  State<Step3Media> createState() => Step3MediaState();
}

class Step3MediaState extends State<Step3Media> {
  final _imagePicker = ImagePicker();
  List<String> _images = [];
  String _propertyStatus = 'Owned Property';
  String? _propertyDocumentUrl;
  String? _nocUrl;

  @override
  void initState() {
    super.initState();
    final data = context.read<LocationFormCubit>().data;
    _images = List.from(data.images);
    _propertyStatus = data.propertyStatus;
    _propertyDocumentUrl = data.propertyDocumentUrl;
    _nocUrl = data.nocUrl;
  }

  Future<void> _pickImages() async {
    final picked = await _imagePicker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _images.addAll(picked.map((e) => e.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _pickDocument(bool isNoc) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        if (isNoc) {
          _nocUrl = result.files.single.path;
        } else {
          _propertyDocumentUrl = result.files.single.path;
        }
      });
    }
  }

  bool validateAndSave() {
    if (_images.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('Validation Error'),
        description: const Text('Please upload at least one location image'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return false;
    }

    if (_propertyDocumentUrl == null || _propertyDocumentUrl!.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('Validation Error'),
        description: const Text('Please upload the property document'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return false;
    }

    if (_nocUrl == null || _nocUrl!.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        title: const Text('Validation Error'),
        description: const Text('Please upload the NOC document'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return false;
    }

    final cubit = context.read<LocationFormCubit>();
    cubit.updateData(
      cubit.data.copyWith(
        images: _images,
        propertyStatus: _propertyStatus,
        propertyDocumentUrl: _propertyDocumentUrl,
        nocUrl: _nocUrl,
      ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          text: 'Location Images *',
          size: 16,
          weight: FontWeight.w600,
        ),
        const SizedBox(height: AppSizes.md),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...List.generate(_images.length, (index) {
              final path = _images[index];
              final isNetworkOrBlob =
                  path.startsWith('http') || path.startsWith('blob:');
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () => _showDocumentDialog(path),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: isNetworkOrBlob
                              ? NetworkImage(path) as ImageProvider
                              : FileImage(File(path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primaryDarkGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryDarkGreen.withValues(alpha: 0.5),
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      color: AppColors.primaryDarkGreen,
                    ),
                    SizedBox(height: 4),
                    AppText(
                      text: 'Add Photo',
                      size: 12,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xxxxl),
        const AppText(
          text: 'Property Documents *',
          size: 16,
          weight: FontWeight.w600,
        ),
        const SizedBox(height: AppSizes.md),
        const AppText(
          text: 'Property Status',
          size: 13,
          color: AppColors.textSecondaryLight,
        ),
        const SizedBox(height: AppSizes.xs),
        DropdownButtonFormField<String>(
          initialValue: _propertyStatus,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Owned Property',
              child: Text('Owned Property'),
            ),
            DropdownMenuItem(
              value: 'Leased Property',
              child: Text('Leased Property'),
            ),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _propertyStatus = val);
          },
        ),
        const SizedBox(height: AppSizes.xl),
        _buildDocUpload(
          'Property Document (Lease/Deed) *',
          _propertyDocumentUrl,
          false,
        ),
        const SizedBox(height: AppSizes.xl),
        _buildDocUpload('NOC Document *', _nocUrl, true),
      ],
    );
  }

  Widget _buildDocUpload(String label, String? url, bool isNoc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(text: label, size: 13, color: AppColors.textSecondaryLight),
        const SizedBox(height: AppSizes.xs),
        if (url == null || url.isEmpty)
          GestureDetector(
            onTap: () => _pickDocument(isNoc),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.inputFillLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: AppColors.primaryDarkGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.upload_file, color: AppColors.primaryDarkGreen),
                  const SizedBox(width: AppSizes.md),
                  const Expanded(
                    child: AppText(
                      text: 'Upload File',
                      size: 14,
                      color: AppColors.textSecondaryLight,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: AppColors.primaryDarkGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showDocumentDialog(url),
                    child: Row(
                      children: [
                        // Preview
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.inputFillLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildPreview(url),
                        ),
                        const SizedBox(width: 12),
                        // File info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                text: label.replaceAll(' *', ''),
                                size: 14,
                                weight: FontWeight.w600,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              AppText(
                                text: 'Tap to view document',
                                size: 12,
                                color: AppColors.primaryDarkGreen,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.primaryDarkGreen),
                  tooltip: 'Change Document',
                  onPressed: () => _pickDocument(isNoc),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove Document',
                  onPressed: () {
                    setState(() {
                      if (isNoc) _nocUrl = null;
                      else _propertyDocumentUrl = null;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.jpg') || 
           lower.contains('.jpeg') || 
           lower.contains('.png') || 
           lower.contains('alt=media') || 
           lower.startsWith('blob:') ||
           lower.startsWith('data:image');
  }

  void _showDocumentDialog(String url) {
    final isImage = _isImageUrl(url);
    final isNetworkOrBlob = url.startsWith('http') || url.startsWith('blob:') || url.startsWith('data:');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: isImage
                    ? InteractiveViewer(
                        child: Image(
                          image: isNetworkOrBlob ? NetworkImage(url) as ImageProvider : FileImage(File(url)),
                          fit: BoxFit.contain,
                        ),
                      )
                    : (isNetworkOrBlob ? SfPdfViewer.network(url) : SfPdfViewer.file(File(url))),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreview(String url) {
    if (_isImageUrl(url)) {
      final isNetworkOrBlob = url.startsWith('http') || url.startsWith('blob:') || url.startsWith('data:');
      return Image(
        image: isNetworkOrBlob ? NetworkImage(url) as ImageProvider : FileImage(File(url)),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.image_outlined, color: AppColors.primaryDarkGreen),
        ),
      );
    } else {
      return const Center(
        child: Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 28),
      );
    }
  }
}
