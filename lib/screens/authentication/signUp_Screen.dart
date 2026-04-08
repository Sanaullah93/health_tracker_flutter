import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:health_tracker_fyp/controllers/sign_up_controller.dart';
import 'package:health_tracker_fyp/screens/authentication/login_screen.dart';
import 'package:health_tracker_fyp/widgets/custom_textfield.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Dashboard Blue Theme Colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color darkBlue = Color(0xFF1976D2);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF666666);
  static const Color borderColor = Color(0xFFE2E8F0);

  final SignUpController controller = Get.put(SignUpController());
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final List<Map<String, dynamic>> _steps = [
    {'title': 'Create Account', 'subtitle': 'Start your wellness journey'},
    {'title': 'Set Password', 'subtitle': 'Secure your account'},
  ];

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primaryBlue.withOpacity(0.05), Colors.white],
                  ),
                ),
              ),
            ),

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: textGrey,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryBlue, darkBlue],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Progress Indicator - Blue Theme
                  Row(
                    children: [
                      for (int i = 0; i < _steps.length; i++) ...[
                        Expanded(
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: i <= _currentStep
                                  ? primaryBlue
                                  : borderColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        if (i < _steps.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1}/${_steps.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                        ),
                      ),
                      Text(
                        _steps[_currentStep]['title'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Title
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _steps[_currentStep]['title'],
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _steps[_currentStep]['subtitle'],
                        style: TextStyle(
                          fontSize: 16,
                          color: textGrey,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Form
                  SizedBox(
                    height: _currentStep == 0 ? 240 : 320,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Step 1: Personal Info
                        _buildPersonalInfoStep(),

                        // Step 2: Account Setup
                        _buildAccountSetupStep(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Navigation Buttons
                  Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousStep,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textDark,
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        child: _currentStep == _steps.length - 1
                            ? _buildCreateAccountButton()
                            : _buildContinueButton(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: borderColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or sign up with',
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: borderColor)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Social Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          icon: Icons.g_mobiledata,
                          label: 'Google',
                          color: Colors.white,
                          onTap: () => controller.signInWithGoogle(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSocialButton(
                          icon: Icons.apple,
                          label: 'Apple',
                          color: textDark,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Login Link
                  Center(
                    child: GestureDetector(
                      onTap: () => Get.offAll(() => const LoginScreen()),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(color: textGrey, fontSize: 15),
                            ),
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: primaryBlue,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      children: [
        CustomTextField(
          controller: controller.nameController,
          hintText: 'Full Name',
          icon: Icons.person_outline,
          iconColor: textGrey,
          focusedColor: primaryBlue,
          onChanged: (value) {},
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        CustomTextField(
          controller: controller.emailController,
          hintText: 'Email Address',
          icon: Icons.email_outlined,
          iconColor: textGrey,
          focusedColor: primaryBlue,
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) {},
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@') || !value.contains('.')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAccountSetupStep() {
    return Column(
      children: [
        Obx(
          () => CustomTextField(
            controller: controller.passwordController,
            hintText: 'Create Password',
            icon: Icons.lock_outline,
            iconColor: textGrey,
            focusedColor: primaryBlue,
            isPassword: true,
            isPasswordHidden: controller.isPasswordHidden.value,
            onPasswordToggle: controller.togglePasswordVisibility,
            onChanged: (value) {},
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 20),
        Obx(
          () => CustomTextField(
            controller: controller.confirmPasswordController,
            hintText: 'Confirm Password',
            icon: Icons.lock_outline,
            iconColor: textGrey,
            focusedColor: primaryBlue,
            isPassword: true,
            isPasswordHidden: controller.isConfirmPasswordHidden.value,
            onPasswordToggle: controller.toggleConfirmPasswordVisibility,
            onChanged: (value) {},
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm password';
              }
              if (value != controller.passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 20),
        Obx(
          () => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: controller.agreeToTerms.value,
                onChanged: (value) {
                  controller.agreeToTerms.value = value!;
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                activeColor: primaryBlue,
                checkColor: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    controller.agreeToTerms.value =
                        !controller.agreeToTerms.value;
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: textGrey,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text: 'By signing up, you agree to our ',
                        ),
                        TextSpan(
                          text: 'Terms',
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Widget _buildContinueButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, darkBlue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _nextStep,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton() {
    return Obx(
      () => Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: controller.agreeToTerms.value
              ? LinearGradient(
                  colors: [accentGreen, primaryBlue],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: controller.agreeToTerms.value ? null : borderColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: controller.agreeToTerms.value
              ? [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: controller.isLoading.value || !controller.agreeToTerms.value
                ? null
                : () => controller.signUp(),
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: controller.isLoading.value
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color == Colors.white ? textDark : Colors.white,
        side: BorderSide(
          color: color == Colors.white ? borderColor : Colors.transparent,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
