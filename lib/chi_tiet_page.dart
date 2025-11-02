import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'chat_page.dart';
import 'reviews_page.dart';

class ChiTietPage extends StatefulWidget {
  final String baiDangId;

  const ChiTietPage({super.key, required this.baiDangId});

  @override
  State<ChiTietPage> createState() => _ChiTietPageState();
}

class _ChiTietPageState extends State<ChiTietPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool isFavorite = false;

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
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    final favorites = List<String>.from(doc.data()?['favorites'] ?? []);
    setState(() {
      isFavorite = favorites.contains(widget.baiDangId);
    });
  }

  Future<void> _toggleFavorite() async {
    if (user == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
    final doc = await userRef.get();
    final favorites = List<String>.from(doc.data()?['favorites'] ?? []);

    setState(() {
      if (isFavorite) {
        favorites.remove(widget.baiDangId);
      } else {
        favorites.add(widget.baiDangId);
      }
      isFavorite = !isFavorite;
    });

    await userRef.update({'favorites': favorites});
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final String raw = phoneNumber.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số điện thoại không có')),
      );
      return;
    }

    // Làm sạch số điện thoại và thêm số 0 nếu cần
    String cleaned = raw.replaceAll(RegExp(r"[^\d+]"), '');
    if (!cleaned.startsWith('+84') && !cleaned.startsWith('0')) {
      cleaned = '0$cleaned';
    }
    
    final Uri launchUri = Uri(scheme: 'tel', path: cleaned);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(
          launchUri,
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      // Thử phương án khác nếu cách trên không được
      final Uri alternativeUri = Uri.parse('tel:$cleaned');
      if (await canLaunchUrl(alternativeUri)) {
        await launchUrl(
          alternativeUri,
          mode: LaunchMode.platformDefault,
        );
        return;
      }

      // Nếu không thể mở, hiển thị dialog cho phép sao chép số để gọi thủ công
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Không thể thực hiện cuộc gọi'),
          content: Text('Thiết bị của bạn không hỗ trợ gọi trực tiếp. Số điện thoại: $cleaned'),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: cleaned));
                Navigator.of(context).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép số điện thoại')),
                  );
                }
              },
              child: const Text('Sao chép'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi khi thực hiện cuộc gọi: $e')),
        );
      }
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bai_dang')
            .doc(widget.baiDangId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy bài đăng'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<String> images = List<String>.from(data['anhChiTiet'] ?? []);
          if (data['anh'] != null && data['anh'].isNotEmpty) {
            images.insert(0, data['anh']);
          }

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: images.isNotEmpty
                      ? CarouselSlider(
                          options: CarouselOptions(
                            height: 300,
                            viewportFraction: 1,
                            enableInfiniteScroll: images.length > 1,
                          ),
                          items: images.map((imageUrl) {
                            return Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            );
                          }).toList(),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 100),
                        ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Giá và tiêu đề
                      Text(
                        _formatCurrency(data['gia']),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['tieuDe'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Thông tin cơ bản
                      _buildInfoSection('Thông tin cơ bản', [
                        _buildInfoRow('Loại căn hộ', data['loaiCanHo'] ?? ''),
                        _buildInfoRow('Diện tích', '${data['dienTich']} m²'),
                        _buildInfoRow('Số tầng', '${data['soTang']}'),
                      ]),

                      const SizedBox(height: 16),

                      // Mô tả
                      _buildInfoSection('Mô tả', [
                        Text(data['moTa'] ?? ''),
                      ]),

                      const SizedBox(height: 16),

                      // Địa chỉ
                      _buildInfoSection('Địa chỉ', [
                        Text(data['diaChi'] ?? ''),
                      ]),

                      const SizedBox(height: 16),

                      // Thông tin liên hệ
                      _buildInfoSection('Thông tin liên hệ', [
                        Text('Người đăng: ${data['userName'] ?? 'Ẩn danh'}'),
                        Text('Ngày đăng: ${_formatDate(data['createdAt'])}'),
                        const SizedBox(height: 8),
                        Text(
                          'Số điện thoại: ${data['soDienThoai'] ?? data['phoneNumber'] ?? 'Chưa cung cấp'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _makePhoneCall(data['soDienThoai'] ?? data['phoneNumber'] ?? ''),
                                  icon: const Icon(Icons.phone),
                                  label: const Text('Gọi điện'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(140, 45),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatPage(
                                          receiverId: data['userId'] ?? '',
                                          receiverName: data['userName'] ?? 'Người dùng',
                                          baiDangId: widget.baiDangId,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.chat_bubble),
                                  label: const Text('Chat'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(140, 45),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReviewsPage(
                                      baiDangId: widget.baiDangId,
                                      baiDangTitle: data['tieuDe'] ?? 'Bài đăng',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.star),
                              label: const Text('Xem đánh giá'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 45),
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}