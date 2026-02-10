import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? product; // If provided, we are in Edit mode

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _b2bPriceController;
  late TextEditingController _b2bMinQtyController;
  late TextEditingController _costPriceController;
  
  // State
  String? _selectedCategory;
  File? _imageFile;
  bool _isLoading = false;
  List<dynamic> _categories = [];
  bool get _isEditMode => widget.product != null;
  bool _isB2BAvailable = true;

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(text: widget.product?['productName'] ?? '');
    _descController = TextEditingController(text: widget.product?['description'] ?? '');
    _priceController = TextEditingController(text: widget.product?['price']?.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?['stock']?.toString() ?? '');
    _b2bPriceController = TextEditingController(text: widget.product?['b2bPrice']?.toString() ?? '');
    _b2bMinQtyController = TextEditingController(text: widget.product?['b2bMinQty']?.toString() ?? '6');
    _costPriceController = TextEditingController(text: widget.product?['costPrice']?.toString() ?? '');
    
    _isB2BAvailable = widget.product?['isB2BAvailable'] ?? true;

    // Handle Category Preselection
    if (_isEditMode && widget.product?['category'] != null) {
      if (widget.product!['category'] is Map) {
         _selectedCategory = widget.product!['category']['_id']?.toString();
      } else {
         _selectedCategory = widget.product!['category']?.toString();
      }
    } else if (_isEditMode && widget.product?['parentCategory'] != null) {
      // Fallback for parentCategory
      _selectedCategory = widget.product!['parentCategory']?.toString();
    }

    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final response = await ApiService.getCategories();
    if (response.success && response.data != null) {
      if (mounted) {
        setState(() {
          final list = response.data!['categories'];
          if (list is List) {
             _categories = list;
          }
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    // In edit mode, image is optional (keep existing)
    if (!_isEditMode && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product image')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final token = UserService().authToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Please login again.')),
      );
      return;
    }

    // Backend expects: productName, description, price, stock, category (ID)
    final data = {
      'productName': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'price': _priceController.text.trim(),
      'stock': _stockController.text.trim(),
      'category': _selectedCategory,
      'b2bPrice': _b2bPriceController.text.trim().isEmpty ? _priceController.text.trim() : _b2bPriceController.text.trim(),
      'b2bMinQty': _b2bMinQtyController.text.trim().isEmpty ? '6' : _b2bMinQtyController.text.trim(),
      'isB2BAvailable': _isB2BAvailable.toString(),
      'costPrice': _costPriceController.text.trim(), // Optional
    };

    late ApiResponse response;
    
    if (_isEditMode) {
       response = await ApiService.updateProduct(token, widget.product!['_id'], data, _imageFile);
    } else {
       response = await ApiService.addProduct(token, data, _imageFile);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Product Updated Successfully!' : 'Product Added Successfully!'), 
            backgroundColor: Colors.green
          ),
        );
        Navigator.pop(context); // Go back
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.message}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show existing image URL if strict edit mode and no new file selected
    final existingImageUrl = (_isEditMode && _imageFile == null && widget.product?['image'] != null)
        ? (widget.product!['image'] is Map 
            ? widget.product!['image']['url'] 
            : widget.product!['image'])
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Product' : 'Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                    image: _imageFile != null
                        ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : (existingImageUrl != null 
                            ? DecorationImage(image: NetworkImage(existingImageUrl), fit: BoxFit.cover)
                            : null),
                  ),
                  child: (_imageFile == null && existingImageUrl == null)
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tap to add/replace product image'),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                hint: const Text("Select Category"),
                items: _categories.map((cat) {
                  final id = cat['_id']?.toString() ?? '';
                  final name = cat['categoryName']?.toString() ?? 'Unknown';
                  return DropdownMenuItem(value: id, child: Text(name));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Retail Pricing
              Text("Retail Pricing & Stock", style: AppTextStyles.headingSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                   Expanded(
                     child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                   ),
                ],
              ),
              const SizedBox(height: 20),

              // B2B Pricing Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text("B2B Settings", style: AppTextStyles.headingSmall),
                   Switch(
                     value: _isB2BAvailable, 
                     onChanged: (val) => setState(() => _isB2BAvailable = val),
                     activeThumbColor: AppColors.primaryGreen,
                   )
                ],
              ),
              const SizedBox(height: 8),
              if (_isB2BAvailable) ...[
                Row(
                  children: [
                     Expanded(
                       child: TextFormField(
                          controller: _b2bPriceController,
                          decoration: const InputDecoration(labelText: 'B2B Price (₹)', border: OutlineInputBorder(), hintText: 'Usually lower'),
                          keyboardType: TextInputType.number,
                        ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: TextFormField(
                          controller: _b2bMinQtyController,
                          decoration: const InputDecoration(labelText: 'Min Qty', border: OutlineInputBorder(), hintText: 'e.g. 6'),
                          keyboardType: TextInputType.number,
                        ),
                     ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Admin Only: Cost Price
               Text("Admin Only", style: AppTextStyles.headingSmall),
               const SizedBox(height: 8),
               TextFormField(
                  controller: _costPriceController,
                  decoration: const InputDecoration(labelText: 'Cost Price (₹) - Hidden from customers', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isEditMode ? 'Update Product' : 'Add Product', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
