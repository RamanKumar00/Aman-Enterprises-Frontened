import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/screens/create_account_screen.dart';
import 'package:aman_enterprises/screens/main_navigation_screen.dart';
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/widgets/custom_button.dart';
import 'package:aman_enterprises/services/auth_service.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:aman_enterprises/screens/admin/admin_dashboard_screen.dart';
import 'package:aman_enterprises/screens/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardOpacityAnimation;
  late Animation<double> _headerOpacityAnimation;
  
  String _selectedCountryCode = '+91';
  String _selectedCountryFlag = '🇮🇳';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _headerOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    
    _cardSlideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    
    _cardOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    // Validate phone number
    if (_phoneController.text.isEmpty) {
      _showSnackBar('Please enter your phone number', isError: true);
      return;
    }
    
    if (_phoneController.text.length < 10) {
      _showSnackBar('Please enter a valid 10-digit phone number', isError: true);
      return;
    }
    
    // Validate password
    if (_passwordController.text.isEmpty) {
      _showSnackBar('Please enter your password', isError: true);
      return;
    }
    
    // Show loading state
    setState(() => _isLoading = true);
    
    // Call API to login
    final response = await ApiService.login(
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );
    
    setState(() => _isLoading = false);
    


    if (mounted) {
      if (response.success) {
        // Default navigation - Go to main screen
        // Location permission will be requested only when user places an order
        Widget targetScreen = const MainNavigationScreen();
        
        // Save user and check role
        if (response.data != null) {
           final userData = response.data!['user'] ?? response.data!;
           await UserService().saveUser(
             userData as Map<String, dynamic>,
             token: response.token,
           );
           if (!mounted) return;
           
           final role = (userData['role'] ?? 'user').toString().toLowerCase();
           
           if (role == 'admin') {
             targetScreen = const AdminDashboardScreen();
           }
           // No longer redirecting to LocationScreen on first login
           // Location will be requested when user proceeds to checkout
        }
        
        _showSnackBar('Login successful!', isError: false);
        // Navigate
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
                
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
          (route) => false,
        );
      } else {
        _showSnackBar(response.message, isError: true);
      }
    }
  }

  void _onGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    final response = await AuthService.signInWithGoogle();
    if (!mounted) return;
      
    setState(() => _isLoading = false);
    
    if (mounted) {
      if (response.success) {
        // Save user data
        if (response.data != null) {
           await UserService().saveUser(response.data!);
           if (!mounted) return;
           if (!mounted) return;
         }
        
        _showSnackBar('Google Sign-In successful!', isError: false);
        
        // Check if address exists
        // No longer redirecting to LocationScreen - location requested at checkout
        Widget targetScreen = const MainNavigationScreen();

        // Navigate to home screen or location screen
         Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
          (route) => false,
        );
      } else {
        _showSnackBar(response.message, isError: true);
        if (response.message.contains('Sign in cancelled')) {
          // No need to show error if cancelled
          return;
        }
      }
    }
  }

  void _onCreateAccount() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CreateAccountScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _onForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red.shade600 : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXLarge),
        ),
      ),
      builder: (context) => _buildCountryPickerSheet(),
    );
  }

  Widget _buildCountryPickerSheet() {
    final countries = [
      {'code': '+91', 'flag': '🇮🇳', 'name': 'India'},
      {'code': '+1', 'flag': '🇺🇸', 'name': 'United States'},
      {'code': '+44', 'flag': '🇬🇧', 'name': 'United Kingdom'},
      {'code': '+61', 'flag': '🇦🇺', 'name': 'Australia'},
      {'code': '+971', 'flag': '🇦🇪', 'name': 'UAE'},
      {'code': '+65', 'flag': '🇸🇬', 'name': 'Singapore'},
    ];
    
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
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
          Text('Select Country', style: AppTextStyles.headingSmall),
          const SizedBox(height: 16),
          ...countries.map((country) => ListTile(
            leading: Text(country['flag']!, style: const TextStyle(fontSize: 28)),
            title: Text(country['name']!, style: AppTextStyles.bodyLarge),
            trailing: Text(
              country['code']!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textLight,
              ),
            ),
            onTap: () {
              setState(() {
                _selectedCountryCode = country['code']!;
                _selectedCountryFlag = country['flag']!;
              });
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _headerOpacityAnimation.value,
              child: Text(
                'Login',
                style: AppTextStyles.headingSmall,
              ),
            );
          },
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLarge,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Header with Logo
                  Opacity(
                    opacity: _headerOpacityAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _headerOpacityAnimation.value)),
                      child: _buildHeader(),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Login Card
                  Transform.translate(
                    offset: Offset(0, _cardSlideAnimation.value),
                    child: Opacity(
                      opacity: _cardOpacityAnimation.value,
                      child: _buildLoginCard(),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Terms & Privacy
                  Opacity(
                    opacity: _cardOpacityAnimation.value,
                    child: _buildTermsText(),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primaryGreenLight.withAlpha(77),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          ),
          child: const Icon(
            Icons.shopping_bag_rounded,
            size: 56,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 24),
        
        // Title
        Text(
          'Aman Enterprises',
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        
        // Subtitle
        Text(
          'Fresh groceries delivered in 10 minutes',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Text
          Text(
            'Welcome Back!',
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your phone number and password to login',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          
          // Phone Input Row
          Row(
            children: [
              // Country Label
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('COUNTRY', style: AppTextStyles.labelText),
                    const SizedBox(height: 8),
                    _buildCountrySelector(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Phone Number
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PHONE NUMBER', style: AppTextStyles.labelText),
                    const SizedBox(height: 8),
                    _buildPhoneInput(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Password Field
          Text('PASSWORD', style: AppTextStyles.labelText),
          const SizedBox(height: 8),
          _buildPasswordInput(),
          const SizedBox(height: 12),
          
          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _onForgotPassword,
              child: Text(
                'Forgot Password?',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Login Button
          CustomButton(
            text: _isLoading ? 'Logging in...' : 'Login',
            onPressed: _isLoading ? null : _onLogin,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),
          
          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or connect with',
                  style: AppTextStyles.bodySmall,
                ),
              ),
              Expanded(child: Divider(color: AppColors.divider)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Google Button
          _buildSocialButton(
            icon: _buildGoogleIcon(),
            text: 'Continue with Google',
            onTap: _onGoogleSignIn,
            hasBorder: true,
          ),
          const SizedBox(height: 24),
          
          // Create Account Link
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Don\'t have an account?  ',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
                GestureDetector(
                  onTap: _onCreateAccount,
                  child: Text(
                    'Sign Up',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountrySelector() {
    return GestureDetector(
      onTap: _showCountryPicker,
      child: Container(
        height: AppDimensions.inputHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_selectedCountryFlag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _selectedCountryCode,
                style: AppTextStyles.inputText.copyWith(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textLight,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      height: AppDimensions.inputHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        style: AppTextStyles.inputText,
        decoration: InputDecoration(
          hintText: '00000 00000',
          hintStyle: AppTextStyles.hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordInput() {
    return Container(
      height: AppDimensions.inputHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: AppTextStyles.inputText,
        decoration: InputDecoration(
          hintText: 'Enter your password',
          hintStyle: AppTextStyles.hintText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.textLight,
              size: 22,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required String text,
    required VoidCallback onTap,
    bool hasBorder = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: AppDimensions.buttonHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          border: hasBorder ? Border.all(color: AppColors.border) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              text,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Image.network(
        'https://www.google.com/favicon.ico',
        width: 24,
        height: 24,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                'G',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTermsText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppTextStyles.bodySmall,
          children: [
            const TextSpan(text: 'By continuing, you agree to Aman Enterprises\' '),
            TextSpan(
              text: 'Terms of Service',
              style: AppTextStyles.bodySmall.copyWith(
                decoration: TextDecoration.underline,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: AppTextStyles.bodySmall.copyWith(
                decoration: TextDecoration.underline,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
