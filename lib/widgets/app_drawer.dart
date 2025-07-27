// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:mahallda_app/services/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:mahallda_app/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mahallda_app/screens/about_app_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  UserModel? _currentUserModel;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    setState(() {
      _isLoadingUser = true;
    });
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final currentUser = firebaseService.getCurrentUser();
      if (currentUser != null) {
        _currentUserModel = await firebaseService.getUserData(currentUser.uid);
      }
    } catch (e) {
      print("Foydalanuvchi ma'lumotlarini yuklashda xato: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Drawer(
      child: Column(
        children: [
          _isLoadingUser
              ? DrawerHeader(
                  decoration:
                      BoxDecoration(color: Theme.of(context).primaryColor),
                  child: const Center(
                      child: CircularProgressIndicator(color: Colors.white)),
                )
              : UserAccountsDrawerHeader(
                  accountName: Text(
                    _currentUserModel?.username ??
                        localizations.translate('unknownUser'),
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  accountEmail: Text(
                    _currentUserModel?.email ??
                        localizations.translate('notAvailable'),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: Colors.white70),
                  ),
                  currentAccountPicture: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        _currentUserModel?.profilePhotoUrl != null &&
                                _currentUserModel!.profilePhotoUrl!.isNotEmpty
                            ? NetworkImage(_currentUserModel!.profilePhotoUrl!)
                            : const AssetImage('assets/placeholder_profile.png')
                                as ImageProvider,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  margin: EdgeInsets.zero, // Default marginni olib tashlash
                  currentAccountPictureSize:
                      const Size.square(72.0), // Avatar hajmini belgilash
                ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(localizations.translate('language')),
                  trailing: DropdownButton<Locale>(
                    value: languageProvider.locale,
                    icon: const Icon(Icons.arrow_drop_down),
                    underline: const SizedBox(),
                    onChanged: (Locale? newLocale) {
                      if (newLocale != null) {
                        languageProvider.changeLanguage(newLocale);
                        Navigator.pop(context);
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: Locale('uz'),
                        child: Row(
                          children: [
                            Text('🇺🇿', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: Locale('ru'),
                        child: Row(
                          children: [
                            Text('🇷🇺', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: Locale('en'),
                        child: Row(
                          children: [
                            Text('🇬🇧', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: Text(localizations.translate('signOut'),
                      style: const TextStyle(color: Colors.redAccent)),
                  onTap: () async {
                    await firebaseService.signOut();
                    if (mounted) {
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacementNamed('/signIn');
                    }
                  },
                ),
                // Ilova haqida
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(
                      localizations.translate('aboutApp')), // "Ilova haqida"
                  onTap: () {
                    Navigator.pop(context); // Drawer ni yopish
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AboutAppScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
