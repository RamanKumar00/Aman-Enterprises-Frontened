import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/services/cart_service.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:aman_enterprises/services/order_service.dart'; 
import 'package:aman_enterprises/screens/location/location_screen.dart';
import 'package:aman_enterprises/screens/order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  final UserService _userService = UserService();
  final OrderService _orderService = OrderService();
  
  bool _isLoading = false;
  
  // Selected Payment Method
  String _paymentMethod = "COD"; // COD, BankTransfer, QR

  @override
  void initState() {
    super.initState();
    _userService.loadUser();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleCheckout() async {
    if (_userService.address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a delivery address')));
      return;
    }

    setState(() => _isLoading = true);
    
    // Use Final Price (Discounted)
    // final totalAmount = _cartService.finalPrice + 40; // Variable not used in remaining logic

    if (_paymentMethod == "QR") {
       _showQRCodeDialog();
       setState(() => _isLoading = false);
    } else if (_paymentMethod == "BankTransfer") {
       _showBankDetailsDialog();
       setState(() => _isLoading = false);
    } else {
       // COD
       _placeOrder();
    }
  }

  void _showQRCodeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Scan & Pay"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: 200,
              color: Colors.white,
              child: const Center(
                child: Icon(Icons.qr_code_scanner_rounded, size: 150, color: Colors.black),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Scan this QR code using any UPI app", textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text("Amount: ₹${(_cartService.finalPrice + 40).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _placeOrder(paymentId: "MANUAL_QR_VERIFICATION_PENDING");
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text("I Have Paid"),
          )
        ],
      ),
    );
  }

  void _showBankDetailsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Bank Transfer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBankDetailRow("Bank Name", "HDFC Bank"),
            _buildBankDetailRow("Account Name", "Aman Enterprises"),
            _buildBankDetailRow("Account Number", "50100234567890"),
            _buildBankDetailRow("IFSC Code", "HDFC0001234"),
            const SizedBox(height: 16),
            Text("Amount: ₹${(_cartService.finalPrice + 40).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text("Please use your Order ID as reference.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _placeOrder(paymentId: "MANUAL_BANK_VERIFICATION_PENDING");
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text("Confirm Transfer"),
          )
        ],
      ),
    );
  }

  Widget _buildBankDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _placeOrder({String? paymentId}) async {
    try {
      setState(() => _isLoading = true);

      // Prepare Products
      final products = _cartService.items.map((item) => {
        "productId": item.product.id,
        "quantity": item.quantity
      }).toList();

      // Prepare Address
      final addressData = {
        "details": _userService.address,
        "city": _userService.city, 
        "state": _userService.state,
        "pincode": _userService.pincode,
        "phone": _userService.phone
      };

      // Determine Payment Method String for Backend
      String backendPaymentMethod = "COD";
      // if (_paymentMethod == "Online") backendPaymentMethod = "Online";
      if (_paymentMethod == "QR") backendPaymentMethod = "QR Code";
      if (_paymentMethod == "BankTransfer") backendPaymentMethod = "Bank Transfer";


      // Place Order
      final order = await _orderService.placeOrder(
        products: products,
        deliveryAddress: addressData,
        paymentMethod: backendPaymentMethod,
        // No delivery slot needed as per new requirements
      );

      // Success
      if (mounted) {
        // Capture total BEFORE clearing
        final totalPaid = _cartService.finalPrice + 40;
        _cartService.clearCart(); 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OrderSuccessScreen(
             orderId: order.id,
             total: totalPaid,
             deliverySlot: "Standard Delivery" // Default text since slots are removed
          )),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: Text('Checkout', style: AppTextStyles.headingSmall),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildAddressSection(),
                   const SizedBox(height: 20),
                   _buildPaymentMethodSection(), // New Section
                   const SizedBox(height: 20),
                   _buildOrderSummary(),
                   const SizedBox(height: 100),
                ],
              ),
            ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   const Icon(Icons.payment, color: Colors.green),
                   const SizedBox(width: 8),
                   Text('Payment Method', style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              // COD Option
              RadioListTile<String>(
                title: const Text("Cash on Delivery"),
                value: "COD",
                groupValue: _paymentMethod,
                onChanged: (val) => setState(() => _paymentMethod = val!),
                activeColor: AppColors.primaryGreen,
              ),
              // Online Option Removed
              
              // QR Code Option
              RadioListTile<String>(
                title: const Text("QR Code Payment"),
                subtitle: const Text("Scan & Pay manually"),
                value: "QR",
                groupValue: _paymentMethod,
                onChanged: (val) => setState(() => _paymentMethod = val!),
                activeColor: AppColors.primaryGreen,
              ),
              // Bank Transfer Option
              RadioListTile<String>(
                title: const Text("Bank Transfer"),
                subtitle: const Text("Direct transfer to bank account"),
                value: "BankTransfer",
                groupValue: _paymentMethod,
                onChanged: (val) => setState(() => _paymentMethod = val!),
                activeColor: AppColors.primaryGreen,
              ),
            ],
          )
    );
  }

  Widget _buildAddressSection() {
     return AnimatedBuilder(
      animation: _userService,
      builder: (context, _) {
        final address = _userService.address;
        final name = _userService.name;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Row(
                     children: [
                       const Icon(Icons.location_on, color: AppColors.primaryGreen),
                       const SizedBox(width: 8),
                       Text('Delivery Address', style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
                     ],
                   ),
                   TextButton(
                     onPressed: () {
                       Navigator.push(
                         context, 
                         MaterialPageRoute(builder: (context) => const LocationScreen())
                       ).then((_) => _userService.loadUser());
                     },
                     child: Text('CHANGE', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                   )
                ],
              ),
              const Divider(),
              Text(name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                address.isNotEmpty ? address : 'No address selected',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMedium),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildOrderSummary() {
     return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
         boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: AppTextStyles.headingSmall.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cartService.items.length,
            itemBuilder: (context, index) {
              final item = _cartService.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                     Text('${item.quantity} x ', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                     Expanded(child: Text(item.product.name)),
                     Text('₹${item.totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          if (_cartService.isFlashDealApplied)
             Padding(
               padding: const EdgeInsets.only(bottom: 8.0),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text('Flash Discount (5%)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                   Text('-₹${_cartService.discountAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                 ],
               ),
             ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total to Pay', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('₹${(_cartService.finalPrice + 40).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final total = _cartService.finalPrice + 40;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total to Pay', style: AppTextStyles.bodySmall),
                Text('₹${total.toStringAsFixed(0)}', style: AppTextStyles.headingLarge.copyWith(color: AppColors.primaryGreen)),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Place Order', style: AppTextStyles.buttonText),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      ],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
