import 'package:aman_enterprises/services/courier_service.dart';
import 'package:flutter/material.dart';

class CourierAnalyticsScreen extends StatefulWidget {
  const CourierAnalyticsScreen({super.key});

  @override
  State<CourierAnalyticsScreen> createState() => _CourierAnalyticsScreenState();
}

class _CourierAnalyticsScreenState extends State<CourierAnalyticsScreen> {
  final CourierService _courierService = CourierService();
  bool _isLoading = true;
  String? _errorMessage;
  List<CourierPerformanceStats> _stats = [];

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _courierService.getPerformanceStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
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
      appBar: AppBar(title: const Text("Courier Performance")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text("Error: $_errorMessage"))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_stats.isEmpty) {
      return const Center(child: Text("No performance data available"));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 24),
          const Text(
            "Courier Comparison",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildComparisonList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    int total = _stats.fold(0, (sum, item) => sum + item.totalShipments);
    int success = _stats.fold(0, (sum, item) => sum + item.successfulDeliveries);
    int rto = _stats.fold(0, (sum, item) => sum + item.rtoCount);
    
    // Average delivery days (weighted)
    double avgDays = 0;
    if (total > 0) {
      double totalDaysPoints = _stats.fold(0, (sum, item) => sum + (item.avgDeliveryDays * item.totalShipments));
      avgDays = totalDaysPoints / total;
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _statCard("Total Shipments", total.toString(), Colors.blue),
        _statCard("Success Rate", total > 0 ? "${((success/total)*100).toStringAsFixed(1)}%" : "0%", Colors.green),
        _statCard("RTO Rate", total > 0 ? "${((rto/total)*100).toStringAsFixed(1)}%" : "0%", Colors.red),
        _statCard("Avg. Delivery", "${avgDays.toStringAsFixed(1)} Days", Colors.orange),
      ],
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _stats.length,
      itemBuilder: (context, index) {
        final stat = _stats[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            title: Text(stat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("On-Time: ${stat.onTimeRate.toStringAsFixed(1)}%"),
                Text("Avg: ${stat.avgDeliveryDays} days"),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _row("Total Shipments", stat.totalShipments.toString()),
                    _row("Successful Deliveries", stat.successfulDeliveries.toString()),
                    _row("Returned (RTO)", stat.rtoCount.toString(), isRed: stat.rtoCount > 0),
                    const Divider(),
                    _row("Success Rate", "${stat.deliverySuccessRate.toStringAsFixed(1)}%"),
                    _row("RTO Rate", "${stat.rtoRate.toStringAsFixed(1)}%", isRed: true),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value, {bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: isRed ? Colors.red : null)),
        ],
      ),
    );
  }
}
