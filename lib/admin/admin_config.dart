// Cấu hình admin tạm thời.
// Thêm UID hoặc email của tài khoản admin vào các danh sách bên dưới.
// Lưu ý: Cách này chỉ phù hợp cho môi trường dev/demo. Ở production nên
// dùng Firebase Custom Claims hoặc kiểm tra quyền từ backend để tránh bị giả mạo.

const Set<String> adminUids = {
   'Rha9Ox0WNlTYGoFtBbK0Owj93HE3',
};

const Set<String> adminEmails = {
   'admin@gmail.com',
};

bool isAdminUid(String? uid) => uid != null && adminUids.contains(uid);

bool isAdminEmail(String? email) => email != null && adminEmails.contains(email);
