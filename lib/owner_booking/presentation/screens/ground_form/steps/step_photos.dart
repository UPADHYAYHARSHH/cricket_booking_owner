import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
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
        final fileName =
            '$userId/grounds/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final fileBytes = await image.readAsBytes();
        await Supabase.instance.client.storage
            .from('venue_media')
            .uploadBinary(fileName, fileBytes);
        final url = Supabase.instance.client.storage
            .from('venue_media')
            .getPublicUrl(fileName);
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
          if (_imageUrls.isEmpty && !_isUploading) ...[
            _emptyState(),
            const SizedBox(height: AppSizes.xl),
          ],
          Wrap(
            spacing: AppSizes.md,
            runSpacing: AppSizes.md,
            children: [
              ..._imageUrls.map(
                (url) => _ImageTile(
                  url: url,
                  onRemove: () => _removeImage(url),
                ),
              ),
              _AddTile(
                isUploading: _isUploading,
                onTap: _isUploading ? null : _pickAndUpload,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 12,
                color: AppColors.textSecondaryLight.withValues(alpha: 0.6),
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: AppText(
                  text: 'Optional \u2014 you can also add photos later from the Grounds tab.',
                  size: 12,
                  color: AppColors.textSecondaryLight.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.xxl + AppSizes.lg,
          horizontal: AppSizes.xxl,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.slotAvailableBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_outlined,
                color: AppColors.primaryDarkGreen,
                size: AppSizes.iconXl,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            AppText(
              text: 'No photos yet',
              size: 15,
              weight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
            ),
            const SizedBox(height: AppSizes.xs),
            AppText(
              text: 'Tap the button below to add ground photos',
              size: 12,
              color: AppColors.textSecondaryLight,
            ),
          ],
        ),
      );
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
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: AppColors.borderLight,
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: Image.network(
                url,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 12,
                color: AppColors.white,
              ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.slotAvailableBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Center(
          child: isUploading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryDarkGreen,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.primaryDarkGreen,
                      size: 22,
                    ),
                    const SizedBox(height: AppSizes.xxs),
                    AppText(
                      text: 'Add',
                      size: 10,
                      weight: FontWeight.w600,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
