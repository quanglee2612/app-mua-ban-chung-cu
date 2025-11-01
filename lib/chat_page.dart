import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String baiDangId;

  const ChatPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.baiDangId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? currentUserId;
  String? currentUserName;

  @override
  void initState() {
    super.initState();
    currentUserId = _auth.currentUser?.uid;
    _loadCurrentUserName();
    if (currentUserId != null) {
      _markMessagesAsRead();
    }
  }

  Future<void> _markMessagesAsRead() async {
    final chatRoomId = _getChatRoomId(currentUserId!, widget.receiverId);
    
    // Reset unreadCount cho người dùng hiện tại trong chat room
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'unreadCount': {
        currentUserId!: 0,
      }
    }, SetOptions(merge: true));

    // Reset tổng số tin nhắn chưa đọc của người dùng
    await _firestore.collection('users').doc(currentUserId).update({
      'unreadMessages': 0,
    });

    // Đánh dấu tất cả tin nhắn là đã đọc
    final messages = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> _loadCurrentUserName() async {
    if (currentUserId != null) {
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      setState(() {
        currentUserName = userDoc.data()?['name'] ?? 'Người dùng';
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || currentUserId == null) return;

    final chatRoomId = _getChatRoomId(currentUserId!, widget.receiverId);
    
    final message = _messageController.text.trim();
    final timestamp = FieldValue.serverTimestamp();

    // Cập nhật phòng chat với tin nhắn mới
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'participants': [currentUserId, widget.receiverId],
      'lastMessage': message,
      'lastMessageTime': timestamp,
      'lastSenderId': currentUserId,
      'baiDangId': widget.baiDangId,
      'unreadCount': {
        widget.receiverId: FieldValue.increment(1), // Tăng số tin chưa đọc cho người nhận
        currentUserId!: 0, // Reset số tin chưa đọc cho người gửi
      },
    }, SetOptions(merge: true));

    // Thêm tin nhắn mới
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'senderName': currentUserName,
      'receiverId': widget.receiverId,
      'message': message,
      'timestamp': timestamp,
      'read': false,
    });

    // Cập nhật collection users để theo dõi tin nhắn chưa đọc
    await _firestore.collection('users').doc(widget.receiverId).update({
      'unreadMessages': FieldValue.increment(1),
      'lastNotification': timestamp,
    });

    _messageController.clear();
  }

  String _getChatRoomId(String userId1, String userId2) {
    // Sắp xếp ID để đảm bảo cùng một phòng chat cho 2 người
    return userId1.compareTo(userId2) > 0
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Vui lòng đăng nhập để chat'),
        ),
      );
    }

    if (widget.receiverId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Không tìm thấy người dùng'),
        ),
      );
    }

    final chatRoomId = _getChatRoomId(currentUserId!, widget.receiverId);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName),
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(widget.receiverId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final isOnline = snapshot.data?.get('isOnline') ?? false;
                return Text(
                  isOnline ? 'Đang hoạt động' : 'Không hoạt động',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? Colors.green[300] : Colors.grey,
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chat_rooms')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Chưa có tin nhắn. Hãy bắt đầu cuộc trò chuyện!'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data!.docs[index];
                    final isMe = message['senderId'] == currentUserId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                message['senderName']?[0].toUpperCase() ?? '?',
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.indigo : Colors.grey[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: isMe
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['message'],
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDateTime(message['timestamp']),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe) const SizedBox(width: 40),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(51), // 0.2 * 255 = 51
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
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
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}