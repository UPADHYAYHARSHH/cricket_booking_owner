import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:turfpro_owner/common/constants/colors.dart';
import 'package:turfpro_owner/common/constants/size_constants.dart';
import 'package:turfpro_owner/common/widgets/app_text.dart';
import 'package:turfpro_owner/utils/auth_helper.dart';
import 'package:intl/intl.dart';

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  bool _isLoadingLocations = true;
  bool _isLoadingReviews = false;
  List<Map<String, dynamic>> _locations = [];
  Map<String, dynamic>? _selectedLocation;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('locations')
          .select('id, name, rating, total_reviews')
          .eq('owner_id', userId);

      if (mounted) {
        setState(() {
          _locations = List<Map<String, dynamic>>.from(response);
          _isLoadingLocations = false;
          if (_locations.isNotEmpty) {
            _selectedLocation = _locations.first;
            _fetchReviews(_selectedLocation!['id']);
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching locations: $e");
      if (mounted) {
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  Future<void> _fetchReviews(String locationId) async {
    setState(() => _isLoadingReviews = true);
    try {
      final response = await Supabase.instance.client
          .from('location_reviews')
          .select()
          .eq('location_id', locationId)
          .order('created_at', ascending: false);

      if (mounted) {
        List<Map<String, dynamic>> rawReviews = List<Map<String, dynamic>>.from(response);
        
        // Try to fetch users manually
        final userIds = rawReviews.map((r) => r['user_id']).where((id) => id != null).toSet().toList();
        Map<String, dynamic> usersMap = {};
        
        if (userIds.isNotEmpty) {
          try {
            await Future.wait(userIds.map((uid) async {
              try {
                final userProfile = await Supabase.instance.client
                    .rpc('get_user_profile', params: {'p_id': uid});
                if (userProfile != null) {
                  usersMap[uid.toString()] = userProfile;
                }
              } catch (e) {
                debugPrint("Error fetching profile for $uid: $e");
              }
            }));
          } catch (e) {
            debugPrint("Error fetching users: $e");
          }
        }
        
        // Attach user info
        for (var i = 0; i < rawReviews.length; i++) {
          final uid = rawReviews[i]['user_id']?.toString();
          if (uid != null && usersMap.containsKey(uid)) {
            rawReviews[i]['users'] = usersMap[uid];
          }
        }

        setState(() {
          _reviews = rawReviews;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching reviews: $e");
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('User Ratings'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0.5,
      ),
      body: _isLoadingLocations
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryDarkGreen))
          : _locations.isEmpty
              ? const Center(
                  child: AppText(
                    text: 'No locations found.',
                    size: 16,
                    color: AppColors.textSecondaryLight,
                  ),
                )
              : Column(
                  children: [
                    _buildLocationSelector(),
                    Expanded(
                      child: _isLoadingReviews
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryDarkGreen))
                          : _reviews.isEmpty
                              ? _buildEmptyState()
                              : _buildReviewsList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPaddingHorizontal,
        vertical: AppSizes.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText(
            text: 'Select Location',
            size: 12,
            weight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
          const SizedBox(height: AppSizes.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              color: AppColors.surfaceLight,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedLocation?['id'],
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryDarkGreen),
                items: _locations.map((loc) {
                  return DropdownMenuItem<String>(
                    value: loc['id'],
                    child: AppText(
                      text: loc['name'] ?? 'Unnamed Location',
                      size: 15,
                      weight: FontWeight.w600,
                    ),
                  );
                }).toList(),
                onChanged: (newId) {
                  if (newId != null && newId != _selectedLocation?['id']) {
                    final newLoc = _locations.firstWhere((l) => l['id'] == newId);
                    setState(() {
                      _selectedLocation = newLoc;
                    });
                    _fetchReviews(newId);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          if (_selectedLocation != null) _buildOverallRatingCard(),
        ],
      ),
    );
  }

  Widget _buildOverallRatingCard() {
    final rating = (_selectedLocation!['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewsCount = _selectedLocation!['total_reviews'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.primaryDarkGreen.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                text: 'Overall Rating',
                size: 13,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  AppText(
                    text: rating.toStringAsFixed(1),
                    size: 24,
                    weight: FontWeight.w800,
                    color: AppColors.primaryDarkGreen,
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppColors.goldenYellow,
                        size: 20,
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusRound),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: AppText(
              text: '$reviewsCount reviews',
              size: 12,
              weight: FontWeight.w600,
              color: AppColors.primaryDarkGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border_rounded, size: 48, color: AppColors.borderLight),
          SizedBox(height: AppSizes.md),
          AppText(
            text: 'No ratings yet',
            size: 16,
            weight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.screenPaddingHorizontal),
      itemCount: _reviews.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSizes.md),
      itemBuilder: (context, index) {
        final review = _reviews[index];
        final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
        final reviewText = review['review_text'] ?? '';
        final createdAtStr = review['created_at'];
        final date = createdAtStr != null
            ? DateFormat('dd MMM yyyy').format(DateTime.parse(createdAtStr))
            : '';

        final user = review['users'];
        final userName = user != null && user['name'] != null ? user['name'] : 'User';
        final photoUrl = user != null ? user['photo_url'] : null;

        return Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryDarkGreen.withOpacity(0.1),
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null || photoUrl.isEmpty
                            ? const Icon(Icons.person, size: 18, color: AppColors.primaryDarkGreen)
                            : null,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      AppText(
                        text: userName,
                        size: 14,
                        weight: FontWeight.w600,
                      ),
                    ],
                  ),
                  AppText(
                    text: date,
                    size: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: List.generate(5, (starIndex) {
                  return Icon(
                    starIndex < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.goldenYellow,
                    size: 16,
                  );
                }),
              ),
              if (reviewText.isNotEmpty && reviewText != 'EMPTY') ...[
                const SizedBox(height: AppSizes.sm),
                AppText(
                  text: reviewText,
                  size: 14,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
