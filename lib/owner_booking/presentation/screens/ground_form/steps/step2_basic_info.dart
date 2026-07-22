import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_layout.dart';

class Step2BasicInfo extends StatefulWidget {
  final bool isEdit;
  const Step2BasicInfo({super.key, required this.isEdit});

  @override
  State<Step2BasicInfo> createState() => _Step2BasicInfoState();
}

class _Step2BasicInfoState extends State<Step2BasicInfo> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _nameCtrl;
  TextEditingController? _descCtrl;
  bool _initialized = false;

  TextEditingController get nameCtrl => _nameCtrl!;
  TextEditingController get descCtrl => _descCtrl!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final data = context.read<GroundFormCubit>().data;
    _nameCtrl = TextEditingController(text: data.name);
    _descCtrl = TextEditingController(text: data.description);
    _initialized = true;
  }

  @override
  void dispose() {
    _nameCtrl?.dispose();
    _descCtrl?.dispose();
    super.dispose();
  }

  void _onNext() {
    if (!_initialized) return;
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<GroundFormCubit>();
    cubit.updateData(
      cubit.data.copyWith(
        name: nameCtrl.text.trim(),
        description: descCtrl.text.trim(),
      ),
    );
    cubit.goToStep(3);
  }

  @override
  Widget build(BuildContext context) {
    return GroundFormLayout(
      isEdit: widget.isEdit,
      currentStep: 2,
      title: 'Basic Info',
      subtitle: 'Give your ground a name players will recognize',
      onNext: _onNext,
      onBack: () => context.read<GroundFormCubit>().goToStep(1),
      child: _initialized
          ? Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _labelWithIcon('GROUND NAME *', Icons.label_outline),
                  const SizedBox(height: AppSizes.sm),
                  _field(
                    nameCtrl,
                    hint: 'e.g. Champions Box Cricket Arena',
                    maxLines: 1,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Ground name is required'
                        : null,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _helperText('This is shown to players on the booking app'),
                  const SizedBox(height: AppSizes.xxl),
                  _labelWithIcon(
                    'DESCRIPTION / ABOUT THIS GROUND',
                    Icons.description_outlined,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _field(
                    descCtrl,
                    hint:
                        'Describe what makes this ground special — surface quality, lighting, rules followed, nearby landmarks…',
                    maxLines: 5,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _helperText(
                        'A good description increases bookings by up to 40%',
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _descCtrl!,
                          builder: (_, value, _) {
                            return Text(
                              '${value.text.length}/500',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondaryLight.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _labelWithIcon(String text, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.primaryDarkGreen.withValues(alpha: 0.7),
        ),
        const SizedBox(width: AppSizes.xs),
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

  Widget _helperText(String text) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        Icons.info_outline,
        size: 12,
        color: AppColors.primaryDarkGreen.withValues(alpha: 0.5),
      ),
      const SizedBox(width: AppSizes.xs),
      AppText(
        text: text,
        size: 11,
        color: AppColors.textSecondaryLight.withValues(alpha: 0.7),
      ),
    ],
  );

  Widget _field(
    TextEditingController ctrl, {
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondaryLight.withValues(alpha: 0.4),
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.inputFillLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(
            color: AppColors.primaryDarkGreen.withValues(alpha: 0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(
            color: AppColors.primaryDarkGreen,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}
