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


    final cubit = context.read<LocationFormCubit>();
    cubit.updateData(
      cubit.data.copyWith(
        images: _images,
        propertyStatus: _propertyStatus,
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
