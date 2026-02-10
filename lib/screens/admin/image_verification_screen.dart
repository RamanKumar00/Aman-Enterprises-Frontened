import 'package:flutter/material.dart';
import 'package:aman_enterprises/services/asset_image_manager.dart';
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';

/// Admin screen for viewing asset coverage and image health
class ImageVerificationScreen extends StatefulWidget {
  final String token;
  
  const ImageVerificationScreen({
    super.key,
    required this.token,
  });

  @override
  State<ImageVerificationScreen> createState() => _ImageVerificationScreenState();
}

class _ImageVerificationScreenState extends State<ImageVerificationScreen> {
  bool _isLoading = true;
  AssetCoverageReport? _report;
  String _status = 'Loading...';
  List<String> _productNames = [];
  List<String> _categoryNames = [];

  @override
  void initState() {
    super.initState();
    _loadAssetCoverage();
  }

  Future<void> _loadAssetCoverage() async {
    setState(() {
      _isLoading = true;
      _status = 'Initializing asset manager...';
    });

    try {
      final assetManager = AssetImageManager();
      await assetManager.initialize();

      setState(() => _status = 'Fetching products...');
      // Fetch all products
      final productsResponse = await ApiService.getProducts();
      final products = productsResponse['products'] as List? ?? [];
      _productNames = products
          .map((p) => p['productName']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      setState(() => _status = 'Fetching categories...');
      // Fetch all categories
      final categoriesResponse = await ApiService.getCategories();
      final categories = categoriesResponse['categories'] as List? ?? [];
      _categoryNames = categories
          .map((c) => c['categoryName']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      setState(() => _status = 'Generating report...');
      // Generate coverage report
      _report = assetManager.getAssetCoverageReport(_productNames, _categoryNames);

      setState(() {
        _isLoading = false;
        _status = 'Complete';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Verification'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssetCoverage,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _report != null
              ? _buildReportView()
              : _buildErrorView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryGreen),
          const SizedBox(height: 16),
          Text(_status, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_status, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAssetCoverage,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportView() {
    final report = _report!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Products',
                  value: '${report.productsWithAssets}/${report.totalProducts}',
                  percentage: report.productCoverage,
                  icon: Icons.shopping_bag,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Categories',
                  value: '${report.categoriesWithAssets}/${report.totalCategories}',
                  percentage: report.categoryCoverage,
                  icon: Icons.category,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Missing Products
          if (report.missingProducts.isNotEmpty) ...[
            _buildSectionHeader(
              'Missing Product Images',
              Icons.warning_amber,
              Colors.orange,
              report.missingProducts.length,
            ),
            const SizedBox(height: 8),
            _buildMissingList(report.missingProducts),
          ],
          
          const SizedBox(height: 16),
          
          // Missing Categories
          if (report.missingCategories.isNotEmpty) ...[
            _buildSectionHeader(
              'Missing Category Images',
              Icons.warning_amber,
              Colors.red,
              report.missingCategories.length,
            ),
            const SizedBox(height: 8),
            _buildMissingList(report.missingCategories),
          ],
          
          const SizedBox(height: 24),
          
          // Available Assets
          _buildSectionHeader(
            'Available Product Assets',
            Icons.check_circle,
            Colors.green,
            AssetImageManager().getAvailableProductAssets().length,
          ),
          const SizedBox(height: 8),
          _buildAssetList(AssetImageManager().getAvailableProductAssets()),
          
          const SizedBox(height: 16),
          
          _buildSectionHeader(
            'Available Category Assets',
            Icons.check_circle,
            Colors.green,
            AssetImageManager().getAvailableCategoryAssets().length,
          ),
          const SizedBox(height: 8),
          _buildAssetList(AssetImageManager().getAvailableCategoryAssets()),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required double percentage,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toStringAsFixed(1)}% coverage',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, int count) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMissingList(List<String> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length > 10 ? 10 : items.length,
        separatorBuilder: (_, __) => Divider(color: Colors.orange.shade200, height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            dense: true,
            leading: const Icon(Icons.image_not_supported, color: Colors.orange, size: 20),
            title: Text(
              items[index],
              style: const TextStyle(fontSize: 14),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssetList(List<String> assets) {
    if (assets.isEmpty) {
      return const Text('No assets found', style: TextStyle(color: Colors.grey));
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: assets.length > 10 ? 10 : assets.length,
        separatorBuilder: (_, __) => Divider(color: Colors.green.shade200, height: 1),
        itemBuilder: (context, index) {
          final path = assets[index];
          final name = path.split('/').last;
          return ListTile(
            dense: true,
            leading: SizedBox(
              width: 40,
              height: 40,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  path,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(fontSize: 14),
            ),
          );
        },
      ),
    );
  }
}
