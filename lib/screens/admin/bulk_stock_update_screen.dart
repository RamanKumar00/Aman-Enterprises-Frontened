import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/services/bulk_product_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BulkStockUpdateScreen extends StatefulWidget {
  const BulkStockUpdateScreen({super.key});

  @override
  State<BulkStockUpdateScreen> createState() => _BulkStockUpdateScreenState();
}

class _BulkStockUpdateScreenState extends State<BulkStockUpdateScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Low Stock
  bool _isLoadingLowStock = false;
  List<Map<String, dynamic>> _lowStockProducts = [];
  int _threshold = 10;
  
  // File Upload
  File? _selectedFile;
  bool _isParsing = false;
  bool _isUploading = false;
  List<StockUpdateRow> _parsedRows = [];
  int _validCount = 0;
  
  // Manual Update
  List<Map<String, dynamic>> _allProducts = [];
  final Set<String> _selectedProductIds = {};
  bool _isLoadingProducts = false;
  String _manualUpdateType = 'add';
  final TextEditingController _manualValueController = TextEditingController();
  bool _isManualUpdating = false;
  
  // Results
  int _successCount = 0;
  int _failedCount = 0;
  bool _updateComplete = false;
  
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLowStockProducts();
    _loadAllProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _manualValueController.dispose();
    super.dispose();
  }

  Future<void> _loadLowStockProducts() async {
    setState(() => _isLoadingLowStock = true);
    try {
      final response = await BulkProductService.getLowStockProducts(threshold: _threshold);
      if (response.success && response.data != null) {
        final data = response.data!['data'];
        setState(() {
          _lowStockProducts = List<Map<String, dynamic>>.from(data['products'] ?? []);
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoadingLowStock = false);
    }
  }

  Future<void> _loadAllProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final response = await BulkProductService.getProductsForPriceUpdate(limit: 200);
      if (response.success && response.data != null) {
        final data = response.data!['data'];
        setState(() {
          _allProducts = List<Map<String, dynamic>>.from(data['products'] ?? []);
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _downloadStockTemplate() async {
    setState(() => _isLoadingLowStock = true);
    try {
      final response = await BulkProductService.downloadStockTemplate();
      if (response.success && response.data != null) {
        final bytes = response.data!['bytes'] as List<int>;
        final filename = response.data!['filename'] as String;
        
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(bytes);
        
        await Share.shareXFiles([XFile(file.path)], text: 'Stock Update Template');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template downloaded!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoadingLowStock = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _parsedRows = [];
          _updateComplete = false;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error picking file: $e');
    }
  }

  Future<void> _parseStockFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isParsing = true;
      _errorMessage = null;
    });

    try {
      final response = await BulkProductService.parseStockFile(_selectedFile!);

      if (response.success && response.data != null) {
        final data = response.data!['data'];
        final rows = (data['rows'] as List)
            .map((r) => StockUpdateRow.fromJson(r))
            .toList();

        setState(() {
          _parsedRows = rows;
          _validCount = data['validRows'] ?? 0;
          _failedCount = data['failedRows'] ?? 0; // Use _failedCount in UI
        });
      } else {
        setState(() => _errorMessage = response.message);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isParsing = false);
    }
  }

  Future<void> _executeStockUpload() async {
    final validUpdates = _parsedRows
        .where((r) => r.isValid)
        .map((r) => r.toUpdateJson())
        .toList();

    if (validUpdates.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Stock Update'),
        content: Text('Update stock for ${validUpdates.length} products?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUploading = true);

    try {
      final response = await BulkProductService.executeStockUpdate(validUpdates);

      if (response.success && response.data != null) {
        final data = response.data!['data'];
        setState(() {
          _successCount = data['success'] ?? 0;
          _failedCount = data['failed'] ?? 0;
          _updateComplete = true;
        });

        _loadLowStockProducts(); // Refresh
      } else {
        setState(() => _errorMessage = response.message);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _executeManualUpdate() async {
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select products first'), backgroundColor: Colors.orange),
      );
      return;
    }

    final value = int.tryParse(_manualValueController.text);
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid stock value'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Manual Update'),
        content: Text('${_manualUpdateType.toUpperCase()} $value stock for ${_selectedProductIds.length} products?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isManualUpdating = true);

    try {
      final response = await BulkProductService.manualStockUpdate(
        productIds: _selectedProductIds.toList(),
        updateType: _manualUpdateType,
        stockValue: value,
      );

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock updated!'), backgroundColor: Colors.green),
        );
        _loadAllProducts();
        _loadLowStockProducts();
        setState(() {
          _selectedProductIds.clear();
          _manualValueController.clear();
        });
      } else {
        setState(() => _errorMessage = response.message);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isManualUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Bulk Stock Update'),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryGreen,
          tabs: const [
            Tab(text: 'Low Stock', icon: Icon(Icons.warning_amber, size: 20)),
            Tab(text: 'File Upload', icon: Icon(Icons.upload_file, size: 20)),
            Tab(text: 'Manual', icon: Icon(Icons.edit, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLowStockTab(),
          _buildFileUploadTab(),
          _buildManualTab(),
        ],
      ),
    );
  }

  Widget _buildLowStockTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Threshold Selector
          Row(
            children: [
              const Text('Low Stock Threshold:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _threshold,
                    items: [5, 10, 20, 50, 100]
                        .map((t) => DropdownMenuItem(value: t, child: Text('≤ $t units')))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _threshold = v ?? 10);
                      _loadLowStockProducts();
                    },
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadLowStockProducts,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Alert Card
          if (_lowStockProducts.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_lowStockProducts.length} Products Low on Stock',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                        ),
                        Text(
                          'These products have $_threshold or fewer units',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Product List
          if (_isLoadingLowStock)
            const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          else if (_lowStockProducts.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.check_circle, color: Colors.green.shade300, size: 64),
                  const SizedBox(height: 16),
                  const Text('All products are well stocked!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _lowStockProducts.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  final product = _lowStockProducts[index];
                  final stock = product['stockQuantity'] ?? 0;
                  
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: stock == 0 ? Colors.red.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$stock',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: stock == 0 ? Colors.red : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      product['productName'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    subtitle: Text(
                      product['category'] ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    trailing: stock == 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('OUT OF STOCK', style: TextStyle(color: Colors.white, fontSize: 10)),
                          )
                        : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileUploadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Download Template Button
          ElevatedButton.icon(
            onPressed: _downloadStockTemplate,
            icon: const Icon(Icons.download),
            label: const Text('Download Stock Template'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          // File Picker
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedFile != null ? AppColors.primaryGreen : Colors.grey.shade300,
                  width: _selectedFile != null ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFile != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                    size: 48,
                    color: _selectedFile != null ? AppColors.primaryGreen : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFile != null 
                        ? _selectedFile!.path.split('/').last
                        : 'Tap to select stock update file',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _selectedFile != null ? AppColors.primaryGreen : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_selectedFile != null && _parsedRows.isEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isParsing ? null : _parseStockFile,
                icon: _isParsing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search),
                label: Text(_isParsing ? 'Parsing...' : 'Parse File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],

          // Parsed Preview
          if (_parsedRows.isNotEmpty) ...[
            const SizedBox(height: 20),
            
            Row(
              children: [
                _buildMiniStat('Valid', '$_validCount', Colors.green),
                const SizedBox(width: 12),
                _buildMiniStat('Invalid', '${_parsedRows.length - _validCount}', Colors.red),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                itemCount: _parsedRows.length,
                itemBuilder: (context, index) {
                  final row = _parsedRows[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: row.isValid ? null : Colors.red.shade50,
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          row.isValid ? Icons.check_circle : Icons.error,
                          size: 18,
                          color: row.isValid ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Text(row.productName, style: const TextStyle(fontSize: 13)),
                        ),
                        Text('${row.currentStock}', style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          '${row.newStock}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: row.newStock > row.currentStock ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            if (!_updateComplete)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUploading || _validCount == 0 ? null : _executeStockUpload,
                  icon: _isUploading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check),
                  label: Text(_isUploading ? 'Updating...' : 'Apply $_validCount Updates'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

            if (_updateComplete)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 8),
                    Text('Updated $_successCount products!'),
                    if (_failedCount > 0)
                      Text('$_failedCount failed', style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ),
              ),
          ],

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
            ),
        ],
      ),
    );
  }

  Widget _buildManualTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Update Type
          const Text('Update Type', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildManualTypeChip('Add', 'add', Icons.add),
              const SizedBox(width: 8),
              _buildManualTypeChip('Reduce', 'reduce', Icons.remove),
              const SizedBox(width: 8),
              _buildManualTypeChip('Replace', 'replace', Icons.swap_horiz),
            ],
          ),

          const SizedBox(height: 16),

          // Value Input
          TextField(
            controller: _manualValueController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Stock Value',
              hintText: 'Enter quantity',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          // Select Products
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select Products', style: TextStyle(fontWeight: FontWeight.w500)),
              if (_selectedProductIds.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _selectedProductIds.clear()),
                  child: Text('Clear (${_selectedProductIds.length})'),
                ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isLoadingProducts
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : ListView.builder(
                    itemCount: _allProducts.length,
                    itemBuilder: (context, index) {
                      final product = _allProducts[index];
                      final id = product['_id'] as String;
                      final isSelected = _selectedProductIds.contains(id);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) {
                          setState(() {
                            if (isSelected) {
                              _selectedProductIds.remove(id);
                            } else {
                              _selectedProductIds.add(id);
                            }
                          });
                        },
                        title: Text(
                          product['productName'] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text('Stock: ${product['stockQuantity']}'),
                        activeColor: AppColors.primaryGreen,
                        dense: true,
                      );
                    },
                  ),
          ),

          const SizedBox(height: 20),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isManualUpdating ? null : _executeManualUpdate,
              icon: _isManualUpdating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
              label: Text(_isManualUpdating ? 'Updating...' : 'Apply to ${_selectedProductIds.length} Products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTypeChip(String label, String value, IconData icon) {
    final isSelected = _manualUpdateType == value;
    return GestureDetector(
      onTap: () => setState(() => _manualUpdateType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
