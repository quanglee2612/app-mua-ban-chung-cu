import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../chi_tiet_page.dart';
// admin_users_page.dart is no longer imported here; navigation to users is via AdminHomePage

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _toggleApprove(String id, bool currentlyApproved) async {
    try {
      await _firestore.collection('bai_dang').doc(id).update({'approved': !currentlyApproved});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(!currentlyApproved ? 'Đã phê duyệt' : 'Bỏ phê duyệt')));
      setState(() {}); // reload
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi cập nhật: $e')));
    }
  }

  Future<void> _deletePost(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa bài đăng này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _firestore.collection('bai_dang').doc(id).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa bài đăng')));
      setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
    }
  }

  Widget _buildItem(DocumentSnapshot d) {
    final data = d.data() as Map<String, dynamic>? ?? {};
    final title = data['tieuDe'] ?? '(không có tiêu đề)';
    final userName = data['userName'] ?? data['userId'] ?? 'Không rõ';
    final approved = data['approved'] == true;
    Timestamp? ts = data['createdAt'] as Timestamp?;
    final time = ts != null ? DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate()) : '-';

    return InkWell(
      onTap: () {
        // Debug tap
        print('Admin: tapped post ${d.id}');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChiTietPage(baiDangId: d.id)),
        );
      },
      child: Card(
        child: ListTile(
          title: Text(title),
          subtitle: Text('Tác giả: $userName \nNgày: $time'),
          isThreeLine: true,
          trailing: SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(approved ? Icons.check_circle : Icons.check_circle_outline, color: approved ? Colors.green : Colors.grey),
                  onPressed: () => _toggleApprove(d.id, approved),
                  tooltip: approved ? 'Bỏ phê duyệt' : 'Phê duyệt',
                ),
                const SizedBox(width: 6),
                IconButton(
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePost(d.id),
                  tooltip: 'Xóa',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Quản lý bài đăng'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('bai_dang').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('Chưa có bài đăng'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildItem(docs[index]),
          );
        },
      ),
    );
  }
}
