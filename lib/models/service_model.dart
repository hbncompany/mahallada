// lib/models/service_model.dart
class Service {
  final String id;
  final String nameEn;
  final String nameRu;
  final String nameUz;
  final List<String> serviceTypes; // JSONda array bo'lishi kerak

  Service({
    required this.id,
    required this.nameEn,
    required this.nameRu,
    required this.nameUz,
    required this.serviceTypes,
  });

  factory Service.fromFirestore(Map<String, dynamic> data, String id) {
    return Service(
      id: id,
      nameEn: data['name_en'] ?? '',
      nameRu: data['name_ru'] ?? '',
      nameUz: data['name_uz'] ?? '',
      serviceTypes: List<String>.from(data['serviceTypes'] ?? []),
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
