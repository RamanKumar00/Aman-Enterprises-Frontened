import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/services/review_service.dart';
import 'package:aman_enterprises/widgets/review_widgets.dart';
import 'package:intl/intl.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _reviews = [];
  Map<String, int> _statusCounts = {};
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  String _selectedStatus = 'all';
  int _page = 1;
  bool _hasMore = true;

  final List<String> _statusFilters = ['all', 'approved', 'pending', 'rejected', 'spam'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchReviews();
    _fetchAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchReviews({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _page = 1;
      });
    }

    final response = await ReviewService.getAllReviewsAdmin(
      page: _page,
      status: _selectedStatus == 'all' ? null : _selectedStatus,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success) {
          if (loadMore) {
            _reviews.addAll(response.data?['reviews'] ?? []);
          } else {
            _reviews = response.data?['reviews'] ?? [];
          }
          _statusCounts = Map<String, int>.from(response.data?['statusCounts'] ?? {});
          final pagination = response.data?['pagination'];
          _hasMore = pagination != null && pagination['currentPage'] < pagination['totalPages'];
        }
      });
    }
  }

  Future<void> _fetchAnalytics() async {
    final response = await ReviewService.getReviewAnalytics();
    if (mounted && response.success) {
      setState(() {
        _analytics = response.data?['analytics'];
      });
    }
  }

  Future<void> _moderateReview(String reviewId, String status) async {
    final response = await ReviewService.moderateReview(
      reviewId: reviewId,
      status: status,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.success ? 'Review $status successfully' : response.message),
          backgroundColor: response.success ? Colors.green : Colors.red,
        ),
      );

      if (response.success) {
        _fetchReviews();
        _fetchAnalytics();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Manage Reviews'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primaryGreen,
          tabs: const [
            Tab(text: 'All Reviews'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReviewsTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Column(
      children: [
        // Status Filter
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((status) {
                final isSelected = _selectedStatus == status;
                final count = status == 'all' 
                    ? _statusCounts.values.fold(0, (a, b) => a + b)
                    : _statusCounts[status] ?? 0;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${status.capitalize()} ($count)'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = status;
                      });
                      _fetchReviews();
                    },
                    selectedColor: AppColors.primaryGreen.withAlpha(51),
                    checkmarkColor: AppColors.primaryGreen,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Reviews List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
              : _reviews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No reviews found', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchReviews,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _reviews.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _reviews.length) {
                            // Load more button
                            return Center(
                              child: TextButton(
                                onPressed: () {
                                  _page++;
                                  _fetchReviews(loadMore: true);
                                },
                                child: const Text('Load More'),
                              ),
                            );
                          }
                          return _buildAdminReviewCard(_reviews[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildAdminReviewCard(Map<String, dynamic> review) {
    final status = review['status'] ?? 'pending';
    final user = review['user'] as Map<String, dynamic>?;
    final product = review['product'] as Map<String, dynamic>?;
    final rating = (review['rating'] ?? 0).toDouble();
    final createdAt = DateTime.tryParse(review['createdAt'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'approved' ? Colors.green.shade200
              : status == 'rejected' ? Colors.red.shade200
              : status == 'spam' ? Colors.orange.shade200
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryGreen.withAlpha(51),
                child: Text(
                  (user?['shopName'] ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?['shopName'] ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      user?['phone'] ?? '',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),

          const SizedBox(height: 12),

          // Product Info
          if (product != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product['productName'] ?? 'Product',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Rating and Date
          Row(
            children: [
              StarRating(rating: rating, size: 16),
              const Spacer(),
              Text(
                DateFormat('MMM dd, yyyy HH:mm').format(createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Review Title
          if (review['title']?.isNotEmpty ?? false)
            Text(
              review['title'],
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),

          // Review Comment
          const SizedBox(height: 4),
          Text(
            review['comment'] ?? '',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status != 'approved')
                _buildActionButton(
                  'Approve',
                  Icons.check_circle_outline,
                  Colors.green,
                  () => _moderateReview(review['_id'], 'approved'),
                ),
              if (status != 'rejected')
                _buildActionButton(
                  'Reject',
                  Icons.cancel_outlined,
                  Colors.red,
                  () => _moderateReview(review['_id'], 'rejected'),
                ),
              if (status != 'spam')
                _buildActionButton(
                  'Spam',
                  Icons.report_outlined,
                  Colors.orange,
                  () => _moderateReview(review['_id'], 'spam'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'spam':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.capitalize(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (_analytics == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    return RefreshIndicator(
      onRefresh: _fetchAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(child: _buildStatCard('Total', _analytics!['totalReviews'], Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Approved', _analytics!['approvedReviews'], Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Pending', _analytics!['pendingReviews'], Colors.orange)),
              ],
            ),

            const SizedBox(height: 24),

            // Average Rating
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Overall Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        (_analytics!['overallAvgRating'] ?? 0).toStringAsFixed(1),
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                      ),
                    ],
                  ),
                  const Spacer(),
                  StarRating(rating: (_analytics!['overallAvgRating'] ?? 0).toDouble(), size: 28),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Rating Distribution
            const Text('Rating Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [5, 4, 3, 2, 1].map((star) {
                  final distribution = _analytics!['ratingDistribution'] as Map<String, dynamic>? ?? {};
                  final count = distribution[star.toString()] ?? 0;
                  final total = _analytics!['totalReviews'] ?? 1;
                  final percentage = total > 0 ? count / total : 0.0;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(width: 20, child: Text('$star', style: const TextStyle(fontWeight: FontWeight.bold))),
                        const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                star >= 4 ? Colors.green : star == 3 ? Colors.amber : Colors.red,
                              ),
                              minHeight: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 40,
                          child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Top Rated Products
            const Text('Top Rated Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...(_analytics!['topRatedProducts'] as List? ?? []).take(5).map((product) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        product['productName'] ?? 'Product',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StarRating(rating: (product['avgRating'] ?? 0).toDouble(), size: 14),
                    const SizedBox(width: 8),
                    Text(
                      '(${product['totalReviews']})',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${value ?? 0}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
