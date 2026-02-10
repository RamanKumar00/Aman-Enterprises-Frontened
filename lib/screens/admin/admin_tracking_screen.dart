import 'package:aman_enterprises/models/courier_models.dart';
import 'package:aman_enterprises/services/courier_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminTrackingScreen extends StatefulWidget {
  final String? awb;
  final String? orderId;

  const AdminTrackingScreen({super.key, this.awb, this.orderId});

  @override
  State<AdminTrackingScreen> createState() => _AdminTrackingScreenState();
}

class _AdminTrackingScreenState extends State<AdminTrackingScreen> {
  final CourierService _courierService = CourierService();
  bool _isLoading = true;
  String? _errorMessage;
  TrackingData? _trackingData;
  Shipment? _shipment;

  @override
  void initState() {
    super.initState();
    _fetchTracking();
  }

  Future<void> _fetchTracking() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.awb != null) {
        _trackingData = await _courierService.trackShipment(widget.awb!);
      } else if (widget.orderId != null) {
        final result = await _courierService.trackByOrderId(widget.orderId!);
        _shipment = result['shipment'] as Shipment;
        _trackingData = result['tracking'] as TrackingData;
      } else {
        throw Exception("No AWB or Order ID provided");
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shipment Tracking")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text("Error: $_errorMessage"))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_trackingData == null) {
      return const Center(child: Text("No tracking data available"));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 20),
          if (_shipment != null) ...[
            _buildShipmentDetails(),
            const SizedBox(height: 20),
          ],
          const Text(
            "Tracking History",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _trackingData!.currentStatus;
    Color color = Colors.blue;
    if (status.toLowerCase().contains("delivered")) color = Colors.green;
    if (status.toLowerCase().contains("fail") || status.toLowerCase().contains("return")) color = Colors.red;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, size: 40, color: color),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (_trackingData!.estimatedDelivery != null)
                        Text(
                          "Est. Delivery: ${_formatDate(_trackingData!.estimatedDelivery!)}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_trackingData!.currentLocation != null) ...[
              const Divider(height: 30),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Current Location: ${_trackingData!.currentLocation!.toString()}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Shipment Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            _detailRow("Courier:", _shipment!.courierName),
            _detailRow("AWB:", _shipment!.awbNumber),
            _detailRow("Created:", _shipment!.createdAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(_shipment!.createdAt!) : "N/A"),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_trackingData!.history.isEmpty) {
      return const Text("No history available.");
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _trackingData!.history.length,
      itemBuilder: (context, index) {
        final item = _trackingData!.history[index];
        final isFirst = index == 0;
        final isLast = index == _trackingData!.history.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Column(
               children: [
                 Container(
                   width: 2,
                   height: 15,
                   color: isFirst ? Colors.transparent : Colors.grey,
                 ),
                 Container(
                   width: 12,
                   height: 12,
                   decoration: BoxDecoration(
                     color: isFirst ? Colors.blue : Colors.grey,
                     shape: BoxShape.circle,
                   ),
                 ),
                 Container(
                   width: 2,
                   height: isLast ? 0 : 50, // Adjust height based on content
                   color: Colors.grey,
                 ),
               ],
             ),
             const SizedBox(width: 12),
             Expanded(
               child: Padding(
                 padding: const EdgeInsets.only(bottom: 20.0),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       item.status,
                       style: TextStyle(
                         fontWeight: FontWeight.bold,
                         fontSize: 16,
                         color: isFirst ? Colors.black : Colors.grey[700],
                       ),
                     ),
                     Text(
                       item.location.isNotEmpty ? item.location : "Location not available",
                       style: const TextStyle(color: Colors.grey),
                     ),
                     Text(
                       DateFormat('dd MMM, hh:mm a').format(item.timestamp),
                       style: const TextStyle(fontSize: 12, color: Colors.grey),
                     ),
                     if (item.description.isNotEmpty && item.description != item.status)
                        Text(
                          item.description,
                          style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                   ],
                 ),
               ),
             ),
          ],
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
