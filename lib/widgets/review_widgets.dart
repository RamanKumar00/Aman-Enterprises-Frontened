import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/services/review_service.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

/// Star rating display widget
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final bool showText;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 18,
    this.color = Colors.amber,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          if (index < rating.floor()) {
            return Icon(Icons.star_rounded, size: size, color: color);
          } else if (index < rating) {
            return Icon(Icons.star_half_rounded, size: size, color: color);
          } else {
            return Icon(Icons.star_outline_rounded, size: size, color: Colors.grey.shade300);
          }
        }),
        if (showText) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ],
    );
  }
}

/// Interactive star rating selector
class StarRatingSelector extends StatelessWidget {
  final int rating;
  final Function(int) onRatingChanged;
  final double size;

  const StarRatingSelector({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        return GestureDetector(
          onTap: () => onRatingChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starValue <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: starValue <= rating ? Colors.amber : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }
}

/// Rating summary widget with distribution bars
class RatingSummary extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution; // {5: 10, 4: 5, 3: 2, 2: 1, 1: 0}

  const RatingSummary({
    super.key,
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = distribution.values.isEmpty ? 1 : distribution.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Average rating and star
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                StarRating(rating: averageRating, size: 20, showText: false),
                const SizedBox(height: 4),
                Text(
                  '$totalReviews reviews',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Distribution bars
          Expanded(
            flex: 3,
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = distribution[star] ?? 0;
                final percentage = maxCount > 0 ? count / maxCount : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              star >= 4 ? Colors.green : star == 3 ? Colors.amber : Colors.red,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$count',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single review card widget
class ReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  final VoidCallback? onHelpfulPressed;
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;
  final bool showProductInfo;
  final bool isEditable;

  const ReviewCard({
    super.key,
    required this.review,
    this.onHelpfulPressed,
    this.onEditPressed,
    this.onDeletePressed,
    this.showProductInfo = false,
    this.isEditable = false,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _isHelpful = false;
  int _helpfulCount = 0;

  @override
  void initState() {
    super.initState();
    _helpfulCount = widget.review['helpfulCount'] ?? 0;
    final helpfulBy = widget.review['helpfulBy'] as List? ?? [];
    final userId = UserService().userId;
    _isHelpful = helpfulBy.contains(userId);
  }

  Future<void> _toggleHelpful() async {
    final reviewId = widget.review['_id'];
    final response = await ReviewService.markReviewHelpful(reviewId);
    
    if (!mounted) return;

    if (response.success) {
      setState(() {
        _isHelpful = response.data?['isHelpful'] ?? !_isHelpful;
        _helpfulCount = response.data?['helpfulCount'] ?? _helpfulCount;
      });
    }
    widget.onHelpfulPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.review['user'] as Map<String, dynamic>?;
    final userName = user?['shopName'] ?? 'Anonymous User';
    final rating = (widget.review['rating'] ?? 0).toDouble();
    final title = widget.review['title'] ?? '';
    final comment = widget.review['comment'] ?? '';
    final isVerified = widget.review['isVerifiedPurchase'] ?? false;
    final isEdited = widget.review['isEdited'] ?? false;
    final createdAt = DateTime.tryParse(widget.review['createdAt'] ?? '') ?? DateTime.now();
    final product = widget.review['product'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: User info and rating
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryGreen.withAlpha(51),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.verified, size: 12, color: Colors.green.shade700),
                                const SizedBox(width: 2),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(createdAt) + (isEdited ? ' (Edited)' : ''),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating
              StarRating(rating: rating, size: 16),
            ],
          ),
          
          // Product info (if showing)
          if (widget.showProductInfo && product != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: product['image']?['url'] ?? '',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey.shade200),
                      errorWidget: (context, url, error) => const Icon(Icons.image, size: 30),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      product['productName'] ?? 'Product',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Review title
          if (title.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],

          // Review comment
          const SizedBox(height: 8),
          Text(
            comment,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),

          // Actions Row
          const SizedBox(height: 12),
          Row(
            children: [
              // Helpful button
              InkWell(
                onTap: _toggleHelpful,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isHelpful ? AppColors.primaryGreen.withAlpha(26) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isHelpful ? Icons.thumb_up : Icons.thumb_up_outlined,
                        size: 16,
                        color: _isHelpful ? AppColors.primaryGreen : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Helpful ($_helpfulCount)',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isHelpful ? AppColors.primaryGreen : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Edit/Delete buttons (if editable)
              if (widget.isEditable) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: Colors.blue,
                  onPressed: widget.onEditPressed,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: Colors.red,
                  onPressed: widget.onDeletePressed,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Write review bottom sheet
class WriteReviewBottomSheet extends StatefulWidget {
  final String productId;
  final String orderId;
  final String productName;
  final Function(bool) onReviewSubmitted;

  const WriteReviewBottomSheet({
    super.key,
    required this.productId,
    required this.orderId,
    required this.productName,
    required this.onReviewSubmitted,
  });

  @override
  State<WriteReviewBottomSheet> createState() => _WriteReviewBottomSheetState();
}

class _WriteReviewBottomSheetState extends State<WriteReviewBottomSheet> {
  int _rating = 0;
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    if (_commentController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write at least 10 characters')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final response = await ReviewService.createReview(
      productId: widget.productId,
      orderId: widget.orderId,
      rating: _rating,
      title: _titleController.text.trim(),
      comment: _commentController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (response.success) {
      widget.onReviewSubmitted(true);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Write a Review',
              style: AppTextStyles.headingSmall,
            ),
            Text(
              widget.productName,
              style: TextStyle(color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 24),

            // Rating
            const Text('Your Rating', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Center(
              child: StarRatingSelector(
                rating: _rating,
                onRatingChanged: (rating) => setState(() => _rating = rating),
              ),
            ),

            const SizedBox(height: 24),

            // Title field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Review Title (Optional)',
                hintText: 'e.g., Great product!',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLength: 100,
            ),

            const SizedBox(height: 16),

            // Comment field
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Your Review',
                hintText: 'Tell us about your experience...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 4,
              maxLength: 1000,
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
