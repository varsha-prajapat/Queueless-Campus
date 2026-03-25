import 'package:flutter/material.dart';
import 'package:frontend/utils/auth_role_helper.dart';
import '../../../../models/department_model.dart';
import '../../../services/admin_services/department_service.dart';
import '../../../../shared/widgets/bottom_message.dart';
import '../../../services/socket_service.dart';
import 'dart:async'; // use SocketService

class DepartmentScreen extends StatefulWidget {
  const DepartmentScreen({super.key});

  @override
  State<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  final DepartmentService _service = DepartmentService();
  final SocketService _socketService = SocketService(); // socket service

  List<Department> _departments = [];
  List<Department> _filtered = [];
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  StreamSubscription<List<dynamic>>? _notifSub; // typed subscription

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _initSocket();
  }

  // ================= LOAD =================
  Future<void> _loadDepartments() async {
    try {
      setState(() => _isLoading = true);

      final data = await _service.getDepartments();

      if (!mounted) return;

      setState(() {
        _departments = data;
        _filtered = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // ❌ No bottom message here
    }
  }

  // ================= SOCKET =================
  void _initSocket() async {
    // 1️⃣ Get userId from AuthRoleHelper
    String userId = await AuthRoleHelper.getUserId(); // ✅ await
    List<String> roles = [
      await AuthRoleHelper.getRole()
    ]; // ✅ wrap in list/ if roles are async

    // 2️⃣ Initialize socket service
    _socketService.init(userId: userId, roles: roles);

    // 3️⃣ Connect
    _socketService.connect();

    // 4️⃣ Listen notifications
    _notifSub = _socketService.notifStream.listen((data) {
      _loadDepartments();
    });
  }

  // ================= SEARCH =================
  void _search(String query) {
    setState(() {
      _filtered = _departments
          .where((d) => d.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // ================= FORM =================
  void _showForm({Department? dept}) {
    final nameController =
        TextEditingController(text: dept != null ? dept.name : "");
    String status = dept?.status ?? "active";
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                dept == null ? "Add Department" : "Edit Department",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Department Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: InputDecoration(
                        labelText: "Status",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: ["active", "inactive"]
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          status = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) {
                            showBottomMessage(
                              context,
                              "Department name is required",
                              isError: true,
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          try {
                            if (dept == null) {
                              await _service.createDepartment(
                                nameController.text.trim(),
                                status,
                              );
                            } else {
                              await _service.updateDepartment(
                                dept.id,
                                nameController.text.trim(),
                                status,
                              );
                            }

                            await _loadDepartments();

                            if (mounted) {
                              Navigator.pop(dialogContext);

                              showBottomMessage(
                                context,
                                dept == null
                                    ? "Department Created Successfully"
                                    : "Department Updated Successfully",
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);

                            showBottomMessage(
                              context,
                              e.toString().replaceAll("Exception:", "").trim(),
                              isError: true,
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= DELETE =================
  void _confirmDelete(String id) {
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "Delete Department",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: const Text(
                "This action cannot be undone.\nAre you sure you want to delete this department?",
                style: TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isDeleting ? null : () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);

                          try {
                            await _service.deleteDepartment(id);

                            if (mounted) {
                              Navigator.pop(dialogContext);
                              await _loadDepartments();

                              showBottomMessage(
                                context,
                                "Department Deleted Successfully",
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isDeleting = false);

                            showBottomMessage(
                              context,
                              e.toString().replaceAll("Exception:", "").trim(),
                              isError: true,
                            );
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Delete"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _notifSub?.cancel(); // cancel subscription
    _socketService.dispose(); // dispose socket service
    _searchController.dispose();
    super.dispose();
  }

  // ================= UI (UNCHANGED) =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Departments",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text("Add Department"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: "Search department...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? const Center(
                          child: Text(
                            "No Departments Found",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadDepartments,
                          child: ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final dept = _filtered[index];
                              final isActive =
                                  dept.status.toLowerCase() == "active";

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 14),
                                  title: Text(
                                    dept.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.green.withOpacity(0.15)
                                            : Colors.red.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        dept.status.toUpperCase(),
                                        style: TextStyle(
                                          color: isActive
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () => _showForm(dept: dept),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _confirmDelete(dept.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
