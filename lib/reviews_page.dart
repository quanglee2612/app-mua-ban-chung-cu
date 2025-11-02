import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/review.dart';

class ReviewsPage extends StatefulWidget {
  final String baiDangId;
  final String baiDangTitle;

  const ReviewsPage({
    super.key,
    required this.baiDangId,
    required this.baiDangTitle,
  });

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá')),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nhận xét')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Kiểm tra xem user đã review chưa
      final existingReviews = await FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .where('baiDangId', isEqualTo: widget.baiDangId)
          .get();

      if (existingReviews.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Bạn đã đánh giá bài đăng này trước đó')),
          );
        }
        return;
      }

      // Thêm review mới
      await FirebaseFirestore.instance.collection('reviews').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Ẩn danh',
        'userPhotoUrl': user.photoURL,
        'baiDangId': widget.baiDangId,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'reactions': {},
      });

      // Cập nhật rating trung bình trong bài đăng
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('baiDangId', isEqualTo: widget.baiDangId)
          .get();

      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += doc.data()['rating'] ?? 0;
      }
      
      final averageRating = totalRating / reviewsSnapshot.docs.length;
      
      await FirebaseFirestore.instance
          .collection('bai_dang')
          .doc(widget.baiDangId)
          .update({
        'averageRating': averageRating,
        'reviewCount': reviewsSnapshot.docs.length,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cảm ơn bạn đã đánh giá!')),
        );
        _commentController.clear();
        setState(() => _rating = 5.0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _reactToReview(String reviewId, String reactionType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final reviewRef =
          FirebaseFirestore.instance.collection('reviews').doc(reviewId);
      final review = await reviewRef.get();
      
      if (!review.exists) return;

      final reactions = Map<String, int>.from(review.data()?['reactions'] ?? {});
      final userReactionsRef = reviewRef.collection('user_reactions');
      final userReaction = await userReactionsRef.doc(user.uid).get();

      // Nếu user đã react trước đó
      if (userReaction.exists) {
        final previousReaction = userReaction.data()?['type'];
        if (previousReaction == reactionType) {
          // Bỏ reaction
          await userReactionsRef.doc(user.uid).delete();
          reactions[reactionType] = (reactions[reactionType] ?? 1) - 1;
        } else {
          // Đổi reaction
          await userReactionsRef.doc(user.uid).set({'type': reactionType});
          reactions[previousReaction] = (reactions[previousReaction] ?? 1) - 1;
          reactions[reactionType] = (reactions[reactionType] ?? 0) + 1;
        }
      } else {
        // React mới
        await userReactionsRef.doc(user.uid).set({'type': reactionType});
        reactions[reactionType] = (reactions[reactionType] ?? 0) + 1;
      }

      await reviewRef.update({'reactions': reactions});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá & Nhận xét'),
      ),
      body: Column(
        children: [
          // Form đánh giá
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.baiDangTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Rating stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: 'Nhận xét của bạn',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Gửi đánh giá',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Danh sách reviews
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('baiDangId', isEqualTo: widget.baiDangId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('Chưa có đánh giá nào cho bài đăng này'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final review =
                        Review.fromMap(doc.id, doc.data() as Map<String, dynamic>);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User info and rating
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: review.userPhotoUrl != null
                                      ? NetworkImage(review.userPhotoUrl!)
                                      : null,
                                  child: review.userPhotoUrl == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review.userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm')
                                            .format(review.createdAt),
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < review.rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Comment
                            Text(review.comment),
                            const SizedBox(height: 8),
                            // Reactions
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () =>
                                      _reactToReview(review.id, 'like'),
                                  icon: const Icon(Icons.thumb_up),
                                  label: Text(
                                      '${review.reactions?['like'] ?? 0}'),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _reactToReview(review.id, 'dislike'),
                                  icon: const Icon(Icons.thumb_down),
                                  label: Text(
                                      '${review.reactions?['dislike'] ?? 0}'),
                                ),
                              ],
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