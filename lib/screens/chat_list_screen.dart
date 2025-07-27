// lib/screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:mahallda_app/l10n/app_localizations.dart';
import 'package:mahallda_app/models/chat_room_model.dart';
import 'package:mahallda_app/models/user_model.dart';
import 'package:mahallda_app/screens/chat_screen.dart';
import 'package:mahallda_app/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  User? _currentUser;
  UserModel? _currentUserModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    _currentUser = firebaseService.getCurrentUser();
    if (_currentUser != null) {
      _currentUserModel = await firebaseService.getUserData(_currentUser!.uid);
    }
    setState(() {
      _isLoading = false;
    });
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
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('chats')), // "Chatlar"
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null || _currentUserModel == null
              ? Center(
                  child: Text(localizations.translate(
                      'loginToViewChats'))) // "Chatlarni ko'rish uchun tizimga kiring."
              : StreamBuilder<List<ChatRoom>>(
                  stream: firebaseService.getChatRoomsStream(_currentUser!.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      print(snapshot.error);
                      return Center(
                          child: Text(
                              "${localizations.translate('errorLoadingChats')}: ${snapshot.error}")); // "Chatlarni yuklashda xato"
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                          child: Text(localizations.translate(
                              'noChatsYet'))); // "Hali chatlar yo'q."
                    } else {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final chatRoom = snapshot.data![index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 25,
                                backgroundImage: chatRoom
                                            .otherUserProfilePhotoUrl !=
                                        null
                                    ? NetworkImage(
                                        chatRoom.otherUserProfilePhotoUrl!)
                                    : const AssetImage(
                                            'assets/placeholder_profile.png')
                                        as ImageProvider,
                              ),
                              title: Text(
                                chatRoom.otherUsername,
                                style: TextStyle(
                                  fontWeight: chatRoom.unreadCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                chatRoom.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: chatRoom.unreadCount > 0
                                      ? Colors.black
                                      : Colors.grey[700],
                                ),
                              ),
                              trailing: chatRoom.unreadCount > 0
                                  ? Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        chatRoom.unreadCount.toString(),
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    )
                                  : null,
                              onTap: () async {
                                // Chat ekraniga o'tish va xabarlarni o'qilgan deb belgilash
                                UserModel targetUser = UserModel(
                                  uid: chatRoom.otherUserId,
                                  username: chatRoom.otherUsername,
                                  profilePhotoUrl:
                                      chatRoom.otherUserProfilePhotoUrl,
                                  // Boshqa kerakli maydonlarni to'ldirish
                                );
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      currentUser: _currentUserModel!,
                                      targetUser: targetUser,
                                    ),
                                  ),
                                );
                                // Chatdan qaytgandan so'ng xabarlarni o'qilgan deb belgilash
                                await firebaseService.markMessagesAsRead(
                                    chatRoom.id, _currentUser!.uid);
                              },
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
    );
  }
}
