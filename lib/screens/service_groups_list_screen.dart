// lib/screens/service_groups_list_screen.dart
import 'package:flutter/material.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/models/service_model.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:mahallda_app/screens/service_types_list_screen.dart'; // Yangi ekran

class ServiceGroupsListScreen extends StatefulWidget {
  const ServiceGroupsListScreen({super.key});

  @override
  State<ServiceGroupsListScreen> createState() =>
      _ServiceGroupsListScreenState();
}

class _ServiceGroupsListScreenState extends State<ServiceGroupsListScreen> {
  List<Service> _serviceSectors = [];
  Map<String, int> _sectorCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServiceGroupsWithCounts();
  }

  Future<void> _fetchServiceGroupsWithCounts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      _serviceSectors = await firebaseService.fetchServiceSectors();
      _sectorCounts = await firebaseService.getServiceSectorProviderCounts();
    } catch (e) {
      _showErrorDialog(e.toString());
      print("Xizmat guruhlarini yuklashda xato: $e");
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
    final currentLangCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            localizations.translate('serviceGroups')), // "Xizmat guruhlari"
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _serviceSectors.isEmpty
              ? Center(
                  child: Text(localizations.translate(
                      'noServiceGroupsFound'))) // "Xizmat guruhlari topilmadi."
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _serviceSectors.length,
                  itemBuilder: (context, index) {
                    final service = _serviceSectors[index];
                    final providerCount = _sectorCounts[service.id] ?? 0;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.work, color: Colors.blue),
                        title: Text(
                          service.getName(currentLangCode),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$providerCount ${localizations.translate('providers')}', // "xizmat ko'rsatuvchi"
                            style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ServiceTypesListScreen(serviceGroup: service),
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
