import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PendingBooksPage extends StatelessWidget {
  const PendingBooksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pending Books',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),
      body:
          user == null
              ? const Center(child: Text('Please login to view pending books'))
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('books') // Changed back to books collection
                        .where('status', isEqualTo: 'pending')
                        .where('sellerId', isEqualTo: user.uid)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('Error in pending books: ${snapshot.error}');
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final books = snapshot.data?.docs ?? [];

                  if (books.isEmpty) {
                    return const Center(
                      child: Text(
                        'No pending books found',
                        style: TextStyle(fontFamily: 'Poppins'),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index].data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text(
                            book['title'] ?? 'Untitled Book',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'RM ${book['price'].toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: const Chip(
                            label: Text(
                              'Pending',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
