import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Add this import

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  void _showReceiptDialog(
    BuildContext context,
    Map<String, dynamic> transaction,
    String transactionId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Receipt for "${transaction['bookTitle']}"'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    transaction['receiptUrl'],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('Failed to load receipt image.');
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please log in to view notifications.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('transactions')
                .where('sellerId', isEqualTo: user.uid)
                .where(
                  'status',
                  whereIn: ['pending', 'completed'],
                ) // Show both pending and completed
                .where(
                  'receiptUrl',
                  isNull: false,
                ) // Only show transactions with receipts
                .orderBy(
                  'receiptUploadTime',
                  descending: true,
                ) // Show newest first
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet!',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final transaction =
                  notifications[index].data() as Map<String, dynamic>;
              final bookTitle = transaction['bookTitle'] ?? 'Unknown Book';
              final buyerId = transaction['buyerId'] ?? 'Unknown Buyer';
              final receiptUrl = transaction['receiptUrl'] ?? '';
              final status = transaction['status'];
              final isCompleted = status == 'completed';

              return Dismissible(
                key: Key(notifications[index].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  try {
                    // Delete the transaction from Firestore
                    await FirebaseFirestore.instance
                        .collection('transactions')
                        .doc(notifications[index].id)
                        .delete();

                    // Show a success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Notification for "$bookTitle" deleted.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } catch (e) {
                    // Handle any errors during deletion
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete notification: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: GestureDetector(
                  onTap: () {
                    if (transaction['receiptUrl']?.isNotEmpty == true) {
                      _showReceiptDialog(
                        context,
                        transaction,
                        notifications[index].id,
                      );
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: Icon(
                        isCompleted ? Icons.check_circle : Icons.pending,
                        color: isCompleted ? Colors.green : Colors.orange,
                      ),
                      title: Text(
                        isCompleted
                            ? 'Payment confirmed for "$bookTitle"'
                            : 'New receipt for "$bookTitle"',
                      ),
                      subtitle: Text('Buyer ID: $buyerId'),
                      trailing: Icon(
                        Icons.receipt_long,
                        color: isCompleted ? Colors.green : Colors.blue,
                      ),
                    ),
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
