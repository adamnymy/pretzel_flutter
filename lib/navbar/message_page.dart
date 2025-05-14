import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pretzel_apk/pages/chat/chat_seller_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  bool _showBanner = true;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) {
      setState(() {
        _showBanner = false;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      setState(() {
        _showBanner = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notifications enabled successfully!',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text(
                  'Notifications Disabled',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: const Text(
                  'Please enable notifications in your device settings to receive message alerts.',
                  style: TextStyle(fontFamily: 'Poppins'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      openAppSettings();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Open Settings',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
        );
      }
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat('h:mm a').format(date);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MM/dd/yy').format(date);
    }
  }

  Widget _buildDefaultAvatar(BuildContext context, String? username) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Text(
        (username ?? 'U')[0].toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildChatList(User user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('lastMessageTime', descending: true)
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
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final chats = snapshot.data!.docs.where((doc) {
          final chatData = doc.data() as Map<String, dynamic>;
          final removedBy = List<String>.from(
            chatData['removedBy'] ?? [],
          );
          return !removedBy.contains(user.uid) &&
              chatData['lastMessage'] != null &&
              chatData['lastMessage'].toString().isNotEmpty;
        }).toList();

        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Messages Found!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Start exploring books and chat with sellers\nto begin your journey!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Navigate back to home or book list
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Explore Books',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            return Dismissible(
              key: Key(chats[index].id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Chat?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) async {
                try {
                  // Get reference to the chat document
                  final chatRef = FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chats[index].id);

                  // Start a batch write
                  final batch = FirebaseFirestore.instance.batch();

                  // Get and delete all messages
                  final messagesSnapshot = await chatRef
                      .collection('messages')
                      .get();
                  
                  for (var message in messagesSnapshot.docs) {
                    batch.delete(message.reference);
                  }

                  // Update chat document
                  batch.update(chatRef, {
                    'removedBy': FieldValue.arrayUnion([user.uid]),
                    'isActive': false,
                    'lastMessage': 'Chat deleted',
                    'unreadCount': 0
                  });

                  // Commit the batch
                  await batch.commit();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Chat deleted',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error deleting chat: $e',
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('books')
                    .doc(chats[index]['bookId'])
                    .get(),
                builder: (context, bookSnapshot) {
                  if (!bookSnapshot.hasData ||
                      !bookSnapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final isUserBuyer =
                      chats[index]['buyerId'] == user.uid;
                  final otherUserId =
                      isUserBuyer
                          ? chats[index]['sellerId']
                          : chats[index]['buyerId'];

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(otherUserId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return const SizedBox();
                      }

                      final userData =
                          userSnapshot.data!.data()
                              as Map<String, dynamic>?;
                      final username =
                          userData?['username'] ??
                          'Unknown User';

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            8,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatSellerPage(
                                  sellerId: chats[index]['sellerId'],
                                  bookId: chats[index]['bookId'],
                                  bookTitle: chats[index]['bookTitle'] ??
                                      'Book',
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // User Avatar
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: (userData != null &&
                                            userData['profilePicture'] !=
                                                null &&
                                            userData['profilePicture']
                                                .toString()
                                                .isNotEmpty)
                                        ? Image.network(
                                          userData['profilePicture'],
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) => _buildDefaultAvatar(
                                            context,
                                            userData['username'],
                                          ),
                                        )
                                        : _buildDefaultAvatar(
                                          context,
                                          userData?['username'],
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Chat Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              username,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w600,
                                                fontFamily: 'Poppins',
                                              ),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (chats[index]['lastMessageTime'] !=
                                              null)
                                            Text(
                                              _formatTimestamp(
                                                chats[index]['lastMessageTime']
                                                    as Timestamp,
                                              ),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        chats[index]['bookTitle'] ??
                                            'Book',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .primaryColor,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              chats[index]['lastMessage'] ??
                                                  '',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                                fontFamily: 'Poppins',
                                              ),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (chats[index]['unreadCount'] >
                                              0)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  12,
                                                ),
                                              ),
                                              child: Text(
                                                chats[index]['unreadCount']
                                                    .toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        elevation: 1,
      ),
      body: Column(
        children: [
          if (_showBanner && user != null)
            Material(
              elevation: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.amber.shade50,
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Turn on notifications to never miss a message',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          final status =
                              await Permission.notification.request();

                          if (status.isGranted) {
                            setState(() {
                              _showBanner = false;
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Notifications enabled successfully!',
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text(
                                        'Enable Notifications',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      content: const Text(
                                        'Please enable notifications in your device settings to receive message alerts.',
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            openAppSettings();
                                            Navigator.pop(context);
                                          },
                                          child: const Text(
                                            'Open Settings',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error requesting permissions: $e',
                                  style: const TextStyle(fontFamily: 'Poppins'),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text(
                        'Turn on',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => setState(() => _showBanner = false),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: user == null
                ? const Center(
                    child: Text(
                      'Please login to view your messages',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 16),
                    ),
                  )
                : _buildChatList(user),
          ),
        ],
      ),
    );
  }
}
