import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/models/product_model.dart';
import 'package:aman_enterprises/services/cart_service.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:aman_enterprises/services/review_service.dart';
import 'package:aman_enterprises/screens/cart_screen.dart';
import 'package:aman_enterprises/widgets/review_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  final CartService _cartService = CartService();
  int _quantity = 1;
  bool _isFavorite = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  // Define these variables here
  bool _isRetailer = false;
  int _minQty = 1;
  
  // Review state
  List<dynamic> _reviews = [];
  Map<String, dynamic>? _ratingStats;
  bool _isLoadingReviews = true;
  bool _canReview = false;
  String? _eligibleOrderId;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.product.isFavorite;
    
    // Check if user is Retailer using the helper method
    final userService = UserService(); 
    _isRetailer = userService.isRetailer;
    
    // Set quantity defaults based on role:
    // - Customers (B2C): Start from 0, user chooses their quantity
    // - Retailers (B2B): Start from pack size (min 6), must be multiples
    if (_isRetailer) {
      _minQty = widget.product.b2bMinQty ?? 6;
      _quantity = _minQty; // Retailers start at minimum pack size
    } else {
      _minQty = 0; // Customers can go to 0
      _quantity = 0; // Customers start from 0 - they choose their quantity
    }

    _animationController = AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Load reviews
    _loadReviews();
    _checkCanReview();
  }
  
  Future<void> _loadReviews() async {
    final response = await ReviewService.getProductReviews(
      productId: widget.product.id,
      limit: 3,
    );
    
    if (mounted) {
      setState(() {
        _isLoadingReviews = false;
        if (response.success) {
          _reviews = response.data?['reviews'] ?? [];
          _ratingStats = response.data?['ratingStats'];
        }
      });
    }
  }
  
  Future<void> _checkCanReview() async {
    if (UserService().authToken == null) return;
    
    final response = await ReviewService.canReviewProduct(widget.product.id);
    if (mounted && response.success) {
      setState(() {
        _canReview = response.data?['canReview'] ?? false;
        _eligibleOrderId = response.data?['orderId'];
      });
    }
  }
  
  void _showWriteReviewSheet() {
    if (!_canReview || _eligibleOrderId == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WriteReviewBottomSheet(
        productId: widget.product.id,
        orderId: _eligibleOrderId!,
        productName: widget.product.name,
        onReviewSubmitted: (success) {
          if (success) {
            _loadReviews();
            _checkCanReview();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  void _updateQuantity(int change) {
    setState(() {
      int step = 1;
      if (_isRetailer) {
        step = widget.product.b2bMinQty ?? 6;
      }
      
      // Calculate new quantity
      int newQuantity = _quantity + (change * step);
      
      // Enforce minimums
      if (_isRetailer) {
         // Retailers cannot go below pack size
         if (newQuantity < _minQty) newQuantity = _minQty;
      } else {
         // Customers can go down to 0
         if (newQuantity < 0) newQuantity = 0;
      }
      
      _quantity = newQuantity;
    });
  }

  void _addToCart() {
    _cartService.addToCart(widget.product, quantity: _quantity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$_quantity x ${widget.product.name} added to cart',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CartScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Product Image Section
                SliverToBoxAdapter(child: _buildImageSection()),
                
                // Product Details
                SliverToBoxAdapter(child: _buildDetailsSection()),
                
                // Description
                SliverToBoxAdapter(child: _buildDescriptionSection()),
                
                // Reviews
                SliverToBoxAdapter(child: _buildReviewsSection()),
                
                // Related Products
                SliverToBoxAdapter(child: _buildRelatedSection()),
                
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          
          // Bottom Bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Product Image
        Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.product.backgroundColor,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(40),
            ),
          ),
          child: Hero(
            tag: 'product_${widget.product.id}',
            child: widget.product.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.product.imageUrl!,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(widget.product.iconColor),
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      widget.product.icon,
                      size: 150,
                      color: widget.product.iconColor,
                    ),
                  )
                : Icon(
                    widget.product.icon,
                    size: 150,
                    color: widget.product.iconColor,
                  ),
          ),
        ),
        
        // Discount Badge
        if (widget.product.discount > 0)
          Positioned(
            top: 100,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
              ),
              child: Text(
                '${widget.product.discount}% OFF',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        
        // Top Bar
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                  ),
                ),
              ),
              
              // Favorite Button
              GestureDetector(
                onTap: _toggleFavorite,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : AppColors.textMedium,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category & Stock
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withAlpha(26),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                ),
                child: Text(
                  widget.product.category,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (widget.product.inStock)
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'In Stock',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Out of Stock',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 12),
          
          // Product Name
          Text(
            widget.product.name,
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.product.unit,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          
          // Rating
          Row(
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < widget.product.rating.floor()
                      ? Icons.star_rounded
                      : (index < widget.product.rating
                          ? Icons.star_half_rounded
                          : Icons.star_outline_rounded),
                  color: Colors.amber,
                  size: 20,
                );
              }),
              const SizedBox(width: 8),
              Text(
                '${widget.product.rating}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' (${widget.product.reviewCount} reviews)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Price & Quantity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   if (_isRetailer)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.shade200)
                        ),
                        child: Text(
                          "B2B: Min $_minQty Qty", 
                          style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.bold)
                        ),
                      ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${(_isRetailer && widget.product.b2bPrice != null ? widget.product.b2bPrice : widget.product.price)!.toStringAsFixed(0)}',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (!_isRetailer && widget.product.originalPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₹${widget.product.originalPrice!.toStringAsFixed(0)}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textLight,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    'per ${widget.product.unit}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              
              // Quantity Selector
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundCream,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded),
                      iconSize: 20,
                      color: _quantity > 0 ? AppColors.textMedium : Colors.grey.shade300,
                      onPressed: _quantity > 0 ? () => _updateQuantity(-1) : null,
                    ),
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '$_quantity',
                        style: AppTextStyles.headingSmall.copyWith(
                          color: _quantity == 0 ? AppColors.textLight : AppColors.textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded),
                      iconSize: 20,
                      color: AppColors.primaryGreen,
                      onPressed: () => _updateQuantity(1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Subscription Option (New - Enhanced Visibility)
          GestureDetector(
            onTap: _showSubscriptionDialog,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4), // Add margin for shadow
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryGreen, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: AppColors.primaryGreen.withValues(alpha: 0.1),
                       shape: BoxShape.circle,
                     ),
                     child: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryGreen, size: 28),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text("Subscribe & Save", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87)),
                         const SizedBox(height: 4),
                         Text("Get daily deliveries for 7/15/30 days", style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                       ],
                     ),
                   ),
                   const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.primaryGreen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog() {
    int duration = 7;
    double totalCost = widget.product.price * _quantity * duration;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          totalCost = widget.product.price * _quantity * duration;
          
          return AlertDialog(
            title: const Text("Setup Subscription"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Product: ${widget.product.name} (x$_quantity)"),
                const SizedBox(height: 16),
                const Text("Select Duration:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [7, 15, 30].map((d) => 
                     Padding(
                       padding: const EdgeInsets.only(right: 8.0),
                       child: ChoiceChip(
                         label: Text("$d Days"),
                         selected: duration == d,
                         onSelected: (val) => setDialogState(() => duration = d),
                         selectedColor: AppColors.primaryGreen.withAlpha(50),
                         labelStyle: TextStyle(color: duration == d ? AppColors.primaryGreen : Colors.black),
                       ),
                     )
                  ).toList(),
                ),
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Advance Pay:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("₹${totalCost.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryGreen)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text("Daily delivery starts tomorrow.", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  
                  const String phoneNumber = "919097037320"; 
                  final String message = "Hello, I want to start a subscription for:\n"
                                         "Product: ${widget.product.name}\n"
                                         "Quantity: $_quantity\n"
                                         "Duration: $duration Days\n"
                                         "Total Amount: ₹${totalCost.toStringAsFixed(0)}\n"
                                         "Please send me the payment link.";
                  
                  final Uri url = Uri.parse("whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}");
                  final Uri webUrl = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

                  try {
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else if (await canLaunchUrl(webUrl)) {
                      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
                    } else {
                       if (!context.mounted) return;
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Could not launch WhatsApp')),
                       );
                    }
                  } catch (e) {
                    debugPrint("Error launching WhatsApp: $e");
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                child: const Text("Proceed to Pay via WhatsApp"),
              )
            ],
          );
        }
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 12),
          Text(
            widget.product.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          
          // Tags
          if (widget.product.tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.product.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                  ),
                  child: Text(
                    tag,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Write Review button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ratings & Reviews',
                style: AppTextStyles.headingSmall,
              ),
              if (_canReview)
                TextButton.icon(
                  onPressed: _showWriteReviewSheet,
                  icon: const Icon(Icons.rate_review, size: 16),
                  label: const Text('Write Review'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Rating Summary
          if (_ratingStats != null && (_ratingStats!['totalReviews'] ?? 0) > 0) ...[
            RatingSummary(
              averageRating: (_ratingStats!['averageRating'] ?? 0).toDouble(),
              totalReviews: _ratingStats!['totalReviews'] ?? 0,
              distribution: Map<int, int>.from(
                (_ratingStats!['ratingDistribution'] as Map? ?? {})
                    .map((k, v) => MapEntry(int.parse(k.toString()), v as int)),
              ),
            ),
            const SizedBox(height: 20),
          ] else if (!_isLoadingReviews) ...[
            // No reviews yet
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.backgroundCream,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              ),
              child: Column(
                children: [
                  Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No reviews yet',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be the first to review this product!',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                  ),
                  if (_canReview) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showWriteReviewSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Write a Review', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          // Reviews List
          if (_isLoadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
            )
          else if (_reviews.isNotEmpty) ...[
            const Text(
              'Recent Reviews',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ..._reviews.map((review) => ReviewCard(
              review: review as Map<String, dynamic>,
              onHelpfulPressed: () => _loadReviews(),
            )),
            if ((_ratingStats?['totalReviews'] ?? 0) > 3)
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Navigate to all reviews screen
                  },
                  child: Text(
                    'See all ${_ratingStats?['totalReviews']} reviews',
                    style: const TextStyle(color: AppColors.primaryGreen),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedSection() {
    final relatedProducts = Product.sampleProducts
        .where((p) => p.id != widget.product.id && p.category == widget.product.category)
        .take(4)
        .toList();

    if (relatedProducts.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You May Also Like',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: relatedProducts.length,
              itemBuilder: (context, index) {
                final product = relatedProducts[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
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
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: product.backgroundColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppDimensions.radiusLarge),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              product.icon,
                              size: 40,
                              color: product.iconColor,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Text(
                              product.name,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '₹${product.price.toStringAsFixed(0)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildBottomBar() {
    final totalPrice = widget.product.price * _quantity;
    
    // Check if button should be enabled
    final bool canAddToCart = widget.product.inStock && _quantity > 0;
    final String buttonText = !widget.product.inStock 
        ? 'Out of Stock' 
        : _quantity == 0 
            ? 'Select Quantity First' 
            : 'Add to Cart';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total Price
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _quantity == 0 ? 'Select Qty' : 'Total Price',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textLight,
                ),
              ),
              Text(
                _quantity == 0 ? '₹0' : '₹${totalPrice.toStringAsFixed(0)}',
                style: AppTextStyles.headingSmall.copyWith(
                  color: _quantity == 0 ? AppColors.textLight : AppColors.primaryGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          
          // Add to Cart Button
          Expanded(
            child: Container(
              height: AppDimensions.buttonHeight,
              decoration: BoxDecoration(
                gradient: canAddToCart 
                    ? const LinearGradient(
                        colors: [AppColors.primaryGreenLight, AppColors.primaryGreen],
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade300, Colors.grey.shade400],
                      ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                boxShadow: canAddToCart ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withAlpha(102),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ] : [],
              ),
              child: ElevatedButton(
                onPressed: canAddToCart ? _addToCart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _quantity == 0 ? Icons.touch_app_outlined : Icons.shopping_cart_outlined,
                      color: canAddToCart ? Colors.white : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        buttonText,
                        style: AppTextStyles.buttonText.copyWith(
                          color: canAddToCart ? Colors.white : Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
