class GroundFormData {
  final String? groundId;
  final String locationId;
  final String category; // single sport ID
  final String openingTime; // "06:00"
  final String closingTime; // "23:00"
  final List<String> operatingDays;
  final String slotDuration;
  final String advanceBookingLimit;
  final Map<String, int> pricingConfig; // weekday/weekend/morning/evening/night
  final bool isVerified;

  const GroundFormData({
    this.groundId,
    required this.locationId,
    required this.category,
    required this.openingTime,
    required this.closingTime,
    required this.operatingDays,
    required this.slotDuration,
    required this.advanceBookingLimit,
    required this.pricingConfig,
    this.isVerified = false,
  });

  factory GroundFormData.empty() => const GroundFormData(
    groundId: null,
    locationId: '',
    category: '',
    openingTime: '06:00',
    closingTime: '23:00',
    operatingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    slotDuration: '1 Hour',
    advanceBookingLimit: '7 days',
    pricingConfig: {'weekday': 600, 'weekend': 800},
    isVerified: false,
  );

  factory GroundFormData.fromMap(Map<String, dynamic> map) {
    // Read weekday and weekend prices from DB columns.
    final Map<String, int> pricingConfig = {
      'weekday': (map['price_per_hour'] as num?)?.toInt() ?? 600,
      'weekend': (map['weekend_price'] as num?)?.toInt() ?? 800,
    };

    return GroundFormData(
      groundId: map['id'] as String?,
      locationId: map['location_id'] as String? ?? '',
      category: map['category'] as String? ?? '',
      openingTime: map['opening_time'] as String? ?? '06:00',
      closingTime: map['closing_time'] as String? ?? '23:00',
      operatingDays: (map['operating_days'] is List)
          ? (map['operating_days'] as List).map((e) => e.toString()).toList()
          : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      slotDuration: map['slot_duration'] as String? ?? '1 Hour',
      advanceBookingLimit: '7 days',
      pricingConfig: pricingConfig,
      isVerified: map['is_verified'] as bool? ?? false,
    );
  }

  int get basePrice => pricingConfig['weekday'] ?? 600;

  Map<String, dynamic> toDbMap({required String ownerId}) {
    return {
      'owner_id': ownerId,
      'location_id': locationId,
      'category': category,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'operating_days': operatingDays,
      'slot_duration': slotDuration,
      'price_per_hour': basePrice,
      'weekend_price': pricingConfig['weekend'] ?? 800,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'category': category,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'operating_days': operatingDays,
      'slot_duration': slotDuration,
      'price_per_hour': basePrice,
      'weekend_price': pricingConfig['weekend'] ?? 800,
    };
  }

  GroundFormData copyWith({
    String? groundId,
    String? locationId,
    String? category,
    String? openingTime,
    String? closingTime,
    List<String>? operatingDays,
    String? slotDuration,
    String? advanceBookingLimit,
    Map<String, int>? pricingConfig,
    bool? isVerified,
  }) {
    return GroundFormData(
      groundId: groundId ?? this.groundId,
      locationId: locationId ?? this.locationId,
      category: category ?? this.category,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      operatingDays: operatingDays ?? this.operatingDays,
      slotDuration: slotDuration ?? this.slotDuration,
      advanceBookingLimit: advanceBookingLimit ?? this.advanceBookingLimit,
      pricingConfig: pricingConfig ?? this.pricingConfig,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
