import 'package:flutter/material.dart';
import 'otp_screen.dart';
import 'register_screen.dart';
import '../services/login_service.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/bottom_message.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await LoginService().login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      // ✅ Direct navigation (No success message)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPScreen(
            email: emailController.text.trim(),
            purpose: "LOGIN_2FA",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      showBottomMessage(
        context,
        e.toString().replaceAll("Exception:", "").trim(),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌿 Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.bgTop,
                  AppColors.bgBottom,
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _buildCard(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Icon(
              Icons.qr_code_rounded,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: 20),
            const Text(
              "Queueless Campus",
              style: AppTextStyles.appTitle,
            ),
            const SizedBox(height: 6),
            const Text(
              "Sign in to continue",
              style: AppTextStyles.linkBase,
            ),
            const SizedBox(height: 30),

            // Email
            TextFormField(
              controller: emailController,
              decoration: _inputDecoration(
                label: "Email",
                icon: Icons.email_outlined,
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 18),

            // Password
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: _inputDecoration(
                label: "Password",
                icon: Icons.lock_outline,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => obscurePassword = !obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : loginUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      )
                    : const Text(
                        "Login",
                        style: AppTextStyles.buttonText,
                      ),
              ),
            ),

            const SizedBox(height: 22),

            // Register link
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              child: RichText(
                text: const TextSpan(
                  style: AppTextStyles.linkBase,
                  children: [
                    TextSpan(text: "Don’t have an account? "),
                    TextSpan(
                      text: "Register",
                      style: AppTextStyles.linkAction,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email is required";
    }

    final regex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$",
    );

    if (!regex.hasMatch(value.trim().toLowerCase())) {
      return "Enter a valid email address";
    }

    return null;
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.error,
        ),
      ),
    );
  }
}
