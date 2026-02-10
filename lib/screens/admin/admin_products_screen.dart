import 'package:flutter/material.dart';
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:aman_enterprises/screens/admin/admin_add_product_screen.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  Map<String, List<dynamic>> _productsByCategory = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String? _selectedCategory; // null = All Products
  late TabController _tabController;
  bool _showCategoryView = true; // Toggle between category view and list view

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    final token = UserService().authToken;
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Fetch categories and products in parallel
    final results = await Future.wait([
      ApiService.getCategories(),
      ApiService.getProductsAdmin(token),
    ]);

    final catResponse = results[0];
    final prodResponse = results[1];

    if (mounted) {
      setState(() {
        // Process categories
        if (catResponse.success && catResponse.data != null) {
          _categories = catResponse.data!['categories'] ?? [];
        }
        
        // Initialize tab controller after getting categories
        _tabController = TabController(
          length: _categories.length + 1, // +1 for "All Products"
          vsync: this,
        );
        _tabController.addListener(_onTabChanged);

        // Process products
        if (prodResponse.success && prodResponse.data != null) {
          final list = prodResponse.data!['products'];
          if (list is List) {
            _products = list;
            _organizeProductsByCategory();
          }
        }
        
        _isLoading = false;
      });
    }
  }

  void _organizeProductsByCategory() {
    _productsByCategory = {};
    
    for (var product in _products) {
      final category = product['parentCategory'] ?? product['category'] ?? 'Uncategorized';
      if (!_productsByCategory.containsKey(category)) {
        _productsByCategory[category] = [];
      }
      _productsByCategory[category]!.add(product);
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        if (_tabController.index == 0) {
          _selectedCategory = null; // All Products
        } else {
          final cat = _categories[_tabController.index - 1];
          _selectedCategory = cat['categoryName'];
        }
      });
    }
  }

  List<dynamic> get _filteredProducts {
    if (_selectedCategory == null) {
      return _products;
    }
    return _products.where((p) {
      final cat = p['parentCategory'] ?? p['category'] ?? '';
      return cat.toString().toLowerCase() == _selectedCategory!.toLowerCase();
    }).toList();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchProducts(query);
    });
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      _fetchData();
      return;
    }

    setState(() => _isLoading = true);
    final response = await ApiService.searchProduct(query);
    
    if (mounted) {
      if (response.success && response.data != null) {
        final homeData = response.data!['homeScreenData'];
        if (homeData != null) {
          final list = homeData['allProducts'] ?? [];
          setState(() {
            _products = list;
            _organizeProductsByCategory();
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final token = UserService().authToken;
    if (token == null) return;
    
    final response = await ApiService.deleteProduct(token, productId);
    if (mounted) {
      if (response.success) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product Deleted Successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "${product['productName']}"?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(product['_id']);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Manage Products'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Toggle View Button
          IconButton(
            icon: Icon(_showCategoryView ? Icons.list : Icons.grid_view, color: AppColors.primaryGreen),
            onPressed: () => setState(() => _showCategoryView = !_showCategoryView),
            tooltip: _showCategoryView ? 'List View' : 'Category View',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryGreen),
            onPressed: _fetchData,
          ),
        ],
        bottom: _isLoading ? null : _buildCategoryTabs(),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textLight),
                        onPressed: () {
                          _searchController.clear();
                          _fetchData();
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
              onChanged: _onSearchChanged,
            ),
          ),
          
          // Products Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : _showCategoryView
                    ? _buildCategoryView()
                    : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGreen,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          ).then((_) => _fetchData());
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  PreferredSizeWidget? _buildCategoryTabs() {
    if (_categories.isEmpty) return null;
    
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      labelColor: AppColors.primaryGreen,
      unselectedLabelColor: AppColors.textLight,
      indicatorColor: AppColors.primaryGreen,
      indicatorWeight: 3,
      tabs: [
        Tab(
          child: Row(
            children: [
              const Icon(Icons.all_inclusive, size: 18),
              const SizedBox(width: 6),
              Text('All (${_products.length})'),
            ],
          ),
        ),
        ..._categories.map((cat) {
          final catName = cat['categoryName'] ?? 'Unknown';
          final count = _productsByCategory[catName]?.length ?? 0;
          return Tab(
            child: Row(
              children: [
                Text('$catName ($count)'),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryView() {
    final productsToShow = _filteredProducts;
    
    if (productsToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _selectedCategory != null
                  ? 'No products in "$_selectedCategory"'
                  : 'No products found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                ).then((_) => _fetchData());
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: productsToShow.length,
        itemBuilder: (context, index) => _buildProductCard(productsToShow[index]),
      ),
    );
  }

  Widget _buildListView() {
    final productsToShow = _filteredProducts;
    
    if (productsToShow.isEmpty) {
      return const Center(child: Text("No products found"));
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: productsToShow.length,
        itemBuilder: (context, index) => _buildProductListItem(productsToShow[index]),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final imageUrl = product['image']?['url'];
    final isInStock = (product['stock'] ?? 0) > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddProductScreen(product: product)),
        ).then((_) => _fetchData());
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey.shade200),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                          ),
                  ),
                  // Stock Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isInStock ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isInStock ? 'In Stock (${product['stock']})' : 'Out of Stock',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Action Buttons
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Column(
                      children: [
                        _buildIconButton(Icons.edit, Colors.blue, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AddProductScreen(product: product)),
                          ).then((_) => _fetchData());
                        }),
                        const SizedBox(height: 4),
                        _buildIconButton(Icons.delete, Colors.red, () => _confirmDelete(product)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product['productName'] ?? 'No Name',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '₹${product['price']}',
                            style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (product['b2bPrice'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'B2B: ₹${product['b2bPrice']}',
                              style: TextStyle(color: Colors.blue.shade800, fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListItem(Map<String, dynamic> product) {
    final imageUrl = product['image']?['url'];
    final isInStock = (product['stock'] ?? 0) > 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.shade200),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image_not_supported),
              ),
        title: Text(
          product['productName'] ?? 'No Name',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isInStock ? Icons.check_circle : Icons.cancel, size: 12, color: isInStock ? Colors.green : Colors.red),
                const SizedBox(width: 4),
                Text('Stock: ${product['stock']}', style: TextStyle(color: isInStock ? Colors.green : Colors.red, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text('₹${product['price']}', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                ),
                if (product['b2bPrice'] != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                    child: Text('B2B: ₹${product['b2bPrice']}', style: TextStyle(color: Colors.blue.shade800, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddProductScreen(product: product)),
                ).then((_) => _fetchData());
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(product),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 4),
          ],
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
