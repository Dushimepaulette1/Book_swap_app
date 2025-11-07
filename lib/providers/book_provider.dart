import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/firestore_service.dart';

/// Provider for managing book listings state
///
/// This provider:
/// - Fetches books from Firestore
/// - Manages book state (all books and user's books)
/// - Notifies listeners when data changes
/// - Handles real-time updates
class BookProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // State variables
  List<Book> _allBooks = [];
  List<Book> _myBooks = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Book> get allBooks => _allBooks;
  List<Book> get myBooks => _myBooks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all books from Firestore
  Future<void> fetchAllBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Note: We'll use Stream later for real-time updates
      // For now, fetch once
      final books = await _firestoreService.getAllBooks().first;
      _allBooks = books;
      _error = null;
    } catch (e) {
      _error = 'Failed to load books: $e';
      _allBooks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch current user's books
  Future<void> fetchMyBooks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final books = await _firestoreService.getMyBooks().first;
      _myBooks = books;
      _error = null;
    } catch (e) {
      _error = 'Failed to load your books: $e';
      _myBooks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Listen to all books in real-time
  void listenToAllBooks() {
    _firestoreService.getAllBooks().listen(
      (books) {
        _allBooks = books;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load books: $error';
        notifyListeners();
      },
    );
  }

  /// Listen to user's books in real-time
  void listenToMyBooks() {
    _firestoreService.getMyBooks().listen(
      (books) {
        _myBooks = books;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Failed to load your books: $error';
        notifyListeners();
      },
    );
  }

  /// Add a new book
  Future<void> addBook({
    required String title,
    required String author,
    required String condition,
    required String swapFor,
    required String imageUrl,
  }) async {
    try {
      await _firestoreService.addBook(
        title: title,
        author: author,
        condition: condition,
        swapFor: swapFor,
        imageUrl: imageUrl,
      );
      // Real-time listener will update the lists automatically
    } catch (e) {
      _error = 'Failed to add book: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing book
  Future<void> updateBook({
    required String bookId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestoreService.updateBook(bookId: bookId, updates: updates);
      // Real-time listener will update the lists automatically
    } catch (e) {
      _error = 'Failed to update book: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a book
  Future<void> deleteBook(String bookId) async {
    try {
      await _firestoreService.deleteBook(bookId);
      // Real-time listener will update the lists automatically
    } catch (e) {
      _error = 'Failed to delete book: $e';
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
