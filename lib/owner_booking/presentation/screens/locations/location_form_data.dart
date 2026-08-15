class LocationFormData {
  final String? locationId;
  
  // Step 1: Basic Info
  final String address;
  final String city;
  final String description;
  final String privacyPolicy;
  final String googleMapsLink;
  final double latitude;
  final double longitude;

  // Step 2: Amenities
  final List<String> amenities;

  // Step 3: Documents & Images
  final String propertyStatus; // 'Owned Property', 'Leased', etc.
  final String? propertyDocumentUrl; // remote URL or local path
  final String? nocUrl; // remote URL or local path
  final List<String> images; // remote URLs or local paths

  LocationFormData({
    this.locationId,
    required this.address,
    required this.city,
    required this.description,
    required this.privacyPolicy,
    required this.googleMapsLink,
    required this.latitude,
    required this.longitude,
    required this.amenities,
    required this.propertyStatus,
    this.propertyDocumentUrl,
    this.nocUrl,
    required this.images,
  });

  factory LocationFormData.empty() {
    return LocationFormData(
      address: '',
      city: '',
      description: '',
      privacyPolicy: '',
      googleMapsLink: '',
      latitude: 0.0,
      longitude: 0.0,
      amenities: [],
      propertyStatus: 'Owned Property',
      images: [],
    );
  }

  factory LocationFormData.fromMap(Map<String, dynamic> map) {
    List<String> parsedImages = [];
    if (map['location_images'] != null && map['location_images'] is List) {
      for (var img in map['location_images']) {
        if (img['image_url'] != null) {
          parsedImages.add(img['image_url'].toString());
        }
      }
    }

    return LocationFormData(
      locationId: map['id']?.toString(),
      address: map['address']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      privacyPolicy: map['privacy_policy']?.toString() ?? '',
      googleMapsLink: map['google_maps_link']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      amenities: (map['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [],
      propertyStatus: map['property_status']?.toString() ?? 'Owned Property',
      propertyDocumentUrl: map['property_document_url']?.toString(),
      nocUrl: map['noc_url']?.toString(),
      images: parsedImages,
    );
  }

  LocationFormData copyWith({
    String? locationId,
    String? address,
    String? city,
    String? description,
    String? privacyPolicy,
    String? googleMapsLink,
    double? latitude,
    double? longitude,
    List<String>? amenities,
    String? propertyStatus,
    String? propertyDocumentUrl,
    String? nocUrl,
    List<String>? images,
  }) {
    return LocationFormData(
      locationId: locationId ?? this.locationId,
      address: address ?? this.address,
      city: city ?? this.city,
      description: description ?? this.description,
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      googleMapsLink: googleMapsLink ?? this.googleMapsLink,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      amenities: amenities ?? this.amenities,
      propertyStatus: propertyStatus ?? this.propertyStatus,
      propertyDocumentUrl: propertyDocumentUrl ?? this.propertyDocumentUrl,
      nocUrl: nocUrl ?? this.nocUrl,
      images: images ?? this.images,
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'address': address,
      'city': city,
      'description': description,
      'privacy_policy': privacyPolicy,
      'google_maps_link': googleMapsLink,
      'latitude': latitude,
      'longitude': longitude,
      'amenities': amenities,
      'property_status': propertyStatus,
      // URLs will be updated separately or included if they are already remote URLs
    };
  }
}
