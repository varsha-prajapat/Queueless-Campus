import 'package:flutter/material.dart';
import '../services/register_service.dart';
import '../../services/commonservice.dart';
import '../../models/department_model.dart';
import './otp_screen.dart';
import './login_screen.dart';
import '../../core/constants/app_constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final departmentController = TextEditingController(); // stores departmentId

  bool obscurePassword = true;
  bool isLoading = false;

  List<Department> departments = [];

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  Future<void> fetchDepartments() async {
    try {
      final data = await DepartmentService().getDepartments();
      if (!mounted) return;
      setState(() => departments = data);
    } catch (e) {
      final message = e.toString().replaceAll("Exception:", "").trim();
      showBottomError(message.isEmpty ? "Failed to load departments" : message);
    }
  }

  void showBottomError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // ✅ Send departmentId only if selected
      final departmentId = departmentController.text.trim().isNotEmpty
          ? departmentController.text.trim()
          : null;

      await RegisterService().registerUser(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        phone: phoneController.text.trim().isEmpty
            ? null
            : phoneController.text.trim(),
        departmentId: departmentId,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OTPScreen(
            email: emailController.text.trim(),
            purpose: "EMAIL_VERIFICATION",
          ),
        ),
      );
    } catch (e) {
      final message = e
          .toString()
          .replaceAll("Exception:", "")
          .replaceAll("Error:", "")
          .trim();

      final finalMessage = message.isEmpty ? "Something went wrong" : message;

      showBottomError(finalMessage);
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
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  const Icon(
                    Icons.qr_code_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Queueless Campus",
                    style: AppTextStyles.appTitle,
                  ),
                  const SizedBox(height: 40),

                  // 📦 Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _field(
                            nameController,
                            "Full Name",
                            validator: (v) =>
                                v!.isEmpty ? "Enter full name" : null,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            emailController,
                            "Email",
                            validator: (v) => v!.isEmpty ? "Enter email" : null,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            passwordController,
                            "Password",
                            obscure: obscurePassword,
                            suffix: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => obscurePassword = !obscurePassword,
                              ),
                            ),
                            validator: (v) =>
                                v!.length < 6 ? "Min 6 characters" : null,
                          ),
                          const SizedBox(height: 16),
                          _field(phoneController, "Phone (Optional)"),
                          const SizedBox(height: 16),

                          // ✅ Department Dropdown (store ID)
                          DropdownButtonFormField<String>(
                            decoration: _decoration("Department (Optional)"),
                            items: departments
                                .map(
                                  (dept) => DropdownMenuItem(
                                    value: dept.id.toString(),
                                    child: Text(dept.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                departmentController.text = v ?? "",
                          ),

                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : registerUser,
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
                                        strokeWidth: 2.4,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : const Text(
                                      "Create Account",
                                      style: AppTextStyles.buttonText,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        style: AppTextStyles.linkBase,
                        children: [
                          TextSpan(text: "Already have an account? "),
                          TextSpan(
                            text: "Login",
                            style: AppTextStyles.linkAction,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint, {
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      validator: validator,
      decoration: _decoration(hint, suffix: suffix),
    );
  }

  InputDecoration _decoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
    );
  }
}
