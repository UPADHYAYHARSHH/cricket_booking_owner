import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/locations/location_form_cubit.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:turfpro_owner/owner_booking/presentation/widgets/amenities_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class Step4Summary extends StatelessWidget {
  const Step4Summary({super.key});

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('alt=media') ||
        lower.startsWith('blob:') ||
        lower.startsWith('data:image');
  }

  void _showDocumentDialog(BuildContext context, String url) {
    final isImage = _isImageUrl(url);
    final isNetworkOrBlob =
        url.startsWith('http') ||
        url.startsWith('blob:') ||
        url.startsWith('data:');

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
                          image: isNetworkOrBlob
                              ? NetworkImage(url) as ImageProvider
                              : FileImage(File(url)),
                          fit: BoxFit.contain,
                        ),
                      )
                    : (isNetworkOrBlob
                          ? SfPdfViewer.network(url)
                          : SfPdfViewer.file(File(url))),
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

  @override
  Widget build(BuildContext context) {
    final data = context.read<LocationFormCubit>().data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(text: 'Summary', size: 20, weight: FontWeight.w700),
        const SizedBox(height: AppSizes.xl),
        _summaryItem('Location Name', data.name),
        _summaryItem('Address', data.address),
        _summaryItem('GPS', '${data.latitude}, ${data.longitude}'),
        _summaryItem('Description', data.description),
        _buildAmenities(data.amenities),
        _summaryItem('Property Status', data.propertyStatus),

        const SizedBox(height: AppSizes.md),
        const AppText(
          text: 'Location Images',
          size: 14,
          weight: FontWeight.w600,
        ),
        const SizedBox(height: AppSizes.md),
        if (data.images.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.images.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSizes.sm),
              itemBuilder: (context, index) {
                final path = data.images[index];
                final isNetworkOrBlob =
                    path.startsWith('http') ||
                    path.startsWith('blob:') ||
                    path.startsWith('data:');
                return GestureDetector(
                  onTap: () => _showDocumentDialog(context, path),
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      image: DecorationImage(
                        image: isNetworkOrBlob
                            ? NetworkImage(path)
                            : FileImage(File(path)) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        else
          const AppText(
            text: 'No images provided',
            size: 13,
            color: AppColors.textSecondaryLight,
          ),

        const SizedBox(height: AppSizes.xl),
        const AppText(
          text: 'Uploaded Documents',
          size: 14,
          weight: FontWeight.w600,
        ),
        const SizedBox(height: AppSizes.md),
        if (data.propertyDocumentUrl != null &&
            data.propertyDocumentUrl!.isNotEmpty)
          _buildDocPreview(
            context,
            'Property Document',
            data.propertyDocumentUrl!,
          ),
        if (data.nocUrl != null && data.nocUrl!.isNotEmpty)
          _buildDocPreview(context, 'NOC Document', data.nocUrl!),
      ],
    );
  }

  Widget _buildDocPreview(BuildContext context, String label, String url) {
    final isImage = _isImageUrl(url);
    final isNetworkOrBlob =
        url.startsWith('http') ||
        url.startsWith('blob:') ||
        url.startsWith('data:');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: GestureDetector(
        onTap: () => _showDocumentDialog(context, url),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.inputFillLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: AppColors.primaryDarkGreen.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: isImage
                    ? Image(
                        image: isNetworkOrBlob
                            ? NetworkImage(url) as ImageProvider
                            : FileImage(File(url)),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: AppColors.primaryDarkGreen,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.picture_as_pdf,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(text: label, size: 14, weight: FontWeight.w600),
                    const SizedBox(height: 2),
                    AppText(
                      text: 'Tap to view',
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
    );
  }

  Widget _summaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(text: label, size: 12, color: AppColors.textSecondaryLight),
          const SizedBox(height: 4),
          AppText(
            text: value.isEmpty ? 'N/A' : value,
            size: 15,
            weight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _buildAmenities(List<String> amenities) {
    if (amenities.isEmpty) {
      return _summaryItem('Amenities', 'N/A');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: 'Amenities',
            size: 12,
            color: AppColors.textSecondaryLight,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: amenities.map((id) {
              final amenity = kVenueAmenities.firstWhere(
                (a) => a['id'] == id,
                orElse: () => {'label': id, 'icon': null},
              );
              final label = amenity['label'] as String;
              final icon = amenity['icon'];

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inputFillLight,
                  borderRadius: BorderRadius.circular(AppSizes.radiusRound),
                  border: Border.all(
                    color: AppColors.primaryDarkGreen,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      HugeIcon(
                        icon: icon,
                        size: 14,
                        color: AppColors.primaryDarkGreen,
                      ),
                      const SizedBox(width: AppSizes.sm),
                    ],
                    AppText(
                      text: label,
                      size: 12,
                      weight: FontWeight.w600,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
