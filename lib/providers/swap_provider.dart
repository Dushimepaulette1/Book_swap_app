import 'package:flutter/foundation.dart';
import '../models/swap_offer.dart';
import '../services/swap_service.dart';

/// Provider for managing swap offers state
class SwapProvider with ChangeNotifier {
  final SwapService _swapService = SwapService();

  // State variables
  List<SwapOffer> _sentOffers = [];
  List<SwapOffer> _receivedOffers = [];
  int _pendingOffersCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<SwapOffer> get sentOffers => _sentOffers;
  List<SwapOffer> get receivedOffers => _receivedOffers;
  int get pendingOffersCount => _pendingOffersCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Listen to sent offers in real-time
  void listenToSentOffers() {
    _swapService.getSentOffers().listen(
      (offers) {
        _sentOffers = offers;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load sent offers: $error';
        notifyListeners();
      },
    );
  }

  /// Listen to received offers in real-time
  void listenToReceivedOffers() {
    _swapService.getReceivedOffers().listen(
      (offers) {
        _receivedOffers = offers;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load received offers: $error';
        notifyListeners();
      },
    );
  }

  /// Listen to pending offers count for notification badge
  void listenToPendingOffersCount() {
    _swapService.getPendingReceivedOffersCount().listen((count) {
      _pendingOffersCount = count;
      notifyListeners();
    });
  }

  /// Create a new swap offer
  Future<void> createSwapOffer({
    required String recipientId,
    required String recipientEmail,
    required String offeredBookId,
    required String offeredBookTitle,
    required String requestedBookId,
    required String requestedBookTitle,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _swapService.createSwapOffer(
        recipientId: recipientId,
        recipientEmail: recipientEmail,
        offeredBookId: offeredBookId,
        offeredBookTitle: offeredBookTitle,
        requestedBookId: requestedBookId,
        requestedBookTitle: requestedBookTitle,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create swap offer: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Accept a swap offer
  Future<void> acceptOffer(String offerId) async {
    try {
      await _swapService.acceptOffer(offerId);
      // Real-time listener will update the list automatically
    } catch (e) {
      _error = 'Failed to accept offer: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Reject a swap offer
  Future<void> rejectOffer(String offerId) async {
    try {
      await _swapService.rejectOffer(offerId);
      // Real-time listener will update the list automatically
    } catch (e) {
      _error = 'Failed to reject offer: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Cancel a swap offer
  Future<void> cancelOffer(String offerId) async {
    try {
      await _swapService.cancelOffer(offerId);
      // Real-time listener will update the list automatically
    } catch (e) {
      _error = 'Failed to cancel offer: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
