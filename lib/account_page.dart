import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'my_posts_page.dart';
import 'admin/admin_config.dart';
import 'admin/admin_home_page.dart';
import 'edit_profile_page.dart';
import 'security_settings_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản của tôi'),
      ),
      body: user == null
          ? const Center(child: Text('Chưa đăng nhập'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thông tin người dùng
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        child: Icon(Icons.person, size: 40),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user!.email ?? 'Không có email',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'UID: ${user!.uid}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/', (route) => false);
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Đăng xuất'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Menu options
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Chỉnh sửa thông tin'),
                      subtitle: const Text('Tên hiển thị, ảnh đại diện, số điện thoại'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfilePage(),
                          ),
                        );
                      },
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Bảo mật tài khoản'),
                      subtitle: const Text('Đổi mật khẩu, xác thực email'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SecuritySettingsPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  // Nếu user không phải admin thì hiển thị mục "Bài đăng của tôi"
                  if (!(isAdminUid(user?.uid) || isAdminEmail(user?.email)))
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.article),
                        title: const Text('Bài đăng của tôi'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MyPostsPage()),
                          );
                        },
                      ),
                    ),
                  // Nếu user là admin thì hiển thị nút quản lý admin
                  if (isAdminUid(user?.uid) || isAdminEmail(user?.email))
                    Card(
                      color: Colors.indigo[50],
                      child: ListTile(
                        leading: const Icon(Icons.admin_panel_settings, color: Colors.indigo),
                        title: const Text('Quản lý (Admin)'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdminHomePage()),
                          );
                        },
                      ),
                    ),
                  const Spacer(),
                  const Divider(),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Ứng dụng mua bán chung cư\nPhiên bản 1.0.0',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
