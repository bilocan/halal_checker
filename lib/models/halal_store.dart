class HalalStore {
  final String id;
  final String name;
  final String? logoUrl;
  final String address;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final String category;
  final String? certificationBody;
  final String? phone;
  final String? website;

  const HalalStore({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.address,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.certificationBody,
    this.phone,
    this.website,
  });

  factory HalalStore.fromJson(Map<String, dynamic> json) => HalalStore(
    id: json['id'] as String,
    name: json['name'] as String,
    logoUrl: json['logo_url'] as String?,
    address: json['address'] as String,
    city: json['city'] as String,
    country: json['country'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    category: json['category'] as String? ?? 'other',
    certificationBody: json['certification_body'] as String?,
    phone: json['phone'] as String?,
    website: json['website'] as String?,
  );
}
