import 'package:flutter/material.dart';
import '../../../models/userui_model.dart';
import '../../../services/admin_services/user_service.dart';
import '../../../services/commonservice.dart' as commonDept;
import '../../../shared/widgets/bottom_message.dart';
import "../../../services/admin_services/department_service.dart"
    as admin_department;
import '../../../services/socket_service.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final UserService _userService = UserService();

  List<Userui> users = [];
  List<Userui> filteredUsers = [];
  Map<String, String> deptIdToName = {}; // departmentId -> departmentName

  bool isLoading = true;
  String searchQuery = "";

  final List<String> roles = ["STAFF", "ADMIN", "STUDENT"];
  late final SocketService _socketService;

  @override
  void initState() {
    super.initState();
    _initData();

    _socketService = SocketService();
    _socketService.connect();

    _socketService.on('userStatusChanged', (data) {
      final updatedUser = Userui.fromJson(data);
      if (!mounted) return;
      setState(() {
        final index = users.indexWhere((u) => u.id == updatedUser.id);
        if (index != -1) users[index] = updatedUser;
        _applySearchWithoutSetState();
      });
    });

    _socketService.on('userCreated', (_) => fetchUsers());
    _socketService.on('userUpdated', (_) => fetchUsers());
    _socketService.on('userDeleted', (_) => fetchUsers());
  }

  Future<void> _initData() async {
    setState(() => isLoading = true);
    try {
      await fetchUsers();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _applySearchWithoutSetState() {
    filteredUsers = users
        .where((user) =>
            user.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  void _applySearch() {
    setState(() {
      _applySearchWithoutSetState();
    });
  }

  // ================= FETCH USERS =================
  Future<void> fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final fetchedUsers = await _userService.getUsers();
      users = fetchedUsers.toList();

      Map<String, String> tempDeptMap = {};
      for (var user in users) {
        final deptId = user.departmentId;
        if (deptId.isNotEmpty && !deptIdToName.containsKey(deptId)) {
          try {
            final dept =
                await commonDept.DepartmentService().getDepartmentById(deptId);
            tempDeptMap[deptId] = dept?.name ?? "No Department";
          } catch (_) {
            tempDeptMap[deptId] = "No Department";
          }
        }
      }

      setState(() {
        deptIdToName.addAll(tempDeptMap);
        _applySearchWithoutSetState();
      });
    } catch (e) {
      showBottomMessage(context, "Failed to fetch users", isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildProfessionalAvatar(Userui user) {
    final String initial =
        user.name.isNotEmpty ? user.name[0].toUpperCase() : "?";
    String imageUrl = user.imageUrl;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color.fromARGB(255, 145, 109, 180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              )
            : Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
      ),
    );
  }

  // ================== EDIT USER ==================
  void _editUser(Userui user) async {
    List<Map<String, String>> departments = [];
    try {
      final deptData =
          await admin_department.DepartmentService().getDepartments();
      departments = deptData.map((dept) {
        return {"id": dept.id, "name": dept.name ?? "-"};
      }).toList();
    } catch (e) {
      showBottomMessage(context, "Failed to load departments", isError: true);
      return;
    }

    String selectedRole = user.role;
    String selectedDepartmentId = user.departmentId;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit User"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: roles.contains(selectedRole) ? selectedRole : null,
                items: roles
                    .map((role) =>
                        DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) selectedRole = val;
                },
                decoration: const InputDecoration(
                  labelText: "Role",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedDepartmentId.isNotEmpty
                    ? selectedDepartmentId
                    : null,
                items: departments
                    .map((dept) => DropdownMenuItem(
                          value: dept["id"],
                          child: Text(dept["name"]!),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) selectedDepartmentId = val;
                },
                decoration: const InputDecoration(
                  labelText: "Department",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                await _userService.updateUser(
                  user.copyWith(
                    role: selectedRole,
                    departmentId: selectedDepartmentId,
                  ),
                );
                Navigator.pop(context);
                fetchUsers();
                showBottomMessage(context, "User updated successfully");
              } catch (e) {
                showBottomMessage(context, "Failed to update user",
                    isError: true);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ================== TOGGLE STATUS ==================
  void _toggleStatus(Userui user) async {
    final bool newStatus = !user.isActive;
    try {
      await _userService.toggleUserStatus(user.id, newStatus);

      setState(() {
        final index = users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          users[index] = users[index].copyWith(isActive: newStatus);
        }
        _applySearchWithoutSetState();
      });

      showBottomMessage(
        context,
        newStatus ? "User unblocked successfully" : "User blocked successfully",
      );
    } catch (e) {
      showBottomMessage(context, "Failed to update status", isError: true);
    }
  }

  // ================== DELETE USER ==================
  void _deleteUser(Userui user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete "${user.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _userService.deleteUser(user.id);

      setState(() {
        users.removeWhere((u) => u.id == user.id);
        _applySearchWithoutSetState();
      });

      showBottomMessage(context, "User deleted");
    } catch (e) {
      showBottomMessage(context, "Failed to delete user", isError: true);
    }
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (val) {
                searchQuery = val;
                _applySearch();
              },
              decoration: InputDecoration(
                hintText: 'Search by username...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? const Center(child: Text('No users found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];

                          final deptName = user.departmentId.isEmpty
                              ? "No Department"
                              : (deptIdToName[user.departmentId] ??
                                  "No Department");

                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: _buildProfessionalAvatar(user),
                              title: Text(user.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Email: ${user.email}'),
                                  Text('Dept: $deptName'),
                                  Text('Role: ${user.role}'),
                                  Text(
                                      'Status: ${user.isActive ? 'Active' : 'Blocked'}'),
                                ],
                              ),
                              isThreeLine: false,
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') _editUser(user);
                                  if (value == 'block') _toggleStatus(user);
                                  if (value == 'delete') _deleteUser(user);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                      value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(
                                      value: 'block',
                                      child: Text(
                                          user.isActive ? 'Block' : 'Unblock')),
                                  const PopupMenuItem(
                                      value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
