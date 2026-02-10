import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/services/invoice_service.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class InvoiceViewScreen extends StatefulWidget {
  final String orderId;
  final String? invoiceNumber;

  const InvoiceViewScreen({
    super.key,
    required this.orderId,
    this.invoiceNumber,
  });

  @override
  State<InvoiceViewScreen> createState() => _InvoiceViewScreenState();
}

class _InvoiceViewScreenState extends State<InvoiceViewScreen> {
  Invoice? _invoice;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInvoice();
  }

  Future<void> _fetchInvoice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // First try to get existing invoice
    var response = await InvoiceService.getInvoiceByOrder(widget.orderId);

    // If not found, generate one
    if (!response.success || response.data?['invoice'] == null) {
      response = await InvoiceService.generateInvoice(widget.orderId);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.success && response.data?['invoice'] != null) {
          _invoice = Invoice.fromJson(response.data!['invoice']);
        } else {
          _error = response.message;
        }
      });
    }
  }

  void _shareInvoice() {
    if (_invoice == null) return;
    
    final text = '''
Invoice: ${_invoice!.invoiceNumber}
Date: ${DateFormat('dd MMM yyyy').format(_invoice!.invoiceDate)}
Order: ${_invoice!.orderTrackingId}

${_invoice!.companyDetails.name}
GSTIN: ${_invoice!.companyDetails.gstin}

Customer: ${_invoice!.customerDetails.name}
Address: ${_invoice!.customerDetails.address}, ${_invoice!.customerDetails.city}

Items:
${_invoice!.items.map((item) => '- ${item.name} x${item.quantity} = ₹${item.totalAmount.toStringAsFixed(2)}').join('\n')}

Subtotal: ₹${_invoice!.pricing.subtotal.toStringAsFixed(2)}
${_invoice!.gstDetails.isIntraState ? 'CGST: ₹${_invoice!.pricing.cgstTotal.toStringAsFixed(2)}\nSGST: ₹${_invoice!.pricing.sgstTotal.toStringAsFixed(2)}' : 'IGST: ₹${_invoice!.pricing.igstTotal.toStringAsFixed(2)}'}
Grand Total: ₹${_invoice!.pricing.grandTotal.toStringAsFixed(2)}
''';

    Share.share(text, subject: 'Invoice ${_invoice!.invoiceNumber}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: Text(_invoice?.invoiceNumber ?? 'Invoice'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_invoice != null) ...[
            IconButton(
              icon: const Icon(Icons.share_outlined, color: AppColors.primaryGreen),
              onPressed: _shareInvoice,
              tooltip: 'Share Invoice',
            ),
            IconButton(
              icon: const Icon(Icons.download_outlined, color: AppColors.primaryGreen),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF Download coming soon!'))
                );
              },
              tooltip: 'Download PDF',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchInvoice,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildInvoiceContent(),
    );
  }

  Widget _buildInvoiceContent() {
    if (_invoice == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const Divider(),
            
            // Company & Customer Details
            _buildPartyDetails(),
            const Divider(),
            
            // Items Table
            _buildItemsTable(),
            const Divider(),
            
            // Tax Summary
            _buildTaxSummary(),
            const Divider(),
            
            // Totals
            _buildTotals(),
            
            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withAlpha(13),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TAX INVOICE',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _invoice!.invoiceNumber,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _invoice!.paymentInfo.status == 'Paid' 
                      ? Colors.green.shade100 
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _invoice!.paymentInfo.status,
                  style: TextStyle(
                    color: _invoice!.paymentInfo.status == 'Paid' 
                        ? Colors.green.shade800 
                        : Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date and Order ID
          Row(
            children: [
              _buildInfoChip(
                Icons.calendar_today_outlined,
                DateFormat('dd MMM yyyy').format(_invoice!.invoiceDate),
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                Icons.receipt_long_outlined,
                'Order: ${_invoice!.orderTrackingId}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryGreen),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyDetails() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FROM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _invoice!.companyDetails.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_invoice!.companyDetails.address},\n${_invoice!.companyDetails.city}, ${_invoice!.companyDetails.state} - ${_invoice!.companyDetails.pincode}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                if (_invoice!.companyDetails.gstin.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'GSTIN: ${_invoice!.companyDetails.gstin}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Buyer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BILL TO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _invoice!.customerDetails.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_invoice!.customerDetails.address},\n${_invoice!.customerDetails.city}, ${_invoice!.customerDetails.state} - ${_invoice!.customerDetails.pincode}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phone: ${_invoice!.customerDetails.phone}',
                  style: const TextStyle(fontSize: 11),
                ),
                if (_invoice!.customerDetails.gstin?.isNotEmpty ?? false) ...[
                  Text(
                    'GSTIN: ${_invoice!.customerDetails.gstin}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(flex: 4, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
                Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
              ],
            ),
          ),
          // Table Rows
          ..._invoice!.items.asMap().entries.map((entry) {
            final item = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                        if (item.hsn?.isNotEmpty ?? false)
                          Text(
                            'HSN: ${item.hsn}',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${item.unitPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${item.taxableAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTaxSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TAX BREAKDOWN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (_invoice!.gstDetails.isIntraState) ...[
                  _buildTaxItem('CGST (${_invoice!.items.isNotEmpty ? _invoice!.items.first.cgstRate : 0}%)', _invoice!.pricing.cgstTotal),
                  Container(width: 1, height: 30, color: Colors.blue.shade200),
                  _buildTaxItem('SGST (${_invoice!.items.isNotEmpty ? _invoice!.items.first.sgstRate : 0}%)', _invoice!.pricing.sgstTotal),
                ] else ...[
                  _buildTaxItem('IGST (${_invoice!.items.isNotEmpty ? _invoice!.items.first.igstRate : 0}%)', _invoice!.pricing.igstTotal),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Place of Supply: ${_invoice!.gstDetails.placeOfSupply}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                _invoice!.gstDetails.isIntraState ? 'Intra-State Supply' : 'Inter-State Supply',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaxItem(String label, double amount) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
      ],
    );
  }

  Widget _buildTotals() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', _invoice!.pricing.subtotal),
          if (_invoice!.pricing.totalDiscount > 0)
            _buildTotalRow('Discount', -_invoice!.pricing.totalDiscount, isDiscount: true),
          _buildTotalRow('Taxable Amount', _invoice!.pricing.taxableAmount),
          if (_invoice!.gstDetails.isIntraState) ...[
            _buildTotalRow('CGST', _invoice!.pricing.cgstTotal),
            _buildTotalRow('SGST', _invoice!.pricing.sgstTotal),
          ] else ...[
            _buildTotalRow('IGST', _invoice!.pricing.igstTotal),
          ],
          if (_invoice!.pricing.shippingCharges > 0)
            _buildTotalRow('Shipping', _invoice!.pricing.shippingCharges),
          if (_invoice!.pricing.roundOff != 0)
            _buildTotalRow('Round Off', _invoice!.pricing.roundOff),
          const Divider(thickness: 2),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'GRAND TOTAL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${_invoice!.pricing.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          Text(
            '${isDiscount ? '-' : ''}₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              color: isDiscount ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method: ${_invoice!.paymentInfo.method}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Text(
            'Terms & Conditions:',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            'Goods once sold will not be taken back. Subject to local jurisdiction.',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Thank you for shopping with ${_invoice!.companyDetails.name}!',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
