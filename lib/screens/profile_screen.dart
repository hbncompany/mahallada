// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/models/user_model.dart';
import 'package:mahallda_app/models/service_provider_model.dart';
import 'package:mahallda_app/models/service_model.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mahallda_app/screens/edit_profile_screen.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? userModel; // <-- Named parameter to'g'ri aniqlangan

  const ProfileScreen(
      {super.key, this.userModel}); // <-- Named parameter to'g'ri aniqlangan

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _displayUserModel;
  ServiceProviderModel? _serviceProviderModel;
  bool _isLoading = true;
  String? _currentUserId;
  Map<String, Service> _serviceSectorsMap = {};

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoading = true;
    });

    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final currentUser = firebaseService.getCurrentUser();

    if (widget.userModel != null) {
      _displayUserModel = widget.userModel;
      _currentUserId = _displayUserModel!.uid;
    } else if (currentUser != null) {
      _currentUserId = currentUser.uid;
      _displayUserModel = await firebaseService.getUserData(_currentUserId!);
    } else {
      print("Foydalanuvchi tizimga kirmagan.");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    if (_displayUserModel != null &&
        _displayUserModel!.role == 'serviceProvider') {
      _serviceProviderModel =
          await firebaseService.getServiceProviderData(_displayUserModel!.uid!);
      List<Service> services = await firebaseService.fetchServiceSectors();
      _serviceSectorsMap = {for (var s in services) s.id: s};
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final isCurrentUserProfile =
        _currentUserId == firebaseService.getCurrentUser()?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCurrentUserProfile
            ? localizations.translate('myProfile')
            : localizations.translate('profile')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _displayUserModel == null
              ? Center(child: Text(localizations.translate('noUserData')))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _displayUserModel!.profilePhotoUrl !=
                                null
                            ? NetworkImage(_displayUserModel!.profilePhotoUrl!)
                            : const AssetImage('assets/placeholder_profile.png')
                                as ImageProvider,
                        child: _displayUserModel!.profilePhotoUrl == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[600],
                              )
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _buildInfoCard(
                        context,
                        title: localizations.translate('generalInfo'),
                        children: [
                          _buildInfoRow(localizations.translate('username'),
                              _displayUserModel!.username ?? 'N/A'),
                          _buildInfoRow(localizations.translate('email'),
                              _displayUserModel!.email ?? 'N/A'),
                          _buildInfoRow(localizations.translate('phoneNumber'),
                              _displayUserModel!.phoneNumber ?? 'N/A'),
                          _buildInfoRow(
                              localizations.translate('role'),
                              localizations
                                  .translate(_displayUserModel!.role ?? 'N/A')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildInfoCard(
                        context,
                        title: localizations.translate('location'),
                        children: [
                          _buildInfoRow(localizations.translate('selectRegion'),
                              _displayUserModel!.regionNameUz ?? 'N/A'),
                          _buildInfoRow(
                              localizations.translate('selectDistrict'),
                              _displayUserModel!.districtNameUz ?? 'N/A'),
                          _buildInfoRow(
                              localizations.translate('selectMahalla'),
                              _displayUserModel!.mahallaNameUz ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_displayUserModel!.role == 'serviceProvider' &&
                          _serviceProviderModel != null)
                        _buildInfoCard(
                          context,
                          title: localizations.translate('serviceDetails'),
                          children: [
                            _buildInfoRow(
                              localizations.translate('serviceSector'),
                              _serviceSectorsMap[
                                          _serviceProviderModel!.serviceSector]
                                      ?.getName(currentLangCode) ??
                                  _serviceProviderModel!.serviceSector ??
                                  'N/A',
                            ),
                            _buildInfoRow(
                                localizations.translate('serviceType'),
                                _serviceProviderModel!.serviceType ?? 'N/A'),
                            _buildInfoRow(
                                localizations.translate('servicePrice'),
                                "${_serviceProviderModel!.servicePrice?.toStringAsFixed(0) ?? 'N/A'} UZS"),
                            _buildInfoRow(
                                localizations.translate('workingDays'),
                                _serviceProviderModel!.workingDays
                                        ?.join(', ') ??
                                    'N/A'),
                            _buildInfoRow(
                                localizations.translate('workingHours'),
                                _serviceProviderModel!.workingHours ?? 'N/A'),
                          ],
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_displayUserModel != null) {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SubscriptionScreen(),
                                ),
                              );
                              if (result == true) {
                                _fetchProfileData();
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            localizations.translate('Subscription'),
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isCurrentUserProfile)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_displayUserModel != null) {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(
                                      user: _displayUserModel!,
                                      serviceProvider: _serviceProviderModel,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _fetchProfileData();
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              localizations.translate('editProfile'),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            const Divider(height: 20, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
