import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:turfpro_owner/utils/auth_helper.dart';
import 'package:turfpro_owner/blocs/auth/auth_cubit.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/widgets/app_sized_box.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/common/widgets/onboarding_layout.dart';
import 'package:toastification/toastification.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class PhotosMediaScreen extends StatefulWidget {
  const PhotosMediaScreen({super.key});

  @override
  State<PhotosMediaScreen> createState() => _PhotosMediaScreenState();
}

class _PhotosMediaScreenState extends State<PhotosMediaScreen> {
  final _youtubeController = TextEditingController();
  final _picker = ImagePicker();

  File? _coverPhoto;
  String? _coverPhotoUrl;

  final Map<String, List<File>> _courtPhotos = {};
  final Map<String, List<String>> _courtPhotoUrls = {};
  
  List<File> _amenityPhotosList = [];
  List<String> _amenityPhotoUrlsList = [];

  File? _videoFile;
  String? _videoUrl;

  List<String> _courtNames = [];
  List<String> _selectedAmenities = [];

  bool _isLoadingData = true;
  bool _isUploading = false;

  final Map<String, String> _amenityLabels = {
    'parking': 'Parking',
    'washrooms': 'Washrooms',
    'changing_rooms': 'Changing Rooms',
    'drinking_water': 'Drinking Water',
    'waiting_area': 'Waiting Area',
    'cafeteria': 'Cafeteria',
    'vending_machine': 'Vending Machine',
    'water_dispenser': 'Water Dispenser',
  };

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final data = await Supabase.instance.client
          .from('owner_details')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        final groundConfig = data['ground_config'] as Map? ?? {};
        final amenitiesConfig = data['amenities_config'] as Map? ?? {};
        final mediaConfig = data['media_config'] as Map? ?? {};

        setState(() {
          // Extract court names
          _courtNames = [];
          groundConfig.forEach((sport, config) {
            final courts = config['courts'] as List? ?? [];
            for (var court in courts) {
              if (court['name'] != null) _courtNames.add(court['name']);
            }
          });

          // Extract selected amenities
          _selectedAmenities = [];
          amenitiesConfig.forEach((key, value) {
            if (value == true && _amenityLabels.containsKey(key)) {
              _selectedAmenities.add(key);
            }
          });

          // Pre-fill existing media
          _coverPhotoUrl = mediaConfig['cover_url'];
          _videoUrl = mediaConfig['video_url'];
          _youtubeController.text = mediaConfig['youtube_link'] ?? '';

          final existingCourts = mediaConfig['court_media'] as Map? ?? {};
          existingCourts.forEach((name, urls) {
            _courtPhotoUrls[name] = List<String>.from(urls);
          });

          final existingAmenities = mediaConfig['amenity_media'] as Map? ?? {};
          if (existingAmenities.containsKey('all')) {
            _amenityPhotoUrlsList = List<String>.from(existingAmenities['all']);
          } else {
            _amenityPhotoUrlsList = [];
            existingAmenities.forEach((key, urls) {
              _amenityPhotoUrlsList.addAll(List<String>.from(urls));
            });
          }

          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _pickImage(String type, {String? key, bool isCover = false}) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      if (isCover) {
        _coverPhoto = File(image.path);
      } else if (type == 'court' && key != null) {
        _courtPhotos.putIfAbsent(key, () => []).add(File(image.path));
      }
    });
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.pickFiles(type: FileType.video);
    if (result != null) {
      setState(() => _videoFile = File(result.files.single.path!));
    }
  }

  Future<String?> _uploadFile(File file, String folder) async {
    final userId = currentUserId;
    if (userId == null) return null;

    final fileName = "${userId}/$folder/${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}";
    
    try {
      await Supabase.instance.client.storage
          .from('venue_media')
          .upload(fileName, file);

      return Supabase.instance.client.storage
          .from('venue_media')
          .getPublicUrl(fileName);
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  void _onSave() async {
    if (_coverPhoto == null && _coverPhotoUrl == null) {
      toastification.show(context: context, type: ToastificationType.warning, title: const Text("Please upload a cover photo"));
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? finalCoverUrl = _coverPhotoUrl;
      if (_coverPhoto != null) {
        finalCoverUrl = await _uploadFile(_coverPhoto!, 'cover');
      }

      final Map<String, List<String>> finalCourtMedia = Map.from(_courtPhotoUrls);
      for (var entry in _courtPhotos.entries) {
        final List<String> urls = finalCourtMedia[entry.key] ?? [];
        for (var file in entry.value) {
          final url = await _uploadFile(file, 'courts');
          if (url != null) urls.add(url);
        }
        finalCourtMedia[entry.key] = urls;
      }

      final List<String> finalAmenityUrls = List.from(_amenityPhotoUrlsList);
      for (var file in _amenityPhotosList) {
        final url = await _uploadFile(file, 'amenities');
        if (url != null) finalAmenityUrls.add(url);
      }
      final Map<String, List<String>> finalAmenityMedia = {
        'all': finalAmenityUrls,
      };

      String? finalVideoUrl = _videoUrl;
      if (_videoFile != null) {
        finalVideoUrl = await _uploadFile(_videoFile!, 'videos');
      }

      final config = {
        'cover_url': finalCoverUrl,
        'court_media': finalCourtMedia,
        'amenity_media': finalAmenityMedia,
        'video_url': finalVideoUrl,
        'youtube_link': _youtubeController.text.trim(),
      };

      context.read<AuthCubit>().saveMediaConfig(mediaConfig: config);
    } catch (e) {
      toastification.show(context: context, type: ToastificationType.error, title: Text("Save failed: $e"));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return OnboardingLayout(
      currentStep: 9,
      title: "Photos & Media",
      subtitle: "Showcase your venue to attract more players",
      isLoading: _isUploading,
      onNext: _onSave,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPromoBanner(),
          const AppSizedBox(height: 32),
          
          _buildSectionHeader("COVER PHOTO *"),
          _buildCoverPicker(),
          
          const AppSizedBox(height: 32),
          _buildSectionHeader("COURT / GROUND PHOTOS *"),
          ..._courtNames.map((name) => _buildMediaCategory(name, name)),

          const AppSizedBox(height: 32),
          _buildSectionHeader("AMENITY PHOTOS"),
          _buildUnifiedAmenityPhotos(),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFBC02D).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Color(0xFFF57F17)),
          const AppSizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: Color(0xFFF57F17), fontSize: 13, height: 1.4),
                children: [
                  TextSpan(text: "Venues with ", style: TextStyle(fontWeight: FontWeight.w500)),
                  TextSpan(text: "8+ high-quality photos", style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: " get ", style: TextStyle(fontWeight: FontWeight.w500)),
                  TextSpan(text: "3x more bookings", style: TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: ". Add exterior, courts, amenities & facilities.", style: TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppText(text: title, size: 13, weight: FontWeight.w800, color: AppColors.textSecondaryLight.withOpacity(0.8), letterSpacing: 0.5),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: AppText(text: label, size: 12, weight: FontWeight.w700, color: AppColors.textSecondaryLight));
  }

  Widget _buildCoverPicker() {
    return GestureDetector(
      onTap: () => _pickImage('cover', isCover: true),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9F4),
          borderRadius: BorderRadius.circular(16),
          image: (_coverPhoto != null || _coverPhotoUrl != null)
            ? DecorationImage(
                image: _coverPhoto != null ? FileImage(_coverPhoto!) : NetworkImage(_coverPhotoUrl!) as ImageProvider,
                fit: BoxFit.cover,
              )
            : null,
        ),
        child: Stack(
          children: [
            if (_coverPhoto == null && _coverPhotoUrl == null)
              const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.primaryDarkGreen), AppSizedBox(height: 8), AppText(text: "Add Main Cover", size: 14, weight: FontWeight.w600, color: AppColors.primaryDarkGreen)])),
            PositionBag(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: const AppText(text: "Change", size: 11, color: Colors.white, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaCategory(String title, String key) {
    final List<File> files = _courtPhotos[key] ?? [];
    final List<String> urls = _courtPhotoUrls[key] ?? [];
    final int total = files.length + urls.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(title.toUpperCase()),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: total + 1,
            itemBuilder: (context, index) {
              if (index == total) {
                return _buildAddMore(() => _pickImage('court', key: key));
              }
              final isExisting = index < urls.length;
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: isExisting ? NetworkImage(urls[index]) : FileImage(files[index - urls.length]) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const AppSizedBox(height: 16),
      ],
    );
  }

  Widget _buildAddMore(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.2), style: BorderStyle.solid),
        ),
        child: const Icon(Icons.add, color: AppColors.primaryDarkGreen),
      ),
    );
  }

  Future<void> _pickAmenityImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isEmpty) return;

    setState(() {
      for (var image in images) {
        _amenityPhotosList.add(File(image.path));
      }
    });
  }

  Widget _buildUnifiedAmenityPhotos() {
    final total = _amenityPhotosList.length + _amenityPhotoUrlsList.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: total + 1,
            itemBuilder: (context, index) {
              if (index == total) {
                return GestureDetector(
                  onTap: _pickAmenityImages,
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.2)),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: AppColors.primaryDarkGreen, size: 28),
                        AppSizedBox(height: 8),
                        AppText(text: "Add Photos", size: 12, weight: FontWeight.w700, color: AppColors.primaryDarkGreen),
                      ],
                    ),
                  ),
                );
              }
              final isExisting = index < _amenityPhotoUrlsList.length;
              return Stack(
                children: [
                  Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: isExisting 
                          ? NetworkImage(_amenityPhotoUrlsList[index]) 
                          : FileImage(_amenityPhotosList[index - _amenityPhotoUrlsList.length]) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 18,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isExisting) {
                            _amenityPhotoUrlsList.removeAt(index);
                          } else {
                            _amenityPhotosList.removeAt(index - _amenityPhotoUrlsList.length);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class PositionBag extends StatelessWidget {
  final double? top, bottom, left, right;
  final Widget child;
  const PositionBag({super.key, this.top, this.bottom, this.left, this.right, required this.child});
  @override
  Widget build(BuildContext context) { return Positioned(top: top, bottom: bottom, left: left, right: right, child: child); }
}
