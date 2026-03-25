import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/profile_provider.dart';
import './book_service_screen.dart';
import './my_tokens_screen.dart';
import './queue_status_screen.dart';
import "../../../utils/auth_role_helper.dart";

class QuickActionButtons extends StatelessWidget {
  const QuickActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final departmentId = profile.departmentId ?? "";

    return FutureBuilder<String>(
      future: AuthRoleHelper.getUserId(), // async fetch of studentId
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: SizedBox()); // show nothing until loaded
        }

        final studentId = snapshot.data ?? "";

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ActionButton(
                icon: Icons.assignment,
                label: "Book Service",
                onTap: () {
                  if (departmentId.isEmpty || studentId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Department or User ID not loaded"),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookServiceScreen(
                        departmentId: departmentId,
                        studentId: studentId,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ActionButton(
                icon: Icons.confirmation_number,
                label: "My Tokens",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyTokensScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ActionButton(
                icon: Icons.group,
                label: "Queue Status",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QueueStatusScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              Icon(icon, size: 30, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
