import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/models/recipe_model.dart';
import 'package:aman_enterprises/models/product_model.dart';
import 'package:aman_enterprises/services/cart_service.dart';
import 'package:aman_enterprises/screens/product_details_screen.dart';
import 'package:aman_enterprises/screens/cart_screen.dart';

class RecipeDetailsScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailsScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    // Determine needed products
    final neededProducts = Product.sampleProducts
        .where((p) => recipe.ingredientProductIds.contains(p.id))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStats(),
                  const SizedBox(height: 24),
                  Text('Ingredients', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),
                  _buildIngredientsList(context, neededProducts),
                  const SizedBox(height: 24),
                  Text('Instructions', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),
                  _buildInstructionsList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, neededProducts),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              recipe.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                recipe.name,
                style: AppTextStyles.headingLarge.copyWith(fontSize: 24),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    recipe.rating.toString(),
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          recipe.description,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(Icons.timer_outlined, '${recipe.cookingTimeMinutes} mins', 'Cooking Time'),
        _buildStatItem(Icons.local_fire_department_outlined, '${recipe.calorieCount} kcal', 'Calories'),
        _buildStatItem(Icons.bar_chart_rounded, recipe.difficulty, 'Difficulty'),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildIngredientsList(BuildContext context, List<Product> neededProducts) {
    if (neededProducts.isEmpty) {
        return const Text('Ingredients not available in store.');
    }

    return Column(
      children: neededProducts.map((product) {
        return GestureDetector(
          onTap: () {
             Navigator.push(
               context,
               MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
             );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: product.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(
                     product.imageUrl ?? '',
                     errorBuilder: (context, error, stackTrace) => Icon(product.icon, color: product.iconColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(product.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                       Text('₹${product.price.toStringAsFixed(0)} / ${product.unit}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primaryGreen),
                  onPressed: () {
                     CartService().addToCart(product);
                     ScaffoldMessenger.of(context).hideCurrentSnackBar();
                     ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart'),
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'VIEW CART',
                            textColor: Colors.tealAccent, // Default snackbar is dark, so text color needs to be visible. Or primaryGreen?
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                          ),
                        ),
                     );
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInstructionsList() {
    return Column(
      children: recipe.instructions.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${entry.key + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.value,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(BuildContext context, List<Product> neededProducts) {
      if (neededProducts.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
             BoxShadow(
               color: Colors.black.withValues(alpha: 0.05),
               blurRadius: 10,
               offset: const Offset(0, -5),
             ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
               for (var product in neededProducts) {
                 CartService().addToCart(product);
               }
               ScaffoldMessenger.of(context).hideCurrentSnackBar();
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: Text('All ${neededProducts.length} ingredients added to cart!'),
                   backgroundColor: AppColors.primaryGreen,
                   duration: const Duration(seconds: 2),
                   action: SnackBarAction(
                     label: 'VIEW CART',
                     textColor: Colors.white,
                     onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
                   ),
                 ),
               );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Add All Ingredients to Cart',
              style: AppTextStyles.buttonText.copyWith(color: Colors.white),
            ),
          ),
        ),
      );
  }
}
