import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/screens/admin/bulk_upload_screen.dart';
import 'package:aman_enterprises/screens/admin/bulk_price_update_screen.dart';
import 'package:aman_enterprises/screens/admin/bulk_stock_update_screen.dart';

class BulkOperationsScreen extends StatelessWidget {
  const BulkOperationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Bulk Operations'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryGreen, AppColors.primaryGreen.withAlpha(200)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.upload_file, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulk Product Management',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage products efficiently using Excel/CSV files',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bulk Upload Section
            Text('Upload Products', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            _buildOperationCard(
              context,
              title: 'Bulk Upload Products',
              subtitle: 'Upload multiple products from Excel/CSV file',
              icon: Icons.cloud_upload_rounded,
              color: Colors.blue,
              features: [
                'Upload .xlsx, .xls, or .csv files',
                'Validate data before upload',
                'Preview and edit before saving',
                'Download sample template',
              ],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BulkUploadScreen()),
              ),
            ),

            const SizedBox(height: 24),

            // Price Update Section
            Text('Price Management', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            _buildOperationCard(
              context,
              title: 'Bulk Price Update',
              subtitle: 'Update prices for multiple products at once',
              icon: Icons.price_change_rounded,
              color: Colors.green,
              features: [
                'Update by percentage or fixed amount',
                'Filter by category',
                'Preview changes before applying',
                'Update MRP, Selling Price, or B2B Price',
              ],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BulkPriceUpdateScreen()),
              ),
            ),

            const SizedBox(height: 24),

            // Stock Update Section
            Text('Stock Management', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            _buildOperationCard(
              context,
              title: 'Bulk Stock Update',
              subtitle: 'Manage stock levels efficiently',
              icon: Icons.inventory_2_rounded,
              color: Colors.orange,
              features: [
                'Upload stock update file',
                'Manual bulk stock adjustment',
                'Add, reduce, or replace stock',
                'Low stock alerts',
              ],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BulkStockUpdateScreen()),
              ),
            ),

            const SizedBox(height: 24),

            // Tips Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for Best Results',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip('Always download and use the sample template'),
                  _buildTip('Review all data in preview before uploading'),
                  _buildTip('Keep a backup of your existing product data'),
                  _buildTip('Ensure product names are unique'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: features.map((feature) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(13),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        feature,
                        style: TextStyle(fontSize: 11, color: color),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_right, size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
