// lib/screens/all_service_providers_screen.dart
import 'package:flutter/material.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/models/combined_service_provider.dart';
import 'package:mahallda_app/models/service_model.dart';
import 'package:mahallda_app/models/region_model.dart';
import 'package:mahallda_app/models/mahalla_model.dart';
import 'package:mahallda_app/services/api_service.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:mahallda_app/widgets/service_provider_card.dart';
import 'package:mahallda_app/screens/service_provider_detail_screen.dart';
import 'package:collection/collection.dart';

class AllServiceProvidersScreen extends StatefulWidget {
  final String? currentUserMahallaCode;
  final String? serviceSectorId;
  final String? serviceType;

  const AllServiceProvidersScreen({
    super.key,
    this.currentUserMahallaCode,
    this.serviceSectorId,
    this.serviceType,
  });

  @override
  State<AllServiceProvidersScreen> createState() =>
      _AllServiceProvidersScreenState();
}

class _AllServiceProvidersScreenState extends State<AllServiceProvidersScreen> {
  List<CombinedServiceProvider> _allProviders = [];
  List<CombinedServiceProvider> _filteredProviders = [];
  bool _isLoading = true;

  bool _filterByMyMahalla = false;
  Service? _selectedFilterServiceSector;
  String? _selectedFilterServiceType;
  Region? _selectedFilterRegion;
  Region? _selectedFilterDistrict;
  Mahalla? _selectedFilterMahalla;

  List<Service> _filterServiceSectors = [];
  List<Region> _filterRegions = [];
  List<Region> _modalDistricts = [];
  List<Mahalla> _modalMahallas = [];

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    if (widget.serviceSectorId != null) {
      // Bu yerda _filterServiceSectors hali yuklanmagan bo'lishi mumkin.
      // Shuning uchun, _fetchFilterData ichida _selectedFilterServiceSector ni o'rnatish yaxshiroq.
    }
    if (widget.serviceType != null) {
      _selectedFilterServiceType = widget.serviceType;
    }
    _fetchAllProviders();
    _fetchFilterData();
  }

  Future<void> _fetchAllProviders() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      _allProviders = await firebaseService.getAllCombinedServiceProviders(
        serviceSectorId: widget.serviceSectorId,
        serviceType: widget.serviceType,
      );
      _applyFilters();
    } catch (e) {
      _showErrorDialog(e.toString());
      print("Barcha xizmat ko'rsatuvchilarni yuklashda xato: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchFilterData() async {
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      _filterServiceSectors = await firebaseService.fetchServiceSectors();

      if (widget.serviceSectorId != null) {
        _selectedFilterServiceSector = _filterServiceSectors.firstWhereOrNull(
            (service) => service.id == widget.serviceSectorId);
      }

      _filterRegions = await _apiService.fetchRegions();
    } catch (e) {
      print("Filter ma'lumotlarini yuklashda xato: $e");
    }
  }

  Future<List<Region>> _fetchDistrictsForModal(int ns10Code) async {
    try {
      return await _apiService.fetchDistricts(ns10Code);
    } catch (e) {
      print("Filter tumanlarini yuklashda xato: $e");
      return [];
    }
  }

  Future<List<Mahalla>> _fetchMahallasForModal(
      int ns10Code, int ns11Code) async {
    try {
      return await _apiService.fetchMahallas(ns10Code, ns11Code);
    } catch (e) {
      print("Filter mahallalarini yuklashda xato: $e");
      return [];
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredProviders = _allProviders.where((provider) {
        bool matches = true;

        if (_filterByMyMahalla && widget.currentUserMahallaCode != null) {
          matches = matches &&
              (provider.user.mahallaCode == widget.currentUserMahallaCode);
        }

        if (_selectedFilterServiceSector != null) {
          matches = matches &&
              (provider.serviceProvider.serviceSector ==
                  _selectedFilterServiceSector!.id);
        }

        if (_selectedFilterServiceType != null) {
          matches = matches &&
              (provider.serviceProvider.serviceType ==
                  _selectedFilterServiceType);
        }

        if (_selectedFilterRegion != null) {
          matches = matches &&
              (provider.user.regionNs10Code ==
                  _selectedFilterRegion!.ns10Code.toString());
        }

        if (_selectedFilterDistrict != null) {
          matches = matches &&
              (provider.user.districtNs11Code ==
                  _selectedFilterDistrict!.ns11Code.toString());
        }

        if (_selectedFilterMahalla != null) {
          matches = matches &&
              (provider.user.mahallaCode ==
                  _selectedFilterMahalla!.code.toString());
        }

        return matches;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _filterByMyMahalla = false;
      _selectedFilterServiceSector = null;
      _selectedFilterServiceType = null;
      _selectedFilterRegion = null;
      _selectedFilterDistrict = null;
      _selectedFilterMahalla = null;
      _modalDistricts.clear(); // O'zgaruvchi nomi to'g'irlandi
      _modalMahallas.clear(); // O'zgaruvchi nomi to'g'irlandi
    });
    _fetchAllProviders();
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

  void _showFilterDialog() {
    final localizations = AppLocalizations.of(context)!;
    final currentLangCode = Localizations.localeOf(context).languageCode;

    bool tempFilterByMyMahalla = _filterByMyMahalla;
    Service? tempSelectedFilterServiceSector = _selectedFilterServiceSector;
    String? tempSelectedFilterServiceType = _selectedFilterServiceType;
    Region? tempSelectedFilterRegion = _selectedFilterRegion;
    Region? tempSelectedFilterDistrict = _selectedFilterDistrict;
    Mahalla? tempSelectedFilterMahalla = _selectedFilterMahalla;

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
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
                    localizations.translate('filter'),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 30),
                  if (widget.currentUserMahallaCode != null)
                    SwitchListTile(
                      title: Text(localizations.translate('myMahalla')),
                      value: tempFilterByMyMahalla,
                      onChanged: (bool value) {
                        modalSetState(() {
                          tempFilterByMyMahalla = value;
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
                  DropdownButtonFormField<Service>(
                    value: tempSelectedFilterServiceSector,
                    decoration: InputDecoration(
                      labelText:
                          localizations.translate('selectServiceSectorFilter'),
                    ),
                    items: _filterServiceSectors.map((service) {
                      return DropdownMenuItem<Service>(
                        value: service,
                        child: Text(service.getName(currentLangCode)),
                      );
                    }).toList(),
                    onChanged: (Service? newValue) {
                      modalSetState(() {
                        tempSelectedFilterServiceSector = newValue;
                        tempSelectedFilterServiceType = null;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: tempSelectedFilterServiceType,
                    decoration: InputDecoration(
                      labelText:
                          localizations.translate('selectServiceTypeFilter'),
                    ),
                    items: tempSelectedFilterServiceSector?.serviceTypes
                            .map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList() ??
                        [],
                    onChanged: (String? newValue) {
                      modalSetState(() {
                        tempSelectedFilterServiceType = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            modalSetState(() {
                              tempFilterByMyMahalla = false;
                              tempSelectedFilterServiceSector = null;
                              tempSelectedFilterServiceType = null;
                              tempSelectedFilterRegion = null;
                              tempSelectedFilterDistrict = null;
                              tempSelectedFilterMahalla = null;
                              tempModalDistricts.clear();
                              tempModalMahallas.clear();
                            });
                            _clearFilters();
                            Navigator.pop(context);
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
                              _filterByMyMahalla = tempFilterByMyMahalla;
                              _selectedFilterServiceSector =
                                  tempSelectedFilterServiceSector;
                              _selectedFilterServiceType =
                                  tempSelectedFilterServiceType;
                              _selectedFilterRegion = tempSelectedFilterRegion;
                              _selectedFilterDistrict =
                                  tempSelectedFilterDistrict;
                              _selectedFilterMahalla =
                                  tempSelectedFilterMahalla;
                              _modalDistricts = tempModalDistricts;
                              _modalMahallas = tempModalMahallas;
                            });
                            Navigator.pop(context);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('allServiceProviders')),
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  CircularProgressIndicator(color: Theme.of(context).hintColor),
            )
          else
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredProviders.isEmpty
              ? Center(
                  child:
                      Text(localizations.translate('noServiceProvidersFound')))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _filteredProviders.length,
                  itemBuilder: (context, index) {
                    final provider = _filteredProviders[index];
                    return ServiceProviderCard(
                      provider: provider,
                      currentLangCode:
                          Localizations.localeOf(context).languageCode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ServiceProviderDetailScreen(provider: provider),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
