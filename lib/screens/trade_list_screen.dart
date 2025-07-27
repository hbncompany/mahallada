// lib/screens/trade_list_screen.dart
import 'package:flutter/material.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/models/trade_listing_model.dart';
import 'package:mahallda_app/models/user_model.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:mahallda_app/screens/create_trade_listing_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mahallda_app/models/product_model.dart';
import 'package:mahallda_app/models/region_model.dart';
import 'package:mahallda_app/models/mahalla_model.dart';
import 'package:mahallda_app/services/api_service.dart';
import 'package:mahallda_app/screens/trade_user_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';

class TradeListScreen extends StatefulWidget {
  const TradeListScreen({super.key});

  @override
  State<TradeListScreen> createState() => _TradeListScreenState();
}

// Define an enum for the filter options
enum TradeListFilter {
  allListings,
  myListings,
}

class _TradeListScreenState extends State<TradeListScreen> {
  Product? _selectedFilterProductGroup;
  String? _selectedFilterProductType;
  String? _selectedFilterCondition;
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  Region? _selectedFilterRegion;
  Region? _selectedFilterDistrict;
  Mahalla? _selectedFilterMahalla;
  bool _filterByMyMahalla = false;

  List<Product> _filterProductGroups = [];
  List<Region> _filterRegions = [];
  List<Region> _modalDistricts = [];
  List<Mahalla> _modalMahallas = [];

  bool _isFilterDataLoading = true;
  UserModel? _currentUserModel;

  // New state variable for trade list filter
  TradeListFilter _currentTradeListFilter = TradeListFilter.allListings;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instance to get current user

  @override
  void initState() {
    super.initState();
    _fetchFilterData();
    _loadCurrentUserModel();
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserModel() async {
    final firebaseService =
    Provider.of<FirebaseService>(context, listen: false);
    final currentUser = firebaseService.getCurrentUser();
    if (currentUser != null) {
      _currentUserModel = await firebaseService.getUserData(currentUser.uid);
      setState(() {});
    }
  }

  Future<void> _fetchFilterData() async {
    setState(() {
      _isFilterDataLoading = true;
    });
    try {
      final firebaseService =
      Provider.of<FirebaseService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);

      _filterProductGroups = await firebaseService.fetchProductGroups();
      _filterRegions = await apiService.fetchRegions();
    } catch (e) {
      _showErrorDialog(e.toString());
      print("Filter ma'lumotlarini yuklashda xato: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isFilterDataLoading = false;
        });
      }
    }
  }

  Future<List<Region>> _fetchDistrictsForModal(int ns10Code) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      return await apiService.fetchDistricts(ns10Code);
    } catch (e) {
      print("Filter tumanlarini yuklashda xato: $e");
      return [];
    }
  }

  Future<List<Mahalla>> _fetchMahallasForModal(
      int ns10Code, int ns11Code) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      return await apiService.fetchMahallas(ns10Code, ns11Code);
    } catch (e) {
      print("Filter mahallalarini yuklashda xato: $e");
      return [];
    }
  }

  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> allListingsWithUsers) {
    return allListingsWithUsers.where((item) {
      final listing = item['listing'] as TradeListing;
      bool matches = true;

      // Apply "My Mahalla" filter
      if (_filterByMyMahalla &&
          _currentUserModel != null &&
          _currentUserModel!.mahallaCode != null) {
        matches =
            matches && (listing.mahallaCode == _currentUserModel!.mahallaCode);
      }

      // Apply other filters only if "My Mahalla" is not active, or if they are relevant
      if (!_filterByMyMahalla) {
        if (_selectedFilterRegion != null) {
          matches = matches &&
              (listing.regionNs10Code ==
                  _selectedFilterRegion!.ns10Code.toString());
        }
        if (_selectedFilterDistrict != null) {
          matches = matches &&
              (listing.districtNs11Code ==
                  _selectedFilterDistrict!.ns11Code.toString());
        }
        if (_selectedFilterMahalla != null) {
          matches = matches &&
              (listing.mahallaCode == _selectedFilterMahalla!.code.toString());
        }
      }


      if (_selectedFilterProductGroup != null) {
        matches = matches &&
            (listing.productGroupId == _selectedFilterProductGroup!.id);
      }

      if (_selectedFilterProductType != null) {
        matches =
            matches && (listing.productType == _selectedFilterProductType);
      }

      if (_selectedFilterCondition != null) {
        matches = matches && (listing.condition == _selectedFilterCondition);
      }

      double? minPrice = double.tryParse(_minPriceController.text);
      double? maxPrice = double.tryParse(_maxPriceController.text);
      if (minPrice != null) {
        matches = matches && (listing.price >= minPrice);
      }
      if (maxPrice != null) {
        matches = matches && (listing.price <= maxPrice);
      }


      return matches;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _selectedFilterProductGroup = null;
      _selectedFilterProductType = null;
      _selectedFilterCondition = null;
      _minPriceController.clear();
      _maxPriceController.clear();
      _selectedFilterRegion = null;
      _selectedFilterDistrict = null;
      _selectedFilterMahalla = null;
      _modalDistricts.clear();
      _modalMahallas.clear();
      _filterByMyMahalla = false;
    });
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showErrorDialog(
          AppLocalizations.of(context)!.translate('couldNotLaunchPhoneCall'));
    }
  }

  // New function to confirm deletion
  Future<void> _confirmDeleteListing(String listingId) async {
    final localizations = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(localizations.translate('deleteListingConfirmationTitle')),
          content: Text(localizations.translate('deleteListingConfirmationMessage')),
          actions: <Widget>[
            TextButton(
              child: Text(localizations.translate('cancel')),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
              },
            ),
            TextButton(
              child: Text(localizations.translate('delete')),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                try {
                  await Provider.of<FirebaseService>(context, listen: false).deleteTradeListing(listingId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.translate('listingDeletedSuccessfully'))),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${localizations.translate('failedToDeleteListing')}: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog() {
    final localizations = AppLocalizations.of(context)!;
    final currentLangCode = Localizations.localeOf(context).languageCode;

    Product? tempSelectedFilterProductGroup = _selectedFilterProductGroup;
    String? tempSelectedFilterProductType = _selectedFilterProductType;
    String? tempSelectedFilterCondition = _selectedFilterCondition;
    final TextEditingController tempMinPriceController =
    TextEditingController(text: _minPriceController.text);
    final TextEditingController tempMaxPriceController =
    TextEditingController(text: _maxPriceController.text);
    Region? tempSelectedFilterRegion = _selectedFilterRegion;
    Region? tempSelectedFilterDistrict = _selectedFilterDistrict;
    Mahalla? tempSelectedFilterMahalla = _selectedFilterMahalla;
    bool tempFilterByMyMahalla = _filterByMyMahalla;

    List<Region> tempModalDistricts = List.from(_modalDistricts);
    List<Mahalla> tempModalMahallas = List.from(_modalMahallas);

    if (tempSelectedFilterRegion != null) {
      _fetchDistrictsForModal(tempSelectedFilterRegion!.ns10Code)
          .then((districts) {
        if (mounted) {
          setState(() {
            tempModalDistricts = districts;
            if (tempSelectedFilterDistrict != null) {
              tempSelectedFilterDistrict = tempModalDistricts.firstWhereOrNull(
                      (d) => d.ns11Code == tempSelectedFilterDistrict!.ns11Code);
              if (tempSelectedFilterDistrict != null) {
                _fetchMahallasForModal(tempSelectedFilterRegion!.ns10Code,
                    tempSelectedFilterDistrict!.ns11Code)
                    .then((mahallas) {
                  if (mounted) {
                    setState(() {
                      tempModalMahallas = mahallas;
                      if (tempSelectedFilterMahalla != null) {
                        tempSelectedFilterMahalla =
                            tempModalMahallas.firstWhereOrNull((m) =>
                            m.code == tempSelectedFilterMahalla!.code);
                      }
                    });
                  }
                });
              }
            }
          });
        }
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(25.0)), // Yuqori burchaklarni yumaloq qilish
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate('filterTradeListings'),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 30),
                  if (_currentUserModel != null &&
                      _currentUserModel!.mahallaCode != null)
                    SwitchListTile(
                      title: Text(localizations.translate('myMahalla')),
                      value: tempFilterByMyMahalla,
                      onChanged: (bool value) {
                        modalSetState(() {
                          tempFilterByMyMahalla = value;
                          // Clear location filters if "My Mahalla" is enabled
                          if (value) {
                            tempSelectedFilterRegion = null;
                            tempSelectedFilterDistrict = null;
                            tempSelectedFilterMahalla = null;
                            tempModalDistricts.clear();
                            tempModalMahallas.clear();
                          }
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                  const SizedBox(height: 10),
                  // Conditionally show location filters if "My Mahalla" is NOT active
                  if (!tempFilterByMyMahalla) ...[
                    DropdownButtonFormField<Region>(
                      value: tempSelectedFilterRegion,
                      decoration: InputDecoration(
                        labelText:
                        localizations.translate('selectRegionFilter'),
                      ),
                      items: _filterRegions.map((region) {
                        return DropdownMenuItem<Region>(
                          value: region,
                          child: Text(region.getName(currentLangCode)),
                        );
                      }).toList(),
                      onChanged: (Region? newValue) async {
                        modalSetState(() {
                          tempSelectedFilterRegion = newValue;
                          tempSelectedFilterDistrict = null;
                          tempSelectedFilterMahalla = null;
                          tempModalDistricts.clear();
                          tempModalMahallas.clear();
                        });
                        if (newValue != null) {
                          final fetchedDistricts =
                          await _fetchDistrictsForModal(newValue.ns10Code);
                          modalSetState(() {
                            tempModalDistricts = fetchedDistricts;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<Region>(
                      value: tempSelectedFilterDistrict,
                      decoration: InputDecoration(
                        labelText:
                        localizations.translate('selectDistrictFilter'),
                      ),
                      items: tempModalDistricts.map((district) {
                        return DropdownMenuItem<Region>(
                          value: district,
                          child:
                          Text(district.getDistrict(currentLangCode) ?? ''),
                        );
                      }).toList(),
                      onChanged: (Region? newValue) async {
                        modalSetState(() {
                          tempSelectedFilterDistrict = newValue;
                          tempSelectedFilterMahalla = null;
                          tempModalMahallas.clear();
                        });
                        if (tempSelectedFilterRegion != null &&
                            newValue != null) {
                          final fetchedMahallas = await _fetchMahallasForModal(
                              tempSelectedFilterRegion!.ns10Code,
                              newValue.ns11Code);
                          modalSetState(() {
                            tempModalMahallas = fetchedMahallas;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<Mahalla>(
                      value: tempSelectedFilterMahalla,
                      decoration: InputDecoration(
                        labelText:
                        localizations.translate('selectMahallaFilter'),
                      ),
                      items: tempModalMahallas.map((mahalla) {
                        return DropdownMenuItem<Mahalla>(
                          value: mahalla,
                          child: Text(mahalla.getName(currentLangCode)),
                        );
                      }).toList(),
                      onChanged: (Mahalla? newValue) {
                        modalSetState(() {
                          tempSelectedFilterMahalla = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                  DropdownButtonFormField<Product>(
                    value: tempSelectedFilterProductGroup,
                    decoration: InputDecoration(
                      labelText:
                      localizations.translate('selectProductGroupFilter'),
                    ),
                    items: _filterProductGroups.map((group) {
                      return DropdownMenuItem<Product>(
                        value: group,
                        child: Text(group.getName(currentLangCode)),
                      );
                    }).toList(),
                    onChanged: (Product? newValue) {
                      modalSetState(() {
                        tempSelectedFilterProductGroup = newValue;
                        tempSelectedFilterProductType = null;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: tempSelectedFilterProductType,
                    decoration: InputDecoration(
                      labelText:
                      localizations.translate('selectProductTypeFilter'),
                    ),
                    items: tempSelectedFilterProductGroup?.productTypes
                        .map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList() ??
                        [],
                    onChanged: (String? newValue) {
                      modalSetState(() {
                        tempSelectedFilterProductType = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: tempSelectedFilterCondition,
                    decoration: InputDecoration(
                      labelText:
                      localizations.translate('selectConditionFilter'),
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
                      modalSetState(() {
                        tempSelectedFilterCondition = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: tempMinPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: localizations.translate('minPrice'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: tempMaxPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: localizations.translate('maxPrice'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            modalSetState(() {
                              tempSelectedFilterProductGroup = null;
                              tempSelectedFilterProductType = null;
                              tempSelectedFilterCondition = null;
                              tempMinPriceController.clear();
                              tempMaxPriceController.clear();
                              tempSelectedFilterRegion = null;
                              tempSelectedFilterDistrict = null;
                              tempSelectedFilterMahalla = null;
                              tempModalDistricts.clear();
                              tempModalMahallas.clear();
                              tempFilterByMyMahalla = false;
                            });
                            _clearFilters(); // Also clear global filters
                            Navigator.pop(context); // Close the modal
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          child: Text(localizations.translate('clearFilters')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilterProductGroup =
                                  tempSelectedFilterProductGroup;
                              _selectedFilterProductType =
                                  tempSelectedFilterProductType;
                              _selectedFilterCondition =
                                  tempSelectedFilterCondition;
                              _minPriceController.text =
                                  tempMinPriceController.text;
                              _maxPriceController.text =
                                  tempMaxPriceController.text;
                              _selectedFilterRegion = tempSelectedFilterRegion;
                              _selectedFilterDistrict =
                                  tempSelectedFilterDistrict;
                              _selectedFilterMahalla =
                                  tempSelectedFilterMahalla;
                              _modalDistricts = tempModalDistricts;
                              _modalMahallas = tempModalMahallas;
                              _filterByMyMahalla = tempFilterByMyMahalla;
                            });
                            Navigator.pop(context); // Close the modal
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          child: Text(localizations.translate('applyFilters')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final firebaseService = Provider.of<FirebaseService>(context);
    final currentUser = _auth.currentUser; // Get current user

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('tradeListings')),
        actions: [
          if (_isFilterDataLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(
                  color: Theme.of(context).hintColor),
            )
          else
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
        ],
        // Add SegmentedButton to AppBar's bottom
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 10), // Adjust height
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SegmentedButton<TradeListFilter>(
                    segments: <ButtonSegment<TradeListFilter>>[
                      ButtonSegment<TradeListFilter>(
                        value: TradeListFilter.allListings,
                        label: Text(localizations.translate('allListings')),
                        icon: const Icon(Icons.list_alt),
                      ),
                      ButtonSegment<TradeListFilter>(
                        value: TradeListFilter.myListings,
                        label: Text(localizations.translate('myListings')),
                        icon: const Icon(Icons.person),
                      ),
                    ],
                    selected: <TradeListFilter>{_currentTradeListFilter},
                    onSelectionChanged: (Set<TradeListFilter> newSelection) {
                      setState(() {
                        _currentTradeListFilter = newSelection.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary, // Color for unselected text/icon
                      selectedForegroundColor: Theme.of(context).colorScheme.onPrimary, // Color for selected text/icon
                      selectedBackgroundColor: Theme.of(context).colorScheme.primary, // Background color for selected segment
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _currentTradeListFilter == TradeListFilter.allListings
            ? firebaseService.getTradeListingsWithUserDetails()
            : (currentUser != null
            ? firebaseService.getMyTradeListingsStream(currentUser.uid).asyncMap((listings) async {
          // Convert TradeListing to a map with user details for consistency
          List<Map<String, dynamic>> result = [];
          for (var listing in listings) {
            // Ensure we fetch user data for 'myListings' as well for display
            UserModel? userModel = await firebaseService.getUserData(listing.userId);
            result.add({'listing': listing, 'userModel': userModel});
          }
          return result;
        })
            : Stream.value([]) // Return an empty stream if no user logged in for "My Listings"
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text(
                    "${localizations.translate('errorLoadingListings')}: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(localizations.translate('noListingsFound')));
          } else {
            final filteredItems = _applyFilters(snapshot.data!);
            if (filteredItems.isEmpty) {
              return Center(
                  child: Text(
                      localizations.translate('noListingsFoundWithFilters')));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final listing = item['listing'] as TradeListing;
                final userModel = item['userModel'] as UserModel?;

                // Determine if the current listing belongs to the logged-in user
                final isMyListing = currentUser != null && listing.userId == currentUser.uid;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (userModel != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TradeUserDetailScreen(user: userModel),
                                ),
                              );
                            } else {
                              _showErrorDialog(
                                  localizations.translate('userNotFound'));
                            }
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: userModel?.profilePhotoUrl !=
                                    null &&
                                    userModel!.profilePhotoUrl!.isNotEmpty
                                    ? NetworkImage(userModel.profilePhotoUrl!)
                                    : const AssetImage(
                                    'assets/placeholder_profile.png')
                                as ImageProvider,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  userModel?.username ??
                                      localizations.translate('unknownUser'),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .primaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                "${listing.createdAt.toDate().day}.${listing.createdAt.toDate().month}.${listing.createdAt.toDate().year}",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 24),

                        if (listing.imageUrls.isNotEmpty)
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: listing.imageUrls.length,
                              itemBuilder: (context, imgIndex) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      right: 10.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        12),
                                    child: Image.network(
                                      listing.imageUrls[imgIndex],
                                      width: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                          Container(
                                            width: 180,
                                            color: Colors.grey[300],
                                            child: Icon(Icons.broken_image,
                                                color: Colors.grey[600]),
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        if (listing.imageUrls.isNotEmpty)
                          const SizedBox(height: 15),

                        Text(
                          listing.productName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${localizations.translate('price')}: ${listing.price.toStringAsFixed(0)} UZS",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${localizations.translate('condition')}: ${localizations.translate(listing.condition)}",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 12),

                        Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${listing.regionNameUz}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(color: Colors.grey[700]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${listing.districtNameUz}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(color: Colors.grey[700]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${listing.mahallaNameUz}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(color: Colors.grey[700]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Text(
                          localizations.translate('description'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          listing.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: Colors.grey[800]),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 15),

                        // Only show action buttons if it's "My Listings" and the listing belongs to the current user
                        if (_currentTradeListFilter == TradeListFilter.myListings && isMyListing)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                /*IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: localizations.translate('edit'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CreateTradeListingScreen(),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    listing.isActive ? Icons.toggle_on : Icons.toggle_off,
                                    color: listing.isActive ? Colors.green : Colors.red,
                                  ),
                                  tooltip: listing.isActive ? localizations.translate('deactivate') : localizations.translate('activate'),
                                  onPressed: () async {
                                  },
                                ),*/
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: localizations.translate('delete'),
                                  onPressed: () => _confirmDeleteListing(listing.id!),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _makePhoneCall(listing.contactNumber),
                            icon: const Icon(Icons.call),
                            label: Text(localizations.translate('contact') +
                                ": ${listing.contactNumber}"),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CreateTradeListingScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}