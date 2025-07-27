// lib/screens/auth/service_provider_details_screen.dart
import 'package:flutter/material.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/models/user_model.dart';
import 'package:mahallda_app/models/service_model.dart';
import 'package:mahallda_app/models/service_provider_model.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:mahallda_app/screens/home_screen.dart';

class ServiceProviderDetailsScreen extends StatefulWidget {
  final UserModel user;

  const ServiceProviderDetailsScreen({super.key, required this.user});

  @override
  State<ServiceProviderDetailsScreen> createState() =>
      _ServiceProviderDetailsScreenState();
}

class _ServiceProviderDetailsScreenState
    extends State<ServiceProviderDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  Service? _selectedServiceSector;
  String? _selectedServiceType;
  final TextEditingController _servicePriceController = TextEditingController();
  final TextEditingController _workingHoursController = TextEditingController();
  List<String> _selectedWorkingDays = [];
  List<Service> _serviceSectors = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchServiceSectors();
  }

  Future<void> _fetchServiceSectors() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      _serviceSectors = await firebaseService.fetchServiceSectors();
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitServiceProviderDetails() async {
    if (!_formKey.currentState!.validate() ||
        _selectedServiceSector == null ||
        _selectedServiceType == null ||
        _selectedWorkingDays.isEmpty) {
      _showErrorDialog(AppLocalizations.of(context)!
          .translate('fillAllFields')); // "Barcha maydonlarni to'ldiring."
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    try {
      // UserModel ga qo'shimcha ma'lumotlarni saqlash (Firebase UID allaqachon mavjud)
      await firebaseService.saveUserData(widget.user);

      // ServiceProviderModel yaratish va saqlash
      ServiceProviderModel serviceProvider = ServiceProviderModel(
        uid: widget.user.uid,
        serviceSector: _selectedServiceSector!.id, // Firestore document ID
        serviceType: _selectedServiceType!,
        servicePrice: double.tryParse(_servicePriceController.text),
        workingDays: _selectedWorkingDays,
        workingHours: _workingHoursController.text.trim(),
      );
      await firebaseService.saveServiceProviderData(serviceProvider);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showErrorDialog(e.toString());
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
        title: Text(localizations.translate('register')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('serviceSector'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<Service>(
                      value: _selectedServiceSector,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: Text(localizations.translate(
                          'selectServiceSector')), // "Xizmat sohasini tanlang"
                      items: _serviceSectors.map((service) {
                        return DropdownMenuItem<Service>(
                          value: service,
                          child: Text(service.getName(currentLangCode)),
                        );
                      }).toList(),
                      onChanged: (Service? newValue) {
                        setState(() {
                          _selectedServiceSector = newValue;
                          _selectedServiceType =
                              null; // Soha o'zgarganda xizmat turini tozalash
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return localizations.translate(
                              'serviceSectorRequired'); // "Xizmat sohasi majburiy."
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      localizations.translate('serviceType'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedServiceType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: Text(localizations.translate(
                          'selectServiceType')), // "Xizmat turini tanlang"
                      items: _selectedServiceSector?.serviceTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList() ??
                          [],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedServiceType = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return localizations.translate(
                              'serviceTypeRequired'); // "Xizmat turi majburiy."
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _servicePriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: localizations.translate('servicePrice'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate(
                              'servicePriceRequired'); // "Xizmat narxi majburiy."
                        }
                        if (double.tryParse(value) == null) {
                          return localizations.translate(
                              'enterValidPrice'); // "Yaroqli narx kiriting."
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      localizations.translate('workingDays'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: [
                        _buildDayCheckbox(
                            localizations.translate('monday'), 'Monday'),
                        _buildDayCheckbox(
                            localizations.translate('tuesday'), 'Tuesday'),
                        _buildDayCheckbox(
                            localizations.translate('wednesday'), 'Wednesday'),
                        _buildDayCheckbox(
                            localizations.translate('thursday'), 'Thursday'),
                        _buildDayCheckbox(
                            localizations.translate('friday'), 'Friday'),
                        _buildDayCheckbox(
                            localizations.translate('saturday'), 'Saturday'),
                        _buildDayCheckbox(
                            localizations.translate('sunday'), 'Sunday'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _workingHoursController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('workingHours'),
                        hintText: '0900-1800',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate(
                              'workingHoursRequired'); // "Ish soatlari majburiy."
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitServiceProviderDetails,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          localizations.translate('register'),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDayCheckbox(String title, String dayValue) {
    return CheckboxListTile(
      title: Text(title),
      value: _selectedWorkingDays.contains(dayValue),
      onChanged: (bool? newValue) {
        setState(() {
          if (newValue == true) {
            _selectedWorkingDays.add(dayValue);
          } else {
            _selectedWorkingDays.remove(dayValue);
          }
        });
      },
    );
  }
}
