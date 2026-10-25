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
    pricingConfig: {
      'weekday': 600,
      'weekend': 800,
      'morning': 0,
      'afternoon': 0,
      'evening': 0,
      'night': 0,
      'weekend_morning': 0,
      'weekend_afternoon': 0,
      'weekend_evening': 0,
      'weekend_night': 0,
    },
    isVerified: false,
  );

  factory GroundFormData.fromMap(Map<String, dynamic> map) {
    // Read weekday, weekend, and period prices from DB columns.
    final Map<String, int> pricingConfig = {
      'weekday': (map['price_per_hour'] as num?)?.toInt() ?? 600,
      'weekend': (map['weekend_price'] as num?)?.toInt() ?? 800,
      'morning': (map['morning_price'] as num?)?.toInt() ?? 0,
      'afternoon': (map['afternoon_price'] as num?)?.toInt() ?? 0,
      'evening': (map['evening_price'] as num?)?.toInt() ?? 0,
      'night': (map['night_price'] as num?)?.toInt() ?? 0,
      'weekend_morning': (map['weekend_morning_price'] as num?)?.toInt() ?? 0,
      'weekend_afternoon': (map['weekend_afternoon_price'] as num?)?.toInt() ?? 0,
      'weekend_evening': (map['weekend_evening_price'] as num?)?.toInt() ?? 0,
      'weekend_night': (map['weekend_night_price'] as num?)?.toInt() ?? 0,
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
      'morning_price': (pricingConfig['morning'] ?? 0) > 0 ? pricingConfig['morning'] : null,
      'afternoon_price': (pricingConfig['afternoon'] ?? 0) > 0 ? pricingConfig['afternoon'] : null,
      'evening_price': (pricingConfig['evening'] ?? 0) > 0 ? pricingConfig['evening'] : null,
      'night_price': (pricingConfig['night'] ?? 0) > 0 ? pricingConfig['night'] : null,
      'weekend_morning_price': (pricingConfig['weekend_morning'] ?? 0) > 0 ? pricingConfig['weekend_morning'] : null,
      'weekend_afternoon_price': (pricingConfig['weekend_afternoon'] ?? 0) > 0 ? pricingConfig['weekend_afternoon'] : null,
      'weekend_evening_price': (pricingConfig['weekend_evening'] ?? 0) > 0 ? pricingConfig['weekend_evening'] : null,
      'weekend_night_price': (pricingConfig['weekend_night'] ?? 0) > 0 ? pricingConfig['weekend_night'] : null,
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
      'morning_price': (pricingConfig['morning'] ?? 0) > 0 ? pricingConfig['morning'] : null,
      'afternoon_price': (pricingConfig['afternoon'] ?? 0) > 0 ? pricingConfig['afternoon'] : null,
      'evening_price': (pricingConfig['evening'] ?? 0) > 0 ? pricingConfig['evening'] : null,
      'night_price': (pricingConfig['night'] ?? 0) > 0 ? pricingConfig['night'] : null,
      'weekend_morning_price': (pricingConfig['weekend_morning'] ?? 0) > 0 ? pricingConfig['weekend_morning'] : null,
      'weekend_afternoon_price': (pricingConfig['weekend_afternoon'] ?? 0) > 0 ? pricingConfig['weekend_afternoon'] : null,
      'weekend_evening_price': (pricingConfig['weekend_evening'] ?? 0) > 0 ? pricingConfig['weekend_evening'] : null,
      'weekend_night_price': (pricingConfig['weekend_night'] ?? 0) > 0 ? pricingConfig['weekend_night'] : null,
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
