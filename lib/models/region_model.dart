
// lib/models/region_model.dart
class Region {
  final int ns10Code;
  final int ns11Code;
  final String nameEn;
  final String nameRu;
  final String nameUz;
  final String? districtEn;
  final String? districtRu;
  final String? districtUz;

  Region({
    required this.ns10Code,
    required this.ns11Code,
    required this.nameEn,
    required this.nameRu,
    required this.nameUz,
    this.districtEn,
    this.districtRu,
    this.districtUz,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      ns10Code: json['ns10_code'],
      ns11Code: json['ns11_code'],
      nameEn: json['name_en'],
      nameRu: json['name_ru'],
      nameUz: json['name_uz'],
      districtEn: json['district_en'],
      districtRu: json['district_ru'],
      districtUz: json['district_uz'],
    );
  }

  String getName(String langCode) {
    switch (langCode) {
      case 'uz':
        return nameUz;
      case 'ru':
        return nameRu;
      case 'en':
        return nameEn;
      default:
        return nameUz;
    }
  }

  String? getDistrict(String langCode) {
    switch (langCode) {
      case 'uz':
        return districtUz;
      case 'ru':
        return districtRu;
      case 'en':
        return districtEn;
      default:
        return districtUz;
    }
  }
}
