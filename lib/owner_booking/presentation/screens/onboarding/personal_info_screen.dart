import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/owner_booking/presentation/blocs/auth/auth_state.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/common/widgets/onboarding_layout.dart';
import 'package:toastification/toastification.dart';
import 'package:turfpro_owner/utils/auth_helper.dart';
import 'package:turfpro_owner/utils/form_util.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _searchController = TextEditingController();
  
  List<Map<String, String>> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Set initial prefilled values from firebase auth helper if available
    _emailController.text = currentUserEmail ?? "";
    _phoneController.text = currentUserPhone ?? "";
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
          _nameController.text = data['owner_name'] ?? '';
          if (data['business_email'] != null && data['business_email'].toString().isNotEmpty) {
            _emailController.text = data['business_email'];
          }
          if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
            _phoneController.text = data['phone'];
          }
          _cityController.text = data['city'] ?? '';
          _stateController.text = data['state'] ?? '';
          
          if (_cityController.text.isNotEmpty && _stateController.text.isNotEmpty) {
            _searchController.text = "${_cityController.text}, ${_stateController.text}";
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().length < 3) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
        return;
      }

      setState(() {
        _isSearching = true;
      });

      final results = await _fetchCitiesFromApi(query.trim());

      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    });
  }

  Future<List<Map<String, String>>> _fetchCitiesFromApi(String query) async {
    final urlString = 'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(query)}&count=10&language=en&format=json';
    debugPrint("DEBUG CITIES: Initializing search for query: '$query'");
    debugPrint("DEBUG CITIES: Request URL: $urlString");

    try {
      final response = await http.get(Uri.parse(urlString));
      debugPrint("DEBUG CITIES: Status Code: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final res = data['results'] as List?;
        debugPrint("DEBUG CITIES: Results returned from API: ${res?.length ?? 0}");
        
        if (res == null) return [];

        final List<Map<String, String>> results = [];
        for (var e in res) {
          if (e is! Map) continue;
          final countryCode = e['country_code'] as String? ?? "";
          final cityName = e['name'] as String? ?? "";
          final stateName = e['admin1'] as String? ?? "";
          
          debugPrint("DEBUG CITIES: Suggestion found -> City: '$cityName', State: '$stateName', Country: '$countryCode'");
          
          if (countryCode == 'IN') {
            if (cityName.isNotEmpty && stateName.isNotEmpty) {
              final alreadyAdded = results.any((r) => 
                r['city']!.toLowerCase() == cityName.toLowerCase() && 
                r['state']!.toLowerCase() == stateName.toLowerCase()
              );
              
              if (!alreadyAdded) {
                results.add({
                  'city': cityName,
                  'state': stateName,
                });
              }
            }
          }
        }
        
        debugPrint("DEBUG CITIES: Successfully filtered ${results.length} Indian cities.");
        return results;
      } else {
        debugPrint("DEBUG CITIES: Non-200 status code returned: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      debugPrint("DEBUG CITIES: Exception caught: $e");
      debugPrint("DEBUG CITIES: StackTrace: $stackTrace");
    }
    return [];
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      if (_cityController.text.isEmpty || _stateController.text.isEmpty) {
        toastification.show(
          context: context,
          type: ToastificationType.warning,
          title: const Text("Please search and select your City & State"),
          autoCloseDuration: const Duration(seconds: 4),
        );
        return;
      }

      context.read<AuthCubit>().savePersonalInfo(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    } else {
      FormUtil.scrollToError(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            currentStep: 1,
            title: "Personal Information",
            subtitle: "Tell us about yourself — the account owner",
            isLoading: state is AuthLoading,
            showBackButton: false,
            onNext: _onSave,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("FULL NAME *"),
                  _buildTextField(_nameController, "e.g. Rajesh Patel", validator: (val) {
                    if (val == null || val.trim().isEmpty) return "Full Name is required";
                    return null;
                  }),
                  const AppSizedBox(height: 20),
                  
                  _buildLabel("MOBILE NUMBER *"),
                  _buildPhoneField(),
                  const AppSizedBox(height: 20),
                  
                  _buildLabel("EMAIL ADDRESS *"),
                  _buildTextField(
                    _emailController, 
                    "rajesh@example.com", 
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return "Email Address is required";
                      final emailReg = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailReg.hasMatch(val.trim())) return "Enter a valid email address";
                      return null;
                    }
                  ),
                  const AppSizedBox(height: 20),

                  _buildLabel("SEARCH CITY & STATE *"),
                  _buildSearchField(),
                  const AppSizedBox(height: 20),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("CITY"),
                            _buildReadOnlyField(_cityController, "City"),
                          ],
                        ),
                      ),
                      const AppSizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("STATE"),
                            _buildReadOnlyField(_stateController, "State"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppText(
        text: label,
        size: 12,
        weight: FontWeight.w700,
        color: AppColors.textSecondaryLight,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondaryLight.withOpacity(0.4)),
        filled: true,
        fillColor: const Color(0xFFF0F9F4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryDarkGreen, width: 2),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: false,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondaryLight.withOpacity(0.4)),
        filled: true,
        fillColor: const Color(0xFFE2F3E9), // Darker green to emphasize read-only state
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.2)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.1)),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Column(
      children: [
        TextFormField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            hintText: "Type at least 3 letters to search...",
            hintStyle: TextStyle(color: AppColors.textSecondaryLight.withOpacity(0.4)),
            filled: true,
            fillColor: const Color(0xFFF0F9F4),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: const Icon(Icons.search, color: AppColors.primaryDarkGreen),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryDarkGreen,
                      ),
                    ),
                  )
                : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _cityController.clear();
                            _stateController.clear();
                            _suggestions = [];
                          });
                        },
                      )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryDarkGreen, width: 2),
            ),
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          const AppSizedBox(height: 4),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.15)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: AppColors.primaryDarkGreen.withOpacity(0.1),
                ),
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.location_on, color: AppColors.primaryDarkGreen),
                    title: AppText(
                      text: "${item['city']}, ${item['state']}",
                      size: 15,
                      weight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                    subtitle: const AppText(
                      text: "India",
                      size: 12,
                      color: Colors.grey,
                    ),
                    hoverColor: const Color(0xFFF0F9F4),
                    onTap: () {
                      setState(() {
                        _cityController.text = item['city']!;
                        _stateController.text = item['state']!;
                        _searchController.text = "${item['city']}, ${item['state']}";
                        _suggestions = [];
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      validator: (val) {
        if (val == null || val.trim().isEmpty) return "Mobile Number is required";
        final phoneReg = RegExp(r'^\+?[0-9]{10,12}$');
        if (!phoneReg.hasMatch(val.trim())) return "Enter a valid 10-digit mobile number";
        return null;
      },
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: "Enter Mobile Number",
        hintStyle: TextStyle(color: AppColors.textSecondaryLight.withOpacity(0.4)),
        filled: true,
        fillColor: const Color(0xFFF0F9F4),
        prefixIcon: const Icon(Icons.phone, color: AppColors.primaryDarkGreen),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDarkGreen.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryDarkGreen, width: 2),
        ),
      ),
    );
  }
}
