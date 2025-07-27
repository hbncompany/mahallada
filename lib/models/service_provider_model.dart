// lib/models/service_provider_model.dart
class ServiceProviderModel {
  String? uid;
  String? serviceSector;
  String? serviceType;
  double? servicePrice;
  List<String>? workingDays;
  String? workingHours; // e.g., "0900-1800"
  double? rating; // <-- Yangi maydon qo'shildi
  final int? experienceYears;
  final String? positionInApp;
  final String? description;
  bool isActive; // <-- Yangi maydon: xizmat faolmi yoki yo'q

  ServiceProviderModel({
    this.uid,
    this.serviceSector,
    this.serviceType,
    this.servicePrice,
    this.workingDays,
    this.workingHours,
    this.rating, // <-- Konstruktorga qo'shildi
    this.experienceYears,
    this.positionInApp,
    this.description,
    this.isActive = true, // Default qiymat true
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'serviceSector': serviceSector,
      'serviceType': serviceType,
      'servicePrice': servicePrice,
      'workingDays': workingDays,
      'workingHours': workingHours,
      'rating': rating, // <-- toMap() ga qo'shildi
      'experienceYears': experienceYears,
      'positionInApp': positionInApp,
      'description': description,
      'isActive': isActive,
    };
  }

  factory ServiceProviderModel.fromMap(Map<String, dynamic> map) {
    return ServiceProviderModel(
      uid: map['uid'],
      serviceSector: map['serviceSector'],
      serviceType: map['serviceType'],
      servicePrice: (map['servicePrice'] as num?)?.toDouble(),
      workingDays:
          (map['workingDays'] as List?)?.map((e) => e.toString()).toList(),
      workingHours: map['workingHours'],
      rating: (map['rating'] as num?)?.toDouble(), // <-- fromMap() ga qo'shildi
      experienceYears: (map['experienceYears'] as num?)?.toInt(),
      positionInApp: map['positionInApp'] as String?,
      description: map['description'] as String?,
      isActive: map['isActive'] as bool? ?? true, // Agar mavjud bo'lmasa, true
    );
  }

  // Xizmatni o'zgartirish uchun yordamchi metod
  ServiceProviderModel copyWith({
    String? uid,
    String? serviceSector,
    String? serviceType,
    double? servicePrice,
    List<String>? workingDays,
    String? workingHours,
    double? rating,
    int? experienceYears,
    String? positionInApp,
    String? description,
    bool? isActive,
  }) {
    return ServiceProviderModel(
      uid: uid ?? this.uid,
      serviceSector: serviceSector ?? this.serviceSector,
      serviceType: serviceType ?? this.serviceType,
      servicePrice: servicePrice ?? this.servicePrice,
      workingDays: workingDays ?? this.workingDays,
      workingHours: workingHours ?? this.workingHours,
      rating: rating ?? this.rating,
      experienceYears: experienceYears ?? this.experienceYears,
      positionInApp: positionInApp ?? this.positionInApp,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
