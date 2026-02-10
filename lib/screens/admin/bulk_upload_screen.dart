import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/services/bulk_product_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  File? _selectedFile;
  bool _isLoading = false;
  bool _isParsing = false;
  bool _isUploading = false;
  String? _errorMessage;
  
  // Parsed data
  List<ParsedProductRow> _parsedRows = [];
  int _validCount = 0;
  int _invalidCount = 0;

  
  // Upload results
  int _successCount = 0;
  int _failedCount = 0;
  bool _uploadComplete = false;

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
          _errorMessage = null;
          _uploadComplete = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  Future<void> _downloadTemplate() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await BulkProductService.downloadProductTemplate();
      
      if (response.success && response.data != null) {
        final bytes = response.data!['bytes'] as List<int>;
        final filename = response.data!['filename'] as String;
        
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$filename');
        await file.writeAsBytes(bytes);
        
        await Share.shareXFiles([XFile(file.path)], text: 'Product Upload Template');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Template downloaded!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message), backgroundColor: Colors.red),
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _parseFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isParsing = true;
      _errorMessage = null;
    });

    try {
      final response = await BulkProductService.parseUploadFile(_selectedFile!);

      if (response.success && response.data != null) {
        final data = response.data!['data'];
        final rows = (data['rows'] as List)
            .map((r) => ParsedProductRow.fromJson(r))
            .toList();

        setState(() {
          _parsedRows = rows;
          _validCount = data['validRows'] ?? 0;
          _invalidCount = data['invalidRows'] ?? 0;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error parsing file: $e';
      });
    } finally {
      setState(() => _isParsing = false);
    }
  }

  Future<void> _executeUpload() async {
    final validProducts = _parsedRows
        .where((r) => r.isValid)
        .map((r) => r.toUploadJson())
        .toList();

    if (validProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid products to upload'), backgroundColor: Colors.orange),
      );
      return;
    }

    // Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Upload'),
        content: Text('Upload ${validProducts.length} products?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            child: const Text('Upload', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final response = await BulkProductService.executeBulkUpload(validProducts);

      if (response.success && response.data != null) {
        final data = response.data!['data'];
        setState(() {
          _successCount = data['successCount'] ?? 0;
          _failedCount = data['failedCount'] ?? 0;
          _uploadComplete = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uploaded $_successCount products successfully!'),
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
        _errorMessage = 'Error uploading: $e';
      });
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Bulk Upload Products'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download),
            tooltip: 'Download Template',
            onPressed: _isLoading ? null : _downloadTemplate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Instructions',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '1. Download the sample template\n2. Fill in product data\n3. Upload the file\n4. Review and confirm',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // File Picker Section
            Text('Select File', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFile != null ? AppColors.primaryGreen : Colors.grey.shade300,
                    style: BorderStyle.solid,
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
                          : 'Tap to select Excel/CSV file',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _selectedFile != null ? AppColors.primaryGreen : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supported: .xlsx, .xls, .csv',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
                  onPressed: _isParsing ? null : _parseFile,
                  icon: _isParsing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search),
                  label: Text(_isParsing ? 'Parsing...' : 'Parse & Validate File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Parsed Data Preview
            if (_parsedRows.isNotEmpty) ...[
              const SizedBox(height: 24),

              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Rows',
                      '${_parsedRows.length}',
                      Icons.table_rows,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Valid',
                      '$_validCount',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Invalid',
                      '$_invalidCount',
                      Icons.error,
                      Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Preview Table
              Text('Preview Data', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 30, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                          SizedBox(width: 30, child: Icon(Icons.check, size: 16)),
                          Expanded(flex: 3, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(child: Text('MRP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                    ),
                    
                    // Table Body
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: _parsedRows.length,
                        itemBuilder: (context, index) {
                          final row = _parsedRows[index];
                          return _buildProductRow(row);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Upload Button
              if (!_uploadComplete)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading || _validCount == 0 ? null : _executeUpload,
                    icon: _isUploading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.cloud_upload),
                    label: Text(_isUploading ? 'Uploading...' : 'Upload $_validCount Valid Products'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ),

              // Upload Complete
              if (_uploadComplete) ...[
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
                      const Text(
                        'Upload Complete!',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text('$_successCount products uploaded successfully'),
                      if (_failedCount > 0)
                        Text(
                          '$_failedCount products failed',
                          style: TextStyle(color: Colors.red.shade600),
                        ),
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(ParsedProductRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        color: row.isValid ? null : Colors.red.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 30,
                child: Text('${row.rowNumber}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ),
              SizedBox(
                width: 30,
                child: Icon(
                  row.isValid ? Icons.check_circle : Icons.error,
                  size: 16,
                  color: row.isValid ? Colors.green : Colors.red,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  row.productName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  row.category,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  '₹${row.mrp.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              Expanded(
                child: Text(
                  '₹${row.sellingPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
          if (row.errors.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...row.errors.map((e) => Text(
              '• $e',
              style: TextStyle(fontSize: 10, color: Colors.red.shade700),
            )),
          ],
        ],
      ),
    );
  }
}
