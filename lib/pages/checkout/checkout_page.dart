import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pretzel_apk/pages/checkout/upload_receipt_page.dart';
import 'package:pretzel_apk/pages/chat/chat_seller_page.dart';

class CheckoutPage extends StatefulWidget {
  final String bookId;
  final String sellerId;
  final double price;
  final String bookTitle;

  const CheckoutPage({
    super.key,
    required this.bookId,
    required this.sellerId,
    required this.price,
    required this.bookTitle,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? _sellerQrUrl;
  bool _isLoading = true;
  bool _isProcessing = false;
  String _selectedPaymentMethod = 'qr';

  @override
  void initState() {
    super.initState();
    _loadSellerDetails();
  }

  Future<void> _loadSellerDetails() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.sellerId)
              .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _sellerQrUrl = data['qrUrl'];
            _isLoading = false;
          });
        } else {
          throw 'Seller has not set up payment QR code';
        }
      } else {
        throw 'Seller not found';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.bookTitle,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'RM ${widget.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Select Payment Method:',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RadioListTile<String>(
                        title: const Text(
                          'Pay with QR',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        value: 'qr',
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() => _selectedPaymentMethod = value!);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text(
                          'Meet & Pay',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        value: 'meetup',
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() => _selectedPaymentMethod = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_selectedPaymentMethod == 'qr') ...[
                        if (_sellerQrUrl != null && _sellerQrUrl!.isNotEmpty)
                          Center(
                            child: Image.network(
                              _sellerQrUrl!,
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: MediaQuery.of(context).size.width * 0.8,
                              fit: BoxFit.contain,
                            ),
                          ),
                        const SizedBox(height: 16),
                        const Text(
                          'Instructions:',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Open your preferred banking/eWallet app\n'
                          '2. Tap "Scan & Pay" and scan the QR code above\n'
                          '3. Enter the exact amount shown\n'
                          '4. Complete the payment\n'
                          '5. Take a screenshot of the receipt',
                          style: TextStyle(fontSize: 14),
                        ),
                      ] else ...[
                        const Text(
                          'Meetup Instructions:',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Choose a safe public location for meetup\n'
                          '2. Bring exact amount in cash\n'
                          '3. Inspect the book before payment\n'
                          '4. Complete the payment in person\n'
                          '5. Mark the transaction as complete',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              _isProcessing
                                  ? null
                                  : () async {
                                    setState(() => _isProcessing = true);
                                    try {
                                      final user =
                                          FirebaseAuth.instance.currentUser;
                                      if (user == null)
                                        throw 'User not logged in';

                                      // Create transaction record first
                                      final transactionRef =
                                          await FirebaseFirestore.instance
                                              .collection('transactions')
                                              .add({
                                                'bookId': widget.bookId,
                                                'bookTitle': widget.bookTitle,
                                                'sellerId': widget.sellerId,
                                                'buyerId': user.uid,
                                                'amount': widget.price,
                                                'status': 'awaiting_payment',
                                                'paymentMethod':
                                                    _selectedPaymentMethod,
                                                'timestamp':
                                                    FieldValue.serverTimestamp(),
                                              });

                                      if (!mounted) return;

                                      if (_selectedPaymentMethod == 'qr') {
                                        // For QR payment
                                        await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (context) => UploadReceiptPage(
                                                  transactionId:
                                                      transactionRef.id,
                                                  bookId: widget.bookId,
                                                  sellerId: widget.sellerId,
                                                ),
                                          ),
                                        );
                                      } else {
                                        // For meetup
                                        await Navigator.of(
                                          context,
                                        ).pushReplacement(
                                          MaterialPageRoute(
                                            builder:
                                                (context) => ChatSellerPage(
                                                  bookId: widget.bookId,
                                                  sellerId: widget.sellerId,
                                                  bookTitle: widget.bookTitle,
                                                ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error: ${e.toString()}',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() => _isProcessing = false);
                                      }
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          child:
                              _isProcessing
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
                                  : Text(
                                    _selectedPaymentMethod == 'qr'
                                        ? 'Next'
                                        : 'Chat with Seller',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
    );
  }
}
