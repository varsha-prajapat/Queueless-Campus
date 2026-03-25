import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/profile_provider.dart';

import '../../../utils/auth_role_helper.dart';
import './token_status_card.dart';
import './quick_button.dart';
import './service_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? studentId;

  @override
  void initState() {
    super.initState();
    _loadStudentId();
  }

  Future<void> _loadStudentId() async {
    final id = await AuthRoleHelper.getUserId();
    if (mounted) {
      setState(() {
        studentId = id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    final departmentName = profileProvider.department.isNotEmpty
        ? profileProvider.department
        : "No Department";

    final departmentId = profileProvider.departmentId ?? "";

    if (studentId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    /// ✅ NO TokenProvider HERE (fixed)
    return Container(
      color: const Color(0xffF5F6FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          /// ================= TOKEN STATUS =================
          const TokenStatusCard(),

          const SizedBox(height: 20),

          /// ================= QUICK ACTION =================
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: QuickActionButtons(),
          ),

          const SizedBox(height: 20),

          /// ================= DEPARTMENT =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    departmentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// ================= SERVICES =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ServiceList(
              departmentId: departmentId,
              studentId: studentId!,
            ),
          ),
        ],
      ),
    );
  }
}
