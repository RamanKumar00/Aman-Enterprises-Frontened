import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/services/bulk_product_service.dart';

class BulkPriceUpdateScreen extends StatefulWidget {
  const BulkPriceUpdateScreen({super.key});

  @override
  State<BulkPriceUpdateScreen> createState() => _BulkPriceUpdateScreenState();
}

class _BulkPriceUpdateScreenState extends State<BulkPriceUpdateScreen> {
  bool _isLoading = false;
  bool _isPreviewing = false;
  bool _isUpdating = false;
  String? _errorMessage;

  // Products
  List<Map<String, dynamic>> _products = [];
  List<String> _categories = [];
  Set<String> _selectedProductIds = {};
  
  // Filters
  String _selectedCategory = 'all';
  final TextEditingController _searchController = TextEditingController();
  
  // Update settings
  String _updateType = 'percentage'; // percentage, fixed, replace
  String _priceField = 'sellingPrice'; // sellingPrice, mrp, b2bPrice
  final TextEditingController _updateValueController = TextEditingController();
  
  // Preview
  List<PriceUpdatePreview> _previewItems = [];
  bool _showPreview = false;

  // Results
  int _successCount = 0;
  int _failedCount = 0;
  bool _updateComplete = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _updateValueController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await BulkProductService.getProductsForPriceUpdate(
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'];
        setState(() {
          _products = List<Map<String, dynamic>>.from(data['products'] ?? []);
          _categories = List<String>.from(data['categories'] ?? []);
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedProductIds.length == _products.length) {
        _selectedProductIds.clear();
      } else {
        _selectedProductIds = _products.map((p) => p['_id'] as String).toSet();
      }
      _showPreview = false;
      _previewItems = [];
    });
  }

  void _toggleProduct(String id) {
    setState(() {
      if (_selectedProductIds.contains(id)) {
        _selectedProductIds.remove(id);
      } else {
        _selectedProductIds.add(id);
      }
      _showPreview = false;
      _previewItems = [];
    });
  }

  Future<void> _previewChanges() async {
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select products'), backgroundColor: Colors.orange),
      );
      return;
    }

    final valueText = _updateValueController.text.trim();
    if (valueText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter update value'), backgroundColor: Colors.orange),
      );
      return;
    }

    final updateValue = double.tryParse(valueText);
    if (updateValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid value'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isPreviewing = true;
      _errorMessage = null;
    });

    try {
      final response = await BulkProductService.previewPriceUpdate(
        productIds: _selectedProductIds.toList(),
        updateType: _updateType,
        updateValue: updateValue,
        priceField: _priceField,
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'];
        final preview = (data['preview'] as List)
            .map((p) => PriceUpdatePreview.fromJson(p))
            .toList();

        setState(() {
          _previewItems = preview;
          _showPreview = true;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() => _isPreviewing = false);
    }
  }

  Future<void> _executeUpdate() async {
    if (_previewItems.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Price Update'),
        content: Text('Update prices for ${_previewItems.length} products?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final updates = _previewItems.map((p) => p.toUpdateJson()).toList();
      final response = await BulkProductService.executePriceUpdate(
        updates: updates,
        priceField: _priceField,
      );

      if (response.success && response.data != null) {
        final data = response.data!['data'];
        setState(() {
          _successCount = data['success'] ?? 0;
          _failedCount = data['failed'] ?? 0;
          _updateComplete = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated $_successCount products!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Bulk Price Update'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filters
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              hint: const Text('Category'),
                              items: [
                                const DropdownMenuItem(value: 'all', child: Text('All Categories')),
                                ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value ?? 'all';
                                  _selectedProductIds.clear();
                                  _showPreview = false;
                                });
                                _loadProducts();
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: _loadProducts,
                            ),
                          ),
                          onSubmitted: (_) => _loadProducts(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Update Settings
                  Text('Update Settings', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price Field
                        const Text('Price Field', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildRadioChip('Selling Price', 'sellingPrice', _priceField, (v) => setState(() => _priceField = v)),
                            const SizedBox(width: 8),
                            _buildRadioChip('MRP', 'mrp', _priceField, (v) => setState(() => _priceField = v)),
                            const SizedBox(width: 8),
                            _buildRadioChip('B2B Price', 'b2bPrice', _priceField, (v) => setState(() => _priceField = v)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Update Type
                        const Text('Update Type', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildRadioChip('By %', 'percentage', _updateType, (v) => setState(() => _updateType = v)),
                            const SizedBox(width: 8),
                            _buildRadioChip('Fixed ₹', 'fixed', _updateType, (v) => setState(() => _updateType = v)),
                            const SizedBox(width: 8),
                            _buildRadioChip('Replace', 'replace', _updateType, (v) => setState(() => _updateType = v)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Value
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _updateValueController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: InputDecoration(
                                  labelText: _updateType == 'percentage' 
                                      ? 'Percentage (+ increase / - decrease)'
                                      : _updateType == 'fixed' 
                                          ? 'Amount (+ increase / - decrease)'
                                          : 'New Price',
                                  hintText: _updateType == 'percentage' ? 'e.g., 10 or -5' : 'e.g., 50 or -20',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  prefixIcon: Icon(
                                    _updateType == 'percentage' ? Icons.percent : Icons.currency_rupee,
                                  ),
                                ),
                                onChanged: (_) => setState(() {
                                  _showPreview = false;
                                  _previewItems = [];
                                }),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _isPreviewing ? null : _previewChanges,
                              icon: _isPreviewing 
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.preview, size: 18),
                              label: const Text('Preview'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Product List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Products (${_products.length})', style: AppTextStyles.headingSmall),
                      TextButton.icon(
                        onPressed: _toggleSelectAll,
                        icon: Icon(
                          _selectedProductIds.length == _products.length 
                              ? Icons.check_box 
                              : Icons.check_box_outline_blank,
                          size: 20,
                        ),
                        label: Text(_selectedProductIds.length == _products.length ? 'Deselect All' : 'Select All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_selectedProductIds.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedProductIds.length} products selected',
                            style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        final id = product['_id'] as String;
                        final isSelected = _selectedProductIds.contains(id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (_) => _toggleProduct(id),
                          title: Text(
                            product['productName'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${product['category']} • MRP: ₹${product['mrp']} • Price: ₹${product['sellingPrice']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          activeColor: AppColors.primaryGreen,
                          dense: true,
                        );
                      },
                    ),
                  ),

                  // Preview Section
                  if (_showPreview && _previewItems.isNotEmpty) ...[
                    const SizedBox(height: 20),

                    Text('Price Changes Preview', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(child: Text('Current', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(child: Text('New', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                Expanded(child: Text('Change', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              itemCount: _previewItems.length,
                              itemBuilder: (context, index) {
                                final item = _previewItems[index];
                                final isIncrease = item.change > 0;
                                
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          item.productName,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '₹${item.currentPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '₹${item.newPrice.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isIncrease ? Colors.green : Colors.red,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                                              size: 12,
                                              color: isIncrease ? Colors.green : Colors.red,
                                            ),
                                            Text(
                                              '${item.changePercent}%',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isIncrease ? Colors.green : Colors.red,
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
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Apply Button
                    if (!_updateComplete)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUpdating ? null : _executeUpdate,
                          icon: _isUpdating 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check),
                          label: Text(_isUpdating ? 'Updating...' : 'Apply Changes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),

                    // Success
                    if (_updateComplete)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 48),
                            const SizedBox(height: 12),
                            const Text('Update Complete!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text('$_successCount prices updated successfully'),
                            if (_failedCount > 0)
                              Text('$_failedCount failed', style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                              child: const Text('Done', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                  ],

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildRadioChip(String label, String value, String groupValue, Function(String) onChanged) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
