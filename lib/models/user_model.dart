// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? uid;
  String? email;
  String? phoneNumber;
  String? username;
  String? profilePhotoUrl;
  String? role; // 'client' or 'serviceProvider'
  String? regionNs10Code;
  String? regionNameEn;
  String? regionNameRu;
  String? regionNameUz;
  String? districtNs11Code;
  String? districtNameEn;
  String? districtNameRu;
  String? districtNameUz;
  String? mahallaCode;
  String? mahallaNameEn;
  String? mahallaNameRu;
  String? mahallaNameUz;
  Timestamp? registrationDate;
  String? fcmToken;
  bool isTrader;
  bool isServiceProvider;
  double? balance; // Agar balans funksiyasi bo'lsa

  // Yangi obuna bilan bog'liq maydonlar
  bool? isPremiumSubscriber;
  Timestamp? subscriptionEndDate; // Obunaning tugash sanasi
  String? latestSubscriptionPurchaseToken; // Eng so'nggi xarid tokenini saqlash

  UserModel({
    this.uid,
    this.email,
    this.phoneNumber,
    this.username,
    this.profilePhotoUrl,
    this.role,
    this.regionNs10Code,
    this.regionNameEn,
    this.regionNameRu,
    this.regionNameUz,
    this.districtNs11Code,
    this.districtNameEn,
    this.districtNameRu,
    this.districtNameUz,
    this.mahallaCode,
    this.mahallaNameEn,
    this.mahallaNameRu,
    this.mahallaNameUz,
    this.registrationDate,
    this.fcmToken,
    this.isTrader = false,
    this.isServiceProvider = false,
    this.balance,
    this.isPremiumSubscriber, // Yangi
    this.subscriptionEndDate, // Yangi
    this.latestSubscriptionPurchaseToken, // Yangi
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'username': username,
      'profilePhotoUrl': profilePhotoUrl,
      'role': role,
      'regionNs10Code': regionNs10Code,
      'regionNameEn': regionNameEn,
      'regionNameRu': regionNameRu,
      'regionNameUz': regionNameUz,
      'districtNs11Code': districtNs11Code,
      'districtNameEn': districtNameEn,
      'districtNameRu': districtNameRu,
      'districtNameUz': districtNameUz,
      'mahallaCode': mahallaCode,
      'mahallaNameEn': mahallaNameEn,
      'mahallaNameRu': mahallaNameRu,
      'mahallaNameUz': mahallaNameUz,
      'registrationDate': registrationDate ?? Timestamp.now(),
      'fcmToken': fcmToken,
      'isTrader': isTrader,
      'isServiceProvider': isServiceProvider,
      'balance': balance,
      'isPremiumSubscriber': isPremiumSubscriber,
      'subscriptionEndDate': subscriptionEndDate,
      'latestSubscriptionPurchaseToken': latestSubscriptionPurchaseToken,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    // Added 'id' parameter
    return UserModel(
      uid: id, // Use the provided ID
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      username: map['username'] as String?,
      profilePhotoUrl: map['profilePhotoUrl'] as String?,
      role: map['role'] as String?,
      regionNs10Code: map['regionNs10Code'] as String?,
      regionNameEn: map['regionNameEn'] as String?,
      regionNameRu: map['regionNameRu'] as String?,
      regionNameUz: map['regionNameUz'] as String?,
      districtNs11Code: map['districtNs11Code'] as String?,
      districtNameEn: map['districtNameEn'] as String?,
      districtNameRu: map['districtNameRu'] as String?,
      districtNameUz: map['districtNameUz'] as String?,
      mahallaCode: map['mahallaCode'] as String?,
      mahallaNameEn: map['mahallaNameEn'] as String?,
      mahallaNameRu: map['mahallaNameRu'] as String?,
      mahallaNameUz: map['mahallaNameUz'] as String?,
      registrationDate: map['registrationDate'] as Timestamp?,
      fcmToken: map['fcmToken'] as String?,
      isTrader: map['isTrader'] as bool? ?? false,
      isServiceProvider: map['isServiceProvider'] as bool? ?? false,
      balance: (map['balance'] as num?)?.toDouble(),
      isPremiumSubscriber: map['isPremiumSubscriber'] as bool?,
      subscriptionEndDate: map['subscriptionEndDate'] as Timestamp?,
      latestSubscriptionPurchaseToken:
      map['latestSubscriptionPurchaseToken'] as String?,
    );
  }

  // copyWith method (unchanged from previous version, but ensure it matches new fields if needed)
  UserModel copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? username,
    String? profilePhotoUrl,
    String? role,
    String? regionNs10Code,
    String? regionNameEn,
    String? regionNameRu,
    String? regionNameUz,
    String? districtNs11Code,
    String? districtNameEn,
    String? districtNameRu,
    String? districtNameUz,
    String? mahallaCode,
    String? mahallaNameEn,
    String? mahallaNameRu,
    String? mahallaNameUz,
    Timestamp? registrationDate,
    String? fcmToken,
    bool? isTrader,
    bool? isServiceProvider,
    double? balance,
    bool? isPremiumSubscriber,
    Timestamp? subscriptionEndDate,
    String? latestSubscriptionPurchaseToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      username: username ?? this.username,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      role: role ?? this.role,
      regionNs10Code: regionNs10Code ?? this.regionNs10Code,
      regionNameEn: regionNameEn ?? this.regionNameEn,
      regionNameRu: regionNameRu ?? this.regionNameRu,
      regionNameUz: regionNameUz ?? this.regionNameUz,
      districtNs11Code: districtNs11Code ?? this.districtNs11Code,
      districtNameEn: districtNameEn ?? this.districtNameEn,
      districtNameRu: districtNameRu ?? this.districtNameRu,
      districtNameUz: districtNameUz ?? this.districtNameUz,
      mahallaCode: mahallaCode ?? this.mahallaCode,
      mahallaNameEn: mahallaNameEn ?? this.mahallaNameEn,
      mahallaNameRu: mahallaNameRu ?? this.mahallaNameRu,
      mahallaNameUz: mahallaNameUz ?? this.mahallaNameUz,
      registrationDate: registrationDate ?? this.registrationDate,
      fcmToken: fcmToken ?? this.fcmToken,
      isTrader: isTrader ?? this.isTrader,
      isServiceProvider: isServiceProvider ?? this.isServiceProvider,
      balance: balance ?? this.balance,
      isPremiumSubscriber: isPremiumSubscriber ?? this.isPremiumSubscriber,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      latestSubscriptionPurchaseToken: latestSubscriptionPurchaseToken ??
          this.latestSubscriptionPurchaseToken,
    );
  }
}
