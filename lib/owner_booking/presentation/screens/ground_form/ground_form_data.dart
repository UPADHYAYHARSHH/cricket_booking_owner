class GroundFormData {
  final String? groundId;
  final String locationId;
  final String name;
  final String description;
  final String category; // single sport ID
  final String openingTime; // "06:00"
  final String closingTime; // "23:00"
  final List<String> operatingDays;
  final String slotDuration;
  final String advanceBookingLimit;
  final Map<String, int> pricingConfig; // weekday/weekend/morning/evening/night
  final List<String> imageUrls;
  final bool isVerified;

  const GroundFormData({
    this.groundId,
    required this.locationId,
    required this.name,
    required this.description,
    required this.category,
    required this.openingTime,
    required this.closingTime,
    required this.operatingDays,
    required this.slotDuration,
    required this.advanceBookingLimit,
    required this.pricingConfig,
    required this.imageUrls,
    this.isVerified = false,
  });

  factory GroundFormData.empty() => const GroundFormData(
        groundId: null,
        locationId: '',
        name: '',
        description: '',
        category: '',
        openingTime: '06:00',
        closingTime: '23:00',
        operatingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        slotDuration: '1 Hour',
        advanceBookingLimit: '7 days',
        pricingConfig: {
          'weekday': 600,
          'weekend': 800,
        },
        imageUrls: [],
        isVerified: false,
      );

  factory GroundFormData.fromMap(Map<String, dynamic> map) {
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

    return GroundFormData(
      groundId: map['id'] as String?,
      locationId: map['location_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      openingTime: map['opening_time'] as String? ?? '06:00',
      closingTime: map['closing_time'] as String? ?? '23:00',
      operatingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      slotDuration: '1 Hour',
      advanceBookingLimit: '7 days',
      pricingConfig: pricingConfig,
      imageUrls: imageUrls,
      isVerified: map['is_verified'] as bool? ?? false,
    );
  }

  int get basePrice => pricingConfig['weekday'] ?? 600;

  Map<String, dynamic> toDbMap({required String ownerId}) {
    return {
      'owner_id': ownerId,
      'location_id': locationId,
      'name': name,
      'description': description,
      'category': category,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'price_per_hour': basePrice,
      'weekend_price': pricingConfig['weekend'] ?? 800,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'price_per_hour': basePrice,
      'weekend_price': pricingConfig['weekend'] ?? 800,
    };
  }

  GroundFormData copyWith({
    String? groundId,
    String? locationId,
    String? name,
    String? description,
    String? category,
    String? openingTime,
    String? closingTime,
    List<String>? operatingDays,
    String? slotDuration,
    String? advanceBookingLimit,
    Map<String, int>? pricingConfig,
    List<String>? imageUrls,
    bool? isVerified,
  }) {
    return GroundFormData(
      groundId: groundId ?? this.groundId,
      locationId: locationId ?? this.locationId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      operatingDays: operatingDays ?? this.operatingDays,
      slotDuration: slotDuration ?? this.slotDuration,
      advanceBookingLimit: advanceBookingLimit ?? this.advanceBookingLimit,
      pricingConfig: pricingConfig ?? this.pricingConfig,
      imageUrls: imageUrls ?? this.imageUrls,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
