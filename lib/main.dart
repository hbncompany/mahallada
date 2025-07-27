// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mahallda_app/firebase_options.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/screens/auth/role_selection_screen.dart';
import 'package:mahallda_app/screens/auth/sign_in_screen.dart';
import 'package:mahallda_app/services/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mahallda_app/screens/home_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Bu import kerak
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:mahallda_app/services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mahallda_app/firebase_options.dart';

// Background xabarlarni boshqarish uchun top-level funksiya
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");
  flutterLocalNotificationsPlugin.show(
    message.hashCode,
    message.notification?.title,
    message.notification?.body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
        ),
        Provider<ApiService>(
          // <-- MUHIM: ApiService ni ham bu yerga qo'shing
          create: (_) => ApiService(),
        ),
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(),
        ),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Mahallada',
            theme: ThemeData(
              primarySwatch: Colors.teal,
              primaryColor: Colors.teal[700], // Asosiy rang
              hintColor: Colors.amber[700], // Aksent rang
              scaffoldBackgroundColor: Colors.grey[100], // Umumiy fon rangi
              appBarTheme: AppBarTheme(
                color: Colors.teal[700],
                foregroundColor: Colors.white,
                elevation: 4,
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700], // Tugmalar rangi
                  foregroundColor: Colors.white, // Tugma matni rangi
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12), // Tugma burchaklari
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.teal[700], // TextButton rangi
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none, // Chegarani olib tashlash
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                labelStyle: TextStyle(color: Colors.grey[700]),
                hintStyle: TextStyle(color: Colors.grey[500]),
              ),
              cardTheme: CardTheme(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Colors.teal[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15), // Katta yumaloq burchaklar
                ),
              ),
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                selectedItemColor: Colors.teal[700],
                unselectedItemColor: Colors.grey[600],
                backgroundColor: Colors.white,
                elevation: 8,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.normal),
              ),
              // Yangi qo'shilgan: DropdownButtonTheme
              dropdownMenuTheme: DropdownMenuThemeData(
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.teal[700]!, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  labelStyle: TextStyle(color: Colors.grey[700]),
                ),
              ),
              // Yangi qo'shilgan: DropdownButtonFormField uchun
              // (InputDecorationTheme allaqachon yuqorida belgilangan)
              // Bu yerda qo'shimcha sozlamalar kerak emas, chunki u InputDecorationTheme dan meros oladi.
            ),
            locale: languageProvider.locale,
            supportedLocales: const [
              Locale('en', ''),
              Locale('ru', ''),
              Locale('uz', ''), // <-- 'uz_' o'rniga 'uz'
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasData) {
                  return const HomeScreen();
                } else {
                  return const SignInScreen();
                }
              },
            ),
            routes: {
              '/roleSelection': (context) => const RoleSelectionScreen(),
              '/signIn': (context) => const SignInScreen(),
            },
          );
        },
      ),
    );
  }
}
