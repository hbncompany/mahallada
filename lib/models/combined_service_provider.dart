// lib/models/combined_service_provider.dart
import 'package:mahallda_app/models/user_model.dart';
import 'package:mahallda_app/models/service_provider_model.dart';

class CombinedServiceProvider {
  final UserModel user;
  final ServiceProviderModel serviceProvider;
  // rating endi ServiceProviderModel ichida bo'lgani uchun bu yerdan olib tashladik
  // final double rating;

  CombinedServiceProvider({
    required this.user,
    required this.serviceProvider,
    // this.rating = 4.5, // Default/placeholder reyting
  });

  // Reytingni ServiceProviderModel'dan olish uchun getter
  double get rating => serviceProvider.rating ?? 0.0;
}
