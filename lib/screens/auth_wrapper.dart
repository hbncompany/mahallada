// lib/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mahallda_app/screens/auth/sign_in_screen.dart'; // SignInScreen ni import qiling
import 'package:mahallda_app/screens/home_screen.dart'; // HomeScreen ni import qiling

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Autentifikatsiya holati yuklanmoqda
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasData) {
          // Foydalanuvchi tizimga kirgan
          return const HomeScreen();
        } else {
          // Foydalanuvchi tizimga kirmagan
          return const SignInScreen();
        }
      },
    );
  }
}
