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
        const AppText(
          text: 'Review & Submit',
          size: 22,
          weight: FontWeight.w800,
          color: AppColors.textPrimaryLight,
        ),
        const SizedBox(height: 6),
        const AppText(
          text: 'Please verify all details before submitting',
          size: 14,
          color: AppColors.textSecondaryLight,
        ),
        const SizedBox(height: AppSizes.xxl),

        _buildCard(
          'Location Details',
          Icons.location_city_rounded,
          [
            _summaryItem('Location Name', data.name, icon: Icons.storefront_outlined),
            const Divider(height: 24, color: AppColors.inputFillLight),
            _summaryItem('Address', data.address, icon: Icons.location_on_outlined),
            const Divider(height: 24, color: AppColors.inputFillLight),
            _summaryItem('GPS Coordinates', '${data.latitude}, ${data.longitude}', icon: Icons.my_location),
            if (data.description.isNotEmpty) ...[
              const Divider(height: 24, color: AppColors.inputFillLight),
              _summaryItem('Description', data.description, icon: Icons.description_outlined),
            ]
          ],
        ),

        if (data.amenities.isNotEmpty)
          _buildCard(
            'Amenities',
            Icons.featured_play_list_outlined,
            [_buildAmenities(data.amenities)],
          ),

        if (data.images.isNotEmpty)
          _buildCard(
            'Location Images',
            Icons.photo_library_outlined,
            [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: data.images.map((path) {
                  final isNetworkOrBlob = path.startsWith('http') || path.startsWith('blob:') || path.startsWith('data:');
                  return GestureDetector(
                    onTap: () => _showDocumentDialog(context, path),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.1)),
                        image: DecorationImage(
                          image: isNetworkOrBlob ? NetworkImage(path) : FileImage(File(path)) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

        if (data.privacyPolicy.isNotEmpty || (data.refundPolicyUrl != null && data.refundPolicyUrl!.isNotEmpty))
          _buildCard(
            'Policies & Documents',
            Icons.policy_outlined,
            [
              if (data.privacyPolicy.isNotEmpty)
                _summaryItem('Refund Policy Text', data.privacyPolicy, icon: Icons.text_snippet_outlined),
              if (data.privacyPolicy.isNotEmpty && data.refundPolicyUrl != null && data.refundPolicyUrl!.isNotEmpty)
                const Divider(height: 24, color: AppColors.inputFillLight),
              if (data.refundPolicyUrl != null && data.refundPolicyUrl!.isNotEmpty)
                _buildDocPreview(context, 'Refund Policy Document', data.refundPolicyUrl!),
            ],
          ),
      ],
    );
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.xxl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryLightGreen.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg - 1)),
              border: Border(bottom: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.08))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primaryDarkGreen),
                const SizedBox(width: 8),
                AppText(
                  text: title,
                  size: 15,
                  weight: FontWeight.w700,
                  color: AppColors.primaryDarkGreen,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocPreview(BuildContext context, String label, String url) {
    final isImage = _isImageUrl(url);
    final isNetworkOrBlob = url.startsWith('http') || url.startsWith('blob:') || url.startsWith('data:');

    return GestureDetector(
      onTap: () => _showDocumentDialog(context, url),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.inputFillLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: isImage
                  ? Image(
                      image: isNetworkOrBlob ? NetworkImage(url) as ImageProvider : FileImage(File(url)),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image_outlined, color: AppColors.primaryDarkGreen),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 22),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(text: label, size: 14, weight: FontWeight.w600, color: AppColors.textPrimaryLight),
                  const SizedBox(height: 2),
                  AppText(text: 'Tap to view', size: 12, color: AppColors.primaryDarkGreen),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.primaryDarkGreen.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, {IconData? icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.inputFillLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(text: label, size: 12, color: AppColors.textSecondaryLight, weight: FontWeight.w500),
              const SizedBox(height: 4),
              AppText(
                text: value.isEmpty ? 'N/A' : value,
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities(List<String> amenities) {
    return Wrap(
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
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.inputFillLight.withOpacity(0.8),
            borderRadius: BorderRadius.circular(AppSizes.radiusRound),
            border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.2), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                HugeIcon(icon: icon, size: 14, color: AppColors.primaryDarkGreen),
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
    );
  }
}
