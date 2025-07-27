// lib/models/chat_room_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id; // chatRoomId
  final String otherUserId;
  final String otherUsername;
  final String? otherUserProfilePhotoUrl;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;
  final int unreadCount;

  ChatRoom({
    required this.id,
    required this.otherUserId,
    required this.otherUsername,
    this.otherUserProfilePhotoUrl,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    this.unreadCount = 0,
  });

  // Bu factory konstruktorini Firestore ma'lumotlariga moslab yozish kerak bo'ladi.
  // ChatRoom to'g'ridan-to'g'ri Firestore kolleksiyasi emas, balki
  // 'chat_rooms' kolleksiyasidagi har bir chat uchun so'nggi xabarni
  // va ishtirokchilar ma'lumotlarini birlashtirib yaratiladi.
  // Shuning uchun bu yerda to'g'ridan-to'g'ri fromMap() bo'lmaydi,
  // balki FirebaseService'da ma'lumotlar yig'ilib yaratiladi.
}
