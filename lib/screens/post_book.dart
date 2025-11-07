import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

/// Screen to post a new book listing
///
/// Allows users to:
/// - Pick a book cover image
/// - Enter book details (title, author, condition, swap preference)
/// - Upload to Firestore and Storage
class PostBookScreen extends StatefulWidget {
  const PostBookScreen({super.key});

  @override
  State<PostBookScreen> createState() => _PostBookScreenState();
}

class _PostBookScreenState extends State<PostBookScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _swapForController = TextEditingController();

  // Services
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  // State variables
  String _selectedCondition = 'New'; // Default condition
  File? _selectedImage; // Stores the picked image
  bool _isLoading = false;
  bool _isDragging = false; // Track if user is dragging over the drop zone

  // Condition options
  final List<String> _conditions = ['New', 'Like New', 'Good', 'Used'];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _swapForController.dispose();
    super.dispose();
  }

  /// Show bottom sheet with image source options
  Future<void> _showImageSourceOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose Image Source',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Camera option
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF2C2855),
                  ),
                  title: const Text('Camera'),
                  subtitle: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromSource(ImageSource.camera);
                  },
                ),

                const Divider(),

                // Gallery option
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF2C2855),
                  ),
                  title: const Text('Gallery'),
                  subtitle: const Text('Choose from photos'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromSource(ImageSource.gallery);
                  },
                ),

                const Divider(),

                // File Browser option
                ListTile(
                  leading: const Icon(
                    Icons.folder_open,
                    color: Color(0xFF2C2855),
                  ),
                  title: const Text('Files'),
                  subtitle: const Text('Browse all files (Downloads, etc.)'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromFiles();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Pick image from specific source
  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      // Use ImagePicker to get image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1000, // Limit image size
        maxHeight: 1000,
        imageQuality: 85, // Compress to 85% quality
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  /// Pick image using file picker (can access Downloads, Documents, etc.)
  Future<void> _pickImageFromFiles() async {
    try {
      // Use FilePicker - it uses Android's SAF (Storage Access Framework)
      // which doesn't require runtime permissions!
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
        allowMultiple: false,
        allowCompression: true,
        dialogTitle: 'Select Book Cover Image',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image selected successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick file: $e')));
      }
    }
  }

  /// Pick image from gallery (backward compatibility)
  Future<void> _pickImage() async {
    await _showImageSourceOptions();
  }

  /// Remove selected image
  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  /// Submit form and upload book
  Future<void> _submitBook() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;

      // Step 1: Upload image if selected
      if (_selectedImage != null) {
        try {
          print('📸 Uploading image...');
          imageUrl = await _storageService.uploadBookImage(_selectedImage!);
          print('✅ Image uploaded: $imageUrl');
        } catch (storageError) {
          print('⚠️ Storage upload failed: $storageError');
          // Use placeholder image if storage upload fails
          imageUrl =
              'https://via.placeholder.com/400x600/2C2855/FFFFFF?text=Book+Cover';

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Note: Using placeholder image (Firebase Storage not enabled)',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // No image selected - use placeholder
        imageUrl =
            'https://via.placeholder.com/400x600/2C2855/FFFFFF?text=No+Image';
      }

      // Step 2: Add book to Firestore with image URL
      print('📚 Adding book to Firestore...');
      await _firestoreService.addBook(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        condition: _selectedCondition,
        swapFor: _swapForController.text.trim(),
        imageUrl: imageUrl,
      );
      print('✅ Book added successfully!');

      // Step 3: Show success and go back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to previous screen
      }
    } catch (e) {
      print('❌ Error posting book: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post book: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Book'),
        backgroundColor: const Color(0xFF2C2855),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFF5C344),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Uploading book...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image picker section with drag & drop
                    DropTarget(
                      onDragDone: (detail) {
                        // Handle dropped files
                        if (detail.files.isNotEmpty) {
                          final file = detail.files.first;
                          // Check if it's an image
                          if (file.path.toLowerCase().endsWith('.jpg') ||
                              file.path.toLowerCase().endsWith('.jpeg') ||
                              file.path.toLowerCase().endsWith('.png') ||
                              file.path.toLowerCase().endsWith('.gif')) {
                            setState(() {
                              _selectedImage = File(file.path);
                              _isDragging = false;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please drop an image file (JPG, PNG, GIF)',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      onDragEntered: (detail) {
                        setState(() {
                          _isDragging = true;
                        });
                      },
                      onDragExited: (detail) {
                        setState(() {
                          _isDragging = false;
                        });
                      },
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: _isDragging
                                ? Colors.blue[50]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isDragging
                                  ? Colors.blue
                                  : Colors.grey[400]!,
                              width: _isDragging ? 2 : 1,
                            ),
                          ),
                          child: _selectedImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isDragging
                                          ? Icons.file_download
                                          : Icons.add_photo_alternate,
                                      size: 60,
                                      color: _isDragging
                                          ? Colors.blue
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isDragging
                                          ? 'Drop image here'
                                          : 'Tap to pick or drag & drop image',
                                      style: TextStyle(
                                        color: _isDragging
                                            ? Colors.blue
                                            : Colors.grey[600],
                                        fontSize: 16,
                                        fontWeight: _isDragging
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (!_isDragging) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Supports: JPG, PNG, GIF',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              : Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _selectedImage!,
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: IconButton(
                                        onPressed: _removeImage,
                                        icon: const Icon(Icons.close),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Book Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Book Title',
                        hintText: 'e.g., Data Structures & Algorithms',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter book title';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Author field
                    TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: 'Author',
                        hintText: 'e.g., Thomas H. Cormen',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter author name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Condition dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCondition,
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      items: _conditions.map((String condition) {
                        return DropdownMenuItem<String>(
                          value: condition,
                          child: Text(condition),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCondition = newValue;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Swap For field
                    TextFormField(
                      controller: _swapForController,
                      decoration: const InputDecoration(
                        labelText: 'Swap For',
                        hintText: 'e.g., Operating Systems textbook',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.swap_horiz),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter what you want to swap for';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Submit button
                    ElevatedButton(
                      onPressed: _submitBook,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5C344),
                        foregroundColor: const Color(0xFF2C2855),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Post Book',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
