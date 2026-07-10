import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'core/theme/colors.dart';
import 'main_scaffold.dart';
import 'channel_setup.dart';
import 'core/widgets/glass_snackbar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final List<TextEditingController> _phoneControllers = List.generate(10, (_) => TextEditingController());
  final List<TextEditingController> _otpControllers = List.generate(5, (_) => TextEditingController());
  
  bool _isOtpSent = false;
  bool _isLoading = false;

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    GlassSnackBar.show(
      context, 
      message, 
      type: isError ? GlassSnackBarType.error : GlassSnackBarType.success,
    );
  }

  void _onNextPressed() async {
    final phoneInput = _phoneControllers.map((c) => c.text).join();
    if (phoneInput.length < 10) {
      _showSnackBar('Please enter a valid 10-digit mobile number', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    // Pass the full international phone number
    final fullPhone = '+91$phoneInput';
    
    // Call FastAPI backend to send code
    final success = await ApiService.sendCode(fullPhone);
    
    if (!mounted) return;
    
    setState(() => _isLoading = false);
    
    if (success) {
      setState(() => _isOtpSent = true);
    } else {
      _showSnackBar('Failed to send OTP. Please try again.', isError: true);
    }
  }

  void _onVerifyPressed() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 5) {
      _showSnackBar('Please enter the 5-digit OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    final phoneInput = _phoneControllers.map((c) => c.text).join();
    final fullPhone = '+91$phoneInput';
    
    final responseData = await ApiService.verifyCode(fullPhone, otp);
    
    if (!mounted) return;
    
    setState(() => _isLoading = false);
    
    if (responseData != null && responseData['user_id'] != null) {
      final String userId = responseData['user_id'];
      final String? channelId = responseData['channel_id'];

      await ApiService.saveUserId(userId);
      if (channelId != null) {
        await ApiService.saveChannelId(channelId);
      }

      if (!mounted) return;

      _showSnackBar('Login Successful!');
      
      if (channelId == null || channelId.isEmpty) {
        // Need to set up channel
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ChannelSetupPage()),
        );
      } else {
        // Ready to go!
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScaffold()),
        );
      }
    } else {
      _showSnackBar('Invalid OTP. Please try again.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? AppColors.grey800 : AppColors.primarySurface,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                // Logo or App Name
                Row(
                  children: [
                    Image.asset(
                      'assets/icon.png',
                      width: 48,
                      height: 48,
                      color: isDark ? Colors.white : null,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'TeleStore',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: isDark ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                
                // Animated Switcher for the content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _isOtpSent ? _buildOtpView() : _buildMobileView(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileView() {
    final theme = Theme.of(context);

    return Column(
      key: const ValueKey('MobileView'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your mobile number to continue',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 40),
        
        Text(
          '+91 (India)',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(10, (index) => _buildPhoneField(index)),
        ),
        const SizedBox(height: 32),
        
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _onNextPressed,
            child: _isLoading 
              ? const SizedBox(
                  width: 24, 
                  height: 24, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : const Text('Next'),
          ),
        ),
        const Spacer(),
        Center(
          child: Text(
            'By continuing, you agree to our Terms & Conditions',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPhoneField(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: TextField(
          controller: _phoneControllers[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) {
            if (value.isNotEmpty && index < 9) {
              FocusScope.of(context).nextFocus();
            }
            if (value.isEmpty && index > 0) {
              FocusScope.of(context).previousFocus();
            }
          },
          style: theme.textTheme.titleLarge?.copyWith(
            color: isDark ? Colors.white : AppColors.grey900,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.grey800 : Colors.white,
            counterText: "",
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpView() {
    final phone = _phoneControllers.map((c) => c.text).join();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      key: const ValueKey('OtpView'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => setState(() => _isOtpSent = false),
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.grey900),
          style: IconButton.styleFrom(
            backgroundColor: isDark ? AppColors.grey700 : AppColors.grey200,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Verification',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'We have sent a 5-digit code to +91 $phone',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 40),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) => _buildOtpField(index)),
        ),
        
        const SizedBox(height: 40),
        
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _onVerifyPressed,
            child: _isLoading 
              ? const SizedBox(
                  width: 24, 
                  height: 24, 
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
              : const Text('Verify & Continue'),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () {},
            child: const Text('Resend Code'),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildOtpField(int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 55,
      height: 65,
      child: TextField(
        controller: _otpControllers[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (value) {
          if (value.isNotEmpty && index < 4) {
            FocusScope.of(context).nextFocus();
          }
          if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
        style: theme.textTheme.displayLarge?.copyWith(
          color: isDark ? Colors.white : AppColors.grey900,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark ? AppColors.grey800 : Colors.white,
          counterText: "",
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
