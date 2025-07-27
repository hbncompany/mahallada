// lib/screens/auth/sign_up_location_screen.dart
import 'package:flutter/material.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/models/user_model.dart';
import 'package:mahallda_app/models/region_model.dart';
import 'package:mahallda_app/models/mahalla_model.dart';
import 'package:mahallda_app/services/api_service.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:mahallda_app/screens/auth/service_provider_details_screen.dart';
import 'package:mahallda_app/screens/home_screen.dart';

class SignUpLocationScreen extends StatefulWidget {
  final UserModel user;

  const SignUpLocationScreen({super.key, required this.user});

  @override
  State<SignUpLocationScreen> createState() => _SignUpLocationScreenState();
}

class _SignUpLocationScreenState extends State<SignUpLocationScreen> {
  final ApiService _apiService = ApiService();
  List<Region> _regions = [];
  List<Region> _districts = [];
  List<Mahalla> _mahallas = [];

  Region? _selectedRegion;
  Region? _selectedDistrict;
  Mahalla? _selectedMahalla;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRegions();
  }

  Future<void> _fetchRegions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _regions = await _apiService.fetchRegions();
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

  Future<void> _fetchDistricts(int ns10Code) async {
    setState(() {
      _isLoading = true;
      _districts = [];
      _mahallas = [];
      _selectedDistrict = null;
      _selectedMahalla = null;
    });
    try {
      _districts = await _apiService.fetchDistricts(ns10Code);
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

  Future<void> _fetchMahallas(int ns10Code, int ns11Code) async {
    setState(() {
      _isLoading = true;
      _mahallas = [];
      _selectedMahalla = null;
    });
    try {
      _mahallas = await _apiService.fetchMahallas(ns10Code, ns11Code);
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

  Future<void> _submitLocation() async {
    if (_selectedRegion == null ||
        _selectedDistrict == null ||
        _selectedMahalla == null) {
      _showErrorDialog(AppLocalizations.of(context)!.translate(
          'selectLocationFields')); // "Barcha joylashuv maydonlarini tanlang."
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    try {
      widget.user.regionNs10Code = _selectedRegion!.ns10Code.toString();
      widget.user.regionNameEn = _selectedRegion!.nameEn;
      widget.user.regionNameRu = _selectedRegion!.nameRu;
      widget.user.regionNameUz = _selectedRegion!.nameUz;

      widget.user.districtNs11Code = _selectedDistrict!.ns11Code.toString();
      widget.user.districtNameEn = _selectedDistrict!.districtEn;
      widget.user.districtNameRu = _selectedDistrict!.districtRu;
      widget.user.districtNameUz = _selectedDistrict!.districtUz;

      widget.user.mahallaCode = _selectedMahalla!.code.toString();
      widget.user.mahallaNameEn = _selectedMahalla!.nameEn;
      widget.user.mahallaNameRu = _selectedMahalla!.nameRu;
      widget.user.mahallaNameUz = _selectedMahalla!.nameUz;

      if (widget.user.role == 'client') {
        await firebaseService.saveUserData(widget.user);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ServiceProviderDetailsScreen(user: widget.user),
            ),
          );
        }
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('selectRegion'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Region>(
                    value: _selectedRegion,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: Text(localizations.translate('selectRegion')),
                    items: _regions.map((region) {
                      return DropdownMenuItem<Region>(
                        value: region,
                        child: Text(region.getName(currentLangCode)),
                      );
                    }).toList(),
                    onChanged: (Region? newValue) {
                      setState(() {
                        _selectedRegion = newValue;
                        if (newValue != null) {
                          _fetchDistricts(newValue.ns10Code);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    localizations.translate('selectDistrict'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Region>(
                    value: _selectedDistrict,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: Text(localizations.translate('selectDistrict')),
                    items: _districts.map((district) {
                      return DropdownMenuItem<Region>(
                        value: district,
                        child:
                            Text(district.getDistrict(currentLangCode) ?? ''),
                      );
                    }).toList(),
                    onChanged: (Region? newValue) {
                      setState(() {
                        _selectedDistrict = newValue;
                        if (_selectedRegion != null && newValue != null) {
                          _fetchMahallas(
                              _selectedRegion!.ns10Code, newValue.ns11Code);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    localizations.translate('selectMahalla'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Mahalla>(
                    value: _selectedMahalla,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: Text(localizations.translate('selectMahalla')),
                    items: _mahallas.map((mahalla) {
                      return DropdownMenuItem<Mahalla>(
                        value: mahalla,
                        child: Text(mahalla.getName(currentLangCode)),
                      );
                    }).toList(),
                    onChanged: (Mahalla? newValue) {
                      setState(() {
                        _selectedMahalla = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitLocation,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        localizations.translate('continue'),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
