import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final _formKey = GlobalKey<FormState>();
  String? _qrUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadQrUrl();
  }

  Future<void> _loadQrUrl() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final data = doc.data();
    if (data != null && data['qrUrl'] != null) {
      setState(() {
        _qrUrl = data['qrUrl'];
      });
    }
  }

  Future<void> _pickAndUploadQr() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _isLoading = true);

    // Upload to Imgur
    final bytes = await picked.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Replace with your Imgur client ID
    const clientId = '58704a4e4afb7bd';

    final response = await http.post(
      Uri.parse('https://api.imgur.com/3/image'),
      headers: {'Authorization': 'Client-ID $clientId'},
      body: {'image': base64Image},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final url = data['data']['link'];
      setState(() {
        _qrUrl = url;
      });
      // Save to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'qrUrl': url,
      }, SetOptions(merge: true));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('QR code uploaded!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload QR code.')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment QR Code')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Upload your payment QR code screenshot (Maybank, CIMB, TNG, etc.). Buyers will scan this to pay you.',
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_qrUrl != null && _qrUrl!.isNotEmpty)
              Column(
                children: [
                  const Text(
                    'Preview:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Image.network(
                    _qrUrl!,
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isLoading
                              ? null
                              : () async {
                                setState(() => _isLoading = true);
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null && _qrUrl != null) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .set({
                                        'qrUrl': _qrUrl,
                                      }, SetOptions(merge: true));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('QR code saved!'),
                                    ),
                                  );
                                }
                                setState(() => _isLoading = false);
                              },
                      icon: const Icon(Icons.save),
                      label:
                          _isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Save QR Code'),
                    ),
                  ),
                ],
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickAndUploadQr,
                icon: const Icon(Icons.upload),
                label:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Upload QR Code Image'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
