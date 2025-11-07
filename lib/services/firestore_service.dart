import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';

/// Service class to handle all Firestore operations for books
///
/// This handles Create, Read, Update, Delete (CRUD) operations
class FirestoreService {
  // Reference to the 'books' collection in Firestore
  final CollectionReference _booksCollection = FirebaseFirestore.instance
      .collection('books');

  // Get current user
  User? get currentUser => FirebaseAuth.instance.currentUser;

  /// CREATE: Add a new book listing
  ///
  /// Takes book data and adds it to Firestore
  /// Returns the ID of the newly created book
  Future<String> addBook({
    required String title,
    required String author,
    required String condition,
    required String swapFor,
    String? imageUrl, // Add optional image URL parameter
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not logged in');

      // Create book data map
      final bookData = {
        'title': title,
        'author': author,
        'condition': condition,
        'swapFor': swapFor,
        'ownerId': user.uid,
        'ownerEmail': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(), // Use server time
        'status': 'available',
        'imageUrl': imageUrl, // Add image URL to data
      };

      // Add to Firestore
      DocumentReference docRef = await _booksCollection.add(bookData);
      return docRef.id; // Return the generated ID
    } catch (e) {
      throw Exception('Failed to add book: $e');
    }
  }

  /// READ: Get all books (for Browse Listings screen)
  ///
  /// Returns a Stream that updates in real-time when data changes
  /// Stream continuously listens for changes in Firestore
  Stream<List<Book>> getAllBooks() {
    return _booksCollection
        .orderBy('createdAt', descending: true) // Newest first
        .snapshots() // Listen to real-time changes
        .map((snapshot) {
          // Convert each document to Book object
          return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
        });
  }

  /// READ: Get only current user's books (for My Listings screen)
  ///
  /// Filters books by ownerId to show only user's listings
  Stream<List<Book>> getMyBooks() {
    final user = currentUser;
    if (user == null) return Stream.value([]); // Empty stream if not logged in

    return _booksCollection
        .where('ownerId', isEqualTo: user.uid) // Filter by owner
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
        });
  }

  /// UPDATE: Edit an existing book
  ///
  /// Updates specific fields of a book document
  Future<void> updateBook({
    required String bookId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _booksCollection.doc(bookId).update(updates);
    } catch (e) {
      throw Exception('Failed to update book: $e');
    }
  }

  /// DELETE: Remove a book listing
  ///
  /// Permanently deletes a book document from Firestore
  Future<void> deleteBook(String bookId) async {
    try {
      await _booksCollection.doc(bookId).delete();
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  /// Get a single book by ID
  ///
  /// Useful for viewing book details
  Future<Book?> getBookById(String bookId) async {
    try {
      DocumentSnapshot doc = await _booksCollection.doc(bookId).get();

      if (doc.exists) {
        return Book.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get book: $e');
    }
  }

  /// Update book status (available → pending → swapped)
  ///
  /// Used when users initiate swap offers
  Future<void> updateBookStatus(String bookId, String newStatus) async {
    try {
      await _booksCollection.doc(bookId).update({'status': newStatus});
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }
}
