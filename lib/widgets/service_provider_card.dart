// lib/widgets/service_provider_card.dart
import 'package:flutter/material.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/models/combined_service_provider.dart';
import 'package:mahallda_app/models/user_model.dart'; // UserModel ni import qilish
import 'package:mahallda_app/models/service_provider_model.dart'; // ServiceProviderModel ni import qilish

// _ServiceProviderCard nomini ServiceProviderCard ga o'zgartirdik
class ServiceProviderCard extends StatelessWidget {
  final CombinedServiceProvider provider;
  final String currentLangCode;
  final VoidCallback onTap;

  const ServiceProviderCard({
    super.key, // Key qo'shildi
    required this.provider,
    required this.currentLangCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: provider.user.profilePhotoUrl != null
                    ? NetworkImage(provider.user.profilePhotoUrl!)
                    : const AssetImage('assets/placeholder_profile.png')
                        as ImageProvider,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.user.username ?? 'N/A',
                      style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      provider.serviceProvider.serviceType ?? 'N/A',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(
                          provider.serviceProvider.workingHours ?? 'N/A',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${localizations.translate('fee')}: ${provider.serviceProvider.servicePrice?.toStringAsFixed(0) ?? 'N/A'} UZS",
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 5),
                      Text(
                        provider.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
