import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dang_tin_page.dart';

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  final user = FirebaseAuth.instance.currentUser;

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 VNĐ';
    num value;
    try {
      if (amount is num) value = amount;
      else if (amount is String) {
        final s = amount.toLowerCase().trim();
        String t = s.replaceAll('vnđ', '').replaceAll('vnd', '').trim();
        if (t.contains('tỷ')) {
          final number = t.split('tỷ')[0].replaceAll(RegExp(r'[^0-9.]'), '');
          value = double.parse(number) * 1000000000;
        } else if (t.contains('triệu')) {
          final number = t.split('triệu')[0].replaceAll(RegExp(r'[^0-9.]'), '');
          value = double.parse(number) * 1000000;
        } else {
          final number = t.replaceAll(RegExp(r'[^0-9.]'), '');
          value = double.parse(number);
        }
      } else {
        return '0 VNĐ';
      }
    } catch (e) {
      return amount.toString();
    }
    final v = value.toDouble();
    if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)} tỷ VNĐ';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(0)} triệu VNĐ';
    return '${NumberFormat('#,###').format(v)} VNĐ';
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
      await FirebaseFirestore.instance.collection('bai_dang').doc(id).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa bài đăng thành công')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
    }
  }

  Future<QuerySnapshot> _getPosts() async {
    if (user == null) throw Exception('Chưa đăng nhập');
    
    print('Debug: Fetching posts for userId = ${user!.uid}');
    return FirebaseFirestore.instance
        .collection('bai_dang')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bài đăng của tôi')),
        body: const Center(child: Text('Chưa đăng nhập')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài đăng của tôi'),
        actions: [
          // Nút refresh để tải lại dữ liệu
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Trigger rebuild để tải lại dữ liệu
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _getPosts(),
        builder: (context, snapshot) {
          // Surface stream errors clearly
          if (snapshot.hasError) {
            print('Debug: posts snapshot error=${snapshot.error}');
            return Center(child: Text('Lỗi khi tải bài đăng: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            print('Debug: snapshot has no data; user=${user?.uid}');
            return const Center(child: Text('Không có dữ liệu'));
          }

          final docs = snapshot.data!.docs;
          print('Debug: fetched ${docs.length} posts for user=${user!.uid}');
          if (docs.isEmpty) {
            return Center(child: Text('Bạn chưa có bài đăng nào (uid: ${user!.uid})'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: (data['anh'] != null && (data['anh'] as String).isNotEmpty)
                      ? Image.network(data['anh'], width: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported))
                      : const SizedBox(width: 80, child: Icon(Icons.image, size: 40)),
                  title: Text(data['tieuDe'] ?? ''),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 4),
                    Text('${data['loaiCanHo'] ?? ''} - ${data['soTang'] ?? ''} tầng'),
                    const SizedBox(height: 4),
                    Text(_formatCurrency(data['gia'])),
                  ]),
                  isThreeLine: true,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (c) => DangTinPage(baiDangId: d.id))); }),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deletePost(d.id)),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
