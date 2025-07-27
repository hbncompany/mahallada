// lib/screens/trade_user_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/models/user_model.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mahallda_app/screens/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TradeUserDetailScreen extends StatefulWidget {
  final UserModel user;

  const TradeUserDetailScreen({super.key, required this.user});

  @override
  State<TradeUserDetailScreen> createState() => _TradeUserDetailScreenState();
}

class _TradeUserDetailScreenState extends State<TradeUserDetailScreen> {
  User? _firebaseCurrentUser;
  UserModel? _currentUserModel;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserModel();
  }

  Future<void> _loadCurrentUserModel() async {
    _firebaseCurrentUser =
        Provider.of<FirebaseService>(context, listen: false).getCurrentUser();
    if (_firebaseCurrentUser != null) {
      _currentUserModel =
          await Provider.of<FirebaseService>(context, listen: false)
              .getUserData(_firebaseCurrentUser!.uid);
      setState(() {});
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

  void _startChat() {
    if (_firebaseCurrentUser == null || _currentUserModel == null) {
      _showErrorDialog(AppLocalizations.of(context)!.translate('loginToChat'));
      return;
    }
    if (_firebaseCurrentUser!.uid == widget.user.uid) {
      _showErrorDialog(
          AppLocalizations.of(context)!.translate('cannotChatWithSelf'));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUser: _currentUserModel!,
          targetUser: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('userProfile')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 70, // Kattaroq avatar
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage: widget.user.profilePhotoUrl != null &&
                      widget.user.profilePhotoUrl!.isNotEmpty
                  ? NetworkImage(widget.user.profilePhotoUrl!)
                  : const AssetImage('assets/placeholder_profile.png')
                      as ImageProvider,
            ),
            const SizedBox(height: 20),
            Text(
              widget.user.username ?? localizations.translate('unknownUser'),
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              widget.user.email ?? localizations.translate('notAvailable'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Card(
              // CardTheme dan sozlamalar oladi
              margin: const EdgeInsets.symmetric(
                  horizontal: 0), // CardTheme da belgilangan
              child: Padding(
                padding: const EdgeInsets.all(20.0), // Paddingni oshirdik
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('contactInfo'),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Divider(
                        height: 25, thickness: 1.5), // Qalinroq divider
                    ListTile(
                      leading: Icon(Icons.phone,
                          color: Theme.of(context).primaryColor, size: 28),
                      title: Text(localizations.translate('phoneNumber'),
                          style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Text(
                          widget.user.phoneNumber ??
                              localizations.translate('notAvailable'),
                          style: Theme.of(context).textTheme.bodyLarge),
                      onTap: widget.user.phoneNumber != null &&
                              widget.user.phoneNumber!.isNotEmpty
                          ? () => _makePhoneCall(widget.user.phoneNumber!)
                          : null,
                    ),
                    ListTile(
                      leading: Icon(Icons.location_on,
                          color: Theme.of(context).primaryColor, size: 28),
                      title: Text(localizations.translate('location'),
                          style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Text(
                        (widget.user.regionNameUz != null &&
                                widget.user.districtNameUz != null &&
                                widget.user.mahallaNameUz != null)
                            ? "${widget.user.regionNameUz}, ${widget.user.districtNameUz}, ${widget.user.mahallaNameUz}"
                            : localizations.translate('notAvailable'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startChat,
                    icon: const Icon(Icons.chat),
                    label: Text(localizations.translate('chat')),
                    // Style ElevatedButtonThemeData dan olinadi
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.user.phoneNumber != null &&
                            widget.user.phoneNumber!.isNotEmpty
                        ? () => _makePhoneCall(widget.user.phoneNumber!)
                        : null,
                    icon: const Icon(Icons.call),
                    label: Text(localizations.translate('call')),
                    // Style ElevatedButtonThemeData dan olinadi
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
