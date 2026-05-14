import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/blocs/ground/ground_cubit.dart';
import 'package:toastification/toastification.dart';

class AddSportScreen extends StatefulWidget {
  const AddSportScreen({super.key});

  @override
  State<AddSportScreen> createState() => _AddSportScreenState();
}

class _AddSportScreenState extends State<AddSportScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  // Pricing Controllers
  final _weekdayPriceController = TextEditingController(text: "1000");
  final _weekendPriceController = TextEditingController(text: "1200");
  final _morningPriceController = TextEditingController(text: "1000");
  final _eveningPriceController = TextEditingController(text: "1500");
  final _nightPriceController = TextEditingController(text: "1300");

  String _selectedCategory = 'Cricket';
  TimeOfDay _openingTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 23, minute: 0);

  final List<XFile> _selectedImages = [];
  final List<String> _selectedAmenities = [];

  final List<String> _allAmenities = [
    'Floodlights',
    'Changing Room',
    'Parking',
    'Drinking Water',
    'First Aid',
    'Canteen',
    'Washroom',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _weekdayPriceController.dispose();
    _weekendPriceController.dispose();
    _morningPriceController.dispose();
    _eveningPriceController.dispose();
    _nightPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isOpening) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openingTime : _closingTime,
    );
    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  void _onNext() {
    if (_currentStep < 2) {
      if (_currentStep == 0 && !_formKey.currentState!.validate()) return;
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _submit() async {
    if (_selectedImages.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text("Images Required"),
        description: const Text(
          "Please upload at least one photo of your turf",
        ),
      );
      return;
    }

    final pricingData = {
      'weekday': int.parse(_weekdayPriceController.text),
      'weekend': int.parse(_weekendPriceController.text),
      'morning': int.parse(_morningPriceController.text),
      'evening': int.parse(_eveningPriceController.text),
      'night': int.parse(_nightPriceController.text),
    };

    context.read<GroundCubit>().registerGround(
      name: _nameController.text.trim(),
      category: _selectedCategory,
      description: _descController.text.trim(),
      openingTime:
          "${_openingTime.hour.toString().padLeft(2, '0')}:${_openingTime.minute.toString().padLeft(2, '0')}:00",
      closingTime:
          "${_closingTime.hour.toString().padLeft(2, '0')}:${_closingTime.minute.toString().padLeft(2, '0')}:00",
      imageUrls: [
        'https://images.unsplash.com/photo-1595030044556-acfaa60edc7f?q=80&w=1000&auto=format&fit=crop',
      ], // In a real app, upload these first
      amenities: _selectedAmenities,
      pricingOverrides: pricingData,
    );

    toastification.show(
      context: context,
      type: ToastificationType.success,
      title: const Text("Success"),
      description: const Text("Turf registered successfully! Slots generated."),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF6B00);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => _currentStep > 0
              ? setState(() => _currentStep--)
              : Navigator.pop(context),
        ),
        title: const AppText(
          text: "Register Sport/Turf",
          size: 18,
          weight: FontWeight.w700,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStep(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: AppButton(
              title: _currentStep == 2 ? "Finish & Submit" : "Next Step",
              onTap: _onNext,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) => _buildStepCircle(index)),
      ),
    );
  }

  Widget _buildStepCircle(int index) {
    bool isActive = _currentStep >= index;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFF6B00) : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AppText(
              text: "${index + 1}",
              color: isActive ? Colors.white : Colors.grey,
              weight: FontWeight.bold,
            ),
          ),
        ),
        if (index < 2)
          Container(
            width: 40,
            height: 2,
            color: _currentStep > index
                ? const Color(0xFFFF6B00)
                : Colors.grey.shade200,
          ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildPricingStep();
      case 2:
        return _buildStep2And3();
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: "Basic Information",
            size: 20,
            weight: FontWeight.w700,
          ),
          const AppSizedBox(height: 8),
          const AppText(
            text: "Enter details about your sports facility",
            size: 14,
            color: Colors.grey,
          ),
          const AppSizedBox(height: 24),
          _buildLabel("Turf Name"),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration("e.g. Dream Arena"),
            validator: (v) => v?.isEmpty ?? true ? "Required" : null,
          ),
          const AppSizedBox(height: 16),
          _buildLabel("Category"),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: _inputDecoration(""),
            items: [
              'Cricket',
              'Football',
              'Badminton',
              'Tennis',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
          ),
          const AppSizedBox(height: 16),
          _buildLabel("Description"),
          TextFormField(
            controller: _descController,
            maxLines: 3,
            decoration: _inputDecoration("Describe your turf facilities..."),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          text: "Flexible Pricing",
          size: 20,
          weight: FontWeight.w700,
        ),
        const AppSizedBox(height: 8),
        const AppText(
          text: "Set different rates for days and times",
          size: 14,
          color: Colors.grey,
        ),
        const AppSizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Weekday Price"),
                  TextFormField(
                    controller: _weekdayPriceController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration("₹ 1000"),
                  ),
                ],
              ),
            ),
            const AppSizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Weekend Price"),
                  TextFormField(
                    controller: _weekendPriceController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration("₹ 1200"),
                  ),
                ],
              ),
            ),
          ],
        ),
        const AppSizedBox(height: 24),
        const AppText(
          text: "Time-based Overrides",
          size: 16,
          weight: FontWeight.w600,
        ),
        const AppSizedBox(height: 16),
        _buildPricingTile(
          "Morning (6 AM - 4 PM)",
          _morningPriceController,
          Icons.wb_sunny_outlined,
        ),
        _buildPricingTile(
          "Evening (4 PM - 8 PM)",
          _eveningPriceController,
          Icons.wb_twilight,
        ),
        _buildPricingTile(
          "Night (8 PM - 12 AM)",
          _nightPriceController,
          Icons.nightlight_round,
        ),
      ],
    );
  }

  Widget _buildPricingTile(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF6B00), size: 20),
          const AppSizedBox(width: 12),
          Expanded(child: AppText(text: label, size: 14)),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                prefixText: "₹ ",
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6B00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2And3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          text: "Timing & Photos",
          size: 20,
          weight: FontWeight.w700,
        ),
        const AppSizedBox(height: 24),
        _buildLabel("Operating Hours"),
        Row(
          children: [
            Expanded(
              child: _buildTimeTile(
                "Opening",
                _openingTime,
                () => _selectTime(context, true),
              ),
            ),
            const AppSizedBox(width: 16),
            Expanded(
              child: _buildTimeTile(
                "Closing",
                _closingTime,
                () => _selectTime(context, false),
              ),
            ),
          ],
        ),
        const AppSizedBox(height: 24),
        _buildLabel("Amenities"),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allAmenities.map((amenity) {
            bool isSelected = _selectedAmenities.contains(amenity);
            return FilterChip(
              label: AppText(
                text: amenity,
                size: 12,
                color: isSelected ? Colors.white : Colors.black,
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAmenities.add(amenity);
                  } else {
                    _selectedAmenities.remove(amenity);
                  }
                });
              },
              selectedColor: const Color(0xFFFF6B00),
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
        const AppSizedBox(height: 24),
        _buildLabel("Upload Photos"),
        const AppSizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _selectedImages.length + 1,
          itemBuilder: (context, index) {
            if (index == _selectedImages.length) {
              return GestureDetector(
                onTap: _pickImages,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.add_a_photo, color: Colors.grey),
                ),
              );
            }
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'https://placehold.co/150',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedImages.removeAt(index)),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: AppText(
        text: text,
        size: 14,
        weight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTimeTile(String label, TimeOfDay time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(text: label, size: 12, color: Colors.grey),
            const AppSizedBox(height: 4),
            AppText(
              text: time.format(context),
              size: 16,
              weight: FontWeight.w700,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6B00)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
