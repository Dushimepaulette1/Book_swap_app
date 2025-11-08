import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

/// Service for managing chat messages
///
/// Handles:
/// - Sending messages
/// - Listening to messages for a swap offer
/// - Marking messages as read
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _messagesCollection =>
      _firestore.collection('chat_messages');

  /// Send a message for a specific swap offer
  Future<void> sendMessage({
    required String swapOfferId,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final chatMessage = ChatMessage(
      id: '', // Firestore will generate this
      swapOfferId: swapOfferId,
      senderId: user.uid,
      senderEmail: user.email ?? '',
      message: message.trim(),
      timestamp: DateTime.now(),
      isRead: false,
    );

    await _messagesCollection.add(chatMessage.toMap());
  }

  /// Listen to messages for a specific swap offer in real-time
  Stream<List<ChatMessage>> getMessagesStream(String swapOfferId) {
    return _messagesCollection
        .where('swapOfferId', isEqualTo: swapOfferId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
  }

  /// Mark all messages in a swap offer as read for current user
  Future<void> markMessagesAsRead(String swapOfferId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Get all unread messages sent by other users
    final unreadMessages = await _messagesCollection
        .where('swapOfferId', isEqualTo: swapOfferId)
        .where('senderId', isNotEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    // Mark each as read
    final batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Get unread message count for a specific swap offer
  Stream<int> getUnreadCountStream(String swapOfferId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _messagesCollection
        .where('swapOfferId', isEqualTo: swapOfferId)
        .where('senderId', isNotEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Delete all messages for a swap offer (when swap is cancelled/rejected)
  Future<void> deleteMessagesForSwap(String swapOfferId) async {
    final messages = await _messagesCollection
        .where('swapOfferId', isEqualTo: swapOfferId)
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
