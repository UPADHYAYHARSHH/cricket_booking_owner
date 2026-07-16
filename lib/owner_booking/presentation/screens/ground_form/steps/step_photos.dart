import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_layout.dart';

class StepPhotos extends StatefulWidget {
  final bool isEdit;
  const StepPhotos({super.key, required this.isEdit});

  @override
  State<StepPhotos> createState() => _StepPhotosState();
}

class _StepPhotosState extends State<StepPhotos> {
  List<String> _imageUrls = [];
  bool _isUploading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _imageUrls = List.from(context.read<GroundFormCubit>().data.imageUrls);
    _initialized = true;
  }

  Future<void> _pickAndUpload() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isEmpty) return;

    setState(() => _isUploading = true);

    for (final image in images) {
      try {
        final fileName = '$userId/grounds/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final fileBytes = await image.readAsBytes();
        await Supabase.instance.client.storage
            .from('venue_media')
            .uploadBinary(fileName, fileBytes);
        final url = Supabase.instance.client.storage.from('venue_media').getPublicUrl(fileName);
        setState(() => _imageUrls = [..._imageUrls, url]);
      } catch (e) {
        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            title: const Text('Upload failed'),
            description: Text(e.toString()),
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      }
    }

    if (mounted) setState(() => _isUploading = false);
  }

  void _removeImage(String url) {
    setState(() => _imageUrls.remove(url));
  }

  void _onNext() {
    final cubit = context.read<GroundFormCubit>();
    cubit.updateData(cubit.data.copyWith(imageUrls: _imageUrls));
    cubit.goToStep(6);
  }

  @override
  Widget build(BuildContext context) {
    return GroundFormLayout(
      isEdit: widget.isEdit,
      currentStep: 5,
      title: 'Photos',
      subtitle: 'Add a few photos so players know what to expect',
      onNext: _onNext,
      onBack: () => context.read<GroundFormCubit>().goToStep(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._imageUrls.map((url) => _ImageTile(url: url, onRemove: () => _removeImage(url))),
              _AddTile(isUploading: _isUploading, onTap: _isUploading ? null : _pickAndUpload),
            ],
          ),
          const AppSizedBox(height: 12),
          const AppText(
            text: 'Optional — you can also add photos later from the Grounds tab.',
            size: 12,
            color: AppColors.textSecondaryLight,
          ),
        ],
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;
  const _ImageTile({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  final bool isUploading;
  final VoidCallback? onTap;
  const _AddTile({required this.isUploading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.2)),
        ),
        child: Center(
          child: isUploading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDarkGreen),
                )
              : const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryDarkGreen),
        ),
      ),
    );
  }
}
