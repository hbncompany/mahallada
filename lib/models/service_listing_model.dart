
// lib/models/service_listing_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceListing {
  final String id;
  final String userId; // Xizmat yaratuvchining UIDsi
  final String username;
  final String? userProfilePhotoUrl; // Xizmat yaratuvchining profil rasmi
  final String serviceGroupId;
  final String serviceGroupUz; // Guruh nomi (uzbek tilida)
  final String serviceName;
  final double price;
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

  ServiceListing({
    required this.id,
    required this.userId,
    required this.username,
    this.userProfilePhotoUrl,
    required this.serviceGroupId,
    required this.serviceGroupUz,
    required this.serviceName,
    required this.price,
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
      'serviceGroupId': serviceGroupId,
      'serviceGroupUz': serviceGroupUz,
      'serviceName': serviceName,
      'price': price,
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
      'isActive': isActive,
    };
  }

  factory ServiceListing.fromMap(Map<String, dynamic> map, String id) {
    return ServiceListing(
      id: id,
      userId: map['userId'] as String,
      username: map['username'] as String,
      userProfilePhotoUrl: map['userProfilePhotoUrl'] as String?,
      serviceGroupId: map['serviceGroupId'] as String,
      serviceGroupUz: map['serviceGroupUz'] as String,
      serviceName: map['serviceName'] as String,
      price: (map['price'] as num).toDouble(),
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
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  ServiceListing copyWith({
    String? id,
    String? userId,
    String? username,
    String? userProfilePhotoUrl,
    String? serviceGroupId,
    String? serviceGroupUz,
    String? serviceName,
    double? price,
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
    return ServiceListing(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfilePhotoUrl: userProfilePhotoUrl ?? this.userProfilePhotoUrl,
      serviceGroupId: serviceGroupId ?? this.serviceGroupId,
      serviceGroupUz: serviceGroupUz ?? this.serviceGroupUz,
      serviceName: serviceName ?? this.serviceName,
      price: price ?? this.price,
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