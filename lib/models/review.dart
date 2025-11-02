class Review {
  final String id;
  final String userId;
  final String userName;
  final String baiDangId;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? userPhotoUrl;
  final Map<String, int>? reactions; // Like, dislike, etc.

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.baiDangId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userPhotoUrl,
    this.reactions,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'baiDangId': baiDangId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
      'userPhotoUrl': userPhotoUrl,
      'reactions': reactions,
    };
  }

  factory Review.fromMap(String id, Map<String, dynamic> map) {
    return Review(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Ẩn danh',
      baiDangId: map['baiDangId'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      userPhotoUrl: map['userPhotoUrl'],
      reactions: Map<String, int>.from(map['reactions'] ?? {}),
    );
  }
}