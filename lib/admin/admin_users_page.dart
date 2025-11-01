import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _toggleLock(String uid, bool currentlyLocked) async {
    try {
      await _firestore.collection('users').doc(uid).update({'disabled': !currentlyLocked});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(!currentlyLocked ? 'Đã khóa tài khoản' : 'Đã mở khóa')));
      setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi cập nhật: $e')));
    }
  }

  Future<void> _deleteUser(String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa user'),
        content: Text('Xóa user sẽ chỉ xóa document trong collection `users`. Việc xóa tài khoản Firebase Auth cần làm trên Firebase Console hoặc Admin SDK. Bạn muốn tiếp tục xóa document user $uid?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _firestore.collection('users').doc(uid).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa document user')));
      setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Quản lý người dùng')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').orderBy('email').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('Chưa có user'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data() as Map<String, dynamic>? ?? {};
              final email = data['email'] ?? '(no email)';
              final name = data['name'] ?? '';
              final disabled = data['disabled'] == true;
              return Card(
                child: ListTile(
                  title: Text(email),
                  subtitle: Text('UID: ${d.id}${name.isNotEmpty ? '\nTên: $name' : ''}'),
                  isThreeLine: name.isNotEmpty,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(disabled ? Icons.lock : Icons.lock_open, color: disabled ? Colors.red : Colors.green),
                        tooltip: disabled ? 'Mở khóa' : 'Khóa tài khoản',
                        onPressed: () => _toggleLock(d.id, disabled),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        tooltip: 'Xóa document user',
                        onPressed: () => _deleteUser(d.id),
                      ),
                    ],
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
