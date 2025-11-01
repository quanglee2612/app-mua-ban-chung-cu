import 'package:flutter/material.dart';
import 'admin_page.dart';
import 'admin_users_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  Widget _buildTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, size: 32, color: Colors.indigo),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title, 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
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
      appBar: AppBar(title: const Text('Quản trị hệ thống')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text('Chọn chức năng quản trị', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildTile(
              context,
              Icons.article_outlined,
              'Quản lý bài đăng',
              'Xem, phê duyệt, xóa bài đăng',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPage())),
            ),
            _buildTile(
              context,
              Icons.people_outline,
              'Quản lý người dùng',
              'Khóa / mở khóa, xóa user',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersPage())),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      'assets/images/admin_illustration.png',
                      height: 120,
                      errorBuilder: (_, __, ___) => const Icon(Icons.admin_panel_settings, size: 80, color: Colors.black12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
