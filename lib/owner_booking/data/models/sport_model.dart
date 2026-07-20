class SportModel {
  final String id;
  final String name;
  final String slug;
  final String iconUrl;
  final String localAsset;
  final String color;
  final int sortOrder;
  final bool isActive;

  const SportModel({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl = '',
    this.localAsset = '',
    this.color = '#1B5E20',
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory SportModel.fromJson(Map<String, dynamic> json) {
    return SportModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      iconUrl: json['icon_url']?.toString() ?? '',
      localAsset: json['local_asset']?.toString() ?? '',
      color: json['color']?.toString() ?? '#1B5E20',
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon_url': iconUrl,
      'local_asset': localAsset,
      'color': color,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}
