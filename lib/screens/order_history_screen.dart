import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/screens/order_tracking_screen.dart';
import 'package:aman_enterprises/screens/invoice_view_screen.dart';
import 'package:aman_enterprises/services/order_service.dart';
import 'package:aman_enterprises/models/order_model.dart';
import 'package:aman_enterprises/widgets/shimmer_widgets.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ordersFuture = _orderService.getMyOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _orderService.getMyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text('My Orders', style: AppTextStyles.headingSmall),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primaryGreen,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Ongoing'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) => const OrderItemShimmer(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  TextButton(
                    onPressed: _refreshOrders,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
             return _buildEmptyState();
          }

          final allOrders = snapshot.data!;
          final ongoingOrders = allOrders.where((o) => ['Placed', 'Confirmed', 'Packed', 'Out for Delivery'].contains(o.status)).toList();
          final historyOrders = allOrders.where((o) => ['Delivered', 'Cancelled'].contains(o.status)).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(ongoingOrders, isOngoing: true),
              _buildOrdersList(historyOrders, isOngoing: false),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
     return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: AppColors.textLight.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: AppTextStyles.headingSmall,
            ),
             const SizedBox(height: 8),
             TextButton(
               onPressed: _refreshOrders, 
               child: const Text("Refresh")
             )
          ],
        ),
      );
  }

  Widget _buildOrdersList(List<OrderModel> orders, {required bool isOngoing}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOngoing ? Icons.shopping_bag_outlined : Icons.history_edu_outlined,
              size: 80,
              color: AppColors.textLight.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              isOngoing ? 'No active orders' : 'No past orders',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _refreshOrders, child: const Text("Refresh")),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(orders[index], isOngoing);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, bool isOngoing) {
    final statusColor = _getStatusColor(order.status);
    final dateStr = "${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}";
    final timeStr = "${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderTrackingScreen(orderId: order.id), // Use _id for fetching details
          ),
        ).then((_) => _refreshOrders());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            // Order Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withAlpha(26),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.trackingId}',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '$dateStr at $timeStr',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                    ),
                    child: Text(
                      order.status,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Order Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.items.length} items',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                      ),
                      Text(
                        '₹${order.totalPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (isOngoing)
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderTrackingScreen(
                                  orderId: order.id,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryGreen),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                            ),
                          ),
                          child: Text(
                            'Track Order',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else ...[
                        if (order.status != 'Cancelled')
                          OutlinedButton(
                            onPressed: () {
                              // Reorder Logic - Add items to cart
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reorder feature coming soon!')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primaryGreen),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                              ),
                            ),
                            child: Text(
                              'Reorder',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        // Invoice button for delivered orders
                        if (order.status == 'Delivered')
                          IconButton(
                            icon: const Icon(Icons.receipt_long, size: 20, color: AppColors.primaryGreen),
                            tooltip: 'View Invoice',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InvoiceViewScreen(orderId: order.id),
                                ),
                              );
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onPressed: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderTrackingScreen(
                                  orderId: order.id,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Placed':
      case 'Confirmed':
      case 'Packed':
      case 'Out for Delivery':
        return Colors.orange;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
