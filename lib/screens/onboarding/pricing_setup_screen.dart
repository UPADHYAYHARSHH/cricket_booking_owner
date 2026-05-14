import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:turfpro_owner/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/common/widgets/onboarding_layout.dart';
import 'package:toastification/toastification.dart';

class PricingSetupScreen extends StatefulWidget {
  const PricingSetupScreen({super.key});

  @override
  State<PricingSetupScreen> createState() => _PricingSetupScreenState();
}

class _PricingSetupScreenState extends State<PricingSetupScreen> {
  final Map<String, Map<String, dynamic>> _sportPricing = {};
  List<String> _selectedSportIds = [];
  String? _activeSportId;
  Map<String, dynamic>? _slotConfig;
  bool _isLoadingData = true;

  final Map<String, String> _sportNames = {
    'box_cricket': 'Box Cricket',
    'volleyball': 'Volleyball',
    'pickleball': 'Pickleball',
    'football': 'Football',
    'badminton': 'Badminton',
    'tennis': 'Tennis',
  };

  final Map<String, IconData> _sportIcons = {
    'box_cricket': Icons.sports_cricket,
    'volleyball': Icons.sports_volleyball,
    'pickleball': Icons.sports_tennis,
    'football': Icons.sports_soccer,
    'badminton': Icons.sports_tennis,
    'tennis': Icons.sports_tennis,
  };

  String _advancePayment = '50% advance';
  String _refundPolicy = 'Full refund (before window)';
  String _gstApplicable = 'Yes — 18% GST';
  String _holidayPricing = 'Same as Weekend';

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('owner_details')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        final Map<String, dynamic> sportsConfig = data['sports_config'] ?? {};
        _slotConfig = data['slot_config'] ?? {};
        final Map<String, dynamic> existingPricing = data['pricing_config'] ?? {};

        setState(() {
          _selectedSportIds = sportsConfig.keys.toList();
          if (_selectedSportIds.isNotEmpty) {
            _activeSportId = _selectedSportIds.first;
          }

          for (var sportId in _selectedSportIds) {
            final existing = existingPricing[sportId] ?? {};
            _sportPricing[sportId] = {
              'weekday': {
                'off_peak': existing['weekday']?['off_peak'] ?? '600',
                'peak_morning': existing['weekday']?['peak_morning'] ?? '800',
                'peak_evening': existing['weekday']?['peak_evening'] ?? '900',
              },
              'weekend': {
                'off_peak': existing['weekend']?['off_peak'] ?? '700',
                'peak': existing['weekend']?['peak'] ?? '1000',
              },
            };
          }

          _advancePayment = existingPricing['advance_payment'] ?? '50% advance';
          _refundPolicy = existingPricing['refund_policy'] ?? 'Full refund (before window)';
          _gstApplicable = existingPricing['gst_applicable'] ?? 'Yes — 18% GST';
          _holidayPricing = existingPricing['holiday_pricing'] ?? 'Same as Weekend';

          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
      setState(() => _isLoadingData = false);
    }
  }

  void _onSave() {
    final Map<String, dynamic> config = Map.from(_sportPricing);
    config['advance_payment'] = _advancePayment;
    config['refund_policy'] = _refundPolicy;
    config['gst_applicable'] = _gstApplicable;
    config['holiday_pricing'] = _holidayPricing;

    context.read<AuthCubit>().savePricingConfig(pricingConfig: config);
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
            currentStep: 7,
            title: "Pricing Setup",
            subtitle: "Set rates per slot (1 hour) for each court",
            isLoading: state is AuthLoading,
            onNext: _onSave,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSportTabs(),
                const AppSizedBox(height: 32),
                if (_activeSportId != null) _buildPricingForm(_activeSportId!),
                
                const AppSizedBox(height: 40),
                _buildLabel("HOLIDAY / PUBLIC HOLIDAY PRICING"),
                _buildChoiceChips(
                  options: ['Same as Weekend', 'Custom Rate'],
                  selected: _holidayPricing,
                  onSelected: (v) => setState(() => _holidayPricing = v),
                ),

                const AppSizedBox(height: 32),
                _buildLabel("MINIMUM ADVANCE PAYMENT *"),
                _buildChoiceChips(
                  options: ['25% advance', '50% advance', '100% (full)'],
                  selected: _advancePayment,
                  onSelected: (v) => setState(() => _advancePayment = v),
                ),
                const AppSizedBox(height: 8),
                const AppText(text: "Remaining amount collected at ground", size: 12, color: AppColors.textSecondaryLight),

                const AppSizedBox(height: 32),
                _buildLabel("CANCELLATION REFUND POLICY"),
                _buildChoiceChips(
                  options: ['Full refund (before window)', '50% refund', 'No refund'],
                  selected: _refundPolicy,
                  onSelected: (v) => setState(() => _refundPolicy = v),
                ),

                const AppSizedBox(height: 32),
                _buildLabel("GST APPLICABLE"),
                _buildChoiceChips(
                  options: ['Yes — 18% GST', 'No GST'],
                  selected: _gstApplicable,
                  onSelected: (v) => setState(() => _gstApplicable = v),
                ),
                const AppSizedBox(height: 8),
                const AppText(text: "Required if your annual turnover exceeds ₹20L", size: 12, color: AppColors.textSecondaryLight),

                const AppSizedBox(height: 32),
                _buildSectionHeader("CRICBOOK PLATFORM FEE (INFO)"),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9F4).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        text: "CricBook charges 5–8% per booking as platform fee.",
                        size: 14,
                        weight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                      const AppSizedBox(height: 4),
                      AppText(
                        text: "This is deducted before settlement to your account. No monthly subscription fee.",
                        size: 13,
                        color: AppColors.textSecondaryLight.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSportTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _selectedSportIds.map((id) {
          final isSelected = _activeSportId == id;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _activeSportId = id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryDarkGreen : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppColors.primaryDarkGreen : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(_sportIcons[id] ?? Icons.sports, color: isSelected ? Colors.white : AppColors.textPrimaryLight, size: 20),
                    const AppSizedBox(width: 8),
                    AppText(text: _sportNames[id] ?? id, size: 14, weight: FontWeight.w700, color: isSelected ? Colors.white : AppColors.textPrimaryLight),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPricingForm(String sportId) {
    final pricing = _sportPricing[sportId]!;
    final morningPeak = "${_slotConfig?['morning_peak_start'] ?? '6:00 AM'}–${_slotConfig?['morning_peak_end'] ?? '9:00 AM'}";
    final eveningPeak = "${_slotConfig?['evening_peak_start'] ?? '6:00 PM'}–${_slotConfig?['evening_peak_end'] ?? '11:00 PM'}";
    final offPeakRange = "${_slotConfig?['morning_peak_end'] ?? '9:00 AM'}–${_slotConfig?['evening_peak_start'] ?? '6:00 PM'}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("BASE PRICING — WEEKDAYS"),
        _buildPricingTable([
          _PricingRowData(label: "Off-Peak ($offPeakRange)", value: pricing['weekday']['off_peak'], isPeak: false, onChanged: (v) => pricing['weekday']['off_peak'] = v),
          _PricingRowData(label: "Peak ($morningPeak)", value: pricing['weekday']['peak_morning'], isPeak: true, onChanged: (v) => pricing['weekday']['peak_morning'] = v),
          _PricingRowData(label: "Peak ($eveningPeak)", value: pricing['weekday']['peak_evening'], isPeak: true, onChanged: (v) => pricing['weekday']['peak_evening'] = v),
        ]),
        
        const AppSizedBox(height: 32),
        _buildSectionHeader("WEEKEND PRICING (SAT & SUN)"),
        _buildPricingTable([
          _PricingRowData(label: "Off-Peak", value: pricing['weekend']['off_peak'], isPeak: false, onChanged: (v) => pricing['weekend']['off_peak'] = v),
          _PricingRowData(label: "Peak", value: pricing['weekend']['peak'], isPeak: true, onChanged: (v) => pricing['weekend']['peak'] = v),
        ]),
      ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: AppText(
        text: label,
        size: 12,
        weight: FontWeight.w700,
        color: AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _buildPricingTable(List<_PricingRowData> rows) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9F4).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(text: "TIME SLOT", size: 12, weight: FontWeight.w800, color: AppColors.primaryDarkGreen.withOpacity(0.6), letterSpacing: 0.5),
                AppText(text: "RATE / HR", size: 12, weight: FontWeight.w800, color: AppColors.primaryDarkGreen.withOpacity(0.6), letterSpacing: 0.5),
              ],
            ),
          ),
          ...rows.map((row) => _buildPricingRow(row)),
        ],
      ),
    );
  }

  Widget _buildPricingRow(_PricingRowData row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: row.isPeak ? const Color(0xFFFFF9E6) : Colors.white,
        border: Border(top: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (row.isPeak) const Icon(Icons.bolt, size: 18, color: Color(0xFFFBC02D)),
                if (row.isPeak) const AppSizedBox(width: 4),
                AppText(
                  text: row.label,
                  size: 14,
                  weight: row.isPeak ? FontWeight.w700 : FontWeight.w500,
                  color: row.isPeak ? const Color(0xFFF57F17) : AppColors.textPrimaryLight,
                ),
              ],
            ),
          ),
          const AppText(text: "₹", size: 16, color: AppColors.textSecondaryLight),
          const AppSizedBox(width: 8),
          SizedBox(
            width: 100,
            child: TextFormField(
              initialValue: row.value,
              onChanged: row.onChanged,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: row.isPeak ? const Color(0xFFF57F17) : AppColors.primaryDarkGreen),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: row.isPeak ? const Color(0xFFFBC02D) : AppColors.primaryDarkGreen.withOpacity(0.2))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: row.isPeak ? const Color(0xFFFBC02D).withOpacity(0.5) : AppColors.primaryDarkGreen.withOpacity(0.15))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: row.isPeak ? const Color(0xFFFBC02D) : AppColors.primaryDarkGreen, width: 1.5)),
              ),
            ),
          ),
        ],
      ),
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

class _PricingRowData {
  final String label;
  final String value;
  final bool isPeak;
  final Function(String) onChanged;

  _PricingRowData({required this.label, required this.value, required this.isPeak, required this.onChanged});
}
