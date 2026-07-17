import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_button.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/common/widgets/app_text_field.dart';
import 'package:turfpro_owner/common/widgets/section_header.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/utils/auth_helper.dart';
import 'package:turfpro_owner/utils/form_util.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _addressController = TextEditingController();
  final _searchController = TextEditingController();

  XFile? _panCardImage;
  XFile? _aadhaarCardImage;
  XFile? _businessRegImage;

  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  bool _isMapLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchExistingDetails();
  }

  Future<void> _fetchExistingDetails() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final data = await Supabase.instance.client
          .from('owner_details')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data != null) {
        setState(() {
          _businessNameController.text = data['business_name'] ?? '';
          _ownerNameController.text = data['owner_name'] ?? '';
          _businessEmailController.text = data['business_email'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _businessEmailController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    if (!kIsWeb) {
      var status = await Permission.photos.status;
      if (status.isDenied) status = await Permission.photos.request();
      if (status.isPermanentlyDenied) {
        _showPermissionDialog("Photo Library");
        return;
      }
      if (!(status.isGranted || status.isLimited)) return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        if (type == 'pan') _panCardImage = image;
        if (type == 'aadhaar') _aadhaarCardImage = image;
        if (type == 'business') _businessRegImage = image;
      });
    }
  }

  void _showPermissionDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$permissionName Permission Required"),
        content: Text(
          "Please enable $permissionName permission in settings to continue.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text("Settings"),
          ),
        ],
      ),
    );
  }

  void _removeImage(String type) {
    setState(() {
      if (type == 'pan') _panCardImage = null;
      if (type == 'aadhaar') _aadhaarCardImage = null;
      if (type == 'business') _businessRegImage = null;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isMapLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        _showPermissionDialog("Location");
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      await _updateLocation(latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
    } catch (e) {
      debugPrint("Location error: $e");
    } finally {
      setState(() => _isMapLoading = false);
    }
  }

  Future<void> _updateLocation(LatLng latLng) async {
    setState(() => _selectedLocation = latLng);
    if (kIsWeb) return;
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final address =
            "${p.name}, ${p.subLocality}, ${p.locality}, ${p.postalCode}";
        setState(() => _addressController.text = address);
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
  }

  Future<void> _searchPlace(String query) async {
    if (query.isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final latLng = LatLng(loc.latitude, loc.longitude);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
        _updateLocation(latLng);
      }
    } catch (e) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: const Text("Location Error"),
        description: const Text("Location not found"),
        autoCloseDuration: const Duration(seconds: 4),
      );
    }
  }

  Future<String?> _uploadFile(XFile? file, String folder) async {
    if (file == null) return null;
    final userId = currentUserId;
    if (userId == null) return null;

    final fileExt = file.name.split('.').last;
    final fileName =
        '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final path = '$folder/$fileName';

    try {
      final bytes = await file.readAsBytes();
      await Supabase.instance.client.storage
          .from('documents')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return Supabase.instance.client.storage
          .from('documents')
          .getPublicUrl(path);
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  void _onNext() {
    if (_formKey.currentState!.validate()) {
      if (_panCardImage == null || _aadhaarCardImage == null) {
        toastification.show(
          context: context,
          type: ToastificationType.warning,
          style: ToastificationStyle.flatColored,
          title: const Text("Missing Documents"),
          description: const Text("Please upload both PAN and Aadhaar cards"),
          autoCloseDuration: const Duration(seconds: 4),
        );
        return;
      }

      // Partial save to database to persist Step 1 progress
      context.read<AuthCubit>().savePartialDetails(
        businessName: _businessNameController.text.trim(),
        businessEmail: _businessEmailController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
      );

      setState(() => _currentStep = 1);
    } else {
      FormUtil.scrollToError(context);
    }
  }

  void _submit() async {
    if (_selectedLocation == null) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.flatColored,
        title: const Text("Location Required"),
        description: const Text("Please select location on map"),
        autoCloseDuration: const Duration(seconds: 4),
      );
      return;
    }
    if (_addressController.text.isEmpty) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        style: ToastificationStyle.flatColored,
        title: const Text("Address Required"),
        description: const Text("Please provide a detailed address"),
        autoCloseDuration: const Duration(seconds: 4),
      );
      return;
    }

    context.read<AuthCubit>().emitLoading();

    final panUrl = await _uploadFile(_panCardImage, 'pan_cards');
    final aadharUrl = await _uploadFile(_aadhaarCardImage, 'aadhar_cards');
    final businessRegUrl = await _uploadFile(_businessRegImage, 'business_reg');

    if (panUrl != null && aadharUrl != null) {
      context.read<AuthCubit>().uploadDocuments(
        businessName: _businessNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        businessEmail: _businessEmailController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        panUrl: panUrl,
        aadharUrl: aadharUrl,
        businessRegUrl: businessRegUrl,
      );
    } else {
      context.read<AuthCubit>().emitError(
        "Failed to upload images. Ensure 'documents' bucket exists in Supabase.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flatColored,
            title: const Text("Registration Successful"),
            description: const Text(
              "Your profile has been submitted for review",
            ),
            autoCloseDuration: const Duration(seconds: 5),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (route) => false,
          );
        }
        if (state is AuthError) {
          toastification.show(
            context: context,
            type: ToastificationType.error,
            style: ToastificationStyle.flatColored,
            title: const Text("Submission Failed"),
            description: Text(state.message),
            autoCloseDuration: const Duration(seconds: 5),
          );
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Scaffold(
            backgroundColor: AppColors.bgLight,
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 20,
                ),
                onPressed: () => _currentStep > 0
                    ? setState(() => _currentStep--)
                    : Navigator.pop(context),
              ),
              title: AppText(
                text: _currentStep == 0 ? "Complete Profile" : "Turf Location",
                size: 18,
                weight: FontWeight.w700,
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: AppText(
                      text: "Step ${_currentStep + 1}/2",
                      size: 13,
                      weight: FontWeight.w600,
                      color: AppColors.primaryDarkGreen,
                    ),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: _currentStep == 0
                      ? _buildStep1(isLoading)
                      : _buildStep2(isLoading),
                ),
                _buildBottomAction(isLoading),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep1(bool isLoading) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressIndicator(),
            const AppSizedBox(height: 24),
            _SectionHeader(
              icon: Icons.business_rounded,
              title: "Business Details",
              subtitle: "Enter your turf business info",
              color: AppColors.primaryDarkGreen,
            ),
            const AppSizedBox(height: 16),
            _CustomTextField(
              controller: _businessNameController,
              label: "Business Name",
              hint: "e.g. Shiv Shakti Turf",
              icon: Icons.sports_soccer_rounded,
              enabled: !isLoading,
              validator: (v) => v?.isEmpty ?? true ? "Required" : null,
            ),
            const AppSizedBox(height: 14),
            _CustomTextField(
              controller: _ownerNameController,
              label: "Owner Name",
              hint: "e.g. Shivraj Patel",
              icon: Icons.person_rounded,
              enabled: !isLoading,
              validator: (v) => v?.isEmpty ?? true ? "Required" : null,
            ),
            const AppSizedBox(height: 14),
            _CustomTextField(
              controller: _businessEmailController,
              label: "Email",
              hint: "e.g. shiv@gmail.com",
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              enabled: !isLoading,
              validator: (v) => (v?.isEmpty ?? true) ? "Required" : null,
            ),
            const AppSizedBox(height: 28),
            _SectionHeader(
              icon: Icons.verified_user_rounded,
              title: "KYC Documents",
              subtitle: "Upload clear photos",
              color: AppColors.primaryDarkGreen,
            ),
            const AppSizedBox(height: 16),
            _DocumentUploadCard(
              label: "PAN Card",
              subtitle: "Upload front side",
              icon: Icons.credit_card_rounded,
              imageXFile: _panCardImage,
              isRequired: true,
              onTap: () => _pickImage('pan'),
              onRemove: () => _removeImage('pan'),
              isLoading: isLoading,
              color: AppColors.primaryDarkGreen,
            ),
            const AppSizedBox(height: 14),
            _DocumentUploadCard(
              label: "Aadhaar Card",
              subtitle: "Upload front side",
              icon: Icons.badge_rounded,
              imageXFile: _aadhaarCardImage,
              isRequired: true,
              onTap: () => _pickImage('aadhaar'),
              onRemove: () => _removeImage('aadhaar'),
              isLoading: isLoading,
              color: AppColors.primaryDarkGreen,
            ),
            const AppSizedBox(height: 14),
            _DocumentUploadCard(
              label: "Business Registration",
              subtitle: "Optional",
              icon: Icons.description_rounded,
              imageXFile: _businessRegImage,
              isRequired: false,
              onTap: () => _pickImage('business'),
              onRemove: () => _removeImage('business'),
              isLoading: isLoading,
              color: AppColors.primaryDarkGreen,
            ),
            const AppSizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(bool isLoading) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(20.5937, 78.9629),
                  zoom: 5,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _getCurrentLocation();
                },
                onCameraMove: (position) => _selectedLocation = position.target,
                onCameraIdle: () => _selectedLocation != null
                    ? _updateLocation(_selectedLocation!)
                    : null,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 35),
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.primaryDarkGreen,
                    size: 40,
                  ),
                ),
              ),

              /// Search Bar
              Positioned(
                top: 20,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search location...",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primaryDarkGreen,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _searchPlace,
                  ),
                ),
              ),

              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: _getCurrentLocation,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: AppColors.primaryDarkGreen),
                ),
              ),
              if (_isMapLoading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryDarkGreen),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                text: "Turf Address",
                weight: FontWeight.w700,
                size: 16,
              ),
              const AppSizedBox(height: 12),
              _CustomTextField(
                controller: _addressController,
                label: "Detailed Address",
                hint: kIsWeb
                    ? "Type address manually on Web"
                    : "Select location on map",
                icon: Icons.location_on_rounded,
                maxLines: 2,
                enabled: !isLoading,
              ),
              const AppSizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: AppButton(
        title: _currentStep == 0 ? "Continue to Location" : "Submit Documents",
        isLoading: isLoading,
        onTap: _currentStep == 0 ? _onNext : _submit,
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _StepDot(
            label: "Details",
            icon: Icons.business_rounded,
            isActive: _currentStep >= 0,
            color: AppColors.primaryDarkGreen,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: _currentStep >= 1
                    ? AppColors.primaryDarkGreen
                    : AppColors.borderLight,
              ),
            ),
          ),
          _StepDot(
            label: "Location",
            icon: Icons.map_rounded,
            isActive: _currentStep >= 1,
            color: AppColors.primaryDarkGreen,
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color color;
  const _StepDot({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? color : AppColors.borderLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? Colors.white : Colors.grey,
          ),
        ),
        const AppSizedBox(height: 4),
        AppText(
          text: label,
          size: 11,
          weight: FontWeight.w600,
          color: isActive ? color : Colors.grey,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const AppSizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(text: title, size: 16, weight: FontWeight.w700),
            AppText(text: subtitle, size: 12, color: Colors.grey),
          ],
        ),
      ],
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  final bool enabled;
  final String? Function(String?)? validator;
  const _CustomTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.enabled = true,
    this.validator,
  });
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      validator: validator,
      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryDarkGreen, size: 20),
      ),
    );
  }
}

class _DocumentUploadCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final XFile? imageXFile;
  final bool isRequired;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final bool isLoading;
  final Color color;
  _DocumentUploadCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    this.imageXFile,
    required this.isRequired,
    required this.onTap,
    required this.onRemove,
    required this.isLoading,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageXFile != null;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasImage ? AppColors.success : AppColors.borderLight,
            width: hasImage ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: hasImage
                      ? Colors.transparent
                      : AppColors.bgLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasImage
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.borderLight,
                  ),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(
                          imageXFile!.path,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: AppColors.textSecondaryLight, size: 26),
                          const AppSizedBox(height: 4),
                          const AppText(
                            text: "Tap to add",
                            size: 10,
                            color: AppColors.textSecondaryLight,
                          ),
                        ],
                      ),
              ),
              const AppSizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppText(text: label, size: 14, weight: FontWeight.w700),
                        if (isRequired) ...[
                          const AppSizedBox(width: 4),
                          const Text(
                            "*",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const AppSizedBox(height: 3),
                    AppText(text: subtitle, size: 12, color: Colors.grey),
                    const AppSizedBox(height: 8),
                    if (hasImage)
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 14,
                          ),
                          const AppSizedBox(width: 4),
                          const AppText(
                            text: "Selected",
                            size: 12,
                            color: AppColors.success,
                            weight: FontWeight.w600,
                          ),
                          const AppSizedBox(width: 8),
                          GestureDetector(
                            onTap: onTap,
                            child: AppText(
                              text: "Change",
                              size: 12,
                              color: color,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const AppSizedBox(width: 12),
                          GestureDetector(
                            onTap: onRemove,
                            child: const AppText(
                              text: "Remove",
                              size: 12,
                              color: Colors.redAccent,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.upload_rounded, color: color, size: 14),
                            const AppSizedBox(width: 4),
                            AppText(
                              text: "Upload",
                              size: 12,
                              color: color,
                              weight: FontWeight.w600,
                            ),
                          ],
                        ),
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
}
