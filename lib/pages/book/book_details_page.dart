import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pretzel_apk/pages/chat/chat_seller_page.dart';
import 'package:pretzel_apk/navbar/cart_page.dart';
import 'package:pretzel_apk/pages/anotherUserProfile_page/anotherUserProfile.dart';

class BookDetailsPage extends StatelessWidget {
  final String bookId;
  final Map<String, dynamic> bookData;

  const BookDetailsPage({
    Key? key,
    required this.bookId,
    required this.bookData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('favorites')
                    .doc(bookId)
                    .snapshots(),
            builder: (context, snapshot) {
              final inWishlist = snapshot.data?.exists ?? false;
              return IconButton(
                icon: Icon(
                  inWishlist ? Icons.bookmark : Icons.bookmark_outline,
                  color: inWishlist ? Theme.of(context).primaryColor : null,
                ),
                onPressed: () => _toggleWishlist(context),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Image
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                width: double.infinity,
                color: Colors.grey[200],
                child: Image.network(
                  bookData['imageUrl'] ?? '',
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const Icon(Icons.error, size: 50),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          bookData['title'] ?? 'Untitled',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'RM ${bookData['price']?.toString() ?? '0.00'}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Course Code
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      bookData['courseCode'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Condition
                  _buildInfoRow(
                    'Condition',
                    bookData['condition'] ?? 'Not specified',
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bookData['description'] ?? 'No description available',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Seller Info
                  FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(bookData['uid'])
                            .get(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Text(
                            'Error loading seller information',
                            style: TextStyle(
                              color: Colors.red,
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.data == null || !snapshot.data!.exists) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Text(
                            'Seller information not available',
                            style: TextStyle(
                              color: Colors.grey,
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      final sellerData =
                          snapshot.data!.data() as Map<String, dynamic>;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seller Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: ClipOval(
                                child:
                                    sellerData['profilePicture'] != null &&
                                            sellerData['profilePicture']
                                                .toString()
                                                .isNotEmpty
                                        ? Image.network(
                                          sellerData['profilePicture'],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  CircleAvatar(
                                                    backgroundColor:
                                                        Theme.of(
                                                          context,
                                                        ).primaryColor,
                                                    child: Text(
                                                      (sellerData['username']
                                                                  as String? ??
                                                              'U')[0]
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontFamily: 'Poppins',
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                        )
                                        : CircleAvatar(
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          child: Text(
                                            (sellerData['username']
                                                        as String? ??
                                                    'U')[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                              ),
                            ),
                            title: Text(
                              sellerData['username'] ?? 'Unknown Seller',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sellerData['rating']?.toStringAsFixed(1) ??
                                      '0.0',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => AnotherUserProfile(
                                        userId: bookData['uid'],
                                        username:
                                            sellerData['username'] ??
                                            'Unknown User',
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
          child: Row(
            children: [
              // Chat Button
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => _startChat(context),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text(
                    'Chat',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Add to Cart Button
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _addToCart(context),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text(
                    'Add to Cart',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Future<void> _toggleWishlist(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to add to wishlist')),
        );
        return;
      }

      // First create user document if it doesn't exist
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await userRef.set({
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Then handle favorites collection
      final favRef = userRef.collection('favorites').doc(bookId);

      final doc = await favRef.get();
      if (doc.exists) {
        // Remove from wishlist
        await favRef.delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from wishlist')),
          );
        }
      } else {
        // Add to wishlist
        await favRef.set({
          'addedAt': FieldValue.serverTimestamp(),
          'bookId': bookId,
          'bookRef': '/books/$bookId',
          'condition': bookData['condition'],
          'courseCode': bookData['courseCode'],
          'imageUrl': bookData['imageUrl'],
          'price': bookData['price'],
          'status': 'available',
          'title': bookData['title'],
          'uid': bookData['uid'],
        });
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Added to wishlist')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _startChat(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to chat with seller')),
      );
      return;
    }

    // Don't allow seller to chat with themselves
    if (user.uid == bookData['uid']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is your book listing')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatSellerPage(
              sellerId: bookData['uid'],
              bookId: bookId,
              bookTitle: bookData['title'] ?? 'Untitled',
            ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add items to cart')),
      );
      return;
    }

    try {
      // Don't allow adding own book to cart
      if (user.uid == bookData['uid']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot buy your own book')),
        );
        return;
      }

      // Add to cart collection
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(bookId);

      final doc = await cartRef.get();
      if (doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book is already in your cart')),
        );
        return;
      }

      await cartRef.set({
        'addedAt': FieldValue.serverTimestamp(),
        'bookId': bookId,
        'bookRef': '/books/$bookId',
        'condition': bookData['condition'],
        'courseCode': bookData['courseCode'],
        'imageUrl': bookData['imageUrl'],
        'price': bookData['price'],
        'status': 'available',
        'title': bookData['title'],
        'sellerId': bookData['uid'],
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Added to cart'),
            action: SnackBarAction(
              label: 'VIEW CART',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }
}
