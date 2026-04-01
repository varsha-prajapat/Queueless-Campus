import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../services/AdminContact.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminContactCard extends StatefulWidget {
  final String role;
  final String? departmentId;
  final bool? counterAssigned;
  final int? pendingTokens;

  const AdminContactCard({
    super.key,
    required this.role,
    this.departmentId,
    this.counterAssigned,
    this.pendingTokens,
  });

  @override
  State<AdminContactCard> createState() => _AdminContactCardState();
}

class _AdminContactCardState extends State<AdminContactCard> {
  late Future<UserModel?> _adminFuture;

  @override
  void initState() {
    super.initState();
    _adminFuture = AdminContactService.getAdminContact(role: widget.role);
  }

  /// ✅ SAFE IMAGE CHECK
  bool _hasValidImage(String? url) {
    return url != null && url.trim().isNotEmpty && url.startsWith("http");
  }

  @override
  Widget build(BuildContext context) {
    final bool hasDepartment = widget.departmentId != null &&
        widget.departmentId!.trim().isNotEmpty &&
        widget.departmentId!.trim().toLowerCase() != "null";

    final bool hasCounter = widget.counterAssigned ?? false;

    return FutureBuilder<UserModel?>(
      future: _adminFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildMessageContainer(
            "Failed to load admin info",
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return _buildMessageContainer(
            "No admin assigned. Please contact support.",
            icon: Icons.person_off,
            iconColor: Colors.orange,
          );
        }

        final admin = snapshot.data!;

        /// ================= CASE 1: NO DEPARTMENT =================
        if (!hasDepartment) {
          return _buildAdminCard(
            admin,
            message: "⚠ Department not assigned. Please contact administrator.",
            showDepartment: false,
          );
        }

        /// ================= CASE 2: COUNTER INACTIVE =================
        if (!hasCounter) {
          return _buildAdminCard(
            admin,
            message: "⚠ Contact admin to activate your counter.",
            showDepartment: true,
          );
        }

        /// ================= CASE 3: ACTIVE =================
        return _buildStaffCard(admin);
      },
    );
  }

  /// ================= ADMIN CARD =================
  Widget _buildAdminCard(UserModel admin,
      {required String message, required bool showDepartment}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          /// 🔥 SAFE AVATAR (ICON FALLBACK FIXED)
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.lightBlue.shade100,
            backgroundImage: _hasValidImage(admin.profileImage)
                ? NetworkImage(admin.profileImage!)
                : null,
            child: !_hasValidImage(admin.profileImage)
                ? const Icon(Icons.person, size: 30, color: Colors.lightBlue)
                : null,
          ),

          const SizedBox(height: 12),

          const Text(
            "Contact Administrator",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(
            showDepartment
                ? "Department ID: ${widget.departmentId}"
                : "No department assigned",
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          _buildMessageBanner(message),

          const SizedBox(height: 12),

          ..._buildAdminInfo(admin),
        ],
      ),
    );
  }

  /// ================= STAFF CARD =================
  Widget _buildStaffCard(UserModel admin) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            "Staff Dashboard",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (widget.pendingTokens != null)
            _buildPendingTokens(widget.pendingTokens!),
        ],
      ),
    );
  }

  /// ================= ADMIN INFO =================
  List<Widget> _buildAdminInfo(UserModel admin) {
    return [
      const Divider(),
      _buildInfoRow(Icons.person, admin.name ?? "Admin"),
      _buildClickableInfoRow(
        Icons.email,
        admin.email ?? "N/A",
        "mailto:${admin.email}",
      ),
      _buildClickableInfoRow(
        Icons.phone,
        admin.phone ?? "N/A",
        "tel:${admin.phone}",
      ),
    ];
  }

  Widget _buildMessageBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }

  Widget _buildClickableInfoRow(IconData icon, String text, String uri) {
    return InkWell(
      onTap: () async {
        final url = Uri.parse(uri);
        if (!await launchUrl(url)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cannot open link")),
          );
        }
      },
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTokens(int count) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.lightBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "Pending tokens: $count",
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildMessageContainer(String message,
      {IconData icon = Icons.info, Color iconColor = Colors.blue}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
