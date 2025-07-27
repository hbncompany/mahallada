// lib/services/firebase_service.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:collection/collection.dart'; // firstWhereOrNull uchun

// --- Ensure these model imports are correct and point to the right files ---
import 'package:mahallda_app/models/user_model.dart';
import 'package:mahallda_app/models/service_provider_model.dart';
import 'package:mahallda_app/models/service_model.dart'; // Assuming this is for your Service class/sectors
import 'package:mahallda_app/models/combined_service_provider.dart';
import 'package:mahallda_app/models/review_model.dart';
import 'package:mahallda_app/models/chat_message_model.dart'; // Ensure ChatMessage model is correct
import 'package:mahallda_app/models/chat_room_model.dart';
import 'package:mahallda_app/models/product_model.dart'; // For product groups
import 'package:mahallda_app/models/trade_listing_model.dart';
import 'package:mahallda_app/models/service_listing_model.dart'; // <--- NEW IMPORT

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final String _serverKey = 'AIzaSyCgdXhY-KYsj_qudluF-eJ136zyBlzLoQs';

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    String? token = await _firebaseMessaging.getToken();
    if (token != null && _auth.currentUser != null) {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
      print('FCM Token: $token');
    }
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }

  // Foydalanuvchi ma'lumotlarini olish (oldin getUserDatas edi, endi getUserData)
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(
            doc.data()!, doc.id); // doc.id ni ham yuboramiz
      }
      return null;
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  Future<void> updateUserSubscriptionStatus(String userId, bool isSubscriber,
      DateTime? endDate, String? purchaseToken) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isPremiumSubscriber': isSubscriber,
        'subscriptionEndDate':
        endDate != null ? Timestamp.fromDate(endDate) : null,
        'latestSubscriptionPurchaseToken': purchaseToken,
      });
    } catch (e) {
      print("Error updating user subscription status: $e");
      rethrow;
    }
  }

  // Foydalanuvchi obuna holatini tekshirish
  Future<bool> isUserPremium(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data() != null) {
      final data = userDoc.data()!;
      final isPremium = data['isPremiumSubscriber'] as bool? ?? false;
      final endDate = data['subscriptionEndDate'] as Timestamp?;

      if (isPremium &&
          endDate != null &&
          endDate.toDate().isAfter(DateTime.now())) {
        return true;
      }
    }
    return false;
  }

  // E'lonlar sonini hisoblash (CreateTradeListingScreen uchun)
  Future<int> getTradeListingsCountByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(
          'tradeListings') // tradeListings kolleksiyasini tekshiring
          .where('userId', isEqualTo: userId) // userId maydonini tekshiring
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print("Error getting trade listings count: $e");
      rethrow;
    }
  }

  // Faylni Firebase Storage ga yuklash (CreateTradeListingScreen va AddDeleteServiceScreen uchun)
  Future<String?> uploadFile(File file, String path) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final Reference storageRef = _storage.ref().child(path).child(fileName);
      final UploadTask uploadTask = storageRef.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading file to Firebase Storage: $e");
      return null;
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'registrationDate': Timestamp.now(),
        }, SetOptions(merge: true));
        await initNotifications();
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await initNotifications();
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential =
      await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'registrationDate': Timestamp.now(),
        }, SetOptions(merge: true));
        await initNotifications();
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<UserCredential?> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'registrationDate': Timestamp.now(),
        }, SetOptions(merge: true));
        await initNotifications();
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw e;
    }
  }

  Future<void> verifyPhoneNumber(
      String phoneNumber,
      Function(PhoneAuthCredential) verificationCompleted,
      Function(FirebaseAuthException) verificationFailed,
      Function(String, int?) codeSent,
      Function(String) codeAutoRetrievalTimeout) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<UserCredential> signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    UserCredential userCredential =
    await _auth.signInWithCredential(credential);
    if (userCredential.user != null) {
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'registrationDate': Timestamp.now(),
      }, SetOptions(merge: true));
      await initNotifications();
    }
    return userCredential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> saveUserData(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> saveServiceProviderData(
      ServiceProviderModel serviceProvider) async {
    await _firestore
        .collection('serviceProviders')
        .doc(serviceProvider.uid)
        .set(serviceProvider.toMap(), SetOptions(merge: true));
  }

  Future<List<UserModel>> getAllUsers() async {
    QuerySnapshot snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>,
        doc.id)) // doc.id ni ham yuboramiz
        .toList();
  }

  Future<ServiceProviderModel?> getServiceProviderData(String uid) async {
    DocumentSnapshot doc =
    await _firestore.collection('serviceProviders').doc(uid).get();
    if (doc.exists) {
      return ServiceProviderModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Service>> fetchServiceSectors() async {
    QuerySnapshot snapshot = await _firestore.collection('services').get();
    return snapshot.docs
        .map((doc) =>
        Service.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Stream<List<TradeListing>> getMyTradeListingsStream(String userId) {
    return _firestore
        .collection('tradeListings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TradeListing.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateTradeListingStatus(String listingId, bool isActive) async {
    await _firestore
        .collection('tradeListings')
        .doc(listingId)
        .update({'isActive': isActive});
  }

  Future<void> updateTradeListing(TradeListing listing) async {
    if (listing.id == null) {
      throw Exception("Trade listing ID cannot be null for update.");
    }
    await _firestore
        .collection('tradeListings')
        .doc(listing.id)
        .update(listing.toMap());
  }

  Future<void> deleteTradeListing(String listingId) async {
    try {
      await _firestore.collection('tradeListings').doc(listingId).delete();
    } catch (e) {
      print('Error deleting trade listing: $e');
      rethrow;
    }
  }

  Stream<List<ServiceProviderModel>> getMyServiceProvidersStream(
      String userId) {
    return _firestore
        .collection('serviceProviders')
        .where('uid', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceProviderModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> updateServiceProvider(
      ServiceProviderModel serviceProvider) async {
    await _firestore
        .collection('serviceProviders')
        .doc(serviceProvider.uid)
        .update(serviceProvider.toMap());
  }

  Future<void> updateServiceProviderStatus(String uid, bool isActive) async {
    await _firestore
        .collection('serviceProviders')
        .doc(uid)
        .update({'isActive': isActive});
  }

  Future<void> deleteServiceProvider(String uid) async {
    await _firestore.collection('serviceProviders').doc(uid).delete();
  }

  Future<List<Product>> fetchProductGroups() async {
    try {
      QuerySnapshot snapshot =
      await _firestore.collection('productGroups').get();
      return snapshot.docs
          .map((doc) =>
          Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print("Error fetching product groups: $e");
      throw Exception("Failed to fetch product groups: $e");
    }
  }

  Future<List<CombinedServiceProvider>> getAllCombinedServiceProviders({
    String? serviceSectorId,
    String? serviceType,
  }) async {
    List<CombinedServiceProvider> combinedProviders = [];
    try {
      Query usersQuery = _firestore
          .collection('users')
          .where('role', isEqualTo: 'serviceProvider');
      QuerySnapshot usersSnapshot = await usersQuery.get();

      for (var userDoc in usersSnapshot.docs) {
        UserModel user = UserModel.fromMap(
            userDoc.data() as Map<String, dynamic>,
            userDoc.id); // doc.id ni ham yuboramiz
        if (user.uid != null) {
          ServiceProviderModel? serviceProvider =
          await getServiceProviderData(user.uid!);
          if (serviceProvider != null) {
            bool matchesSector = serviceSectorId == null ||
                serviceProvider.serviceSector == serviceSectorId;
            bool matchesType = serviceType == null ||
                serviceProvider.serviceType == serviceType;

            if (matchesSector && matchesType) {
              combinedProviders.add(CombinedServiceProvider(
                user: user,
                serviceProvider: serviceProvider,
              ));
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching combined service providers: $e");
      rethrow;
    }
    return combinedProviders;
  }

  Future<void> addReview(Review review) async {
    await _firestore.collection('reviews').add(review.toMap());
    await _updateServiceProviderRating(review.serviceProviderUid);
  }

  Stream<List<Review>> getReviewsForServiceProvider(String serviceProviderUid) {
    return _firestore
        .collection('reviews')
        .where('serviceProviderUid', isEqualTo: serviceProviderUid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Review.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<void> _updateServiceProviderRating(String serviceProviderUid) async {
    QuerySnapshot reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('serviceProviderUid', isEqualTo: serviceProviderUid)
        .get();

    if (reviewsSnapshot.docs.isNotEmpty) {
      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc['rating'] as num).toDouble();
      }
      double averageRating = totalRating / reviewsSnapshot.docs.length;

      await _firestore
          .collection('serviceProviders')
          .doc(serviceProviderUid)
          .set(
        {'rating': averageRating},
        SetOptions(merge: true),
      );
    } else {
      await _firestore
          .collection('serviceProviders')
          .doc(serviceProviderUid)
          .set(
        {'rating': 0.0},
        SetOptions(merge: true),
      );
    }
  }

  String getChatRoomId(String user1Id, String user2Id) {
    List<String> ids = [user1Id, user2Id];
    ids.sort();
    return ids.join('_');
  }

  Future<void> sendMessage(
      String senderId, String receiverId, String message) async {
    String chatRoomId = getChatRoomId(senderId, receiverId);

    DocumentSnapshot chatRoomDoc =
    await _firestore.collection('chat_rooms').doc(chatRoomId).get();
    if (!chatRoomDoc.exists) {
      await _firestore.collection('chat_rooms').doc(chatRoomId).set({
        'participants': [senderId, receiverId],
        'lastMessage': '',
        'lastMessageTimestamp': Timestamp.now(),
        'unreadCount_${senderId}': 0,
        'unreadCount_${receiverId}': 0,
      });
    }

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(
      ChatMessage(
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        timestamp: Timestamp.now(),
        isRead: false,
      ).toMap(),
    );

    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'lastMessage': message,
      'lastMessageTimestamp': Timestamp.now(),
      'unreadCount_${receiverId}': FieldValue.increment(1),
    });

    UserModel? receiverUser = await getUserData(receiverId);
    if (receiverUser != null && receiverUser.fcmToken != null) {
      UserModel? senderUser = await getUserData(senderId);
      _sendPushNotification(
        receiverUser.fcmToken!,
        senderUser?.username ?? 'Yangi xabar',
        message,
        {
          'chatRoomId': chatRoomId,
          'senderId': senderId,
          'receiverId': receiverId
        },
      );
    }
  }

  Stream<List<ChatMessage>> getMessages(String user1Id, String user2Id) {
    String chatRoomId = getChatRoomId(user1Id, user2Id);
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatMessage.fromMap(doc.data()))
        .toList());
  }

  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'unreadCount_${userId}': 0,
    });

    QuerySnapshot unreadMessages = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  Stream<List<ChatRoom>> getChatRoomsStream(String userId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<ChatRoom> chatRooms = [];
      for (var doc in snapshot.docs) {
        String chatRoomId = doc.id;
        List<String> participants = List<String>.from(doc['participants']);
        String otherUserId = participants.firstWhere((id) => id != userId);

        UserModel? otherUser = await getUserData(otherUserId);
        if (otherUser != null) {
          final data = doc.data() as Map<String, dynamic>?;
          int unreadCount =
              (data?['unreadCount_${userId}'] as num?)?.toInt() ?? 0;

          chatRooms.add(ChatRoom(
            id: chatRoomId,
            otherUserId: otherUserId,
            otherUsername: otherUser.username ?? 'Noma\'lum foydalanuvchi',
            otherUserProfilePhotoUrl: otherUser.profilePhotoUrl,
            lastMessage: data?['lastMessage'] ?? '',
            lastMessageTimestamp:
            data?['lastMessageTimestamp'] as Timestamp? ?? Timestamp.now(),
            unreadCount: unreadCount,
          ));
        }
      }
      return chatRooms;
    });
  }

  Stream<int> getTotalUnreadChatCountStream(String userId) {
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        totalUnread += (data?['unreadCount_${userId}'] as num?)?.toInt() ?? 0;
      }
      return totalUnread;
    });
  }

  Future<Map<String, int>> getServiceSectorProviderCounts() async {
    Map<String, int> counts = {};
    try {
      List<CombinedServiceProvider> allProviders =
      await getAllCombinedServiceProviders();
      for (var provider in allProviders) {
        if (provider.serviceProvider.serviceSector != null) {
          counts[provider.serviceProvider.serviceSector!] =
              (counts[provider.serviceProvider.serviceSector!] ?? 0) + 1;
        }
      }
    } catch (e) {
      print("Error getting service sector provider counts: $e");
    }
    return counts;
  }

  Future<Map<String, int>> getServiceTypeProviderCounts(
      String serviceSectorId) async {
    Map<String, int> counts = {};
    try {
      List<CombinedServiceProvider> filteredProviders =
      await getAllCombinedServiceProviders(
        serviceSectorId: serviceSectorId,
      );
      for (var provider in filteredProviders) {
        if (provider.serviceProvider.serviceType != null) {
          counts[provider.serviceProvider.serviceType!] =
              (counts[provider.serviceProvider.serviceType!] ?? 0) + 1;
        }
      }
    } catch (e) {
      print(
          "Error getting service type provider counts for sector $serviceSectorId: $e");
    }
    return counts;
  }

  Future<void> addTradeListing(TradeListing listing) async {
    await _firestore.collection('tradeListings').add(listing.toMap());
  }

  Stream<List<Map<String, dynamic>>> getTradeListingsWithUserDetails() {
    return _firestore
        .collection('tradeListings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> listingsWithUsers = [];
      for (var doc in snapshot.docs) {
        TradeListing listing = TradeListing.fromMap(doc.data(), doc.id);
        UserModel? userModel = await getUserData(listing.userId);
        listingsWithUsers.add({
          'listing': listing,
          'userModel': userModel,
        });
      }
      return listingsWithUsers;
    });
  }

  // --- Service Listing Methods (NEW) ---
  Future<void> addServiceListing(ServiceListing listing) async {
    try {
      await _firestore.collection('serviceListings').add(listing.toMap());
    } catch (e) {
      print('Error adding service listing: $e');
      rethrow;
    }
  }

  Stream<List<ServiceListing>> getMyServiceListingsStream(String userId) {
    return _firestore
        .collection('serviceListings')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceListing.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateServiceListing(ServiceListing listing) async {
    if (listing.id == null) {
      throw Exception("Service listing ID cannot be null for update.");
    }
    try {
      await _firestore
          .collection('serviceListings')
          .doc(listing.id)
          .update(listing.toMap());
    } catch (e) {
      print('Error updating service listing: $e');
      rethrow;
    }
  }

  Future<void> deleteServiceListing(String listingId) async {
    try {
      await _firestore.collection('serviceListings').doc(listingId).delete();
    } catch (e) {
      print('Error deleting service listing: $e');
      rethrow;
    }
  }

  Future<void> updateServiceListingStatus(
      String listingId, bool isActive) async {
    try {
      await _firestore
          .collection('serviceListings')
          .doc(listingId)
          .update({'isActive': isActive});
    } catch (e) {
      print('Error updating service listing status: $e');
      rethrow;
    }
  }
  // --- END Service Listing Methods ---

  // --- Mahalla Chat Specific Methods ---

  // Generates a unique ID for the mahalla chat room
  String getMahallaChatRoomId(
      String regionNs10Code, String districtNs11Code, String mahallaCode) {
    return 'mahalla_${regionNs10Code}_${districtNs11Code}_$mahallaCode';
  }

  // Checks if a user is joined in a specific mahalla chat
  Future<bool> isUserJoinedMahallaChat(String chatRoomId, String userId) async {
    try {
      DocumentSnapshot doc =
      await _firestore.collection('mahalla_chats').doc(chatRoomId).get();
      if (doc.exists) {
        List<dynamic> participants = doc.get('participants');
        return participants.contains(userId);
      }
      return false;
    } catch (e) {
      print('Error checking mahalla chat membership: $e');
      rethrow;
    }
  }

  // Allows a user to join a mahalla chat
  Future<void> joinMahallaChat({
    required String chatRoomId,
    required String userId,
    required UserModel userModel,
  }) async {
    DocumentReference chatRoomRef =
    _firestore.collection('mahalla_chats').doc(chatRoomId);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot chatRoomDoc = await transaction.get(chatRoomRef);

      if (!chatRoomDoc.exists) {
        // Create the chat room if it doesn't exist
        transaction.set(chatRoomRef, {
          'mahallaNameUz':
          userModel.mahallaNameUz, // Store mahalla name for display
          'regionNs10Code': userModel.regionNs10Code,
          'districtNs11Code': userModel.districtNs11Code,
          'mahallaCode': userModel.mahallaCode,
          'participants': FieldValue.arrayUnion([userId]),
          'createdAt': Timestamp.now(),
        });
      } else {
        // Update participants list if room exists
        transaction.update(chatRoomRef, {
          'participants': FieldValue.arrayUnion([userId]),
        });
      }
    });
  }

  // Allows a user to leave a mahalla chat
  Future<void> leaveMahallaChat({
    required String chatRoomId,
    required String userId,
  }) async {
    DocumentReference chatRoomRef =
    _firestore.collection('mahalla_chats').doc(chatRoomId);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot chatRoomDoc = await transaction.get(chatRoomRef);

      if (chatRoomDoc.exists) {
        List<dynamic> currentParticipants =
        List.from(chatRoomDoc.get('participants'));
        if (currentParticipants.contains(userId)) {
          transaction.update(chatRoomRef, {
            'participants': FieldValue.arrayRemove([userId]),
          });
        }
      }
    });
  }

  // Sends a message to the mahalla chat
  Future<void> sendMahallaMessage({
    required String chatRoomId,
    required String senderId,
    required String senderUsername,
    String? senderProfilePhotoUrl,
    required String message,
  }) async {
    DocumentReference chatRoomRef =
    _firestore.collection('mahalla_chats').doc(chatRoomId);
    CollectionReference messagesRef = chatRoomRef.collection('messages');

    await messagesRef.add({
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderProfilePhotoUrl': senderProfilePhotoUrl,
      'message': message,
      'timestamp': Timestamp.now(),
      'type': 'text', // Can be expanded for image/video later
    });

    // Update last message in chat room document (optional, but good for summary)
    await chatRoomRef.set({
      'lastMessage': message,
      'lastMessageSenderId': senderId,
      'lastMessageTimestamp': Timestamp.now(),
    }, SetOptions(merge: true));

    // Send push notifications to other participants in the mahalla chat
    DocumentSnapshot chatRoomDoc = await chatRoomRef.get();
    if (chatRoomDoc.exists) {
      List<dynamic> participants = chatRoomDoc.get('participants');
      for (var participantId in participants) {
        if (participantId != senderId) {
          UserModel? recipientUser = await getUserData(participantId);
          if (recipientUser?.fcmToken != null) {
            _sendPushNotification(
              recipientUser!.fcmToken!,
              senderUsername, // Title of notification
              message, // Body of notification
              {
                'chatRoomId': chatRoomId,
                'type': 'mahalla_chat',
                'senderId': senderId,
              },
            );
          }
        }
      }
    }
  }

  // Gets the stream of messages for a mahalla chat
  Stream<List<ChatMessage>> getMahallaMessages(String chatRoomId) {
    return _firestore
        .collection('mahalla_chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp',
        descending:
        false) // Order descending for chat UI (latest at bottom)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatMessage.fromMap(doc.data()))
        .toList());
  }

  Future<void> _sendPushNotification(String token, String title, String body,
      Map<String, dynamic> data) async {
    final url = Uri.parse('https://fcm.googleapis.com/fcm/send');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'key=$_serverKey',
    };
    final payload = {
      'to': token,
      'notification': {
        'title': title,
        'body': body,
      },
      'data': data,
      'priority': 'high',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        print('FCM notification sent successfully');
      } else {
        print(
            'FCM notification failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error sending FCM notification: $e');
    }
  }
}
