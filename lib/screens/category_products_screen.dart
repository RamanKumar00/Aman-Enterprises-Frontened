import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/models/product_model.dart';
import 'package:aman_enterprises/widgets/product_card.dart';
import 'package:aman_enterprises/services/cart_service.dart';

import 'package:aman_enterprises/services/api_service.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryName;
  final Color categoryColor;
  final String? categoryImage;

  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
    required this.categoryColor,
    this.categoryImage,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  String _selectedFilter = 'All';
  String _sortBy = 'Popular';
  final CartService _cartService = CartService();
  
  final List<String> _filters = ['All', 'Organic', 'Fresh', 'Frozen', 'On Sale'];
  final List<String> _sortOptions = ['Popular', 'Price: Low to High', 'Price: High to Low', 'Newest'];

  bool _isSearching = false;
  bool _isLoading = true;
  List<Product> _products = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cartService.addListener(_onCartChange);
    _fetchCategoryProducts();
  }

  void _onCartChange() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchCategoryProducts() async {
    setState(() => _isLoading = true);
    try {
      // Use search API to find products by category name
      // The backend search logic checks parentCategory and subCategory
      final response = await ApiService.searchProduct(widget.categoryName);
      if (response.success && response.data != null) {
        final List<dynamic> jsonList = response.data!['homeScreenData']['allProducts'] ?? [];
        setState(() {
          _products = jsonList.map((json) => Product.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
         // Fallback or empty
         setState(() {
           _products = [];
           _isLoading = false;
         });
      }
    } catch (e) {
      debugPrint("Error fetching category products: $e");
      setState(() {
        _products = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cartService.removeListener(_onCartChange);
    _searchController.dispose();
    super.dispose();
  }

  // Get products filtered by category and search
  List<Product> get _filteredProducts {
    // We already fetched products for this category, so we just filter by local search/sort
    return _products.where((product) {
      
      // 1. Filter by Search Query (Local)
      if (_isSearching && _searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        if (!product.name.toLowerCase().contains(query) && 
            !product.description.toLowerCase().contains(query)) {
          return false;
        }
      }

      // 2. Filter by "Filter Chips" (Mock logic for now - relying on tags or discount)
      if (_selectedFilter != 'All') {
        if (_selectedFilter == 'On Sale' && product.discount <= 0) return false;
        // Basic tag matching if available
        if (_selectedFilter == 'Organic' && !product.name.toLowerCase().contains('organic')) return false; 
        if (_selectedFilter == 'Fresh' && !product.name.toLowerCase().contains('fresh')) return false;
        if (_selectedFilter == 'Frozen' && !product.name.toLowerCase().contains('frozen')) return false;
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Apply Sorting
    List<Product> products = List.from(_filteredProducts);
    
    if (_sortBy == 'Price: Low to High') {
      products.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Price: High to Low') {
      products.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'Newest') {
         // Assuming backend returns newest first or we have no date field, 
         // we might need to rely on ID or just keep original order
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: CustomScrollView(
        slivers: [
          // Animated App Bar with Category Header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: widget.categoryColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isSearching)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search in ${widget.categoryName}...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _isSearching = false);
                            },
                          ),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                  ),
                )
              else ...[
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                  ),
                  onPressed: () => setState(() => _isSearching = true),
                ),
              ],
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 20),
                ),
                onPressed: () => _showSortBottomSheet(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.categoryColor,
                      widget.categoryColor.withAlpha(200),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.categoryName,
                          style: AppTextStyles.headingLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isLoading ? 'Loading...' : '${products.length} products',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white.withAlpha(200),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Filter Chips
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? widget.categoryColor : Colors.white,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                            border: Border.all(
                              color: isSelected ? widget.categoryColor : AppColors.border,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: widget.categoryColor.withAlpha(51),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ] : null,
                          ),
                          child: Text(
                            filter,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isSelected ? Colors.white : AppColors.textMedium,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          
          // Products Grid
          if (_isLoading)
             const SliverFillRemaining(
               child: Center(child: CircularProgressIndicator()),
             )
          else if (products.isEmpty)
              SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ProductCard(product: products[index]),
                      childCount: products.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: widget.categoryColor.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 60,
              color: widget.categoryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No products found',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later or try a different filter',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sort By',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 16),
              ..._sortOptions.map((option) {
                final isSelected = _sortBy == option;
                return ListTile(
                  onTap: () {
                    setState(() => _sortBy = option);
                    Navigator.pop(context);
                  },
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? widget.categoryColor : AppColors.textLight,
                  ),
                  title: Text(
                    option,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
