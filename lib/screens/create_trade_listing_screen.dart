// lib/screens/create_trade_listing_screen.dart
import 'package:flutter/material.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/models/product_model.dart';
import 'package:mahallda_app/models/region_model.dart';
import 'package:mahallda_app/models/mahalla_model.dart';
import 'package:mahallda_app/models/trade_listing_model.dart';
import 'package:mahallda_app/models/user_model.dart';
import 'package:mahallda_app/services/api_service.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

class CreateTradeListingScreen extends StatefulWidget {
  const CreateTradeListingScreen({super.key});

  @override
  State<CreateTradeListingScreen> createState() =>
      _CreateTradeListingScreenState();
}

class _CreateTradeListingScreenState extends State<CreateTradeListingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  UserModel? _currentUserModel;

  List<Product> _productGroups = [];
  Product? _selectedProductGroup;
  String? _selectedProductType;
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _selectedCondition;
  final TextEditingController _descriptionController = TextEditingController();
  List<File> _selectedImageFiles = [];
  List<String> _enteredImageUrls = [];
  final TextEditingController _imageUrlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<Region> _regions = [];
  Region? _selectedRegion;
  List<Region> _districts = [];
  Region? _selectedDistrict;
  List<Mahalla> _mahallas = [];
  Mahalla? _selectedMahalla;

  final TextEditingController _contactNumberController =
      TextEditingController();
  bool _useProfileContact = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      _currentUserModel = await firebaseService
          .getUserData(firebaseService.getCurrentUser()!.uid);
      _productGroups = await firebaseService.fetchProductGroups();
      _regions = await apiService.fetchRegions();

      if (_currentUserModel != null) {
        if (_currentUserModel!.regionNs10Code != null) {
          _selectedRegion = _regions.firstWhereOrNull((r) =>
              r.ns10Code.toString() == _currentUserModel!.regionNs10Code);
          if (_selectedRegion != null) {
            _districts =
                await apiService.fetchDistricts(_selectedRegion!.ns10Code);
            if (_currentUserModel!.districtNs11Code != null) {
              _selectedDistrict = _districts.firstWhereOrNull((d) =>
                  d.ns11Code.toString() == _currentUserModel!.districtNs11Code);
              if (_selectedDistrict != null) {
                _mahallas = await apiService.fetchMahallas(
                    _selectedRegion!.ns10Code, _selectedDistrict!.ns11Code);
                if (_currentUserModel!.mahallaCode != null) {
                  _selectedMahalla = _mahallas.firstWhereOrNull((m) =>
                      m.code.toString() == _currentUserModel!.mahallaCode);
                }
              }
            }
          }
        }
        _contactNumberController.text = _currentUserModel!.phoneNumber ?? '';
      }
    } catch (e) {
      _showErrorDialog(e.toString());
      print("Boshlang'ich ma'lumotlarni yuklashda xato: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if ((_selectedImageFiles.length + _enteredImageUrls.length) >= 3) {
      _showErrorDialog(
          AppLocalizations.of(context)!.translate('maxImagesReached'));
      return;
    }
    final pickedFile =
        await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFiles.add(File(pickedFile.path));
      });
    }
  }

  void _removeImageFile(int index) {
    setState(() {
      _selectedImageFiles.removeAt(index);
    });
  }

  void _addImageUrl() {
    final url = _imageUrlController.text.trim();
    if (url.isNotEmpty && Uri.tryParse(url)?.hasAbsolutePath == true) {
      if ((_selectedImageFiles.length + _enteredImageUrls.length) >= 3) {
        _showErrorDialog(
            AppLocalizations.of(context)!.translate('maxImagesReached'));
        return;
      }
      setState(() {
        _enteredImageUrls.add(url);
        _imageUrlController.clear();
      });
    } else {
      _showErrorDialog(
          AppLocalizations.of(context)!.translate('enterValidImageUrl'));
    }
  }

  void _removeImageUrl(int index) {
    setState(() {
      _enteredImageUrls.removeAt(index);
    });
  }

  Future<void> _createListing() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentUserModel == null ||
        _currentUserModel!.uid == null ||
        _currentUserModel!.username == null) {
      _showErrorDialog(
          AppLocalizations.of(context)!.translate('loginToCreateListing'));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    try {
      List<String> finalImageUrls = [];
      for (var imageFile in _selectedImageFiles) {
        String url = await apiService.uploadTradeImage(imageFile);
        finalImageUrls.add(url);
      }
      finalImageUrls.addAll(_enteredImageUrls);

      final newListing = TradeListing(
        id: '',
        userId: _currentUserModel!.uid!,
        username: _currentUserModel!.username!,
        userProfilePhotoUrl: _currentUserModel!.profilePhotoUrl,
        productGroupId: _selectedProductGroup!.id,
        productGroupUz: _selectedProductGroup!.nameUz,
        productType: _selectedProductType!,
        productName: _productNameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        condition: _selectedCondition!,
        description: _descriptionController.text.trim(),
        imageUrls: finalImageUrls,
        contactNumber: _useProfileContact
            ? (_currentUserModel!.phoneNumber ?? '')
            : _contactNumberController.text.trim(),
        regionNs10Code: _selectedRegion!.ns10Code.toString(),
        regionNameUz: _selectedRegion!.nameUz,
        districtNs11Code: _selectedDistrict!.ns11Code.toString(),
        districtNameUz: _selectedDistrict!.getDistrict('uz') ?? '',
        mahallaCode: _selectedMahalla!.code.toString(),
        mahallaNameUz: _selectedMahalla!.nameUz,
        createdAt: Timestamp.now(),
      );

      await firebaseService.addTradeListing(newListing);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(localizations.translate('listingCreatedSuccessfully'))),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorDialog(
          localizations.translate('failedToCreateListing') + ": $e");
      print("E'lon yaratishda xato: $e");
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
        title: Text(localizations.translate('createListing')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('productInfo'),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<Product>(
                      value: _selectedProductGroup,
                      decoration: InputDecoration(
                        labelText: localizations.translate('productGroup'),
                      ),
                      items: _productGroups.map((group) {
                        return DropdownMenuItem<Product>(
                          value: group,
                          child: Text(group.getName(currentLangCode)),
                        );
                      }).toList(),
                      onChanged: (Product? newValue) {
                        setState(() {
                          _selectedProductGroup = newValue;
                          _selectedProductType = null;
                        });
                      },
                      validator: (value) => value == null
                          ? localizations.translate('selectProductGroup')
                          : null,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _selectedProductType,
                      decoration: InputDecoration(
                        labelText: localizations.translate('productType'),
                      ),
                      items: _selectedProductGroup?.productTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList() ??
                          [],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedProductType = newValue;
                        });
                      },
                      validator: (value) => value == null
                          ? localizations.translate('selectProductType')
                          : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _productNameController,
                      decoration: InputDecoration(
                        labelText: localizations.translate('productName'),
                      ),
                      validator: (value) => value!.isEmpty
                          ? localizations.translate('enterProductName')
                          : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: localizations.translate('price') + ' (UZS)',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return localizations.translate('enterPrice');
                        }
                        if (double.tryParse(value) == null) {
                          return localizations.translate('enterValidPrice');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      decoration: InputDecoration(
                        labelText: localizations.translate('condition'),
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 'new',
                            child: Text(localizations.translate('new'))),
                        DropdownMenuItem(
                            value: 'used',
                            child: Text(localizations.translate('used'))),
                      ],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCondition = newValue;
                        });
                      },
                      validator: (value) => value == null
                          ? localizations.translate('selectCondition')
                          : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: localizations.translate('description'),
                      ),
                      validator: (value) => value!.isEmpty
                          ? localizations.translate('enterDescription')
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      localizations.translate('productImagesOptional'),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: Text(
                                localizations.translate('pickFromGallery')),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: Text(localizations.translate('takePhoto')),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                        child: Text(localizations.translate('or'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(color: Colors.grey[700]))),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imageUrlController,
                            decoration: InputDecoration(
                              labelText: localizations.translate('imageUrl'),
                              hintText: 'https://example.com/image.jpg',
                            ),
                            keyboardType: TextInputType.url,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _addImageUrl,
                          child: Text(localizations.translate('addImageUrl')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: (_selectedImageFiles.isNotEmpty ||
                              _enteredImageUrls.isNotEmpty)
                          ? 100
                          : 0,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImageFiles.length +
                            _enteredImageUrls.length,
                        itemBuilder: (context, index) {
                          if (index < _selectedImageFiles.length) {
                            return Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _selectedImageFiles[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () => _removeImageFile(index),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red[700],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            final imageUrlIndex =
                                index - _selectedImageFiles.length;
                            return Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      _enteredImageUrls[imageUrlIndex],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: Icon(Icons.broken_image,
                                            color: Colors.grey[600]),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () => _removeImageUrl(imageUrlIndex),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.red[700],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      localizations.translate('locationInfo'),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<Region>(
                      value: _selectedRegion,
                      decoration: InputDecoration(
                        labelText: localizations.translate('selectRegion'),
                      ),
                      items: _regions.map((region) {
                        return DropdownMenuItem<Region>(
                          value: region,
                          child: Text(region.getName(currentLangCode)),
                        );
                      }).toList(),
                      onChanged: (Region? newValue) async {
                        setState(() {
                          _selectedRegion = newValue;
                          _selectedDistrict = null;
                          _selectedMahalla = null;
                          _districts.clear();
                          _mahallas.clear();
                        });
                        if (newValue != null) {
                          final apiService =
                              Provider.of<ApiService>(context, listen: false);
                          _districts = await apiService
                              .fetchDistricts(newValue.ns10Code);
                          setState(() {});
                        }
                      },
                      validator: (value) => value == null
                          ? localizations.translate('selectRegion')
                          : null,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<Region>(
                      value: _selectedDistrict,
                      decoration: InputDecoration(
                        labelText: localizations.translate('selectDistrict'),
                      ),
                      items: _districts.map((district) {
                        return DropdownMenuItem<Region>(
                          value: district,
                          child:
                              Text(district.getDistrict(currentLangCode) ?? ''),
                        );
                      }).toList(),
                      onChanged: (Region? newValue) async {
                        setState(() {
                          _selectedDistrict = newValue;
                          _selectedMahalla = null;
                          _mahallas.clear();
                        });
                        if (_selectedRegion != null && newValue != null) {
                          final apiService =
                              Provider.of<ApiService>(context, listen: false);
                          _mahallas = await apiService.fetchMahallas(
                              _selectedRegion!.ns10Code, newValue.ns11Code);
                          setState(() {});
                        }
                      },
                      validator: (value) => value == null
                          ? localizations.translate('selectDistrict')
                          : null,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<Mahalla>(
                      value: _selectedMahalla,
                      decoration: InputDecoration(
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
                      validator: (value) => value == null
                          ? localizations.translate('selectMahalla')
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      localizations.translate('contactInfo'),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    CheckboxListTile(
                      title: Text(localizations.translate('useProfileContact')),
                      value: _useProfileContact,
                      onChanged: (bool? value) {
                        setState(() {
                          _useProfileContact = value!;
                          if (_useProfileContact) {
                            _contactNumberController.text =
                                _currentUserModel?.phoneNumber ?? '';
                          } else {
                            _contactNumberController.clear();
                          }
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    if (!_useProfileContact)
                      TextFormField(
                        controller: _contactNumberController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: localizations.translate('contactNumber'),
                          hintText: '+998 XX YYY ZZ ZZ',
                        ),
                        validator: (value) {
                          if (!_useProfileContact && value!.isEmpty) {
                            return localizations
                                .translate('enterContactNumber');
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createListing,
                        child: Text(
                          localizations.translate('createListing'),
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
}
