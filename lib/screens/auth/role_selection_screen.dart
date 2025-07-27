// lib/screens/auth/role_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/screens/auth/sign_up_profile_screen.dart';
import 'package:mahallda_app/screens/auth/sign_in_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('appName')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                localizations.translate('selectRole'),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              RadioListTile<String>(
                title: Text(localizations.translate('client')),
                value: 'client',
                groupValue: _selectedRole,
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text(localizations.translate('serviceProvider')),
                value: 'serviceProvider',
                groupValue: _selectedRole,
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value;
                  });
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _selectedRole == null
                    ? null
                    : () {
                        if (_selectedRole == 'client' ||
                            _selectedRole == 'serviceProvider') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SignUpProfileScreen(role: _selectedRole!),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  localizations.translate('continue'),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignInScreen()),
                  );
                },
                child: Text(localizations.translate('signIn')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
