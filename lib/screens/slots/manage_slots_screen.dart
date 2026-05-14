import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/blocs/slot/slot_cubit.dart';

class ManageSlotsScreen extends StatefulWidget {
  final String groundId;
  final String groundName;
  const ManageSlotsScreen({super.key, required this.groundId, required this.groundName});

  @override
  State<ManageSlotsScreen> createState() => _ManageSlotsScreenState();
}

class _ManageSlotsScreenState extends State<ManageSlotsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  void _loadSlots() {
    context.read<SlotCubit>().fetchSlots(widget.groundId, _selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF6B00);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(text: "Manage Slots - ${widget.groundName}", size: 16, weight: FontWeight.w700),
      ),
      body: Column(
        children: [
          _buildDatePicker(),
          Expanded(
            child: BlocBuilder<SlotCubit, SlotState>(
              builder: (context, state) {
                if (state is SlotLoading) return const Center(child: CircularProgressIndicator(color: primaryColor));
                
                if (state is SlotLoaded) {
                  if (state.slots.isEmpty) {
                    return _buildNoSlotsState();
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.2,
                    ),
                    itemCount: state.slots.length,
                    itemBuilder: (context, index) {
                      final slot = state.slots[index];
                      return _SlotTile(slot: slot);
                    },
                  );
                }

                if (state is SlotError) return Center(child: AppText(text: state.message, color: Colors.red));

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Column(
        children: [
          const AppText(text: "Select Date", size: 14, weight: FontWeight.w600),
          const AppSizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(14, (index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(_selectedDate);
                
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = date);
                    _loadSlots();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF6B00) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        AppText(text: DateFormat('EEE').format(date), size: 12, color: isSelected ? Colors.white : Colors.grey),
                        AppText(text: DateFormat('d').format(date), size: 16, weight: FontWeight.w700, color: isSelected ? Colors.white : Colors.black),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSlotsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
          const AppSizedBox(height: 16),
          const AppText(text: "No slots found for this date", size: 16, weight: FontWeight.w600, color: Colors.grey),
          const AppSizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Logic to generate slots based on ground opening/closing times
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Slot generation logic coming soon")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00)),
            child: const AppText(text: "Generate Slots", color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  final dynamic slot;
  const _SlotTile({required this.slot});

  @override
  Widget build(BuildContext context) {
    final status = slot['status'] ?? 'available';
    final isBlocked = status == 'blocked';
    final isBooked = status == 'booked';

    Color bgColor = Colors.white;
    Color textColor = Colors.black;
    if (isBlocked) { bgColor = Colors.red.shade50; textColor = Colors.red; }
    if (isBooked) { bgColor = Colors.green.shade50; textColor = Colors.green; }

    return GestureDetector(
      onTap: isBooked ? null : () {
        context.read<SlotCubit>().toggleSlotStatus(slot['id'], !isBlocked);
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isBlocked ? Colors.red.withValues(alpha: 0.3) : isBooked ? Colors.green.withValues(alpha: 0.3) : Colors.grey.shade300),
        ),
        child: Center(
          child: AppText(
            text: "${slot['start_time']} - ${slot['end_time']}",
            size: 11,
            weight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
