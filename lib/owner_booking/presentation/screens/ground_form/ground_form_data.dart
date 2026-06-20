class GroundFormData {
  final String? groundId;
  final String name;
  final String description;
  final List<String> categories; // sport IDs
  final Map<String, int> sportsConfig; // sport → court count
  final String address;
  final String city;
  final String googleMapsLink;
  final double latitude;
  final double longitude;
  final String openingTime; // "06:00"
  final String closingTime; // "23:00"
  final List<String> operatingDays;
  final String slotDuration;
  final String advanceBookingLimit;
  final Map<String, int> pricingConfig; // weekday/weekend/morning/evening/night
  final List<String> amenities;
  final List<String> imageUrls;
  final bool isVerified;

  const GroundFormData({
    this.groundId,
    required this.name,
    required this.description,
    required this.categories,
    required this.sportsConfig,
    required this.address,
    required this.city,
    required this.googleMapsLink,
    required this.latitude,
    required this.longitude,
    required this.openingTime,
    required this.closingTime,
    required this.operatingDays,
    required this.slotDuration,
    required this.advanceBookingLimit,
    required this.pricingConfig,
    required this.amenities,
    required this.imageUrls,
    this.isVerified = false,
  });

  factory GroundFormData.empty() => const GroundFormData(
        groundId: null,
        name: '',
        description: '',
        categories: [],
        sportsConfig: {},
        address: '',
        city: '',
        googleMapsLink: '',
        latitude: 0.0,
        longitude: 0.0,
        openingTime: '06:00',
        closingTime: '23:00',
        operatingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        slotDuration: '1 Hour',
        advanceBookingLimit: '7 days',
        pricingConfig: {
          'weekday': 600,
          'weekend': 800,
        },
        amenities: [],
        imageUrls: [],
        isVerified: false,
      );

  factory GroundFormData.fromMap(Map<String, dynamic> map) {
    final categories = List<String>.from(map['categories'] ?? []);

    // Read sports_config from DB if present, else derive from categories (1 court each).
    final rawSportsConfig = map['sports_config'];
    final Map<String, int> sportsConfig;
    if (rawSportsConfig is Map && rawSportsConfig.isNotEmpty) {
      sportsConfig = {
        for (final e in rawSportsConfig.entries)
          e.key as String: (e.value as num).toInt(),
      };
    } else {
      sportsConfig = {for (final cat in categories) cat: 1};
    }

    // Read weekday and weekend prices from DB columns.
    final Map<String, int> pricingConfig = {
      'weekday': (map['price_per_hour'] as num?)?.toInt() ?? 600,
      'weekend': (map['weekend_price'] as num?)?.toInt() ?? 800,
    };

    // Parse images from joined ground_images
    final imageUrls = <String>[];
    final images = map['ground_images'];
    if (images is List) {
      for (final img in images) {
        if (img is Map && img['image_url'] != null) {
          imageUrls.add(img['image_url'] as String);
        }
      }
    }

    // Parse amenities — stored as either List or comma-separated string
    final rawAmenities = map['amenities'];
    final amenities = rawAmenities is List
        ? List<String>.from(rawAmenities)
        : <String>[];

    return GroundFormData(
      groundId: map['id'] as String?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      categories: categories,
      sportsConfig: sportsConfig,
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      googleMapsLink: '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      openingTime: map['opening_time'] as String? ?? '06:00',
      closingTime: map['closing_time'] as String? ?? '23:00',
      operatingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      slotDuration: '1 Hour',
      advanceBookingLimit: '7 days',
      pricingConfig: pricingConfig,
      amenities: amenities,
      imageUrls: imageUrls,
      isVerified: map['is_verified'] as bool? ?? false,
    );
  }

  int get basePrice => pricingConfig['weekday'] ?? 600;

  /// Returns the map for Supabase update / insert (excludes sports_config stored nested in pricing).
  Map<String, dynamic> toDbMap({required String ownerId}) {
    return {
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'categories': categories,
      'sports_config': sportsConfig,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'amenities': amenities,
      'price_per_hour': basePrice,
      'weekend_price': pricingConfig['weekend'] ?? 800,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'description': description,
      'categories': categories,
      'sports_config': sportsConfig,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'amenities': amenities,
      'price_per_hour': basePrice,
      'weekend_price': pricingConfig['weekend'] ?? 800,
    };
  }

  GroundFormData copyWith({
    String? groundId,
    String? name,
    String? description,
    List<String>? categories,
    Map<String, int>? sportsConfig,
    String? address,
    String? city,
    String? googleMapsLink,
    double? latitude,
    double? longitude,
    String? openingTime,
    String? closingTime,
    List<String>? operatingDays,
    String? slotDuration,
    String? advanceBookingLimit,
    Map<String, int>? pricingConfig,
    List<String>? amenities,
    List<String>? imageUrls,
    bool? isVerified,
  }) {
    return GroundFormData(
      groundId: groundId ?? this.groundId,
      name: name ?? this.name,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      sportsConfig: sportsConfig ?? this.sportsConfig,
      address: address ?? this.address,
      city: city ?? this.city,
      googleMapsLink: googleMapsLink ?? this.googleMapsLink,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      operatingDays: operatingDays ?? this.operatingDays,
      slotDuration: slotDuration ?? this.slotDuration,
      advanceBookingLimit: advanceBookingLimit ?? this.advanceBookingLimit,
      pricingConfig: pricingConfig ?? this.pricingConfig,
      amenities: amenities ?? this.amenities,
      imageUrls: imageUrls ?? this.imageUrls,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
