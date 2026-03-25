import 'package:flutter/material.dart';
import '../../utils/admin_service.dart';
import '../../shared/widgets/bottom_message.dart';
import '../../../services/commonservice.dart'; // ✅ For DepartmentService

class AccessManagerScreen extends StatefulWidget {
  const AccessManagerScreen({super.key});

  @override
  State<AccessManagerScreen> createState() => _AccessManagerScreenState();
}

class _AccessManagerScreenState extends State<AccessManagerScreen> {
  final emailController = TextEditingController();

  String? selectedRole;
  String? selectedDepartment;

  final roles = ["ADMIN", "STAFF", "STUDENT"];

  List<String> departments = []; // ✅ Dynamic departments

  bool isLoading = false;
  bool isLoadingDepartments = true; // ✅ Loading flag for departments

  // 🎨 Colors
  static const Color primary = Color(0xFF1F5F5B);
  static const Color bg = Color(0xFFF6FAF9);
  static const Color card = Colors.white;
  static const Color fieldBg = Color(0xFFF1F3FA);

  @override
  void initState() {
    super.initState();
    loadDepartments(); // ✅ Fetch departments on init
  }

  /// ✅ Load departments dynamically from API
  Future<void> loadDepartments() async {
    try {
      final deptData = await DepartmentService().getDepartments();
      setState(() {
        departments = deptData.map<String>((dept) => dept.name ?? "").toList();
        isLoadingDepartments = false;
      });
    } catch (e) {
      setState(() => isLoadingDepartments = false);
      showBottomMessage(context, "Failed to load departments", isError: true);
    }
  }

  Future<void> invite() async {
    final email = emailController.text.trim();

    if (email.isEmpty || selectedRole == null || selectedDepartment == null) {
      showBottomMessage(context, "Please fill all fields", isError: true);
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      showBottomMessage(context, "Enter a valid email address", isError: true);
      return;
    }

    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      await AdminService.inviteUser(
        email: email,
        role: selectedRole!,
        department: selectedDepartment!,
      );

      if (!mounted) return;

      setState(() => isLoading = false);
      showBottomMessage(context, "Invitation sent successfully");
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showBottomMessage(
        context,
        e.toString().replaceAll("Exception:", "").trim(),
        isError: true,
      );
    }
  }

  InputDecoration input(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      filled: true,
      fillColor: fieldBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: primary.withOpacity(0.6),
          width: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: Colors.black,
        title: const Text(
          "Access Manager",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_alt_1,
                size: 36,
                color: primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "Invite users & manage access",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: input("Email", icon: Icons.email_outlined),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: input("Role", icon: Icons.badge_outlined),
                    hint: const Text("Select role"),
                    items: roles.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text(r),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => selectedRole = v),
                  ),
                  const SizedBox(height: 18),
                  isLoadingDepartments
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : DropdownButtonFormField<String>(
                          value: selectedDepartment,
                          decoration: input("Department",
                              icon: Icons.apartment_outlined),
                          hint: const Text("Select department"),
                          items: departments.map((d) {
                            return DropdownMenuItem(
                              value: d,
                              child: Text(d),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => selectedDepartment = v),
                        ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : invite,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "SEND INVITE",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
