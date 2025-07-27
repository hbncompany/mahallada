// lib/screens/auth/sign_in_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/screens/auth/role_selection_screen.dart';
import 'package:mahallda_app/screens/home_screen.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:provider/provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneNumberController =
      TextEditingController(); // Telefon raqami uchun
  bool _isLoading = false;
  String? _verificationId; // SMS tasdiqlash uchun

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      await firebaseService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message =
          AppLocalizations.of(context)!.translate('somethingWentWrong');
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message =
            AppLocalizations.of(context)!.translate('invalidEmailPassword');
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      await firebaseService.signInWithGoogle();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ??
          AppLocalizations.of(context)!.translate('somethingWentWrong'));
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

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      await firebaseService.signInAnonymously();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ??
          AppLocalizations.of(context)!.translate('somethingWentWrong'));
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

  // Telefon raqami bilan kirish uchun
  Future<void> _verifyPhoneNumber() async {
    setState(() {
      _isLoading = true;
    });
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    await firebaseService.verifyPhoneNumber(
      _phoneNumberController.text.trim(),
      (PhoneAuthCredential credential) async {
        // Avtomatik tasdiqlash
        await firebaseService.signInWithPhoneCredential(credential);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      },
      (FirebaseAuthException e) {
        _showErrorDialog(e.message ??
            AppLocalizations.of(context)!.translate('somethingWentWrong'));
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
      (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _isLoading = false;
        });
        // SMS kod kiritish dialogini ko'rsatish
        _showSmsCodeDialog(verificationId);
      },
      (String verificationId) {
        // Auto-retrieval timeout
        _showErrorDialog('SMS code auto-retrieval timeout.');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  void _showSmsCodeDialog(String verificationId) {
    final TextEditingController smsCodeController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!
              .translate('enterSmsCode')), // "SMS kodni kiriting"
          content: TextField(
            controller: smsCodeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!
                  .translate('smsCode'), // "SMS kod"
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final PhoneAuthCredential credential =
                      PhoneAuthProvider.credential(
                    verificationId: verificationId,
                    smsCode: smsCodeController.text.trim(),
                  );
                  final firebaseService =
                      Provider.of<FirebaseService>(context, listen: false);
                  await firebaseService.signInWithPhoneCredential(credential);
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  _showErrorDialog(e.message ??
                      AppLocalizations.of(context)!
                          .translate('somethingWentWrong'));
                } catch (e) {
                  _showErrorDialog(e.toString());
                }
              },
              child: Text(AppLocalizations.of(context)!
                  .translate('verify')), // "Tasdiqlash"
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('error')), // "Xato"
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.translate('ok')), // "OK"
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
        title: Text(localizations.translate('signIn')),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                localizations.translate('welcome'),
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: localizations.translate('email'),
                  prefixIcon:
                      Icon(Icons.email, color: Theme.of(context).hintColor),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.translate('emailRequired');
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return localizations.translate('enterValidEmail');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: localizations.translate('password'),
                  prefixIcon:
                      Icon(Icons.lock, color: Theme.of(context).hintColor),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localizations.translate('passwordRequired');
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
                        onPressed: _signInWithEmail,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          localizations.translate('signIn'),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const RoleSelectionScreen()),
                  );
                },
                child: Text(
                  localizations.translate('register'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              TextField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: localizations.translate('phoneNumber'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _verifyPhoneNumber,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          localizations.translate(
                              'signInWithPhone'), // "Телефон орқали кириш"
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: Image.asset('assets/google_logo.png',
                      height: 24), // Google logosi
                  label: Text(localizations.translate('googleSignIn')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _signInAnonymously,
                  icon: const Icon(Icons.person),
                  label: Text(localizations.translate('anonymousSignIn')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
