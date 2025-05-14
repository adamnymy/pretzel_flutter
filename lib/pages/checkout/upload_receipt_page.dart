import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class UploadReceiptPage extends StatefulWidget {
  final String transactionId;
  final String bookId;
  final String sellerId;

  const UploadReceiptPage({
    Key? key,
    required this.transactionId,
    required this.bookId,
    required this.sellerId,
  }) : super(key: key);

  @override
  State<UploadReceiptPage> createState() => _UploadReceiptPageState();
}

class _UploadReceiptPageState extends State<UploadReceiptPage> {
  File? _receiptFile;
  bool _isUploading = false;
  String? _receiptUrl;

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _receiptFile = File(picked.path);
      });
    }
  }

  Future<void> _uploadReceipt() async {
    if (_receiptFile == null) return;

    try {
      setState(() => _isUploading = true);

      print(
        'Debug: Starting receipt upload for transaction ${widget.transactionId}',
      );

      // Upload receipt image to Imgur
      final imgurClientId =
          '58704a4e4afb7bd'; // Replace with your Imgur Client ID
      final uri = Uri.parse('https://api.imgur.com/3/image');
      final request =
          http.MultipartRequest('POST', uri)
            ..headers['Authorization'] = 'Client-ID $imgurClientId'
            ..files.add(
              await http.MultipartFile.fromPath('image', _receiptFile!.path),
            );

      print('Debug: Uploading file to Imgur');
      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode != 200) {
        throw 'Imgur upload failed: ${responseData.body}';
      }

      final responseJson = json.decode(responseData.body);
      _receiptUrl = responseJson['data']['link']; // Get the Imgur URL
      print('Debug: Got Imgur URL: $_receiptUrl');

      // Update only the transaction with receipt
      await FirebaseFirestore.instance
          .collection('transactions')
          .doc(widget.transactionId)
          .update({
            'status': 'completed',
            'receiptUrl': _receiptUrl,
            'receiptUploadTime': FieldValue.serverTimestamp(),
          });

      // Update just the book status
      await FirebaseFirestore.instance
          .collection('books')
          .doc(widget.bookId)
          .update({'status': 'sold'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print('Error uploading receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upload Payment Receipt',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Please upload your payment receipt to complete the transaction.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
            ),
            const SizedBox(height: 24),
            if (_receiptFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _receiptFile!,
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'No receipt selected',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickReceipt,
              icon: const Icon(Icons.upload_file),
              label: const Text(
                'Select Receipt',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_isUploading || _receiptFile == null)
                        ? null
                        : _uploadReceipt,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child:
                    _isUploading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Text(
                          'Submit Receipt',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.white,
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
