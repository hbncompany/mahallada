// lib/models/review_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String serviceProviderUid;
  final String clientUid;
  final String clientUsername;
  final String reviewText;
  final double rating;
  final Timestamp timestamp;

  Review({
    required this.id,
    required this.serviceProviderUid,
    required this.clientUid,
    required this.clientUsername,
    required this.reviewText,
    required this.rating,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'serviceProviderUid': serviceProviderUid,
      'clientUid': clientUid,
      'clientUsername': clientUsername,
      'reviewText': reviewText,
      'rating': rating,
      'timestamp': timestamp,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      serviceProviderUid: map['serviceProviderUid'],
      clientUid: map['clientUid'],
      clientUsername: map['clientUsername'],
      reviewText: map['reviewText'],
      rating: (map['rating'] as num).toDouble(),
      timestamp: map['timestamp'] as Timestamp,
    );
  }
}
