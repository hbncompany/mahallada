// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:mahallda_app/services/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:mahallda_app/models/user_model.dart';
import 'package:mahallda_app/models/service_model.dart';
import 'package:mahallda_app/models/combined_service_provider.dart';
import 'package:mahallda_app/screens/profile_screen.dart';
import 'package:mahallda_app/screens/all_service_providers_screen.dart';
import 'package:mahallda_app/widgets/service_provider_card.dart';
import 'package:mahallda_app/screens/chat_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mahallda_app/screens/service_groups_list_screen.dart';
import 'package:mahallda_app/screens/service_types_list_screen.dart';
import 'package:mahallda_app/screens/trade_list_screen.dart'; // Yangi import
import 'package:mahallda_app/screens/service_provider_detail_screen.dart'; // Yangi import
import 'package:mahallda_app/widgets/app_drawer.dart'; // <-- Yangi import
import 'package:mahallda_app/widgets/bottom_shape.dart'; // <-- Yangi import
import 'package:mahallda_app/screens/mahalla_chat_screen.dart'; // Yangi impo

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Service> _services = [];
  List<CombinedServiceProvider> _topServiceProviders = [];
  bool _isLoading = true;
  int _selectedIndex = 0; // Endi 0 dan 4 gacha bo'ladi
  UserModel? _currentUserModel;
  User? _currentUser;

  // Bottom Navigation Bar uchun ekranlar ro'yxati
  static final List<Widget> _widgetOptions = <Widget>[
    const _HomeContent(), // Home screenning asosiy kontenti
    const MahallaChatScreen(), // Yangi Trade Screen
    const TradeListScreen(), // Yangi Trade Screen
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      _currentUser = firebaseService.getCurrentUser();
      if (_currentUser != null) {
        _currentUserModel =
            await firebaseService.getUserData(_currentUser!.uid);
      }

      _services = await firebaseService.fetchServiceSectors();
      List<CombinedServiceProvider> allProviders =
          await firebaseService.getAllCombinedServiceProviders();

      allProviders.sort((a, b) => (b.rating).compareTo(a.rating));
      _topServiceProviders = allProviders.take(3).toList();
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Agar profilga bosilsa, ProfileScreen ga o'tish
    if (index == 3) {
      // Index 4 endi profil uchun
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('appName')),
        actions: [
          if (_currentUser != null)
            StreamBuilder<int>(
              stream: firebaseService
                  .getTotalUnreadChatCountStream(_currentUser!.uid),
              builder: (context, snapshot) {
                final int unreadCount = snapshot.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ChatListScreen()),
                        );
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
      drawer: const AppDrawer(), // <-- AppDrawer ni qo'shish
      body: _widgetOptions
          .elementAt(_selectedIndex), // Tanlangan ekranni ko'rsatish
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: localizations.translate('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.group),
            label: localizations.translate('mahallaChat'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_grocery_store), // Yangi Trade ikonka
            label: localizations.translate('trade'), // "Ayriboshlash"
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: localizations.translate('profile'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal[700],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // 5 ta item uchun
      ),
    );
  }
}

// HomeScreen ning asosiy kontentini alohida widgetga ajratamiz
class _HomeContent extends StatefulWidget {
  const _HomeContent({Key? key}) : super(key: key);

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  List<Service> _services = [];
  List<CombinedServiceProvider> _topServiceProviders = [];
  bool _isLoading = true;
  UserModel? _currentUserModel;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);

      _currentUser = firebaseService.getCurrentUser();
      if (_currentUser != null) {
        _currentUserModel =
            await firebaseService.getUserData(_currentUser!.uid);
      }

      _services = await firebaseService.fetchServiceSectors();
      List<CombinedServiceProvider> allProviders =
          await firebaseService.getAllCombinedServiceProviders();

      allProviders.sort((a, b) => (b.rating).compareTo(a.rating));
      _topServiceProviders = allProviders.take(3).toList();
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

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.translate('services'),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ServiceGroupsListScreen()),
                        );
                      },
                      child: Row(
                        children: [
                          Text(localizations.translate('seeAll')),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _services.length,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      IconData iconData;
                      if (service.nameEn.toLowerCase().contains('plumb')) {
                        iconData = Icons.plumbing;
                      } else if (service.nameEn
                          .toLowerCase()
                          .contains('electric')) {
                        iconData = Icons.electrical_services;
                      } else if (service.nameEn
                          .toLowerCase()
                          .contains('tailor')) {
                        iconData = Icons.content_cut;
                      } else if (service.nameEn
                          .toLowerCase()
                          .contains('doctor')) {
                        iconData = Icons.local_hospital;
                      } else {
                        iconData = Icons.category;
                      }

                      return _ServiceCategoryCard(
                        icon: iconData,
                        title: service.getName(currentLangCode),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ServiceTypesListScreen(
                                    serviceGroup: service)),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.translate('topServiceProviders'),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllServiceProvidersScreen(
                              currentUserMahallaCode:
                                  _currentUserModel?.mahallaCode,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Text(localizations.translate('seeAll')),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topServiceProviders.length,
                  itemBuilder: (context, index) {
                    final provider = _topServiceProviders[index];
                    return ServiceProviderCard(
                      provider: provider,
                      currentLangCode: currentLangCode,
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
              ],
            ),
          );
  }
}

class _ServiceCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ServiceCategoryCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.teal[700],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// firstWhereOrNull extensionini bu yerga ham qo'shamiz, agar u global bo'lmasa
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
