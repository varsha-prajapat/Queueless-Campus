import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import "../../admin_screens/admin_card.dart";
import "../../admin_screens/Department_screen.dart";
import "../../admin_screens/service_screen.dart";
import "../../admin_screens/admin_banner_screen.dart";
import "../../admin_screens/manage_counters_screen.dart";
import "../../../../shared/widgets/access_manager_screen.dart";
import "../../admin_screens/UserScreen.dart";
import "../../admin_screens/token_dashboard_screen.dart"; // ✅ ADDED

class AdminSection extends StatelessWidget {
  const AdminSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            /// TITLE
            Text(
              "Admin Dashboard",
              style: AppTextStyles.appTitle,
            ),

            const SizedBox(height: 20),

            /// GRID
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              children: [
                /// USERS
                AdminCard(
                  title: "Users",
                  icon: Icons.people_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserScreen(),
                      ),
                    );
                  },
                ),

                /// DEPARTMENTS
                AdminCard(
                  title: "Departments",
                  icon: Icons.account_tree_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DepartmentScreen(),
                      ),
                    );
                  },
                ),

                /// SERVICES
                AdminCard(
                  title: "Services",
                  icon: Icons.design_services_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ServiceScreen(),
                      ),
                    );
                  },
                ),

                /// COUNTERS
                AdminCard(
                  title: "Counters",
                  icon: Icons.confirmation_number_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageCountersScreen(),
                      ),
                    );
                  },
                ),

                /// ACCESS MANAGER
                AdminCard(
                  title: "Access Manager",
                  icon: Icons.security_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccessManagerScreen(),
                      ),
                    );
                  },
                ),

                /// TOKEN DASHBOARD ✅ FIXED
                AdminCard(
                  title: "Dash Token",
                  icon: Icons.vpn_key_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TokenDashboardScreen(),
                      ),
                    );
                  },
                ),

                /// BANNERS
                AdminCard(
                  title: "Banners",
                  icon: Icons.flag_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminBannerScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
