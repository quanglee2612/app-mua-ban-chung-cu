import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chi_tiet_page.dart';

class TrangChuPage extends StatefulWidget {
  const TrangChuPage({super.key});

  @override
  State<TrangChuPage> createState() => _TrangChuPageState();
}

class _TrangChuPageState extends State<TrangChuPage> {
  final user = FirebaseAuth.instance.currentUser;
  List<String> favorites = [];

  // Bộ lọc
  String searchText = '';
  String selectedType = 'Tất cả';
  String selectedPrice = 'Tất cả';
  final List<String> propertyTypes = [
    'Tất cả',
    'Chung cư cao cấp',
    'Chung cư bình dân',
    'Chung cư mini',
    'Chung cư thương mại',
  ];
  final List<String> priceRanges = [
    'Tất cả',
    '< 1 tỷ',
    '1 - 2 tỷ',
    '> 2 tỷ',
  ];

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 VNĐ';

    num value;
    try {
      if (amount is num) {
        value = amount;
      } else if (amount is String) {
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
      // If parsing fails, return the raw string so UI won't crash
      return amount.toString();
    }

    final v = value.toDouble();
    if (v >= 1000000000) {
      return '${(v / 1000000000).toStringAsFixed(1)} tỷ VNĐ';
    } else if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(0)} triệu VNĐ';
    } else {
      return '${NumberFormat('#,###').format(v)} VNĐ';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      // Defensive: doc.data() may be null or in an unexpected state
      final data = doc.data();

      // Avoid calling setState if widget was removed while awaiting
      if (!mounted) return;

      setState(() {
        favorites = List<String>.from(data?['favorites'] ?? []);
      });
    } catch (e, st) {
      // Log for debugging; avoid throwing so UI doesn't crash
      // Use debugPrint to avoid using print in production
      debugPrint('Lỗi khi load favorites: $e');
      debugPrint('$st');
      // Optionally show a small non-blocking message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải danh sách yêu thích')),
        );
      }
    }
  }

  Future<void> _toggleFavorite(String postId) async {
    if (user == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);

    setState(() {
      if (favorites.contains(postId)) {
        favorites.remove(postId);
      } else {
        favorites.add(postId);
      }
    });

    await userRef.update({'favorites': favorites});
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: LayoutBuilder(builder: (context, constraints) {
              // On narrow screens stack filters vertically to avoid overflow
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm tiêu đề...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                      onChanged: (value) {
                        setState(() => searchText = value.trim().toLowerCase());
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedType,
                            items: propertyTypes
                                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                .toList(),
                            decoration: InputDecoration(
                              labelText: 'Loại',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (value) {
                              setState(() => selectedType = value ?? 'Tất cả');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedPrice,
                            items: priceRanges
                                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                .toList(),
                            decoration: InputDecoration(
                              labelText: 'Giá',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (value) {
                              setState(() => selectedPrice = value ?? 'Tất cả');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              // Wide layout: keep filters on single row
              return Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm tiêu đề...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                      onChanged: (value) {
                        setState(() => searchText = value.trim().toLowerCase());
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedType,
                      items: propertyTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      decoration: InputDecoration(
                        labelText: 'Loại',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (value) {
                        setState(() => selectedType = value ?? 'Tất cả');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedPrice,
                      items: priceRanges.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      decoration: InputDecoration(
                        labelText: 'Giá',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (value) {
                        setState(() => selectedPrice = value ?? 'Tất cả');
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bai_dang')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Chưa có bài đăng nào.'));
                }

                // Lọc dữ liệu
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['tieuDe'] ?? '').toString().toLowerCase();
                  final type = data['loaiCanHo'] ?? '';
                  final gia = data['gia'] is num ? data['gia'] as num : 0;

                  // Lọc theo tiêu đề
                  if (searchText.isNotEmpty && !title.contains(searchText)) return false;
                  // Lọc theo loại
                  if (selectedType != 'Tất cả' && type != selectedType) return false;
                  // Lọc theo giá
                  switch (selectedPrice) {
                    case '< 1 tỷ':
                      if (gia >= 1000000000) return false;
                      break;
                    case '1 - 2 tỷ':
                      if (gia < 1000000000 || gia > 2000000000) return false;
                      break;
                    case '> 2 tỷ':
                      if (gia <= 2000000000) return false;
                      break;
                  }
                  return true;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('Không tìm thấy bài đăng phù hợp.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final postId = docs[index].id;
                    final isFavorite = favorites.contains(postId);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChiTietPage(baiDangId: postId),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        shadowColor: Colors.black26,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ảnh chính
                            if (data['anh'] != null && data['anh'] != '')
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Image.network(
                                  data['anh'],
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 180,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported, size: 60),
                                  ),
                                ),
                              ),

                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['tieuDe'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '${data['loaiCanHo'] ?? ''} - ',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${data['soTang']} tầng',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['moTa'] ?? '',
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        _formatCurrency(data['gia']),
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${data['dienTich']} m²',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Người đăng: ${data['userName'] ?? 'Ẩn danh'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          // ❤️ Nút yêu thích
                                          IconButton(
                                            icon: Icon(
                                              isFavorite
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFavorite
                                                  ? Colors.redAccent
                                                  : Colors.grey,
                                            ),
                                            onPressed: () => _toggleFavorite(postId),
                                          ),
                                          Text(
                                            _formatDate(data['createdAt']),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
