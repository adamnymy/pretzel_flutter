import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatSellerPage extends StatefulWidget {
  final String sellerId;
  final String bookId;
  final String bookTitle;

  const ChatSellerPage({
    Key? key,
    required this.sellerId,
    required this.bookId,
    required this.bookTitle,
  }) : super(key: key);

  @override
  State<ChatSellerPage> createState() => _ChatSellerPageState();
}

class _ChatSellerPageState extends State<ChatSellerPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markChatAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<DocumentReference> _createOrGetChatDocument(String userId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw 'User not authenticated';

      // Query for existing chat based on bookId and participants
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('chats')
              .where('bookId', isEqualTo: widget.bookId)
              .where('participants', arrayContains: currentUser.uid)
              .get();

      // Return existing chat if found
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        await doc.reference.update({'isActive': true});
        return doc.reference;
      }

      // If no chat exists and current user is seller, throw error
      if (currentUser.uid == widget.sellerId) {
        throw 'Chat not found. Only buyers can initiate new conversations.';
      }

      // Create new chat (only reached if current user is buyer)
      return await FirebaseFirestore.instance.collection('chats').add({
        'bookId': widget.bookId,
        'bookTitle': widget.bookTitle,
        'sellerId': widget.sellerId,
        'buyerId': currentUser.uid,
        'participants': [currentUser.uid, widget.sellerId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        'unreadCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'removedBy': [],
        'isActive': true,
      });
    } catch (e) {
      print('Error creating/getting chat: $e');
      rethrow;
    }
  }

  Future<void> _markChatAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Check if current user is seller or buyer
      final bool isCurrentUserSeller = widget.sellerId == user.uid;
      final String buyerId = isCurrentUserSeller ? '' : user.uid;
      final String sellerId = isCurrentUserSeller ? user.uid : widget.sellerId;

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('chats')
              .where('bookId', isEqualTo: widget.bookId)
              .where('buyerId', isEqualTo: buyerId)
              .where('sellerId', isEqualTo: sellerId)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final chatDoc = querySnapshot.docs.first;
        if (chatDoc.data()['lastSenderId'] != user.uid) {
          await chatDoc.reference.update({'unreadCount': 0});
        }
      }
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Create or get chat document first
      final chatDoc = await _createOrGetChatDocument(user.uid);
      final batch = FirebaseFirestore.instance.batch();
      final messageRef = chatDoc.collection('messages').doc();
      final now = FieldValue.serverTimestamp();

      batch.set(messageRef, {
        'senderId': user.uid,
        'message': message,
        'timestamp': now,
        'read': false,
      });

      batch.update(chatDoc, {
        'lastMessage': message,
        'lastMessageTime': now,
        'lastSenderId': user.uid,
        'unreadCount': FieldValue.increment(1),
        'updatedAt': now,
        'removedBy': [],
      });

      await batch.commit();
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: ${e.toString()}')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.bookTitle,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .where('bookId', isEqualTo: widget.bookId)
                      .where('participants', arrayContains: user.uid)
                      .where('isActive', isEqualTo: true)
                      .limit(1)
                      .snapshots(),
              builder: (context, chatSnapshot) {
                if (!chatSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (chatSnapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Start a conversation',
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  );
                }

                final chatDoc = chatSnapshot.data!.docs.first;

                return StreamBuilder<QuerySnapshot>(
                  stream:
                      chatDoc.reference
                          .collection('messages')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!.docs;

                    return ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message =
                            messages[index].data() as Map<String, dynamic>;
                        final isMe = message['senderId'] == user?.uid;

                        if (!isMe && !(message['read'] ?? false)) {
                          messages[index].reference.update({'read': true});
                        }

                        return _MessageBubble(
                          message: message['message'] ?? '',
                          isMe: isMe,
                          timestamp:
                              (message['timestamp'] as Timestamp?)?.toDate(),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Message Input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontFamily: 'Poppins',
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime? timestamp;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isMe ? const Radius.circular(0) : null,
                bottomLeft: !isMe ? const Radius.circular(0) : null,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(timestamp!),
                    style: TextStyle(
                      color:
                          isMe ? Colors.white.withOpacity(0.7) : Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
