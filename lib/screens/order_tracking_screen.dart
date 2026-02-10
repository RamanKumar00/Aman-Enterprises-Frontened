import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/services/order_service.dart';
import 'package:aman_enterprises/models/order_model.dart';
import 'package:aman_enterprises/services/courier_service.dart';
import 'package:aman_enterprises/models/courier_models.dart';
import 'package:intl/intl.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final CourierService _courierService = CourierService();
  OrderModel? _order;
  TrackingData? _courierTracking;
  bool _isLoading = true;
  String? _error;
  Timer? _pollTimer;

  // Animation for map
  late AnimationController _mapController;
  
  // Dynamic State
  int _currentStep = 0;
  String _statusText = "Loading...";
  Color _statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _mapController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30), 
    );
    _mapController.addListener(_updateMapState);

    _fetchOrderDetails();
    // Poll every 10 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) _fetchOrderDetails(silent: true);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrderDetails({bool silent = false}) async {
    if (!silent) {
      setState(() { _isLoading = true; _error = null; });
    }

    try {
      final order = await _orderService.getOrderDetails(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
          _updateStatusState();
        });
        
        // Fetch courier tracking if applicable
        if (order.status == 'Shipped' || order.status == 'Out for Delivery' || order.status == 'Delivered') {
           try {
             final trackingResult = await _courierService.trackByOrderId(widget.orderId);
             if (mounted) {
               setState(() {
                 _courierTracking = trackingResult['tracking'] as TrackingData?;
               });
             }
           } catch (_) {}
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _updateStatusState() {
    if (_order == null) return;

    final status = _order!.status;
    
    // Map status to step index
    switch (status) {
      case 'Placed': _currentStep = 0; _statusText = "Order Placed"; _statusColor = Colors.blue; break;
      case 'Confirmed': _currentStep = 1; _statusText = "Order Confirmed"; _statusColor = Colors.blue; break;
      case 'Packed': _currentStep = 2; _statusText = "Order Packed"; _statusColor = Colors.orange; break;
      case 'Out for Delivery': _currentStep = 3; _statusText = "Out for Delivery"; _statusColor = Colors.orange; break;
      case 'Delivered': _currentStep = 4; _statusText = "Delivered"; _statusColor = AppColors.primaryGreen; break;
      case 'Cancelled': _currentStep = -1; _statusText = "Cancelled"; _statusColor = Colors.red; break;
      default: _currentStep = 0;
    }

    if (status == 'Out for Delivery' && !_mapController.isAnimating && _mapController.value < 1.0) {
      _mapController.forward();
    } else if (status == 'Delivered') {
      _mapController.value = 1.0;
    }
  }

  void _updateMapState() {
    setState(() {}); // Rebuild for map animation
  }
  
  Future<void> _cancelOrder() async {
    try {
       await _orderService.cancelOrder(widget.orderId);
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Cancelled")));
       _fetchOrderDetails();
    } catch (e) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to cancel: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)));
    }

    if (_error != null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $_error')));
    }

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
        title: Text('Track Order', style: AppTextStyles.headingSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textMedium),
            onPressed: () => _fetchOrderDetails(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildOrderHeader(),

            if (_order?.status == 'Out for Delivery') 
               _buildMapSection(),

            if (_order?.status == 'Cancelled')
               Padding(
                 padding: const EdgeInsets.all(32),
                 child: Text("This order has been cancelled.", style: AppTextStyles.headingSmall.copyWith(color: Colors.red)),
               ),

            _buildTimeline(),
            
            if (_order?.status != 'Cancelled' && _currentStep >= 2)
              _buildDeliveryPartner(),

            if (_order?.status != 'Cancelled' &&  _currentStep >= 3) ...[
                _buildTipSection(),
                _buildDeliveryInstructions(),
            ],

            _buildOrderItems(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: _order?.status != 'Cancelled' && _order?.status != 'Delivered' ? _buildBottomBar() : null,
    );
  }

  // ... [Keep existing widget build methods, just updating data binding] ...

  Widget _buildOrderHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withAlpha(26),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.primaryGreen, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${_order?.trackingId ?? ""}', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                Text(_statusText, style: AppTextStyles.bodySmall.copyWith(color: _statusColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor.withAlpha(26),
              borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            ),
            child: Text(
               _order?.status == 'Delivered' ? 'Completed' : (_order?.status == 'Cancelled' ? 'Cancelled' : 'Live'),
               style: AppTextStyles.bodySmall.copyWith(color: _statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Simplified Map for brevity, using same logic as before but controlled by backend status
  Widget _buildMapSection() {
     return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: Text("Live Map Tracking Active\nDriver coming to ${_order?.shippingAddress?.details ?? 'you'}", textAlign: TextAlign.center)),
     );
  }

  Widget _buildTimeline() {
    // Combine internal steps with courier tracking if available
    if (_courierTracking != null && _courierTracking!.history.isNotEmpty) {
       return Container(
         margin: const EdgeInsets.symmetric(horizontal: 16),
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text('Detailed Delivery Tracking', style: AppTextStyles.headingSmall),
             const SizedBox(height: 16),
             ..._courierTracking!.history.map((history) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Column(
                         children: [
                           Icon(Icons.local_shipping, color: AppColors.primaryGreen, size: 20),
                           Container(height: 20, width: 2, color: Colors.grey[300]),
                         ],
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(history.status, style: const TextStyle(fontWeight: FontWeight.bold)),
                             Text(history.location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                             Text(DateFormat('dd MMM, hh:mm a').format(history.timestamp), style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                           ],
                         ),
                       )
                    ],
                  ),
                );
             }),
           ],
         ),
       );
    }

    final steps = [
      {'title': 'Order Placed', 'time': _getTimeForStatus('Placed')},
      {'title': 'Order Confirmed', 'time': _getTimeForStatus('Confirmed')},
      {'title': 'Packed', 'time': _getTimeForStatus('Packed')},
      {'title': 'Out for Delivery', 'time': _getTimeForStatus('Out for Delivery')},
      {'title': 'Delivered', 'time': _getTimeForStatus('Delivered')},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Status', style: AppTextStyles.headingSmall),
          const SizedBox(height: 16),
          ...List.generate(steps.length, (index) {
             final isCompleted = index <= _currentStep;
             // Don't show future steps if cancelled
             if (_currentStep == -1 && index > 0) return const SizedBox.shrink(); // Only show placed if cancelled? Or show cancelled step.
             
             return Row(
               children: [
                 Column(
                   children: [
                     Icon(
                       isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, 
                       color: isCompleted ? AppColors.primaryGreen : Colors.grey
                     ),
                     if (index < steps.length - 1)
                       Container(height: 30, width: 2, color: isCompleted && index < _currentStep ? AppColors.primaryGreen : Colors.grey[300]),
                   ],
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(steps[index]['title']!, style: TextStyle(fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal)),
                       if(steps[index]['time'] != null) Text(steps[index]['time']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                     ],
                   ),
                 )
               ],
             );
          })
        ],
      ),
    );
  }
  
  String? _getTimeForStatus(String status) {
    // Ideally find in _order.timeline
    if (_order?.timeline == null) return null;
    try {
      final item = _order!.timeline!.firstWhere((e) => e.status == status);
      return "${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return null;
    }
  }

  Widget _buildDeliveryPartner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: const [
           CircleAvatar(backgroundColor: AppColors.primaryGreen, child: Text("D", style: TextStyle(color: Colors.white))),
           SizedBox(width: 12),
           Expanded(child: Text("Delivery Partner Assigned", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTipSection() => Container(); // Simplified for now
  Widget _buildDeliveryInstructions() => Container(); // Simplified

  Widget _buildOrderItems() {
    if (_order == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text("${_order!.items.length} Items", style: AppTextStyles.headingSmall),
           const SizedBox(height: 16),
           ..._order!.items.map((item) => Padding(
             padding: const EdgeInsets.only(bottom: 12),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text("${item.quantity} x ${item.name}"),
                 Text("₹${(item.price * item.quantity).toStringAsFixed(0)}"),
               ],
             ),
           )),
           const Divider(),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               const Text("Total", style: TextStyle(fontWeight: FontWeight.bold)),
               Text("₹${_order!.totalPrice.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryGreen)),
             ],
           )
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _order?.status == 'Packed' || _order?.status == 'Placed' || _order?.status == 'Confirmed' 
              ? () => _cancelOrder() 
              : null, // Disable if out for delivery
          style: OutlinedButton.styleFrom(
             side: const BorderSide(color: Colors.red),
             padding: const EdgeInsets.symmetric(vertical: 16)
          ),
          child: const Text("Cancel Order", style: TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
