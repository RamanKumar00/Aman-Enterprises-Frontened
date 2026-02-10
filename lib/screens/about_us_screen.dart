import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = packageInfo.version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: Text('About Us', style: AppTextStyles.headingSmall),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withAlpha(26),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.store_rounded,
                size: 60,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Aman Enterprises',
              style: AppTextStyles.headingMedium.copyWith(color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 8),
            Text(
              'Wholesale & Retail',
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textMedium),
            ),
            const SizedBox(height: 32),

            // Description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              ),
              child: Column(
                children: [
                   Text(
                    'Welcome to Aman Enterprises, your trusted partner for wholesale and retail shopping. We are dedicated to providing the best quality products at the most competitive prices.',
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.5, color: AppColors.textDark),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Our mission is to simplify your shopping experience by bringing a wide range of products directly to your fingertips.',
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Connect with us
             Text(
              'Connect With Us',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(Icons.facebook, Colors.blue),
                const SizedBox(width: 16),
                _buildSocialButton(Icons.camera_alt, Colors.pink), // Instagram
                const SizedBox(width: 16),
                _buildSocialButton(Icons.language, Colors.blueAccent), // Website
              ],
            ),

            const SizedBox(height: 48),
            
            // Version
            Text(
              'Version $_version',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2026 Aman Enterprises. All rights reserved.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}
