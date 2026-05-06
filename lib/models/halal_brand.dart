class HalalBrand {
  final String id;
  final String name;
  final String? logoUrl;
  final String country;
  final String category;
  final String? certificationBody;
  final String? website;

  const HalalBrand({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.country,
    required this.category,
    this.certificationBody,
    this.website,
  });

  factory HalalBrand.fromJson(Map<String, dynamic> json) => HalalBrand(
    id: json['id'] as String,
    name: json['name'] as String,
    logoUrl: json['logo_url'] as String?,
    country: json['country'] as String,
    category: json['category'] as String? ?? 'other',
    certificationBody: json['certification_body'] as String?,
    website: json['website'] as String?,
  );
}
