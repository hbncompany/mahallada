// lib/screens/service_types_list_screen.dart
import 'package:flutter/material.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/models/service_model.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:mahallda_app/screens/all_service_providers_screen.dart'; // AllServiceProvidersScreen ni import qiling

class ServiceTypesListScreen extends StatefulWidget {
  final Service serviceGroup; // Tanlangan xizmat guruhi

  const ServiceTypesListScreen({super.key, required this.serviceGroup});

  @override
  State<ServiceTypesListScreen> createState() => _ServiceTypesListScreenState();
}

class _ServiceTypesListScreenState extends State<ServiceTypesListScreen> {
  Map<String, int> _typeCounts = {};
  bool _isLoading = true;
  int _allProvidersCount = 0; // "Barchasi" uchun xizmat ko'rsatuvchilar soni

  @override
  void initState() {
    super.initState();
    _fetchServiceTypesWithCounts();
  }

  Future<void> _fetchServiceTypesWithCounts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      _typeCounts = await firebaseService
          .getServiceTypeProviderCounts(widget.serviceGroup.id);

      // "Barchasi" uchun umumiy sonni hisoblash
      _allProvidersCount =
          _typeCounts.values.fold(0, (sum, count) => sum + count);
    } catch (e) {
      _showErrorDialog(e.toString());
      print("Xizmat turlarini yuklashda xato: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.translate('error')),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(ctx)!.translate('ok')),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceGroup
            .getName(Localizations.localeOf(context).languageCode)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: widget.serviceGroup.serviceTypes.length +
                  1, // "+1" "Barchasi" opsiyasi uchun
              itemBuilder: (context, index) {
                if (index == 0) {
                  // "Barchasi" opsiyasi
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading:
                          const Icon(Icons.select_all, color: Colors.green),
                      title: Text(
                        localizations.translate('allTypes'), // "Barcha turlar"
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_allProvidersCount ${localizations.translate('providers')}',
                          style: const TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () {
                        // Barcha xizmat ko'rsatuvchilarni tanlangan guruh bo'yicha filtrlash
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllServiceProvidersScreen(
                              serviceSectorId: widget.serviceGroup.id,
                              serviceType: null, // Barcha turlar uchun null
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }

                // Xizmat turlari ro'yxati
                final serviceType = widget.serviceGroup.serviceTypes[index - 1];
                final providerCount = _typeCounts[serviceType] ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.category, color: Colors.orange),
                    title: Text(
                      serviceType,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$providerCount ${localizations.translate('providers')}',
                        style: const TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                    ),
                    onTap: () {
                      // Tanlangan xizmat turi bo'yicha xizmat ko'rsatuvchilarni filtrlash
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllServiceProvidersScreen(
                            serviceSectorId: widget.serviceGroup.id,
                            serviceType: serviceType,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
