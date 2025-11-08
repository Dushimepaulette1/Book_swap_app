import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for chat messages between users
///
/// Each message is linked to a swap offer and contains:
/// - Message content
/// - Sender information
/// - Timestamp
/// - Read status
class ChatMessage {
  final String id;
  final String swapOfferId; // Link to the swap offer
  final String senderId;
  final String senderEmail;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.swapOfferId,
    required this.senderId,
    required this.senderEmail,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  /// Create ChatMessage from Firestore document
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      swapOfferId: data['swapOfferId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderEmail: data['senderEmail'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'swapOfferId': swapOfferId,
      'senderId': senderId,
      'senderEmail': senderEmail,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  /// Create a copy with updated fields
  ChatMessage copyWith({
    String? id,
    String? swapOfferId,
    String? senderId,
    String? senderEmail,
    String? message,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      swapOfferId: swapOfferId ?? this.swapOfferId,
      senderId: senderId ?? this.senderId,
      senderEmail: senderEmail ?? this.senderEmail,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
