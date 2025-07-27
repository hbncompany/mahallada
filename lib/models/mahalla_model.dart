
// lib/models/mahalla_model.dart
class Mahalla {
  final int code;
  final String nameEn;
  final String nameRu;
  final String nameUz;
  final int ns10Code;
  final int ns11Code;

  Mahalla({
    required this.code,
    required this.nameEn,
    required this.nameRu,
    required this.nameUz,
    required this.ns10Code,
    required this.ns11Code,
  });

  factory Mahalla.fromJson(Map<String, dynamic> json) {
    return Mahalla(
      code: json['code'],
      nameEn: json['name_en'],
      nameRu: json['name_ru'],
      nameUz: json['name_uz'],
      ns10Code: json['ns10_code'],
      ns11Code: json['ns11_code'],
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
}