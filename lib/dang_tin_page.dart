import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DangTinPage extends StatefulWidget {
  final String? baiDangId;
  const DangTinPage({super.key, this.baiDangId});

  @override
  State<DangTinPage> createState() => _DangTinPageState();
}

class _DangTinPageState extends State<DangTinPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers cho các trường thông tin
  final _tieuDeController = TextEditingController();
  final _moTaController = TextEditingController();
  final _giaController = TextEditingController();
  final _anhController = TextEditingController();
  final _anhChiTietController = TextEditingController();
  final _diaChiController = TextEditingController();
  final _dienTichController = TextEditingController();
  final _soTangController = TextEditingController();
  final _phoneController = TextEditingController();

  // Các biến cho thông tin lựa chọn
  String _selectedType = 'Chung cư cao cấp';
  bool _isLoading = false;

  // Danh sách loại căn hộ
  final List<String> _propertyTypes = [
    'Chung cư cao cấp',
    'Chung cư bình dân',
    'Chung cư mini',
    'Chung cư thương mại'
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Reset dữ liệu
    _tieuDeController.text = '';
    _moTaController.text = '';
    _giaController.text = '';
    _anhController.text = '';
    _anhChiTietController.text = '';
    _diaChiController.text = '';
    _dienTichController.text = '';
    _soTangController.text = '';
    _phoneController.text = '';

    // Nếu đang chỉnh sửa bài đăng cũ
    if (widget.baiDangId != null) {
      setState(() => _isLoading = true);
      try {
        final doc = await FirebaseFirestore.instance
            .collection('bai_dang')
            .doc(widget.baiDangId)
            .get();

        if (!doc.exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không tìm thấy bài đăng')),
            );
            if (Navigator.canPop(context)) Navigator.pop(context);
          }
          return;
        }

        final data = doc.data()!;
        final gia = data['gia'];
        String giaText = '';
        if (gia is num) {
          if (gia >= 1000000000) {
            giaText = '${(gia / 1000000000).toStringAsFixed(1)} tỷ';
          } else if (gia >= 1000000) {
            giaText = '${(gia / 1000000).toStringAsFixed(0)} triệu';
          } else {
            giaText = gia.toString();
          }
        }

        if (mounted) {
          setState(() {
            _tieuDeController.text = data['tieuDe'] ?? '';
            _moTaController.text = data['moTa'] ?? '';
            _giaController.text = giaText;
            _anhController.text = data['anh'] ?? '';
            _anhChiTietController.text =
                (data['anhChiTiet'] as List<dynamic>?)?.join('\n') ?? '';
            _diaChiController.text = data['diaChi'] ?? '';
            _dienTichController.text = (data['dienTich'] ?? '').toString();
            _soTangController.text = (data['soTang'] ?? '').toString();
            _phoneController.text = data['phoneNumber'] ?? '';
            _selectedType = data['loaiCanHo'] ?? _propertyTypes[0];
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
          );
          setState(() => _isLoading = false);
        }
      }
    } // ✅ <--- thiếu dấu ngoặc này
  }

  @override
  void dispose() {
    _tieuDeController.dispose();
    _moTaController.dispose();
    _giaController.dispose();
    _anhController.dispose();
    _anhChiTietController.dispose();
    _diaChiController.dispose();
    _dienTichController.dispose();
    _soTangController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _dangTin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để đăng tin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String userName = user.email ?? 'Ẩn danh';
      try {
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          // Kiểm tra cờ disabled (khóa tài khoản)
          if (data != null && data['disabled'] == true) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Tài khoản của bạn đã bị khóa. Liên hệ admin để biết thêm.'),
                backgroundColor: Colors.red,
              ));
              setState(() => _isLoading = false);
            }
            return;
          }
          userName = data?['name'] ?? userName;
        }
      } catch (e) {
        print('Lỗi khi lấy thông tin user: $e');
      }

      String giaTri = _giaController.text.toLowerCase();
      num giaTriSo;

      try {
        giaTri = giaTri.toLowerCase().trim();
        giaTri = giaTri.replaceAll('vnđ', '').replaceAll('vnd', '').trim();

        if (giaTri.contains('tỷ')) {
          final number = giaTri.split('tỷ')[0].trim();
          giaTriSo = double.parse(number) * 1000000000;
        } else if (giaTri.contains('triệu')) {
          final number = giaTri.split('triệu')[0].trim();
          giaTriSo = double.parse(number) * 1000000;
        } else {
          giaTri = giaTri.replaceAll(RegExp(r'[^0-9]'), '');
          giaTriSo = int.parse(giaTri);
        }
      } catch (e) {
        throw Exception('Giá không hợp lệ. Vui lòng nhập: 2 tỷ, 500 triệu hoặc số');
      }

      double dienTich;
      try {
        dienTich = double.parse(_dienTichController.text.trim());
      } catch (e) {
        throw Exception('Diện tích không hợp lệ.');
      }

      int soTang;
      try {
        soTang = int.parse(_soTangController.text.trim());
      } catch (e) {
        throw Exception('Số tầng không hợp lệ.');
      }

      await FirebaseFirestore.instance.collection('bai_dang').add({
        'tieuDe': _tieuDeController.text.trim(),
        'moTa': _moTaController.text.trim(),
        'gia': giaTriSo,
        'anh': _anhController.text.trim(),
        'anhChiTiet': _anhChiTietController.text
            .split('\n')
            .where((url) => url.trim().isNotEmpty)
            .toList(),
        'diaChi': _diaChiController.text.trim(),
        'dienTich': dienTich,
        'soTang': soTang,
        'loaiCanHo': _selectedType,
        'phoneNumber': _phoneController.text.trim(),
        'userId': user.uid,
        'userName': userName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đăng tin thành công')));
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng tin'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang xử lý...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _tieuDeController,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Nhập tiêu đề' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Loại căn hộ',
                          border: OutlineInputBorder(),
                        ),
                        items: _propertyTypes
                            .map((type) =>
                                DropdownMenuItem(value: type, child: Text(type)))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _diaChiController,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Nhập địa chỉ' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _moTaController,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả chi tiết',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Nhập mô tả' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _giaController,
                              decoration: const InputDecoration(
                                labelText: 'Giá (VNĐ)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.text,
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Nhập giá' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _dienTichController,
                              decoration: const InputDecoration(
                                labelText: 'Diện tích (m²)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Nhập diện tích' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _soTangController,
                        decoration: const InputDecoration(
                          labelText: 'Số tầng',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Nhập số tầng' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại liên hệ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Nhập số điện thoại' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _anhController,
                        decoration: const InputDecoration(
                          labelText: 'Link ảnh đại diện',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Nhập link ảnh' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _anhChiTietController,
                        decoration: const InputDecoration(
                          labelText: 'Link ảnh chi tiết (mỗi ảnh 1 dòng)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _dangTin,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.indigo,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                )
                              : const Text(
                                  'Đăng tin',
                                  style:
                                      TextStyle(fontSize: 16, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
