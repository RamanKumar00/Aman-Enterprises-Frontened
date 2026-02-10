import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/services/flash_deal_service.dart';

class ManageFlashDealsScreen extends StatefulWidget {
  const ManageFlashDealsScreen({super.key});

  @override
  State<ManageFlashDealsScreen> createState() => _ManageFlashDealsScreenState();
}

class _ManageFlashDealsScreenState extends State<ManageFlashDealsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _minOrderController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;
  final FlashDealService _service = FlashDealService();

  @override
  void initState() {
    super.initState();
    _fetchCurrentDeal();
  }

  Future<void> _fetchCurrentDeal() async {
    setState(() => _isLoading = true);
    final deal = await _service.getActiveDeal();
    if (deal != null) {
      _minOrderController.text = deal.minOrderValue.toString();
      _discountController.text = deal.discountPercentage.toString();
      setState(() {
        _isActive = deal.isActive;
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveDeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final success = await _service.updateDeal(
      minOrderValue: double.parse(_minOrderController.text),
      discountPercentage: double.parse(_discountController.text),
      isActive: _isActive,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flash Deal Updated Successfully')),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update deal')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Flash Deals'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Configure Flash Deal Logic",
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _minOrderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minimum Order Value (₹)',
                        border: OutlineInputBorder(),
                        prefixText: '₹ ',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter value';
                        if (double.tryParse(value) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Discount Percentage (%)',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter percentage';
                        if (double.tryParse(value) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: const Text("Enable Flash Deal"),
                      subtitle: const Text("If disabled, no auto-dsicount will be applied."),
                      value: _isActive,
                      activeThumbColor: AppColors.primaryGreen,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveDeal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text("Save & Update", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
