import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'account_page.dart';
import 'dang_tin_page.dart';
import 'admin/admin_config.dart';
import 'admin/admin_home_page.dart';
import 'trang_chu_page.dart';
import 'favorites_page.dart';
import 'chat_list_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _handleAuthStateChanged() {
    setState(() {
      _pages = _buildPages();
    });
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  List<Widget> _buildPages() {
    final user = _auth.currentUser;
    final bool isAdmin = isAdminUid(user?.uid) || isAdminEmail(user?.email);

    return [
      const TrangChuPage(),
      const FavoritesPage(),
      // Nếu là admin thì tab thứ 3 hiển thị trang quản lý, còn user thường hiển thị trang đăng tin
      if (isAdmin) const AdminHomePage() else const DangTinPage(),
      ChatListPage(key: UniqueKey()), // Force recreate when user changes
      const AccountPage(),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pages = _buildPages();
    _updateOnlineStatus(true);
    _auth.authStateChanges().listen((_) => _handleAuthStateChanged());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateOnlineStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
    } else if (state == AppLifecycleState.paused || 
              state == AppLifecycleState.detached) {
      _updateOnlineStatus(false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: _buildBottomItems(),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildBottomItems() {
    final user = _auth.currentUser;
    final bool isAdmin = isAdminUid(user?.uid) || isAdminEmail(user?.email);

    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Trang chủ',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.favorite),
        label: 'Yêu thích',
      ),
      isAdmin
          ? const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Quản lý',
            )
          : const BottomNavigationBarItem(
              icon: Icon(Icons.add_box),
              label: 'Đăng tin',
            ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.chat),
        label: 'Tin nhắn',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Tài khoản',
      ),
    ];
  }
}