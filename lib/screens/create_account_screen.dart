import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/services/api_service.dart';
import 'package:aman_enterprises/screens/main_navigation_screen.dart';
import 'package:aman_enterprises/services/auth_service.dart';
import 'package:aman_enterprises/services/user_service.dart';
import 'package:aman_enterprises/screens/admin/admin_dashboard_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen>
    with SingleTickerProviderStateMixin {
  // Controllers for all required fields
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _adminSecretKeyController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _agreeToTerms = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Role selection
  String _selectedRole = 'Customer';
  final List<Map<String, String>> _roles = [
    {'value': 'Customer', 'label': 'Customer', 'icon': 'person'},
    {'value': 'RetailUser', 'label': 'Retailer', 'icon': 'store'},
    {'value': 'Admin', 'label': 'Admin', 'icon': 'admin_panel_settings'},
  ];

  // Scroll controller for the form
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _passwordController.dispose();

    _confirmPasswordController.dispose();
    _adminSecretKeyController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onCreateAccount() async {
    // Check if this is a customer (simple form) or business user (full form)
    final bool isCustomer = _selectedRole == 'Customer';
    
    // Validate common inputs for all roles
    if (_shopNameController.text.isEmpty) {
      _showSnackBar(isCustomer ? 'Please enter your full name' : 'Please enter your shop/business name');
      return;
    }
    
    if (_phoneController.text.isEmpty || _phoneController.text.length != 10) {
      _showSnackBar('Please enter a valid 10-digit phone number');
      return;
    }
    
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showSnackBar('Please enter a valid email address');
      return;
    }
    
    // Validate business-specific fields only for Retailer and Admin
    if (!isCustomer) {
      if (_addressController.text.isEmpty) {
        _showSnackBar('Please enter your address');
        return;
      }
      
      if (_pincodeController.text.isEmpty || _pincodeController.text.length != 6) {
        _showSnackBar('Please enter a valid 6-digit pincode');
        return;
      }
      
      if (_stateController.text.isEmpty) {
        _showSnackBar('Please enter your state');
        return;
      }
      
      if (_cityController.text.isEmpty) {
        _showSnackBar('Please enter your city');
        return;
      }
    }
    
    if (_passwordController.text.isEmpty || _passwordController.text.length < 8) {
      _showSnackBar('Password must be at least 8 characters');
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return;
    }
    
    if (!_agreeToTerms) {
      _showSnackBar('Please agree to the Terms of Service and Privacy Policy');
      return;
    }
    
    // Show loading state
    setState(() => _isLoading = true);
    
    try {
      // Debug: Print what we're sending
      debugPrint('=== SIGNUP ATTEMPT ===');
      debugPrint('Role: $_selectedRole');
      debugPrint('Shop/Name: ${_shopNameController.text.trim()}');
      debugPrint('Phone: ${_phoneController.text.trim()}');
      debugPrint('Email: ${_emailController.text.trim()}');
      debugPrint('isCustomer: $isCustomer');
      
      // Call API to register user
      // For customers, use default values for business fields
      final response = await ApiService.register(
        shopName: _shopNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: isCustomer ? 'N/A' : _addressController.text.trim(),
        pincode: isCustomer ? '000000' : _pincodeController.text.trim(),
        state: isCustomer ? 'N/A' : _stateController.text.trim(),
        city: isCustomer ? 'N/A' : _cityController.text.trim(),
        role: _selectedRole == 'Customer' ? 'RetailUser' : _selectedRole,

        password: _passwordController.text,
        adminSecretKey: _selectedRole == 'Admin' ? _adminSecretKeyController.text.trim() : null,
      );
      
      debugPrint('=== API RESPONSE ===');
      debugPrint('Success: ${response.success}');
      debugPrint('Message: ${response.message}');
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        if (response.success) {
          // Save user data if returned
          if (response.data != null) {
             final userData = response.data!['user'] ?? response.data!;
             await UserService().saveUser(userData as Map<String, dynamic>);
          }
          
          _showSuccessDialog();
        } else {
          _showSnackBar(response.message);
        }
      }
    } catch (e) {
      debugPrint('=== ERROR ===');
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: message.contains('Please') || message.contains('Password') 
            ? Colors.red.shade600 
            : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        margin: const EdgeInsets.all(AppDimensions.paddingMedium),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreenLight.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primaryGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Account Created!',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 12),
              
              Text(
                'Your account has been successfully created. Start shopping for fresh groceries now!',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    
                    // No longer redirecting to LocationScreen on first login
                    // Location will be requested when user proceeds to checkout
                    Widget targetScreen = _selectedRole == 'Admin'
                        ? const AdminDashboardScreen()
                        : const MainNavigationScreen();
                        
                    // Navigate to appropriate screen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => targetScreen,
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                    ),
                  ),
                  child: Text(
                    'Start Shopping',
                    style: AppTextStyles.buttonText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppDimensions.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 32),
                
                // Form Fields
                _buildFormFields(),
                const SizedBox(height: 24),
                
                // Terms Checkbox
                _buildTermsCheckbox(),
                const SizedBox(height: 32),
                
                // Create Account Button
                _buildCreateAccountButton(),
                const SizedBox(height: 24),
                
                // Google Sign Up
                _buildGoogleButton(),
                const SizedBox(height: 24),
                
                // Login Link
                _buildLoginLink(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: 20,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text(
        'Aman Enterprises',
        style: AppTextStyles.headingSmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Account',
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Fresh groceries delivered to your doorstep in minutes.',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    final bool isCustomer = _selectedRole == 'Customer';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Role Selection - FIRST (so user chooses before filling form)
        _buildSectionHeader('Account Type', Icons.person_add_rounded),
        const SizedBox(height: 16),
        _buildInputLabel('I am signing up as *'),
        const SizedBox(height: 8),
        _buildRoleDropdown(),
        const SizedBox(height: 24),

        // Secret Key for Admin
        if (_selectedRole == 'Admin') ...[
          _buildInputLabel('Admin Secret Key *'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _adminSecretKeyController,
            hintText: 'Enter admin secret key',
            prefixIcon: Icons.security_rounded,
            obscureText: true,
          ),
          const SizedBox(height: 20),
        ],
        
        // Section: Personal/Business Details (changes based on role)
        _buildSectionHeader(
          isCustomer ? 'Personal Details' : 'Business Details', 
          isCustomer ? Icons.person_rounded : Icons.store_rounded,
        ),
        const SizedBox(height: 16),
        
        // Name field (label changes based on role)
        _buildInputLabel(isCustomer ? 'Full Name *' : 'Shop / Business Name *'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _shopNameController,
          hintText: isCustomer ? 'Enter your full name' : 'Enter your shop name',
          prefixIcon: isCustomer ? Icons.person_outlined : Icons.storefront_rounded,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 20),
        
        // Section: Contact Details
        _buildSectionHeader('Contact Details', Icons.contact_phone_rounded),
        const SizedBox(height: 16),
        
        // Phone Number
        _buildInputLabel('Phone Number *'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _phoneController,
          hintText: '10-digit phone number',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        const SizedBox(height: 20),
        
        // Email Address
        _buildInputLabel('Email Address *'),
        const SizedBox(height: 8),
        _buildTextField(
          controller: _emailController,
          hintText: 'example@email.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        
        // Address Section - Only for Retailer and Admin
        if (!isCustomer) ...[
          // Section: Address Details
          _buildSectionHeader('Address Details', Icons.location_on_rounded),
          const SizedBox(height: 16),
          
          // Full Address
          _buildInputLabel('Full Address *'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _addressController,
            hintText: 'Street address, building, etc.',
            prefixIcon: Icons.home_outlined,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          
          // City and State Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('City *'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _cityController,
                      hintText: 'City',
                      prefixIcon: Icons.location_city_rounded,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputLabel('State *'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _stateController,
                      hintText: 'State',
                      prefixIcon: Icons.map_rounded,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Pincode
          _buildInputLabel('Pincode *'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _pincodeController,
            hintText: '6-digit pincode',
            prefixIcon: Icons.pin_drop_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          const SizedBox(height: 20),
        ],
        
        // Section: Account Security
        _buildSectionHeader('Set Password', Icons.lock_rounded),
        const SizedBox(height: 16),
        
        // Password
        _buildInputLabel('Password *'),
        const SizedBox(height: 8),
        _buildPasswordField(
          controller: _passwordController,
          hintText: 'Minimum 8 characters',
          obscureText: _obscurePassword,
          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 20),
        
        // Confirm Password
        _buildInputLabel('Confirm Password *'),
        const SizedBox(height: 8),
        _buildPasswordField(
          controller: _confirmPasswordController,
          hintText: 'Re-enter your password',
          obscureText: _obscureConfirmPassword,
          onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withAlpha(25),
            AppColors.primaryGreen.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.primaryGreen.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryGreen,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w500,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool obscureText = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCream.withAlpha(128),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border.withAlpha(128)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        obscureText: obscureText,
        style: AppTextStyles.inputText.copyWith(
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.hintText.copyWith(
            color: AppColors.textLight,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              prefixIcon,
              color: AppColors.primaryGreen,
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 54,
            minHeight: 54,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCream.withAlpha(128),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border.withAlpha(128)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: AppTextStyles.inputText.copyWith(
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.hintText.copyWith(
            color: AppColors.textLight,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primaryGreen,
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 54,
            minHeight: 54,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.textLight,
              size: 22,
            ),
            onPressed: onToggleVisibility,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCream.withAlpha(128),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border.withAlpha(128)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primaryGreen,
          ),
          style: AppTextStyles.inputText.copyWith(
            color: AppColors.textDark,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          items: _roles.map((role) {
            IconData iconData;
            switch (role['icon']) {
              case 'store':
                iconData = Icons.store_rounded;
                break;
              case 'admin_panel_settings':
                iconData = Icons.admin_panel_settings_rounded;
                break;
              default:
                iconData = Icons.person_rounded;
            }
            
            return DropdownMenuItem<String>(
              value: role['value'],
              child: Row(
                children: [
                  Icon(
                    iconData,
                    color: AppColors.primaryGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(role['label']!),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => _selectedRole = newValue);
            }
          },
        ),
      ),
    );
  }


  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Custom Checkbox
        GestureDetector(
          onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _agreeToTerms 
                  ? AppColors.primaryGreen 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _agreeToTerms 
                    ? AppColors.primaryGreen 
                    : AppColors.textLight,
                width: 2,
              ),
            ),
            child: _agreeToTerms
                ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        
        // Terms Text
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodyMedium,
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: AppTextStyles.bodyMedium.copyWith(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: AppTextStyles.bodyMedium.copyWith(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton() {
    return Container(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreenLight,
            AppColors.primaryGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withAlpha(102),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onCreateAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create Account',
                    style: AppTextStyles.buttonText,
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account?  ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          GestureDetector(
            onTap: _navigateToLogin,
            child: Text(
              'Login',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
  


  void _onGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    final response = await AuthService.signInWithGoogle();
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      if (response.success) {
        // Save user data
        if (response.data != null) {
           await UserService().saveUser(response.data!);
           if (!mounted) return;
        }

        _showSnackBar('Account created with Google!');
        // Navigate to home screen
         Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainNavigationScreen(),
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
        _showSnackBar(response.message);
        if (response.message.contains('Sign in cancelled')) {
          return;
        }
      }
    }
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _onGoogleSignIn,
      child: Container(
        width: double.infinity,
        height: AppDimensions.buttonHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
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
                  return const Icon(
                    Icons.g_mobiledata_rounded, // Fallback icon
                    color: Colors.blue, 
                    size: 24
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign up with Google',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
