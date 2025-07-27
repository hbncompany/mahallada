// lib/models/chat_message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String senderId;
  final String
  receiverId; // In mahalla chat, receiverId might be the chat room ID or 'mahalla'
  final String message;
  final Timestamp timestamp;
  final bool isRead;
  final String? senderUsername; // Added for mahalla chat
  final String? senderProfilePhotoUrl; // Added for mahalla chat

  ChatMessage({
    required this.senderId,
    this.receiverId = 'mahalla', // Default for mahalla chat
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.senderUsername,
    this.senderProfilePhotoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'isRead': isRead,
      'senderUsername': senderUsername,
      'senderProfilePhotoUrl': senderProfilePhotoUrl,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      senderId: map['senderId'] as String,
      receiverId:
      map['receiverId'] as String? ?? 'mahalla', // Handle potential null
      message: map['message'] as String,
      timestamp: map['timestamp'] as Timestamp,
      isRead: map['isRead'] as bool? ?? false,
      senderUsername: map['senderUsername'] as String?,
      senderProfilePhotoUrl: map['senderProfilePhotoUrl'] as String?,
    );
  }
}
