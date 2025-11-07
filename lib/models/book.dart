import 'package:cloud_firestore/cloud_firestore.dart';

/// Book model representing a textbook listing
///
/// This class defines the structure of a book in our app
class Book {
  final String id; // Unique ID from Firestore
  final String title; // Book title
  final String author; // Author name
  final String condition; // New, Like New, Good, or Used
  final String swapFor; // What book they want in exchange
  final String ownerId; // User ID who posted this book
  final String ownerEmail; // Email of owner
  final DateTime createdAt; // When it was posted
  final String status; // available, pending, or swapped
  final String? imageUrl; // URL of book cover image (optional)

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.condition,
    required this.swapFor,
    required this.ownerId,
    required this.ownerEmail,
    required this.createdAt,
    this.status = 'available',
    this.imageUrl, // Optional field
  });

  /// Convert Book object to Map (for saving to Firestore)
  ///
  /// Firestore stores data as Maps (key-value pairs)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'condition': condition,
      'swapFor': swapFor,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'imageUrl': imageUrl, // Add image URL to map
    };
  }

  /// Create Book object from Firestore document
  ///
  /// When we read from Firestore, we get a Map. This converts it to Book object.
  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      condition: data['condition'] ?? '',
      swapFor: data['swapFor'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'available',
      imageUrl: data['imageUrl'], // Can be null
    );
  }

  /// Create a copy of this Book with some fields changed
  ///
  /// Useful for updating a book (create new object with changed fields)
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? condition,
    String? swapFor,
    String? status,
    String? imageUrl,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      condition: condition ?? this.condition,
      swapFor: swapFor ?? this.swapFor,
      ownerId: this.ownerId,
      ownerEmail: this.ownerEmail,
      createdAt: this.createdAt,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
