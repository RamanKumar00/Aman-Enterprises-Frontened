import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/services/invoice_service.dart';
import 'package:aman_enterprises/screens/invoice_view_screen.dart';
import 'package:intl/intl.dart';

class AdminInvoicesScreen extends StatefulWidget {
  const AdminInvoicesScreen({super.key});

  @override
  State<AdminInvoicesScreen> createState() => _AdminInvoicesScreenState();
}

class _AdminInvoicesScreenState extends State<AdminInvoicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _invoices = [];
  Map<String, dynamic>? _gstSummary;
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;
  final TextEditingController _searchController = TextEditingController();
  String _selectedPeriod = 'monthly';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchInvoices();
    _fetchGSTSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchInvoices({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _page = 1;
      });
    }

    final response = await InvoiceService.getAllInvoicesAdmin(
      page: _page,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success) {
          if (loadMore) {
            _invoices.addAll(response.data?['invoices'] ?? []);
          } else {
            _invoices = response.data?['invoices'] ?? [];
          }
          final pagination = response.data?['pagination'];
          _hasMore = pagination != null && pagination['currentPage'] < pagination['totalPages'];
        }
      });
    }
  }

  Future<void> _fetchGSTSummary() async {
    final response = await InvoiceService.getGSTSummary(period: _selectedPeriod);
    if (mounted && response.success) {
      setState(() {
        _gstSummary = response.data;
      });
    }
  }

  Future<void> _exportInvoices() async {
    final response = await InvoiceService.exportInvoices();
    if (mounted) {
      if (response.success) {
        final count = response.data?['count'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported $count invoices'),
            backgroundColor: Colors.green,
          ),
        );
        // In a real app, you would download/save the CSV file here
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Invoices & GST'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primaryGreen),
            onPressed: _exportInvoices,
            tooltip: 'Export Invoices',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primaryGreen,
          tabs: const [
            Tab(text: 'All Invoices'),
            Tab(text: 'GST Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInvoicesTab(),
          _buildGSTReportsTab(),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab() {
    return Column(
      children: [
        // Search Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by invoice #, order #, customer...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textLight),
                      onPressed: () {
                        _searchController.clear();
                        _fetchInvoices();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.backgroundCream,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (_) => _fetchInvoices(),
          ),
        ),

        // Invoices List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
              : _invoices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No invoices found', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchInvoices,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _invoices.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _invoices.length) {
                            return Center(
                              child: TextButton(
                                onPressed: () {
                                  _page++;
                                  _fetchInvoices(loadMore: true);
                                },
                                child: const Text('Load More'),
                              ),
                            );
                          }
                          return _buildInvoiceCard(_invoices[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final invoiceNumber = invoice['invoiceNumber'] ?? '';
    final paymentStatus = invoice['paymentInfo']?['status'] ?? 'Pending';
    final customer = invoice['customerDetails'] as Map<String, dynamic>?;
    final pricing = invoice['pricing'] as Map<String, dynamic>?;
    final order = invoice['order'] as Map<String, dynamic>?;
    final invoiceDate = DateTime.tryParse(invoice['invoiceDate'] ?? '') ?? DateTime.now();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InvoiceViewScreen(
              orderId: order?['_id'] ?? invoice['order'] ?? '',
              invoiceNumber: invoiceNumber,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withAlpha(26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long, color: AppColors.primaryGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoiceNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(invoiceDate),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                _buildPaymentBadge(paymentStatus),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Customer & Order Info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        customer?['name'] ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      Text(
                        customer?['phone'] ?? '',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        order?['trackingId'] ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      Text(
                        order?['orderStatus'] ?? '',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Amount Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAmountItem('Subtotal', pricing?['subtotal'] ?? 0),
                  _buildAmountItem('Tax', pricing?['totalTax'] ?? 0),
                  _buildAmountItem('Total', pricing?['grandTotal'] ?? 0, isTotal: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = Colors.green;
        break;
      case 'failed':
        color = Colors.red;
        break;
      case 'refunded':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildAmountItem(String label, dynamic amount, {bool isTotal = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${(amount ?? 0).toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? AppColors.primaryGreen : null,
          ),
        ),
      ],
    );
  }

  Widget _buildGSTReportsTab() {
    return RefreshIndicator(
      onRefresh: _fetchGSTSummary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: ['monthly', 'yearly'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedPeriod = period);
                        _fetchGSTSummary();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected ? [
                            BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 4),
                          ] : null,
                        ),
                        child: Text(
                          period == 'monthly' ? 'This Month' : 'This Year',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primaryGreen : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // GST Summary
            if (_gstSummary != null) ...[
              // Period Label
              Text(
                'GST Summary',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (_gstSummary!['period'] != null)
                Text(
                  '${DateFormat('MMM dd, yyyy').format(DateTime.parse(_gstSummary!['period']['start']))} - ${DateFormat('MMM dd, yyyy').format(DateTime.parse(_gstSummary!['period']['end']))}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),

              const SizedBox(height: 16),

              // Summary Cards
              _buildGSTSummaryCards(_gstSummary!['summary'] ?? {}),

              const SizedBox(height: 24),

              // Tax Breakdown
              _buildTaxBreakdown(_gstSummary!['summary'] ?? {}),

              // Monthly Breakdown (for yearly view)
              if (_selectedPeriod == 'yearly' && (_gstSummary!['monthlyBreakdown'] as List?)?.isNotEmpty == true) ...[
                const SizedBox(height: 24),
                const Text('Monthly Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildMonthlyBreakdown(_gstSummary!['monthlyBreakdown']),
              ],
            ] else
              const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
          ],
        ),
      ),
    );
  }

  Widget _buildGSTSummaryCards(Map<String, dynamic> summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSummaryCard('Total Invoices', '${summary['totalInvoices'] ?? 0}', Colors.blue, Icons.receipt)),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard('Total Revenue', '₹${(summary['totalRevenue'] ?? 0).toStringAsFixed(0)}', Colors.green, Icons.payments)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSummaryCard('Taxable Amount', '₹${(summary['totalTaxableAmount'] ?? 0).toStringAsFixed(0)}', Colors.orange, Icons.account_balance)),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard('Total Tax', '₹${(summary['totalTax'] ?? 0).toStringAsFixed(0)}', Colors.purple, Icons.percent)),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxBreakdown(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tax Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _buildTaxRow('CGST', summary['totalCGST'] ?? 0, Colors.blue),
          _buildTaxRow('SGST', summary['totalSGST'] ?? 0, Colors.green),
          _buildTaxRow('IGST', summary['totalIGST'] ?? 0, Colors.orange),
          const Divider(),
          _buildTaxRow('Total Tax', summary['totalTax'] ?? 0, Colors.purple, isBold: true),
        ],
      ),
    );
  }

  Widget _buildTaxRow(String label, dynamic amount, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
          Text(
            '₹${(amount ?? 0).toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? color : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdown(List<dynamic> breakdown) {
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: breakdown.map((item) {
          final monthNum = item['_id'] ?? 1;
          final monthName = months[monthNum];
          
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(monthName, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item['invoiceCount']} invoices', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${(item['totalRevenue'] ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tax: ₹${((item['totalCGST'] ?? 0) + (item['totalSGST'] ?? 0) + (item['totalIGST'] ?? 0)).toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
