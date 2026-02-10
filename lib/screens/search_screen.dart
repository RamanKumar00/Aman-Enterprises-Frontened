import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/models/product_model.dart';
import 'package:aman_enterprises/screens/product_details_screen.dart';
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/widgets/shimmer_widgets.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';

class SearchScreen extends StatefulWidget {
  final bool autoStartVoice;
  const SearchScreen({super.key, this.autoStartVoice = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  
  String _selectedCategory = 'All';
  String _selectedSort = 'Relevance';
  RangeValues _priceRange = const RangeValues(0, 500);
  bool _showFilters = false;
  
  List<Product> _searchResults = [];
  final List<String> _recentSearches = [
    'Fresh Tomatoes',
    'Milk',
    'Bread',
    'Apples',
    'Rice',
  ];

  final List<String> _categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Dairy',
    'Bakery',
    'Grains',
    'Beverages',
  ];

  final List<String> _sortOptions = [
    'Relevance',
    'Price: Low to High',
    'Price: High to Low',
    'Rating',
    'Newest',
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _searchFocusNode.requestFocus();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (widget.autoStartVoice && _speechEnabled) {
      _startListening();
    }
    setState(() {});
  }

  void _startListening() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
      if (status.isDenied) return;
    }

    if (!_isListening) {
      await _speechToText.listen(onResult: _onSpeechResult);
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _searchController.text = result.recognizedWords;
    });
    
    if (result.finalResult) {
      _performSearch(result.recognizedWords);
      _addToRecentSearches(result.recognizedWords);
      setState(() => _isListening = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.searchProduct(query);
      
      if (!mounted) return;

      if (response.success && response.data != null) {
        // Backend returns: { homeScreenData: { allProducts: [...] } }
        final data = response.data!['homeScreenData'];
        final List<dynamic> productsList = data != null ? (data['allProducts'] ?? []) : [];
        
        setState(() {
          _searchResults = productsList.map((json) => Product.fromJson(json)).toList();
        });
      } else {
        // Fallback to local filtering if API fails
        _performLocalSearch(query);
      }
    } catch (e) {
      debugPrint('Search error: $e');
      _performLocalSearch(query);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _performLocalSearch(String query) {
    setState(() {
      _searchResults = Product.sampleProducts.where((product) {
        final matchesQuery = product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.category.toLowerCase().contains(query.toLowerCase());
        final matchesCategory = _selectedCategory == 'All' ||
            product.category == _selectedCategory;
        final matchesPrice = product.price >= _priceRange.start &&
            product.price <= _priceRange.end;
        return matchesQuery && matchesCategory && matchesPrice;
      }).toList();

      // Sort results (same as before)
      _sortResults();
    });
  }

  void _sortResults() {
      switch (_selectedSort) {
        case 'Price: Low to High':
          _searchResults.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'Price: High to Low':
          _searchResults.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'Rating':
          _searchResults.sort((a, b) => b.rating.compareTo(a.rating));
          break;
      }
  }

  void _addToRecentSearches(String query) {
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches.removeLast();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Filter Toggle
          if (_searchController.text.isNotEmpty) _buildFilterBar(),
          
          // Filters Panel
          if (_showFilters) _buildFiltersPanel(),
          
          // Content
          Expanded(
            child: _searchController.text.isEmpty
                ? _buildRecentSearches()
                    : _isLoading 
                    ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, index) => const ProductCardShimmer(),
                      )
                    : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
        onPressed: () => Navigator.pop(context),
      ),
      title: Container(
        height: 45,
        decoration: BoxDecoration(
          color: AppColors.backgroundCream,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: _performSearch,
          onSubmitted: (query) {
            _addToRecentSearches(query);
            _performSearch(query);
          },
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            hintText: _isListening ? 'Listening...' : 'Search for groceries...',
            hintStyle: AppTextStyles.hintText.copyWith(
              color: _isListening ? Colors.red : AppColors.textLight,
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textLight),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
            color: _isListening ? Colors.red : AppColors.primaryGreen,
          ),
          onPressed: _speechEnabled
              ? () {
                  if (_isListening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Text(
            '${_searchResults.length} results',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _showFilters ? AppColors.primaryGreen : AppColors.backgroundCream,
                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: _showFilters ? Colors.white : AppColors.textMedium,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Filters',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _showFilters ? Colors.white : AppColors.textMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories
          Text('Category', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = category);
                    _performSearch(_searchController.text);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryGreen : AppColors.backgroundCream,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                    ),
                    child: Text(
                      category,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Price Range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Price Range', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              Text(
                '₹${_priceRange.start.toInt()} - ₹${_priceRange.end.toInt()}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryGreen),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 500,
            divisions: 50,
            activeColor: AppColors.primaryGreen,
            inactiveColor: AppColors.border,
            onChanged: (values) {
              setState(() => _priceRange = values);
              _performSearch(_searchController.text);
            },
          ),
          const SizedBox(height: 8),

          // Sort
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sort by', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              DropdownButton<String>(
                value: _selectedSort,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: _sortOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option, style: AppTextStyles.bodySmall),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSort = value);
                    _performSearch(_searchController.text);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: AppTextStyles.headingSmall,
              ),
              TextButton(
                onPressed: () => setState(() => _recentSearches.clear()),
                child: Text(
                  'Clear All',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((search) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded, size: 16, color: AppColors.textLight),
                      const SizedBox(width: 8),
                      Text(search, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Popular Categories
          Text('Popular Categories', style: AppTextStyles.headingSmall),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildPopularCategory(Icons.eco_rounded, 'Vegetables', Colors.green),
              _buildPopularCategory(Icons.apple, 'Fruits', Colors.red),
              _buildPopularCategory(Icons.local_drink_rounded, 'Dairy', Colors.blue),
              _buildPopularCategory(Icons.breakfast_dining_rounded, 'Bakery', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCategory(IconData icon, String name, Color color) {
    return GestureDetector(
      onTap: () {
        _searchController.text = name;
        _performSearch(name);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              name,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: AppColors.textLight.withAlpha(128)),
            const SizedBox(height: 16),
            Text('No products found', style: AppTextStyles.headingSmall),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: product.backgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimensions.radiusLarge),
                  ),
                ),
                child: Icon(product.icon, size: 50, color: product.iconColor),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(product.unit, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
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
}
