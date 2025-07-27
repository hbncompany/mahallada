// lib/screens/mahalla_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:mahallda_app/models/chat_message_model.dart';
import 'package:mahallda_app/models/user_model.dart';
import 'package:mahallda_app/screens/trade_user_detail_screen.dart'; // Import the user detail screen

class MahallaChatScreen extends StatefulWidget {
  const MahallaChatScreen({super.key});

  @override
  State<MahallaChatScreen> createState() => _MahallaChatScreenState();
}

class _MahallaChatScreenState extends State<MahallaChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late FirebaseService _firebaseService;
  User? _currentUser;
  UserModel? _currentUserModel;
  String? _mahallaChatRoomId;
  bool _isJoined = false;
  bool _isLoading = true; // To manage initial loading state

  @override
  void initState() {
    super.initState();
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
    _currentUser = FirebaseAuth.instance.currentUser;
    _initializeMahallaChat();
  }

  Future<void> _initializeMahallaChat() async {
    if (_currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _currentUserModel = await _firebaseService.getUserData(_currentUser!.uid);
    if (_currentUserModel != null && _currentUserModel!.mahallaCode != null) {
      _mahallaChatRoomId = _firebaseService.getMahallaChatRoomId(
        _currentUserModel!.regionNs10Code!,
        _currentUserModel!.districtNs11Code!,
        _currentUserModel!.mahallaCode!,
      );
      // Check if the user is already joined
      bool isCurrentlyJoined = await _firebaseService.isUserJoinedMahallaChat(
        _mahallaChatRoomId!,
        _currentUser!.uid,
      );
      setState(() {
        _isJoined = isCurrentlyJoined;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      // Optionally show a message if mahalla data is missing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.translate('mahallaDataMissing')),
          ),
        );
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_currentUser == null ||
        _currentUserModel == null ||
        _mahallaChatRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.translate('chatNotInitialized'))),
      );
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      await _firebaseService.sendMahallaMessage(
        chatRoomId: _mahallaChatRoomId!,
        senderId: _currentUser!.uid,
        senderUsername: _currentUserModel!.username ?? 'Unknown User',
        senderProfilePhotoUrl: _currentUserModel!.profilePhotoUrl,
        message: messageText,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.translate('failedToSend')}: $e')),
      );
    }
  }

  void _joinChat() async {
    if (_currentUser == null ||
        _currentUserModel == null ||
        _mahallaChatRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.translate('mahallaDataMissing'))),
      );
      return;
    }

    try {
      await _firebaseService.joinMahallaChat(
        chatRoomId: _mahallaChatRoomId!,
        userId: _currentUser!.uid,
        userModel: _currentUserModel!, // Pass UserModel
      );
      setState(() {
        _isJoined = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.translate('joinedMahallaChat'))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.translate('failedToJoin')}: $e')),
      );
    }
  }

  void _leaveChat() async {
    if (_currentUser == null || _mahallaChatRoomId == null) return;

    try {
      await _firebaseService.leaveMahallaChat(
        chatRoomId: _mahallaChatRoomId!,
        userId: _currentUser!.uid,
      );
      setState(() {
        _isJoined = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.translate('leftMahallaChat'))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.translate('failedToLeave')}: $e')),
      );
    }
  }

  // New method to navigate to user's profile
  void _navigateToUserProfile(String userId) async {
    final userModel = await _firebaseService.getUserData(userId);
    if (userModel != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TradeUserDetailScreen(user: userModel),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text(AppLocalizations.of(context)!.translate('userNotFound')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.translate('mahallaChat'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.translate('mahallaChat'))),
        body: Center(child: Text(localizations.translate('pleaseLoginToChat'))),
      );
    }

    if (_currentUserModel == null || _currentUserModel!.mahallaCode == null) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.translate('mahallaChat'))),
        body: Center(
            child:
            Text(localizations.translate('updateProfileForMahallaChat'))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(localizations.translate('mahallaChat')),
            Text(localizations.translate('${_currentUserModel!.mahallaNameUz}'), style: TextStyle(fontSize: 10),),
          ],
        ),
        actions: [
          if (_isJoined)
            TextButton(
              onPressed: _leaveChat,
              child: Text(
                localizations.translate('leaveChat'),
                style: TextStyle(color: Theme.of(context).colorScheme.onError),
              ),
            )
          else
            TextButton(
              onPressed: _joinChat,
              child: Text(
                localizations.translate('joinChat'),
                style:
                TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _mahallaChatRoomId == null
                ? Center(
              child:
              Text(localizations.translate('cannotLoadMahallaChat')),
            )
                : StreamBuilder<List<ChatMessage>>(
              stream: _firebaseService
                  .getMahallaMessages(_mahallaChatRoomId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          '${localizations.translate('error')}: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child:
                      Text(localizations.translate('noMessagesYet')));
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true, // Show latest messages at the bottom
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length -
                        1 -
                        index]; // Display in reverse order
                    final isMe = message.senderId == _currentUser!.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 15.0),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              : Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe
                                ? const Radius.circular(12)
                                : const Radius.circular(0),
                            bottomRight: isMe
                                ? const Radius.circular(0)
                                : const Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (!isMe) // Show sender's name if not current user
                              GestureDetector(
                                onTap: () => _navigateToUserProfile(
                                    message.senderId),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundImage: message
                                          .senderProfilePhotoUrl !=
                                          null &&
                                          message
                                              .senderProfilePhotoUrl!
                                              .isNotEmpty
                                          ? NetworkImage(message
                                          .senderProfilePhotoUrl!)
                                          : const AssetImage(
                                          'assets/placeholder_profile.png')
                                      as ImageProvider,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      message.senderUsername ??
                                          localizations
                                              .translate('unknownUser'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (!isMe) const SizedBox(height: 4),
                            Text(
                              message.message,
                              style: TextStyle(
                                color: isMe
                                    ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    : Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(
                                  message.timestamp.toDate()),
                              style: TextStyle(
                                color: isMe
                                    ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withOpacity(0.7)
                                    : Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer
                                    .withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isJoined) // Only show message input if joined
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: localizations.translate('enterMessage'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      maxLines: null, // Allow multiple lines
                      keyboardType: TextInputType.multiline,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    mini: true,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
    DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate.isAtSameMomentAs(today)) {
      // Today
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate
        .isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
      // Yesterday
      return '${AppLocalizations.of(context)!.translate('yesterday')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      // Other dates
      return '${timestamp.day}.${timestamp.month}.${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
