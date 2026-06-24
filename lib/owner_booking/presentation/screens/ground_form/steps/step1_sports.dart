import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/screens/ground_form/ground_form_layout.dart';

const List<Map<String, dynamic>> _kSports = [
  {'id': 'box_cricket', 'name': 'Box Cricket', 'subtitle': 'Enclosed cricket arena', 'icon': Icons.sports_cricket},
  {'id': 'football', 'name': 'Football / Futsal', 'subtitle': '5-a-side, 7-a-side', 'icon': Icons.sports_soccer},
  {'id': 'badminton', 'name': 'Badminton', 'subtitle': 'Single / double court', 'icon': Icons.sports_tennis},
  {'id': 'volleyball', 'name': 'Volleyball', 'subtitle': 'Indoor / outdoor', 'icon': Icons.sports_volleyball},
  {'id': 'pickleball', 'name': 'Pickleball', 'subtitle': 'Paddle sport', 'icon': Icons.sports_tennis},
  {'id': 'tennis', 'name': 'Tennis', 'subtitle': 'Hard / clay / grass', 'icon': Icons.sports_tennis},
  {'id': 'basketball', 'name': 'Basketball', 'subtitle': 'Full / half court', 'icon': Icons.sports_basketball},
];

class Step1Sports extends StatefulWidget {
  final bool isEdit;
  const Step1Sports({super.key, required this.isEdit});

  @override
  State<Step1Sports> createState() => _Step1SportsState();
}

class _Step1SportsState extends State<Step1Sports> {
  String _selectedSport = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _selectedSport = context.read<GroundFormCubit>().data.category;
    _initialized = true;
  }

  void _select(String id) {
    setState(() => _selectedSport = id);
  }

  void _onNext() {
    if (_selectedSport.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text('Select a sport for this ground'),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }
    final cubit = context.read<GroundFormCubit>();
    cubit.updateData(cubit.data.copyWith(category: _selectedSport));
    cubit.goToStep(2);
  }

  @override
  Widget build(BuildContext context) {
    return GroundFormLayout(
      isEdit: widget.isEdit,
      currentStep: 1,
      title: 'Sport',
      subtitle: 'Which single sport is this ground for?',
      onNext: _onNext,
      onBack: () => Navigator.pop(context),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _kSports.length,
        itemBuilder: (context, index) {
          final sport = _kSports[index];
          final id = sport['id'] as String;
          final isSelected = _selectedSport == id;

          return GestureDetector(
            onTap: () => _select(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0F9F4) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryDarkGreen
                      : AppColors.primaryDarkGreen.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : const Color(0xFFF0F9F4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryDarkGreen.withOpacity(0.2)
                            : Colors.transparent,
                      ),
                    ),
                    child: Icon(sport['icon'] as IconData,
                        color: AppColors.primaryDarkGreen, size: 22),
                  ),
                  const AppSizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                            text: sport['name'] as String,
                            size: 15,
                            weight: FontWeight.w700),
                        AppText(
                            text: sport['subtitle'] as String,
                            size: 12,
                            color: AppColors.textSecondaryLight),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? AppColors.primaryDarkGreen : Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
