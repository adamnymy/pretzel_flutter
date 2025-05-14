import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pretzel_apk/services/image_service.dart';
import 'package:pretzel_apk/pages/setting/account/payment_method_page.dart';

class SellPage extends StatefulWidget {
  const SellPage({Key? key}) : super(key: key);

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController(); // Add this line
  String _selectedCondition = 'Good';
  String? _selectedDiplomaCourse;
  File? _bookImage;
  bool _isLoading = false;

  final List<String> _diplomaCourses = [
    'Accountancy (AC110)',
    'Business Studies (BA111)',
    'Banking Studies (BA119)',
    'Office Management (BA132)',
    'Public Administration (AM110)',
    'Computer Science (CS110)',
    'Library Management (IM110)',
    'Information Management (IM120)',
    'Art and Design (AD111)',
  ];

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024, // Limit image width
        maxHeight: 1024, // Limit image height
        imageQuality: 85, // Compress image quality
      );

      if (picked != null) {
        setState(() => _bookImage = File(picked.path));
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error selecting image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submit() async {
    // Validation checks
    if (!_formKey.currentState!.validate() || _bookImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and add an image'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Please login to list a book');

      // Only check for QR code
      final isQrUploaded = await _checkQrUploaded(context);
      if (!isQrUploaded) {
        setState(() => _isLoading = false);
        return;
      }

      // Rest of your existing upload logic
      print('Uploading image to ImgBB...');
      final imageUrl = await ImageService.uploadImage(_bookImage!);
      if (imageUrl == null) throw Exception('Failed to upload image');
      print('Image uploaded successfully: $imageUrl');

      // 2. Create book document in Firestore
      print('Creating book document...');
      final bookData = {
        'title': _titleController.text.trim(),
        'courseCode': _courseCodeController.text.trim().toUpperCase(),
        'diplomaCourse': _selectedDiplomaCourse,
        'condition': _selectedCondition,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text.trim(), // Add this line
        'imageUrl': imageUrl,
      };
      await _uploadBook(bookData);

      // 3. Update user's books count
      print('Updating books count...');
      await _updateBooksListedCount(user.uid);

      print('Book listed successfully!');

      // 4. Show success message and pop
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book listed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error listing book: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadBook(Map<String, dynamic> bookData) async {
    try {
      // Create searchable keywords
      final searchKeywords = [
        bookData['title'].toLowerCase(),
        bookData['courseCode'].toLowerCase(),
        // Add any other searchable fields
      ];

      // Add to Firestore with searchKeywords and timestamp
      await FirebaseFirestore.instance.collection('books').add({
        ...bookData,
        'searchKeywords': searchKeywords,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'available',
        'uid': FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (e) {
      throw Exception('Error uploading book: $e');
    }
  }

  Future<void> _updateBooksListedCount(String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);

      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final currentCount = userDoc.data()?['booksListed'] ?? 0;
      await transaction.update(userRef, {
        'booksListed': currentCount + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<bool> _checkQrUploaded(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final data = doc.data();
    if (data == null ||
        data['qrUrl'] == null ||
        data['qrUrl'].toString().isEmpty) {
      // Not uploaded, show dialog
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Upload Payment QR Code'),
              content: const Text(
                'You need to upload your payment QR code before selling a book.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentMethodsPage(),
                      ),
                    );
                  },
                  child: const Text('Upload Now'),
                ),
              ],
            ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List Your Book'), elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Text(
                'Share your books with fellow students!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Image Section
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child:
                            _bookImage != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    _bookImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 48,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add Book Photo',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form Fields
                    _buildTextField(
                      controller: _titleController,
                      label: 'Book Title',
                      icon: Icons.book_outlined,
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Enter the book title' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _courseCodeController,
                      label: 'Course Code',
                      icon: Icons.code,
                      hint: 'e.g. CTU553',
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Enter course code' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildDropdownField(
                      value: _selectedDiplomaCourse,
                      items: _diplomaCourses,
                      label: 'Diploma Course',
                      icon: Icons.school_outlined,
                      onChanged:
                          (value) =>
                              setState(() => _selectedDiplomaCourse = value),
                      validator:
                          (value) =>
                              value == null
                                  ? 'Please select a diploma course'
                                  : null,
                    ),
                    const SizedBox(height: 16),

                    _buildDropdownField(
                      value: _selectedCondition,
                      items: ['New', 'Like New', 'Good', 'Fair', 'Worn'],
                      label: 'Book Condition',
                      icon: Icons.star_outline,
                      onChanged:
                          (value) =>
                              setState(() => _selectedCondition = value!),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _priceController,
                      label: 'Price',
                      icon: Icons.attach_money,
                      prefix: 'RM ',
                      keyboardType: TextInputType.number,
                      validator:
                          (value) =>
                              value!.isEmpty || double.tryParse(value) == null
                                  ? 'Enter a valid price'
                                  : null,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      icon: Icons.description_outlined,
                      hint:
                          'Tell buyers about your book\'s condition, markings, etc.',
                      maxLines: 3, // Allow multiple lines
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? 'Please add a description'
                                  : null,
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child:
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton.icon(
                                onPressed: () async {
                                  if (await _checkQrUploaded(context)) {
                                    _submit();
                                  }
                                },
                                icon: const Icon(Icons.sell_outlined),
                                label: const Text(
                                  'List Book for Sale',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? prefix,
    TextInputType? keyboardType,
    int? maxLines, // Add this parameter
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1, // Add this line
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines != null, // Add this line
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items:
          items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose(); // Add this line
    super.dispose();
  }
}
