import 'package:flutter/material.dart';
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/models/order_model.dart';
import 'package:aman_enterprises/screens/admin/courier_selection_screen.dart';
import 'package:aman_enterprises/screens/admin/admin_tracking_screen.dart';
import 'package:aman_enterprises/screens/admin/courier_analytics_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  
  final List<String> _statuses = [
    "Placed", "Confirmed", "Packed", "Out for Delivery", "Delivered", "Cancelled"
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    final token = UserService().authToken;
    if (token == null) return;

    final response = await ApiService.getAllOrdersAdmin(token);
    
    if (mounted) {
      if (response.success && response.data != null) {
        setState(() {
          _orders = response.data!['orders'] ?? []; // Adjust based on controller response structure
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        // Show error
      }
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    final token = UserService().authToken;
    if (token == null) return;

    final response = await ApiService.updateOrderStatus(token, orderId, newStatus);
    
    if (mounted) {
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order Status Updated to $newStatus')),
        );
        _fetchOrders(); // Refresh
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.message}')),
        );
      }
    }
  }


  void _shipOrder(dynamic orderData) {
    try {
      final order = OrderModel.fromJson(orderData);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourierSelectionScreen(order: order),
        ),
      ).then((val) {
        if (val == true) _fetchOrders();
      });
    } catch (e) {
      debugPrint('Error parsing order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open shipping: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Courier Performance',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CourierAnalyticsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _orders.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final order = _orders[index];
                final String status = order['status'] ?? 'Unknown';
                final String orderId = order['_id'] ?? '';
                final product = order['product'] ?? {};
                final details = order['userDetails'] ?? {};
                
                // Color coding
                Color statusColor = Colors.blue;
                if (status == 'Delivered') statusColor = Colors.green;
                if (status == 'Cancelled') statusColor = Colors.red;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    title: Text('Order: ...${orderId.substring(orderId.length - 6)}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer: ${details['name'] ?? 'Unknown'} (${details['phone'] ?? ''})'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('Status: '),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(50),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                status, 
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Product Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: product['image'] != null 
                                  ? Image.network(product['image'], width: 40, height: 40, fit: BoxFit.cover)
                                  : null,
                              title: Text(product['name'] ?? 'Product Unavailble'),
                              subtitle: Text('Qty: ${order['quantity']} | Price: ₹${product['price']}'),
                            ),
                            const Divider(),
                            const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Wrap(
                              spacing: 8,
                              children: _statuses.map((s) {
                                return ActionChip(
                                  label: Text(s),
                                  backgroundColor: status == s ? AppColors.primaryGreen : null,
                                  labelStyle: TextStyle(color: status == s ? Colors.white : Colors.black),
                                  onPressed: () {
                                    if (status != s) {
                                      _updateStatus(orderId, s);
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            if (status == 'Packed')
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.local_shipping),
                                  label: const Text('Assign Delivery Partner'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () => _shipOrder(order),
                                ),
                              ),
                            if (status == 'Shipped' || status == 'Delivered' || status == 'Out for Delivery')
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.map),
                                  label: const Text('Track Shipment'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.purple,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onPressed: () {
                                     final shippingInfo = order['shippingInfo'];
                                     String? awb = shippingInfo?['awbNumber'];
                                     String? orderId = order['_id'];
                                     
                                     if (awb != null || orderId != null) {
                                       Navigator.push(
                                         context,
                                         MaterialPageRoute(
                                           builder: (_) => AdminTrackingScreen(
                                             awb: awb,
                                             orderId: orderId, // Fallback if AWB is null but order exists
                                           ),
                                         ),
                                       );
                                     } else {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                         const SnackBar(content: Text('Tracking info not available')),
                                       );
                                     }
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
