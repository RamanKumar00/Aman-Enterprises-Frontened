import 'package:aman_enterprises/models/courier_models.dart';
import 'package:aman_enterprises/models/order_model.dart';
import 'package:aman_enterprises/services/courier_service.dart';
import 'package:flutter/material.dart';

class CourierSelectionScreen extends StatefulWidget {
  final OrderModel order;
  // Assuming we have a default pickup pincode for now or it should be fetched from settings
  final String pickupPincode; 

  const CourierSelectionScreen({
    super.key,
    required this.order,
    this.pickupPincode = "110001", // Default/Fallback
  });

  @override
  State<CourierSelectionScreen> createState() => _CourierSelectionScreenState();
}

class _CourierSelectionScreenState extends State<CourierSelectionScreen> {
  final CourierService _courierService = CourierService();
  bool _isLoading = true;
  String? _errorMessage;
  
  // State for calculation
  late TextEditingController _weightController;
  late TextEditingController _lengthController;
  late TextEditingController _breadthController;
  late TextEditingController _heightController;
  bool _isCod = false;
  
  // Results
  List<ShippingRate> _rates = [];
  ShippingRate? _recommended;
  ShippingRate? _selectedRate;
  
  @override
  void initState() {
    super.initState();
    // Initialize with estimation (0.5kg per item is a rough guess if not available)
    double estimatedWeight = widget.order.items.fold(0, (sum, item) => sum + (0.5 * item.quantity));
    _weightController = TextEditingController(text: estimatedWeight.toString());
    _lengthController = TextEditingController(text: "20");
    _breadthController = TextEditingController(text: "15");
    _heightController = TextEditingController(text: "10");
    
    // We don't have payment method in OrderModel seen previously, assuming false for now or checking logic
    // Ideally OrderModel should have paymentMethod. I'll default to false (Prepaid) and let admin toggle.
    _isCod = false; 

    _fetchRates();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _lengthController.dispose();
    _breadthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _fetchRates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _rates = [];
      _recommended = null;
      _selectedRate = null;
    });

    try {
      final weight = double.tryParse(_weightController.text) ?? 0.5;
      final deliveryPincode = widget.order.shippingAddress?.pincode;

      if (deliveryPincode == null || deliveryPincode.isEmpty) {
        throw Exception("Delivery pincode is missing");
      }

      // Parallel fetch: Rates and Recommendation
      final results = await Future.wait([
        _courierService.getRates(
          pickupPincode: widget.pickupPincode,
          deliveryPincode: deliveryPincode,
          weight: weight,
          cod: _isCod,
          codAmount: _isCod ? widget.order.totalPrice : 0,
        ),
        _courierService.getRecommendedCourier(
          pickupPincode: widget.pickupPincode,
          deliveryPincode: deliveryPincode,
          weight: weight,
          cod: _isCod,
          codAmount: _isCod ? widget.order.totalPrice : 0,
        )
      ]);

      final ratesData = results[0];
      final recData = results[1];

      setState(() {
        _rates = ratesData['rates'] as List<ShippingRate>;
        _recommended = recData['recommended'] as ShippingRate?;
        
        // Auto-select recommended
        if (_recommended != null) {
           // Find the matching rate object in the list to ensure consistency
           try {
             _selectedRate = _rates.firstWhere((r) => 
               r.courierName == _recommended!.courierName && 
               r.courierService == _recommended!.courierService
             );
           } catch (e) {
             _selectedRate = _recommended;
           }
        } else if (_rates.isNotEmpty) {
          _selectedRate = _rates.first;
        }
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createShipment() async {
    if (_selectedRate == null) return;

    setState(() => _isLoading = true);

    try {
      await _courierService.createShipment(
        orderId: widget.order.id,
        courierName: _selectedRate!.courierName, // Or courierService depending on backend expectation
        autoSelect: false, // We manually selected
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shipment created successfully!')),
      );
      
      Navigator.pop(context, true); // Return success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Courier"),
      ),
      body: Column(
        children: [
          _buildInputSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text("Error: $_errorMessage"))
                    : _buildRatesList(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: "Weight (kg)"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text("COD"),
                    value: _isCod,
                    onChanged: (val) {
                      setState(() => _isCod = val ?? false);
                      _fetchRates();
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchRates,
              child: const Text("Recalculate Rates"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatesList() {
    if (_rates.isEmpty) {
      return const Center(child: Text("No couriers available for this route."));
    }

    return ListView.builder(
      itemCount: _rates.length,
      itemBuilder: (context, index) {
        final rate = _rates[index];
        final isSelected = _selectedRate?.courierService == rate.courierService; // Use unique identifier if possible
        final isRecommended = _recommended?.courierService == rate.courierService;

        return Card(
          color: isSelected ? Colors.blue.shade50 : null,
          shape: isSelected
              ? RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(8))
              : null,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: InkWell(
            onTap: () => setState(() => _selectedRate = rate),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        rate.courierName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        "₹${rate.totalCharge}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text("RECOMMENDED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      Text("ETA: ${rate.estimatedDays ?? 'N/A'} days"),
                      const Spacer(),
                      Icon(
                        rate.codAvailable ? Icons.check_circle : Icons.cancel,
                        color: rate.codAvailable ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(rate.codAvailable ? "COD" : "No COD"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedRate != null
                    ? "Selected: ${_selectedRate!.courierName} (₹${_selectedRate!.totalCharge})"
                    : "Select a courier",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: _selectedRate != null && !_isLoading ? _createShipment : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text("SHIP ORDER"),
            ),
          ],
        ),
      ),
    );
  }
}
