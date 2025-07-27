// lib/screens/edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/models/user_model.dart';
import 'package:mahallda_app/models/service_provider_model.dart';
import 'package:mahallda_app/models/service_model.dart';
import 'package:mahallda_app/models/region_model.dart';
import 'package:mahallda_app/models/mahalla_model.dart';
import 'package:mahallda_app/services/api_service.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  final ServiceProviderModel? serviceProvider;

  const EditProfileScreen({
    super.key,
    required this.user,
    this.serviceProvider,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _servicePriceController;
  late TextEditingController _workingHoursController;

  File? _profileImage;
  String? _profileImageUrl;
  bool _isLoading = false;

  // Location related
  final ApiService _apiService = ApiService();
  List<Region> _regions = [];
  List<Region> _districts = [];
  List<Mahalla> _mahallas = [];
  Region? _selectedRegion;
  Region? _selectedDistrict;
  Mahalla? _selectedMahalla;

  // Service provider related
  List<Service> _serviceSectors = [];
  Service? _selectedServiceSector;
  String? _selectedServiceType;
  List<String> _selectedWorkingDays = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _servicePriceController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneNumberController =
        TextEditingController(text: widget.user.phoneNumber);

    if (widget.user.role == 'serviceProvider' &&
        widget.serviceProvider != null) {
      _servicePriceController = TextEditingController(
          text: widget.serviceProvider!.servicePrice?.toStringAsFixed(0));
      _workingHoursController =
          TextEditingController(text: widget.serviceProvider!.workingHours);
      _selectedWorkingDays =
          List.from(widget.serviceProvider!.workingDays ?? []);
    } else {
      _servicePriceController = TextEditingController();
      _workingHoursController = TextEditingController();
    }
  }

  // firstWhereOrNull metodini qo'lda implementatsiya qilish
  T? _firstWhereOrNull<T>(List<T> list, bool Function(T element) test) {
    for (var element in list) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }

  // _fetchDistricts metodini _EditProfileScreenState sinfiga qo'shish
  Future<void> _fetchDistricts(int ns10Code) async {
    setState(() {
      _isLoading = true; // Bu yerda ham yuklanish holatini boshqaramiz
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
          _isLoading = false; // Yuklanish tugadi
        });
      }
    }
  }

  // _fetchMahallas metodini _EditProfileScreenState sinfiga qo'shish
  Future<void> _fetchMahallas(int ns10Code, int ns11Code) async {
    setState(() {
      _isLoading = true; // Bu yerda ham yuklanish holatini boshqaramiz
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
          _isLoading = false; // Yuklanish tugadi
        });
      }
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _regions = await _apiService.fetchRegions();

      if (widget.user.regionNs10Code != null) {
        _selectedRegion = _firstWhereOrNull(_regions,
            (r) => r.ns10Code.toString() == widget.user.regionNs10Code);
        if (_selectedRegion != null) {
          await _fetchDistricts(_selectedRegion!.ns10Code);
          if (widget.user.districtNs11Code != null) {
            _selectedDistrict = _firstWhereOrNull(_districts,
                (d) => d.ns11Code.toString() == widget.user.districtNs11Code);
            if (_selectedDistrict != null) {
              await _fetchMahallas(
                  _selectedRegion!.ns10Code, _selectedDistrict!.ns11Code);
              if (widget.user.mahallaCode != null) {
                _selectedMahalla = _firstWhereOrNull(_mahallas,
                    (m) => m.code.toString() == widget.user.mahallaCode);
              }
            }
          }
        }
      }

      if (widget.user.role == 'serviceProvider') {
        final firebaseService =
            Provider.of<FirebaseService>(context, listen: false);
        _serviceSectors = await firebaseService.fetchServiceSectors();
        if (widget.serviceProvider?.serviceSector != null) {
          _selectedServiceSector = _firstWhereOrNull(_serviceSectors,
              (s) => s.id == widget.serviceProvider!.serviceSector);
          if (_selectedServiceSector != null &&
              widget.serviceProvider?.serviceType != null) {
            _selectedServiceType = widget.serviceProvider!.serviceType;
          }
        }
      }

      _profileImageUrl = widget.user.profilePhotoUrl;
    } catch (e) {
      _showErrorDialog(e.toString());
      print("Ma'lumotlarni yuklashda xato: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final localizations = AppLocalizations.of(context)!;
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final apiService = ApiService();

    try {
      print('_profileImageUrl');
      if (_profileImage != null) {
        _profileImageUrl = await apiService.uploadProfilePhoto(_profileImage!, widget.user.uid.toString());
        print(_profileImageUrl);
      }
      print(_profileImageUrl);

      widget.user.username = _usernameController.text.trim();
      widget.user.email = _emailController.text.trim();
      widget.user.phoneNumber = _phoneNumberController.text.trim();
      widget.user.profilePhotoUrl = _profileImageUrl;

      widget.user.regionNs10Code = _selectedRegion?.ns10Code.toString();
      widget.user.regionNameEn = _selectedRegion?.nameEn;
      widget.user.regionNameRu = _selectedRegion?.nameRu;
      widget.user.regionNameUz = _selectedRegion?.nameUz;

      widget.user.districtNs11Code = _selectedDistrict?.ns11Code.toString();
      widget.user.districtNameEn = _selectedDistrict?.districtEn;
      widget.user.districtNameRu = _selectedDistrict?.districtRu;
      widget.user.districtNameUz = _selectedDistrict?.districtUz;

      widget.user.mahallaCode = _selectedMahalla?.code.toString();
      widget.user.mahallaNameEn = _selectedMahalla?.nameEn;
      widget.user.mahallaNameRu = _selectedMahalla?.nameRu;
      widget.user.mahallaNameUz = _selectedMahalla?.nameUz;

      await firebaseService.saveUserData(widget.user);

      if (widget.user.role == 'serviceProvider' &&
          widget.serviceProvider != null) {
        widget.serviceProvider!.serviceSector = _selectedServiceSector?.id;
        widget.serviceProvider!.serviceType = _selectedServiceType;
        widget.serviceProvider!.servicePrice =
            double.tryParse(_servicePriceController.text);
        widget.serviceProvider!.workingDays = _selectedWorkingDays;
        widget.serviceProvider!.workingHours =
            _workingHoursController.text.trim();

        await firebaseService.saveServiceProviderData(widget.serviceProvider!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(localizations.translate('profileUpdatedSuccessfully'))),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print(e);
      _showErrorDialog(
          localizations.translate('failedToUpdateProfile') + ": $e");
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
        title: Text(localizations.translate('editProfile')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (_profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : const AssetImage(
                                        'assets/placeholder_profile.png'))
                                as ImageProvider,
                        child: _profileImage == null && _profileImageUrl == null
                            ? Icon(
                                Icons.camera_alt,
                                size: 60,
                                color: Colors.grey[600],
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _pickImage,
                      child: Text(localizations.translate('uploadPhoto')),
                    ),
                    const SizedBox(height: 30),
                    _buildSectionTitle(localizations.translate('generalInfo')),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('username'),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('usernameRequired');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: localizations.translate('email'),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('emailRequired');
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return localizations.translate('enterValidEmail');
                        }
                        return null;
                      },
                      enabled: false,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: localizations.translate('phoneNumber'),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildSectionTitle(localizations.translate('location')),
                    DropdownButtonFormField<Region>(
                      value: _selectedRegion,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        labelText: localizations.translate('selectRegion'),
                      ),
                      items: _regions.map((region) {
                        return DropdownMenuItem<Region>(
                          value: region,
                          child: Text(region.getName(currentLangCode)),
                        );
                      }).toList(),
                      onChanged: (Region? newValue) {
                        setState(() {
                          _selectedRegion = newValue;
                          _selectedDistrict = null;
                          _selectedMahalla = null;
                          _districts = [];
                          _mahallas = [];
                          if (newValue != null) {
                            _fetchDistricts(newValue.ns10Code);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<Region>(
                      value: _selectedDistrict,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        labelText: localizations.translate('selectDistrict'),
                      ),
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
                          _selectedMahalla = null;
                          _mahallas = [];
                          if (_selectedRegion != null && newValue != null) {
                            _fetchMahallas(
                                _selectedRegion!.ns10Code, newValue.ns11Code);
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<Mahalla>(
                      value: _selectedMahalla,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        labelText: localizations.translate('selectMahalla'),
                      ),
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
                    if (widget.user.role == 'serviceProvider') ...[
                      _buildSectionTitle(
                          localizations.translate('serviceDetails')),
                      DropdownButtonFormField<Service>(
                        value: _selectedServiceSector,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          labelText: localizations.translate('serviceSector'),
                        ),
                        items: _serviceSectors.map((service) {
                          return DropdownMenuItem<Service>(
                            value: service,
                            child: Text(service.getName(currentLangCode)),
                          );
                        }).toList(),
                        onChanged: (Service? newValue) {
                          setState(() {
                            _selectedServiceSector = newValue;
                            _selectedServiceType = null;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _selectedServiceType,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          labelText: localizations.translate('serviceType'),
                        ),
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
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _servicePriceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: localizations.translate('servicePrice'),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations
                                .translate('servicePriceRequired');
                          }
                          if (double.tryParse(value) == null) {
                            return localizations.translate('enterValidPrice');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      Text(
                        localizations.translate('workingDays'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Column(
                        children: [
                          _buildDayCheckbox(
                              localizations.translate('monday'), 'Monday'),
                          _buildDayCheckbox(
                              localizations.translate('tuesday'), 'Tuesday'),
                          _buildDayCheckbox(
                              localizations.translate('wednesday'),
                              'Wednesday'),
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
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _workingHoursController,
                        decoration: InputDecoration(
                          labelText: localizations.translate('workingHours'),
                          hintText: '0900-1800',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations
                                .translate('workingHoursRequired');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          localizations.translate('saveChanges'),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ),
    );
  }

  Widget _buildDayCheckbox(String title, String dayValue) {
    return CheckboxListTile(
      title: Text(title),
      checkboxShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(
        color: Color.fromRGBO(217, 217, 217, 1),
        width: 2.0,
      ),
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
