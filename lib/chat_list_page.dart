import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chat_page.dart';

class ChatListPage extends StatelessWidget {
  ChatListPage({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Center(
        child: Text('Vui lòng đăng nhập để xem tin nhắn'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chat_rooms')
            .where('participants', arrayContains: currentUser.uid)
            .snapshots(),
        builder: (context, chatSnapshot) {
          if (chatSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Chưa có cuộc trò chuyện nào'),
            );
          }

          return ListView.builder(
            itemCount: chatSnapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatSnapshot.data!.docs[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final participants = List<String>.from(chatData['participants'] ?? []);
              // Kiểm tra nếu không tìm thấy người dùng khác
              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => 'deleted_user',  // Sử dụng một ID mặc định cho người dùng đã xóa
              );

              // Nếu người dùng không tồn tại, bỏ qua cuộc trò chuyện này
              if (otherUserId == 'deleted_user') {
                return const SizedBox.shrink();
              }

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('bai_dang').doc(chatData['baiDangId']).get(),
                builder: (context, baiDangSnapshot) {
                  return StreamBuilder<DocumentSnapshot>(
                    stream: _firestore.collection('users').doc(otherUserId).snapshots(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                      final userName = userData?['name'] ?? 'Người dùng';
                      final isOnline = userData?['isOnline'] ?? false;
                      final baiDangData = baiDangSnapshot.data?.data() as Map<String, dynamic>?;

                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                userName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.black87),
                              ),
                            ),
                            if (isOnline)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(userName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              baiDangData?['tieuDe'] ?? 'Bài đăng đã bị xóa',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              chatData['lastMessage'] ?? '',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatDateTime(chatData['lastMessageTime']),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                receiverId: otherUserId,
                                receiverName: userName,
                                baiDangId: chatData['baiDangId'],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}