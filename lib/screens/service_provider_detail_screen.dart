// lib/screens/service_provider_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/models/combined_service_provider.dart';
import 'package:mahallda_app/models/review_model.dart';
import 'package:mahallda_app/models/user_model.dart';
import 'package:mahallda_app/screens/chat_screen.dart';
import 'package:mahallda_app/screens/profile_screen.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Bu qator qo'shildi/tekshirildi

class ServiceProviderDetailScreen extends StatefulWidget {
  final CombinedServiceProvider provider;

  const ServiceProviderDetailScreen({super.key, required this.provider});

  @override
  State<ServiceProviderDetailScreen> createState() =>
      _ServiceProviderDetailScreenState();
}

class _ServiceProviderDetailScreenState
    extends State<ServiceProviderDetailScreen> {
  UserModel? _currentUserModel;
  bool _isLoading = true;
  final TextEditingController _reviewController = TextEditingController();
  double _userRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final currentUser = firebaseService.getCurrentUser();
      if (currentUser != null) {
        _currentUserModel = await firebaseService.getUserData(currentUser.uid);
      }
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

  String _calculateExperience(
      Timestamp? registrationDate, AppLocalizations localizations) {
    if (registrationDate == null) {
      return localizations.translate('notAvailable');
    }

    final now = DateTime.now();
    final regDate = registrationDate.toDate();
    final difference = now.difference(regDate);

    if (difference.inDays < 365) {
      return "${difference.inDays} ${localizations.translate('days')}";
    } else {
      final years = (difference.inDays / 365).floor();
      return "$years ${localizations.translate('years')}";
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showErrorDialog(
          AppLocalizations.of(context)!.translate('couldNotLaunchPhoneCall'));
    }
  }

  void _startChat(
      BuildContext context, UserModel currentUser, UserModel targetUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUser: currentUser,
          targetUser: targetUser,
        ),
      ),
    );
  }

  void _showReviewDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(localizations.translate('writeReview')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _userRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() {
                        _userRating = (index + 1).toDouble();
                      });
                      (ctx as Element).markNeedsBuild();
                    },
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: localizations.translate('yourReview'),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: Text(localizations.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: _submitReview,
              child: Text(localizations.translate('submit')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitReview() async {
    if (_userRating == 0.0 || _reviewController.text.isEmpty) {
      _showErrorDialog(AppLocalizations.of(context)!
          .translate('pleaseProvideRatingAndReview'));
      return;
    }

    if (_currentUserModel == null ||
        _currentUserModel!.uid == null ||
        _currentUserModel!.username == null) {
      _showErrorDialog(
          AppLocalizations.of(context)!.translate('loginToSubmitReview'));
      return;
    }

    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final newReview = Review(
      id: '',
      serviceProviderUid: widget.provider.user.uid!,
      clientUid: _currentUserModel!.uid!,
      clientUsername: _currentUserModel!.username!,
      reviewText: _reviewController.text.trim(),
      rating: _userRating,
      timestamp: Timestamp.now(), // <-- Timestamp to'g'ri ishlatildi
    );

    try {
      await firebaseService.addReview(newReview);
      _reviewController.clear();
      _userRating = 0.0;
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .translate('reviewSubmittedSuccessfully'))),
        );
      }
    } catch (e) {
      _showErrorDialog(
          AppLocalizations.of(context)!.translate('failedToSubmitReview') +
              ": $e");
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
    print('widget.provider.user:');
    print(widget.provider.user.districtNameUz);
    print(widget.provider.serviceProvider.servicePrice);
    final localizations = AppLocalizations.of(context)!;
    final currentLangCode = Localizations.localeOf(context).languageCode;
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    String serviceSectorName =
        widget.provider.serviceProvider.serviceSector ?? 'N/A';
    // Service modelidan nomni olish uchun _serviceSectorsMap ni ishlatishimiz kerak.
    // Bu ma'lumotni _loadCurrentUser() ichida yoki alohida FutureBuilder orqali yuklash mumkin.
    // Hozircha bu yerda faqat ID ko'rsatiladi.

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('serviceProviderDetails')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          image: DecorationImage(
                            image: widget.provider.user.profilePhotoUrl != null
                                ? NetworkImage(
                                    widget.provider.user.profilePhotoUrl!)
                                : const AssetImage(
                                        'assets/placeholder_profile.png')
                                    as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 30),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: IconButton(
                          icon: const Icon(Icons.bookmark_border,
                              color: Colors.white, size: 30),
                          onPressed: () {
                            // Bookmark funksiyasi
                          },
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.provider.user.username ?? 'N/A',
                              style: const TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                if (widget.provider.user.phoneNumber != null &&
                                    widget
                                        .provider.user.phoneNumber!.isNotEmpty)
                                  GestureDetector(
                                    onTap: () => _makePhoneCall(
                                        widget.provider.user.phoneNumber!),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.green[500],
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.call,
                                          color: Colors.white, size: 24),
                                    ),
                                  ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () {
                                    if (_currentUserModel != null &&
                                        widget.provider.user.uid != null) {
                                      _startChat(context, _currentUserModel!,
                                          widget.provider.user);
                                    } else {
                                      _showErrorDialog(localizations
                                          .translate('loginToChat'));
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[500],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.chat,
                                        color: Colors.white, size: 24),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () {
                                    _showErrorDialog(localizations
                                        .translate('videoCallNotAvailable'));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.red[500],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.videocam,
                                        color: Colors.white, size: 24),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(
                          localizations.translate('serviceGroup'),
                          serviceSectorName,
                          icon: Icons.work,
                        ),
                        _buildInfoRow(
                          localizations.translate('serviceType'),
                          widget.provider.serviceProvider.serviceType ?? 'N/A',
                          icon: Icons.category,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          localizations.translate('region'),
                          widget.provider.user.regionNameUz ?? 'N/A',
                          icon: Icons.location_on,
                        ),
                        _buildInfoRow(
                          localizations.translate('district'),
                          widget.provider.user.districtNameUz ?? 'N/A',
                          icon: Icons.location_city,
                        ),
                        _buildInfoRow(
                          localizations.translate('mahalla'),
                          widget.provider.user.mahallaNameUz ?? 'N/A',
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          localizations.translate('experience'),
                          _calculateExperience(
                              widget.provider.user.registrationDate,
                              localizations),
                          icon: Icons.history,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          localizations.translate('positionInApp'),
                          widget.provider.rating.toStringAsFixed(1),
                          icon: Icons.star_half,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          localizations.translate('description'),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.provider.serviceProvider.serviceType ??
                              'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut.',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 30),
                        if (_currentUserModel != null &&
                            _currentUserModel!.role == 'client')
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.translate('sendReview'),
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _showReviewDialog,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                    localizations.translate('writeReview')),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        Text(
                          localizations.translate('reviews'),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<List<Review>>(
                          stream: firebaseService.getReviewsForServiceProvider(
                              widget.provider.user.uid!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              print(snapshot.error);
                              return Center(
                                  child: Text(
                                      "${localizations.translate('errorLoadingReviews')}: ${snapshot.error}"));
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Center(
                                  child: Text(
                                      localizations.translate('noReviewsYet')));
                            } else {
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  final review = snapshot.data![index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                review.clientUsername,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                              Row(
                                                children: List.generate(5,
                                                    (starIndex) {
                                                  return Icon(
                                                    starIndex < review.rating
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color: Colors.amber,
                                                    size: 18,
                                                  );
                                                }),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            review.reviewText,
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[800]),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "${review.timestamp.toDate().day}.${review.timestamp.toDate().month}.${review.timestamp.toDate().year}",
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
}
