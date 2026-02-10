import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:aman_enterprises/core/theme/app_theme.dart';
import 'package:aman_enterprises/screens/main_navigation_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _resendSeconds = 30;
  Timer? _resendTimer;
  bool _isVerifying = false;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startResendTimer();
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
    
    _animationController.forward();
  }

  void _startResendTimer() {
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _animationController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _onOTPDigitChanged(String value, int index) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Check if all digits are entered
    if (_otpControllers.every((c) => c.text.isNotEmpty)) {
      _verifyOTP();
    }
  }


  void _verifyOTP() async {
    
    setState(() => _isVerifying = true);
    
    // Simulate OTP verification
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isVerifying = false);
    
    if (mounted) {
      // Navigate to home
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const MainNavigationScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
        (route) => false,
      );
    }
  }

  void _resendOTP() {
    if (!_canResend) return;
    
    setState(() {
      _resendSeconds = 30;
      _canResend = false;
    });
    
    _startResendTimer();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'OTP resent to ${widget.countryCode} ${widget.phoneNumber}',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Verification',
          style: AppTextStyles.headingSmall,
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // OTP Icon
              _buildOTPIcon(),
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Enter Verification Code',
                style: AppTextStyles.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                'We have sent a verification code to',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.countryCode} ${widget.phoneNumber}',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // OTP Input Fields
              _buildOTPFields(),
              const SizedBox(height: 32),
              
              // Verify Button
              _buildVerifyButton(),
              const SizedBox(height: 24),
              
              // Resend Timer
              _buildResendSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.primaryGreenLight.withAlpha(51),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.sms_outlined,
        size: 48,
        color: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildOTPFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          width: 65,
          height: 65,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _otpControllers[index].text.isNotEmpty
                ? AppColors.primaryGreen.withAlpha(26)
                : AppColors.backgroundCream,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(
              color: _focusNodes[index].hasFocus
                  ? AppColors.primaryGreen
                  : AppColors.border,
              width: _focusNodes[index].hasFocus ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.primaryGreen,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
            onChanged: (value) => _onOTPDigitChanged(value, index),
            onTap: () => setState(() {}),
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton() {
    final isComplete = _otpControllers.every((c) => c.text.isNotEmpty);
    
    return Container(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isComplete
              ? [AppColors.primaryGreenLight, AppColors.primaryGreen]
              : [AppColors.border, AppColors.border],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
        boxShadow: isComplete
            ? [
                BoxShadow(
                  color: AppColors.primaryGreen.withAlpha(102),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isComplete && !_isVerifying ? _verifyOTP : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          ),
        ),
        child: _isVerifying
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Verify & Continue',
                style: AppTextStyles.buttonText.copyWith(
                  color: isComplete ? Colors.white : AppColors.textLight,
                ),
              ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        Text(
          "Didn't receive the code?",
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _canResend ? _resendOTP : null,
          child: Text(
            _canResend
                ? 'Resend Code'
                : 'Resend in ${_resendSeconds}s',
            style: AppTextStyles.bodyMedium.copyWith(
              color: _canResend
                  ? AppColors.primaryGreen
                  : AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
