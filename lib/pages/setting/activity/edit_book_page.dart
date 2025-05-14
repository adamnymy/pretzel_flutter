import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditBookPage extends StatefulWidget {
  final String bookId;
  final Map<String, dynamic> bookData;

  const EditBookPage({Key? key, required this.bookId, required this.bookData})
    : super(key: key);

  @override
  State<EditBookPage> createState() => _EditBookPageState();
}

class _EditBookPageState extends State<EditBookPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _courseCodeController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late String _selectedCondition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.bookData['title']);
    _courseCodeController = TextEditingController(
      text: widget.bookData['courseCode'],
    );
    _priceController = TextEditingController(
      text: widget.bookData['price'].toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.bookData['description'] ?? '',
    );
    _selectedCondition = widget.bookData['condition'] ?? 'Good';  // Add default value
  }

  @override
  void dispose() {
    _titleController.dispose();
    _courseCodeController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('books')
          .doc(widget.bookId)
          .update({
            'title': _titleController.text.trim(),
            'courseCode': _courseCodeController.text.trim().toUpperCase(),
            'condition': _selectedCondition,
            'price': double.parse(_priceController.text),
            'description': _descriptionController.text.trim(),
            'updatedAt': FieldValue.serverTimestamp(),
            'sellerId': FirebaseAuth.instance.currentUser!.uid, // Ensure sellerId is set
          });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating book: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines ?? 1,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        floatingLabelStyle: TextStyle(
          color: Theme.of(context).primaryColor,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Book',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFormField(
              controller: _titleController,
              label: 'Book Title',
              hint: 'Enter the title of your book',
              validator: (value) => value?.isEmpty ?? true
                  ? 'Please enter a title'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildFormField(
              controller: _courseCodeController,
              label: 'Course Code',
              hint: 'e.g., CTU151',
              validator: (value) => value?.isEmpty ?? true
                  ? 'Please enter a course code'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCondition,
              decoration: InputDecoration(
                labelText: 'Condition',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.black, // Add this line to make text black
              ),
              dropdownColor: Colors.white, // Add this line for dropdown background
              validator: (value) => value == null ? 'Please select a condition' : null,
              items: ['New', 'Like New', 'Good', 'Fair', 'Poor']
                  .map((condition) => DropdownMenuItem(
                        value: condition,
                        child: Text(
                          condition,
                          style: const TextStyle(
                            color: Colors.black, // Add this line for dropdown items
                            fontFamily: 'Poppins',
                            fontSize: 14,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedCondition = value);
              },
            ),
            const SizedBox(height: 16),
            _buildFormField(
              controller: _priceController,
              label: 'Price (RM)',
              hint: 'Enter the price',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter a price';
                if (double.tryParse(value!) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildFormField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Tell buyers about your book\'s condition, markings, etc.',
              maxLines: 3,
              validator: (value) => value?.isEmpty ?? true
                  ? 'Please add a description'
                  : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateBook,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
