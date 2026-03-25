import 'package:flutter/material.dart';
import 'package:frontend/screens/home/student/dashboard_screen.dart';
import '../../../../shared/widgets/banner_slider.dart';
import '../../../../shared/services/banner_service.dart';
import '../../../../models/banner_model.dart';
import '../../../../shared/screens/admin_contact_card.dart';

class StudentSection extends StatefulWidget {
  final String? departmentId; // nullable

  const StudentSection({super.key, this.departmentId});

  @override
  State<StudentSection> createState() => _StudentSectionState();
}

class _StudentSectionState extends State<StudentSection> {
  @override
  Widget build(BuildContext context) {
    // Trim and check department ID
    final String deptId = widget.departmentId?.trim() ?? "";
    final bool hasDepartment =
        deptId.isNotEmpty && deptId.toLowerCase() != "null";

    return Scaffold(
      appBar: AppBar(title: const Text("Student Dashboard")),
      body: FutureBuilder<List<BannerModel>>(
        future: BannerService.getUserBanners(
          role: "student",
          departmentId: deptId,
        ),
        builder: (context, bannerSnapshot) {
          final banners = bannerSnapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ================= BANNER =================
              if (bannerSnapshot.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (banners.isNotEmpty)
                BannerSlider(banners: banners),

              const SizedBox(height: 20),

              // ================= STUDENT DEPARTMENT CARD =================
              if (!hasDepartment) ...[
                AdminContactCard(
                  role: "STUDENT",
                  departmentId: deptId.isNotEmpty ? deptId : null,
                ),
                const SizedBox(height: 20),
              ],

              // ================= DASHBOARD =================
              if (hasDepartment) const DashboardScreen(),
            ],
          );
        },
      ),
    );
  }
}
