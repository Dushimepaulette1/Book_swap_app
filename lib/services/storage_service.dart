import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to handle image uploads to Firebase Storage
///
/// This manages uploading book cover images and getting download URLs
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload book cover image
  ///
  /// Takes an image file, uploads it to Firebase Storage,
  /// and returns the download URL
  ///
  /// Images are stored in: books/{userId}/{timestamp}_{filename}
  Future<String> uploadBookImage(File imageFile) async {
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Create unique filename using timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'book_${timestamp}.jpg';

      // Create reference to storage location
      // Path structure: books/userId/filename
      final Reference storageRef = _storage
          .ref()
          .child('books')
          .child(user.uid)
          .child(fileName);

      // Upload the file
      // UploadTask tracks upload progress
      final UploadTask uploadTask = storageRef.putFile(imageFile);

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      // This is the URL we'll save in Firestore
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete an image from storage
  ///
  /// Takes the download URL and deletes the image
  /// Useful when user deletes a book listing
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Get reference from URL
      final Reference storageRef = _storage.refFromURL(imageUrl);

      // Delete the file
      await storageRef.delete();
    } catch (e) {
      // Log error but don't throw - image might already be deleted
      print('Error deleting image: $e');
    }
  }

  /// Upload image with progress tracking
  ///
  /// Same as uploadBookImage but provides upload progress
  /// Returns a Stream<double> with progress (0.0 to 1.0)
  Stream<double> uploadBookImageWithProgress(File imageFile) {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'book_${timestamp}.jpg';

    final Reference storageRef = _storage
        .ref()
        .child('books')
        .child(user.uid)
        .child(fileName);

    final UploadTask uploadTask = storageRef.putFile(imageFile);

    // Map upload progress to percentage
    return uploadTask.snapshotEvents.map((TaskSnapshot snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }
}
