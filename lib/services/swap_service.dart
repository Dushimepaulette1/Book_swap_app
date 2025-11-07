import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/swap_offer.dart';
import 'firestore_service.dart';

/// Service for managing swap offers in Firestore
class SwapService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Collection reference
  CollectionReference get _swapOffersCollection =>
      _firestore.collection('swap_offers');

  /// Create a new swap offer
  Future<void> createSwapOffer({
    required String recipientId,
    required String recipientEmail,
    required String offeredBookId,
    required String offeredBookTitle,
    required String requestedBookId,
    required String requestedBookTitle,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to create swap offer');
    }

    final swapOffer = SwapOffer(
      id: '', // Firestore will generate
      senderId: currentUser.uid,
      senderEmail: currentUser.email ?? '',
      recipientId: recipientId,
      recipientEmail: recipientEmail,
      offeredBookId: offeredBookId,
      offeredBookTitle: offeredBookTitle,
      requestedBookId: requestedBookId,
      requestedBookTitle: requestedBookTitle,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await _swapOffersCollection.add(swapOffer.toFirestore());
  }

  /// Get all swap offers sent by current user
  Stream<List<SwapOffer>> getSentOffers() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _swapOffersCollection
        .where('senderId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SwapOffer.fromFirestore(doc))
              .toList();
        });
  }

  /// Get all swap offers received by current user
  Stream<List<SwapOffer>> getReceivedOffers() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _swapOffersCollection
        .where('recipientId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SwapOffer.fromFirestore(doc))
              .toList();
        });
  }

  /// Accept a swap offer
  /// When accepted, both books are removed from listings
  Future<void> acceptOffer(String offerId) async {
    // Get the swap offer details first
    final offerDoc = await _swapOffersCollection.doc(offerId).get();

    if (!offerDoc.exists) {
      throw Exception('Swap offer not found');
    }

    final offer = SwapOffer.fromFirestore(offerDoc);

    // Update the offer status
    await _swapOffersCollection.doc(offerId).update({
      'status': 'accepted',
      'respondedAt': Timestamp.now(),
    });

    // Delete both books from the listings
    try {
      // Delete the offered book (sender's book)
      await _firestoreService.deleteBook(offer.offeredBookId);

      // Delete the requested book (recipient's book)
      await _firestoreService.deleteBook(offer.requestedBookId);
    } catch (e) {
      // If book deletion fails, log but don't throw
      // Books might already be deleted or not exist
      print('Error deleting books after swap acceptance: $e');
    }
  }

  /// Reject a swap offer
  Future<void> rejectOffer(String offerId) async {
    await _swapOffersCollection.doc(offerId).update({
      'status': 'rejected',
      'respondedAt': Timestamp.now(),
    });
  }

  /// Cancel a swap offer (by sender)
  Future<void> cancelOffer(String offerId) async {
    await _swapOffersCollection.doc(offerId).delete();
  }

  /// Get count of pending received offers (for notification badge)
  Stream<int> getPendingReceivedOffersCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _swapOffersCollection
        .where('recipientId', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
