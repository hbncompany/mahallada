// lib/models/product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String nameEn;
  final String nameRu;
  final String nameUz;
  final List<String> productTypes; // Mahsulot turlari

  Product({
    required this.id,
    required this.nameEn,
    required this.nameRu,
    required this.nameUz,
    required this.productTypes,
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      nameEn: data['name_en'] ?? '',
      nameRu: data['name_ru'] ?? '',
      nameUz: data['name_uz'] ?? '',
      productTypes: List<String>.from(data['productTypes'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name_en': nameEn,
      'name_ru': nameRu,
      'name_uz': nameUz,
      'product_types': productTypes,
    };
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
