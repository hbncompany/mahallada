// lib/screens/subscription_screen.dart
import 'dart:async';
import 'dart:io';
import 'dart:convert'; // For json.encode

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mahallda_app/l10n/app_localizations.dart'; // Lokalizatsiya uchun
import 'package:mahallda_app/services/firebase_service.dart'; // Firebase servisingiz
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Timestamp uchun
import 'package:http/http.dart' as http; // HTTP requests for Flask backend

// Google Play Console/App Store Connect'da sozlagan mahsulot ID'laringiz
const List<String> _kProductIds = <String>[
  'mahallda_premium_monthly', // Oylik obuna ID
  'mahallda_premium_yearly', // Yillik obuna ID
  // ... qo'shimcha obuna turlari
];

// --- IMPORTANT: Replace with your actual Flask backend URL ---
const String _flaskBackendUrl =
    'http://hbnappdatas.pythonanywhere.com/verify-purchase';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // Declare _inAppPurchase as late final and initialize in initState
  late final InAppPurchase _inAppPurchase;

  StreamSubscription<List<PurchaseDetails>>? _purchaseStreamSubscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _loading = true;
  String? _queryProductError;
  PurchaseDetails? _latestPurchase; // Foydalanuvchining eng so'nggi xaridi
  bool _isPremiumSubscriber = false;
  DateTime? _subscriptionEndDate;

  @override
  void initState() {
    super.initState();
    // Initialize _inAppPurchase here, within the widget's lifecycle
    _inAppPurchase = InAppPurchase.instance;

    _initializePurchasesAndListen();
    _loadProductsAndSetInitialLoading();
    _checkCurrentUserSubscriptionStatus();
  }

  @override
  void dispose() {
    _purchaseStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializePurchasesAndListen() async {
    _isAvailable = await _inAppPurchase.isAvailable();

    if (_isAvailable) {
      _purchaseStreamSubscription = _inAppPurchase.purchaseStream.listen(
            (List<PurchaseDetails> purchaseDetailsList) {
          _handlePurchaseUpdates(purchaseDetailsList);
        },
        onDone: () {
          _purchaseStreamSubscription?.cancel();
        },
        onError: (error) {
          print("Error listening to purchase stream: $error");
          setState(() {
            _queryProductError =
                AppLocalizations.of(context)!.translate('purchaseStreamError') +
                    ': $error';
            _loading = false;
          });
        },
      );
    } else {
      setState(() {
        _queryProductError = AppLocalizations.of(context)!
            .translate('inAppPurchasesNotAvailable');
        _loading = false;
      });
      print("In-App Purchases are not available on this device.");
    }
  }

  Future<void> _loadProductsAndSetInitialLoading() async {
    setState(() {
      _loading = true;
    });

    if (!_isAvailable) {
      setState(() {
        _loading = false;
      });
      return;
    }

    ProductDetailsResponse productDetailResponse =
    await _inAppPurchase.queryProductDetails(_kProductIds.toSet());

    if (productDetailResponse.error != null) {
      setState(() {
        _queryProductError = productDetailResponse.error!.message;
        _loading = false;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _queryProductError =
            AppLocalizations.of(context)!.translate('noProductsFound');
        _loading = false;
      });
      return;
    }

    setState(() {
      _products = productDetailResponse.productDetails;
      _loading = false;
    });
  }

  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.translate('purchasePending'))),
        );
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          print("Purchase Error: ${purchaseDetails.error?.message}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.translate('purchaseFailed') +
                        ': ${purchaseDetails.error?.message}')),
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          if (purchaseDetails.pendingCompletePurchase) {
            await _verifyPurchaseOnBackend(purchaseDetails);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!
                    .translate('purchaseSuccessful'))),
          );
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
    await _checkCurrentUserSubscriptionStatus();
  }

  Future<void> _verifyPurchaseOnBackend(PurchaseDetails purchaseDetails) async {
    final firebaseService =
    Provider.of<FirebaseService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("User not logged in, cannot verify purchase.");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(_flaskBackendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': user.uid,
          'productId': purchaseDetails.productID,
          'verificationData':
          purchaseDetails.verificationData.localVerificationData,
          'source':
          purchaseDetails.verificationData.source, // 'ios' or 'android'
          'transactionDate': purchaseDetails.transactionDate,
          'purchaseId': purchaseDetails.purchaseID,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final String? endDateString = responseData['subscriptionEndDate'];
          DateTime? newEndDate;
          if (endDateString != null) {
            newEndDate = DateTime.tryParse(endDateString);
          }

          if (newEndDate != null) {
            await firebaseService.updateUserSubscriptionStatus(
              user.uid,
              true,
              newEndDate,
              purchaseDetails.purchaseID,
            );
            setState(() {
              _latestPurchase = purchaseDetails;
            });
            print(
                "Purchase verified by Flask backend and user status updated!");
          } else {
            print(
                "Flask backend verification success, but no valid end date received.");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(AppLocalizations.of(context)!
                      .translate('purchaseVerificationFailed') +
                      ': Invalid end date from server.')),
            );
          }
        } else {
          print(
              "Flask backend verification failed: ${responseData['message'] ?? 'Unknown error'}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!
                    .translate('purchaseVerificationFailed') +
                    ': ${responseData['message'] ?? 'Unknown error'}')),
          );
        }
      } else {
        print("Flask backend returned status code: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .translate('purchaseVerificationFailed') +
                  ': Server error ${response.statusCode}')),
        );
      }
    } catch (e) {
      print("Error communicating with Flask backend: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .translate('purchaseVerificationFailed') +
                ': Network error $e')),
      );
    }
  }

  Future<void> _checkCurrentUserSubscriptionStatus() async {
    final firebaseService =
    Provider.of<FirebaseService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await firebaseService.getUserData(user.uid);
      if (userDoc != null) {
        setState(() {
          _isPremiumSubscriber = userDoc.isPremiumSubscriber ?? false;
          _subscriptionEndDate = userDoc.subscriptionEndDate?.toDate();
          if (_isPremiumSubscriber &&
              _subscriptionEndDate != null &&
              _subscriptionEndDate!.isBefore(DateTime.now())) {
            _isPremiumSubscriber = false;
            firebaseService.updateUserSubscriptionStatus(
                user.uid, false, null, null);
          }
        });
      }
    }
  }

  void _buyProduct(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam =
    PurchaseParam(productDetails: productDetails);
    if (Platform.isAndroid) {
      // Platform-specific parameters can be added here if needed
    }
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _loading = true;
    });

    if (!_isAvailable) {
      setState(() {
        _queryProductError = AppLocalizations.of(context)!
            .translate('inAppPurchasesNotAvailableForRestore');
        _loading = false;
      });
      print("In-App Purchases are not available, cannot restore.");
      return;
    }

    try {
      await _inAppPurchase.restorePurchases();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.translate('restoreInProgress'))),
      );
    } catch (e) {
      print("Error restoring purchases: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.translate('restoreFailed') +
                    ': $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('subscription')),
      ),
      body: _loading
          ? Center(
          child: CircularProgressIndicator(
            valueColor:
            AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ))
          : _queryProductError != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _queryProductError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCurrentSubscriptionStatusCard(localizations),
            const SizedBox(height: 20),
            Text(
              localizations.translate('availablePlans'),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._products
                .map((product) =>
                _buildProductCard(product, localizations))
                .toList(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _restorePurchases,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
              ),
              child:
              Text(localizations.translate('restorePurchases')),
            ),
            const SizedBox(height: 10),
            Text(
              localizations.translate('restorePurchasesDescription'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSubscriptionStatusCard(AppLocalizations localizations) {
    String statusText;
    Color statusColor;

    if (_isPremiumSubscriber &&
        _subscriptionEndDate != null &&
        _subscriptionEndDate!.isAfter(DateTime.now())) {
      statusText = localizations.translate('premiumActiveUntil') +
          ': ${_subscriptionEndDate!}'; // formatDate is assumed in AppLocalizations
      statusColor = Colors.green;
    } else {
      statusText = localizations.translate('freeUser');
      statusColor = Colors.orange;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('yourSubscriptionStatus'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  _isPremiumSubscriber ? Icons.check_circle : Icons.info,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 16, color: statusColor),
                  ),
                ),
              ],
            ),
            if (!_isPremiumSubscriber) ...[
              const SizedBox(height: 10),
              Text(
                localizations.translate('subscribeToEnjoyBenefits'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
      ProductDetails product, AppLocalizations localizations) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              product.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () => _buyProduct(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                    '${localizations.translate('buyFor')} ${product.price}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
