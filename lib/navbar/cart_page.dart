import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pretzel_apk/pages/checkout/checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Set<String> _selectedItems = {};

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cart',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body:
          user == null
              ? const Center(
                child: Text(
                  'Please login to view your cart',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
                ),
              )
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('cart')
                        .orderBy('addedAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final cartItems = snapshot.data!.docs;

                  if (cartItems.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your cart is empty!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add some books to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: cartItems.length,
                          itemBuilder: (context, index) {
                            final item =
                                cartItems[index].data() as Map<String, dynamic>;
                            return Dismissible(
                              key: Key(cartItems[index].id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red,
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (_) async {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('cart')
                                    .doc(cartItems[index].id)
                                    .delete();
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Checkbox(
                                        value: _selectedItems.contains(
                                          cartItems[index].id,
                                        ),
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              _selectedItems.add(
                                                cartItems[index].id,
                                              );
                                            } else {
                                              _selectedItems.remove(
                                                cartItems[index].id,
                                              );
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            item['imageUrl'] ?? '',
                                            width: 60,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Container(
                                                  width: 60,
                                                  height: 80,
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                    Icons.image_not_supported,
                                                  ),
                                                ),
                                          ),
                                        ),
                                        title: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item['courseCode'] ?? '',
                                              style: TextStyle(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item['title'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[100],
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  item['condition'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                    fontFamily: 'Poppins',
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                'RM ${item['price']?.toString() ?? '0.00'}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (cartItems.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                offset: const Offset(0, -4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value:
                                          cartItems.length ==
                                          _selectedItems.length,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedItems.addAll(
                                              cartItems.map((item) => item.id),
                                            );
                                          } else {
                                            _selectedItems.clear();
                                          }
                                        });
                                      },
                                    ),
                                    const Text(
                                      'Select All',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Total',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        Text(
                                          'RM ${_calculateSelectedTotal(cartItems)}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        _selectedItems.isEmpty
                                            ? null
                                            : () {
                                              // For single-item checkout (first selected)
                                              final selectedId =
                                                  _selectedItems.first;
                                              final selectedDoc = cartItems
                                                  .firstWhere(
                                                    (item) =>
                                                        item.id == selectedId,
                                                  );
                                              final data =
                                                  selectedDoc.data()
                                                      as Map<String, dynamic>;

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) => CheckoutPage(
                                                        bookId:
                                                            data['bookId'], // or selectedDoc.id if that's your bookId
                                                        sellerId:
                                                            data['sellerId'],
                                                        price: data['price'],
                                                        bookTitle:
                                                            data['title'],
                                                      ),
                                                ),
                                              );
                                            },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Checkout (${_selectedItems.length} items)',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
    );
  }

  String _calculateTotal(List<QueryDocumentSnapshot> items) {
    final total = items.fold<double>(
      0,
      (sum, item) => sum + (item.data() as Map<String, dynamic>)['price'],
    );
    return total.toStringAsFixed(2);
  }

  String _calculateSelectedTotal(List<QueryDocumentSnapshot> items) {
    final total = items
        .where((item) => _selectedItems.contains(item.id))
        .fold<double>(
          0,
          (sum, item) => sum + (item.data() as Map<String, dynamic>)['price'],
        );
    return total.toStringAsFixed(2);
  }
}
