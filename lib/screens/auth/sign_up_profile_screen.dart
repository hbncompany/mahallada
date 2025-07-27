// lib/screens/auth/sign_up_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/screens/auth/sign_up_location_screen.dart';
import 'package:mahallda_app/services/api_service.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:mahallda_app/models/user_model.dart'; // UserModel ni import qilish

class SignUpProfileScreen extends StatefulWidget {
  final String role;

  const SignUpProfileScreen({super.key, required this.role});

  @override
  State<SignUpProfileScreen> createState() => _SignUpProfileScreenState();
}

class _SignUpProfileScreenState extends State<SignUpProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();

  File? _profileImage;
  bool _isLoading = false;
  String? _profileImageUrl;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
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
      // 1. Rasmni yuklash
      if (_profileImage != null) {
        _profileImageUrl = await apiService.uploadProfilePhoto(_profileImage!, 'user');
      }

      // 2. Firebase Auth orqali ro'yxatdan o'tish
      UserCredential? userCredential = await firebaseService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (userCredential != null && userCredential.user != null) {
        // 3. UserModel obyektini yaratish
        UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          email: _emailController.text.trim(),
          username: _usernameController.text.trim(),
          profilePhotoUrl: _profileImageUrl,
          role: widget.role,
        );

        // 4. Keyingi sahifaga o'tish
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignUpLocationScreen(user: newUser),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = localizations.translate('somethingWentWrong');
      if (e.code == 'weak-password') {
        message = localizations.translate('weakPassword');
      } else if (e.code == 'email-already-in-use') {
        message = localizations.translate('emailAlreadyInUse');
      }
      _showErrorDialog(message);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('register')),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? Icon(
                            Icons.camera_alt,
                            size: 40,
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
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: localizations.translate('username'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.translate(
                          'usernameRequired'); // "Foydalanuvchi nomi majburiy."
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: localizations.translate('email'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.translate(
                          'emailRequired'); // "Elektron pochta majburiy."
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return localizations.translate(
                          'enterValidEmail'); // "To'g'ri elektron pochta kiriting."
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: localizations.translate('password'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations
                          .translate('passwordRequired'); // "Parol majburiy."
                    }
                    if (value.length < 6) {
                      return localizations.translate(
                          'passwordMinLength'); // "Parol kamida 6 ta belgidan iborat bo'lishi kerak."
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: localizations.translate('confirmPassword'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.translate(
                          'confirmPasswordRequired'); // "Parolni tasdiqlash majburiy."
                    }
                    if (value != _passwordController.text) {
                      return localizations.translate('passwordsDoNotMatch');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
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
        ),
      ),
    );
  }
}
