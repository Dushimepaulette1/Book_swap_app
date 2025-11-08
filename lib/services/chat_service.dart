import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _messagesCollection =>
      _firestore.collection('chat_messages');

  // Sending a message
  Future<void> sendMessage({
    required String swapOfferId,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final chatMessage = ChatMessage(
      id: '',
      swapOfferId: swapOfferId,
      senderId: user.uid,
      senderEmail: user.email ?? '',
      message: message.trim(),
      timestamp: DateTime.now(),
      isRead: false,
    );

    await _messagesCollection.add(chatMessage.toMap());
  }

  // Getting messages for swap offers
  Stream<List<ChatMessage>> getMessagesStream(String swapOfferId) {
    return _messagesCollection
        .where('swapOfferId', isEqualTo: swapOfferId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList(),
        );
  }

  // Marking messages as read
  Future<void> markMessagesAsRead(String swapOfferId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final unreadMessages = await _messagesCollection
        .where('swapOfferId', isEqualTo: swapOfferId)
        .where('senderId', isNotEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Getting the unread messages count for a specific swap offer
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

  // Getting the total unread messages count across all chats
  Stream<int> getTotalUnreadCountStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _messagesCollection
        .where('senderId', isNotEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          // Filter messages where current user is the recipient
          // (messages sent to me that I haven't read)
          return snapshot.docs.length;
        });
  }

  // Deleting all messages that have been swapped
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
