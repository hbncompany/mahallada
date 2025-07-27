// lib/models/trade_listing_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TradeListing {
  final String id;
  final String userId; // E'lon yaratuvchining UIDsi
  final String username;
  final String? userProfilePhotoUrl; // E'lon yaratuvchining profil rasmi
  final String productGroupId;
  final String productGroupUz; // Guruh nomi (uzbek tilida)
  final String productType;
  final String productName;
  final double price;
  final String condition; // 'new', 'used'
  final String description;
  final List<String> imageUrls; // Rasmlar URL manzillari
  final String contactNumber;
  final String regionNs10Code;
  final String regionNameUz;
  final String districtNs11Code;
  final String districtNameUz;
  final String mahallaCode;
  final String mahallaNameUz;
  final Timestamp createdAt;
  bool isActive; // <-- Yangi maydon: e'lon faolmi yoki yo'q

  TradeListing({
    required this.id,
    required this.userId,
    required this.username,
    this.userProfilePhotoUrl,
    required this.productGroupId,
    required this.productGroupUz,
    required this.productType,
    required this.productName,
    required this.price,
    required this.condition,
    required this.description,
    required this.imageUrls,
    required this.contactNumber,
    required this.regionNs10Code,
    required this.regionNameUz,
    required this.districtNs11Code,
    required this.districtNameUz,
    required this.mahallaCode,
    required this.mahallaNameUz,
    required this.createdAt,
    this.isActive = true, // Default qiymat true
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'userProfilePhotoUrl': userProfilePhotoUrl,
      'productGroupId': productGroupId,
      'productGroupUz': productGroupUz,
      'productType': productType,
      'productName': productName,
      'price': price,
      'condition': condition,
      'description': description,
      'imageUrls': imageUrls,
      'contactNumber': contactNumber,
      'regionNs10Code': regionNs10Code,
      'regionNameUz': regionNameUz,
      'districtNs11Code': districtNs11Code,
      'districtNameUz': districtNameUz,
      'mahallaCode': mahallaCode,
      'mahallaNameUz': mahallaNameUz,
      'createdAt': createdAt,
      'isActive': isActive, // isActive ham toMap() ga qo'shildi
    };
  }

  factory TradeListing.fromMap(Map<String, dynamic> map, String id) {
    return TradeListing(
      id: id,
      userId: map['userId'] as String,
      username: map['username'] as String,
      userProfilePhotoUrl: map['userProfilePhotoUrl'] as String?,
      productGroupId: map['productGroupId'] as String,
      productGroupUz: map['productGroupUz'] as String,
      productType: map['productType'] as String,
      productName: map['productName'] as String,
      price: (map['price'] as num).toDouble(),
      condition: map['condition'] as String,
      description: map['description'] as String,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      contactNumber: map['contactNumber'] as String,
      regionNs10Code: map['regionNs10Code'] as String,
      regionNameUz: map['regionNameUz'] as String,
      districtNs11Code: map['districtNs11Code'] as String,
      districtNameUz: map['districtNameUz'] as String,
      mahallaCode: map['mahallaCode'] as String,
      mahallaNameUz: map['mahallaNameUz'] as String,
      createdAt: map['createdAt'] as Timestamp,
      isActive: map['isActive'] as bool? ?? true, // Agar mavjud bo'lmasa, true
    );
  }

  // copyWith methodini qo'shish
  TradeListing copyWith({
    String? id,
    String? userId,
    String? username,
    String? userProfilePhotoUrl,
    String? productGroupId,
    String? productGroupUz,
    String? productType,
    String? productName,
    double? price,
    String? condition,
    String? description,
    List<String>? imageUrls,
    String? contactNumber,
    String? regionNs10Code,
    String? regionNameUz,
    String? districtNs11Code,
    String? districtNameUz,
    String? mahallaCode,
    String? mahallaNameUz,
    Timestamp? createdAt,
    bool? isActive,
  }) {
    return TradeListing(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfilePhotoUrl: userProfilePhotoUrl ?? this.userProfilePhotoUrl,
      productGroupId: productGroupId ?? this.productGroupId,
      productGroupUz: productGroupUz ?? this.productGroupUz,
      productType: productType ?? this.productType,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      contactNumber: contactNumber ?? this.contactNumber,
      regionNs10Code: regionNs10Code ?? this.regionNs10Code,
      regionNameUz: regionNameUz ?? this.regionNameUz,
      districtNs11Code: districtNs11Code ?? this.districtNs11Code,
      districtNameUz: districtNameUz ?? this.districtNameUz,
      mahallaCode: mahallaCode ?? this.mahallaCode,
      mahallaNameUz: mahallaNameUz ?? this.mahallaNameUz,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
