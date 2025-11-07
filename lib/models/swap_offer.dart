import 'package:cloud_firestore/cloud_firestore.dart';

/// Swap Offer Model
///
/// Represents a swap offer where one user wants to exchange
/// their book for another user's book
class SwapOffer {
  final String id;
  final String senderId; // User who initiated the swap
  final String senderEmail; // For display
  final String recipientId; // User who owns the requested book
  final String recipientEmail; // For display
  final String offeredBookId; // Book the sender is offering
  final String offeredBookTitle; // For display
  final String requestedBookId; // Book the sender wants
  final String requestedBookTitle; // For display
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final DateTime? respondedAt; // When recipient accepted/rejected

  SwapOffer({
    required this.id,
    required this.senderId,
    required this.senderEmail,
    required this.recipientId,
    required this.recipientEmail,
    required this.offeredBookId,
    required this.offeredBookTitle,
    required this.requestedBookId,
    required this.requestedBookTitle,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  /// Create SwapOffer from Firestore document
  factory SwapOffer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SwapOffer(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderEmail: data['senderEmail'] ?? '',
      recipientId: data['recipientId'] ?? '',
      recipientEmail: data['recipientEmail'] ?? '',
      offeredBookId: data['offeredBookId'] ?? '',
      offeredBookTitle: data['offeredBookTitle'] ?? '',
      requestedBookId: data['requestedBookId'] ?? '',
      requestedBookTitle: data['requestedBookTitle'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert SwapOffer to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'recipientId': recipientId,
      'recipientEmail': recipientEmail,
      'offeredBookId': offeredBookId,
      'offeredBookTitle': offeredBookTitle,
      'requestedBookId': requestedBookId,
      'requestedBookTitle': requestedBookTitle,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null
          ? Timestamp.fromDate(respondedAt!)
          : null,
    };
  }

  /// Create a copy with updated fields
  SwapOffer copyWith({
    String? id,
    String? senderId,
    String? senderEmail,
    String? recipientId,
    String? recipientEmail,
    String? offeredBookId,
    String? offeredBookTitle,
    String? requestedBookId,
    String? requestedBookTitle,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return SwapOffer(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderEmail: senderEmail ?? this.senderEmail,
      recipientId: recipientId ?? this.recipientId,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      offeredBookId: offeredBookId ?? this.offeredBookId,
      offeredBookTitle: offeredBookTitle ?? this.offeredBookTitle,
      requestedBookId: requestedBookId ?? this.requestedBookId,
      requestedBookTitle: requestedBookTitle ?? this.requestedBookTitle,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}
