import 'package:flutter/material.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I place an order?',
      'answer': 'Browse products, add items to cart, proceed to checkout, select delivery address and payment method, then confirm your order.',
      'isExpanded': false,
    },
    {
      'question': 'What are the delivery timings?',
      'answer': 'We deliver from 8:00 AM to 10:00 PM every day. Express delivery is available within 30 minutes for selected areas.',
      'isExpanded': false,
    },
    {
      'question': 'How can I track my order?',
      'answer': 'Go to My Orders, select the order you want to track, and you\'ll see real-time updates with delivery partner details.',
      'isExpanded': false,
    },
    {
      'question': 'What payment methods are accepted?',
      'answer': 'We accept Cash on Delivery, UPI (GPay, PhonePe, Paytm), Credit/Debit Cards, and Net Banking.',
      'isExpanded': false,
    },
    {
      'question': 'How do I cancel an order?',
      'answer': 'You can cancel your order before it\'s dispatched from My Orders section. Refund will be processed within 5-7 business days.',
      'isExpanded': false,
    },
    {
      'question': 'What is the return policy?',
      'answer': 'We accept returns for damaged or incorrect items within 24 hours of delivery. Contact support with photos of the issue.',
      'isExpanded': false,
    },
  ];

  final List<Map<String, dynamic>> _contactOptions = [
    {
      'icon': Icons.phone_rounded,
      'title': 'Call Us',
      'subtitle': '+91 1800-123-4567',
      'color': Colors.green,
    },
    {
      'icon': Icons.email_rounded,
      'title': 'Email Us',
      'subtitle': 'support@amanenterprises.com',
      'color': Colors.blue,
    },
    {
      'icon': Icons.chat_rounded,
      'title': 'Live Chat',
      'subtitle': 'Chat with our support team',
      'color': Colors.purple,
    },
    {
      'icon': Icons.headset_mic_rounded,
      'title': 'Request Callback',
      'subtitle': 'We\'ll call you back',
      'color': Colors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text('Help & Support', style: AppTextStyles.headingSmall),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Help Banner
            _buildHelpBanner(),

            // Quick Actions
            _buildQuickActions(),

            // FAQs Section
            _buildFAQSection(),

            // Contact Us Section
            _buildContactSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreenLight, AppColors.primaryGreen],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help?',
                  style: AppTextStyles.headingSmall.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'re here to help you 24/7',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withAlpha(204)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              Icons.receipt_long_rounded,
              'Order Issues',
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              Icons.payment_rounded,
              'Payment Help',
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              Icons.local_shipping_rounded,
              'Delivery Help',
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label selected')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Frequently Asked Questions', style: AppTextStyles.headingSmall),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
            ),
            child: Column(
              children: List.generate(_faqs.length, (index) {
                final faq = _faqs[index];
                final isLast = index == _faqs.length - 1;

                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _faqs[index]['isExpanded'] = !_faqs[index]['isExpanded'];
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                faq['question'] as String,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: faq['isExpanded'] ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox(width: double.infinity),
                      secondChild: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faq['answer'] as String,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMedium,
                            height: 1.5,
                          ),
                        ),
                      ),
                      crossFadeState: faq['isExpanded']
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                    if (!isLast) const Divider(height: 1),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contact Us', style: AppTextStyles.headingSmall),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _contactOptions.length,
            itemBuilder: (context, index) {
              final option = _contactOptions[index];
              return GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${option['title']} selected')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (option['color'] as Color).withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          option['icon'] as IconData,
                          color: option['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        option['title'] as String,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        option['subtitle'] as String,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textLight,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
