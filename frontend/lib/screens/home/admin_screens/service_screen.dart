import 'package:flutter/material.dart';
import '../../../services/admin_services/service.dart';
import '../../../shared/widgets/bottom_message.dart';
import '../../../services/commonservice.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> departments = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadDepartments() async {
    try {
      final deptData = await DepartmentService().getDepartments();

      setState(() {
        departments = deptData.map<Map<String, dynamic>>((dept) {
          final status = dept.status ?? "active";
          return {
            "_id": dept.id.toString(),
            "name": dept.name ?? "Unknown",
            "isActive": status.toLowerCase() == "active",
          };
        }).toList();

        // Add fallback for departments referenced in services but missing in API
        for (var service in services) {
          String deptId = service["departmentId"] is Map
              ? service["departmentId"]["_id"]?.toString() ?? ""
              : service["departmentId"]?.toString() ?? "";

          String deptName = service["departmentId"] is Map
              ? service["departmentId"]["name"] ?? "Unknown"
              : "Unknown";

          if (deptId.isNotEmpty &&
              !departments.any((d) => d["_id"] == deptId)) {
            departments.add({
              "_id": deptId,
              "name": deptName,
              "isActive": false,
            });
          }
        }
      });
    } catch (e) {
      showBottomMessage(context, "Failed to load departments", isError: true);
    }
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      final serviceData = await ServiceApi.fetchServices();

      if (serviceData is List) {
        services = serviceData
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        services = [];
      }

      setState(() => isLoading = false);

      // Reload departments to ensure all referenced departments are included
      loadDepartments();
    } catch (e) {
      setState(() => isLoading = false);
      showBottomMessage(context, "Failed to load services", isError: true);
    }
  }

  Future<void> deleteService(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Service"),
        content: const Text("Are you sure you want to delete this service?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ServiceApi.deleteService(id);
      showBottomMessage(context, "Service deleted");
      loadData();
    } catch (e) {
      showBottomMessage(context, "Delete failed", isError: true);
    }
  }

  String getDepartmentName(dynamic departmentId) {
    if (departmentId == null) return "Unknown";

    String id = departmentId is Map
        ? departmentId["_id"]?.toString() ?? ""
        : departmentId.toString();

    for (var dept in departments) {
      if (dept["_id"] == id) {
        return dept["name"] ?? "Unknown";
      }
    }

    return "Unknown";
  }

  Future<void> openServiceDialog({Map<String, dynamic>? service}) async {
    final nameController = TextEditingController(text: service?["name"] ?? "");
    final feeController =
        TextEditingController(text: (service?["fee"] ?? 0).toString());
    String serviceType = service?["serviceType"] ?? "Documents";
    bool allowUrgent = service?["allowUrgent"] ?? false;
    bool isPaused = service?["isPaused"] ?? false;
    String? selectedDepartmentId;

    if (service != null) {
      if (service["departmentId"] is Map) {
        selectedDepartmentId = service["departmentId"]["_id"]?.toString();
      } else {
        selectedDepartmentId = service["departmentId"]?.toString();
      }
    }

    // Filter departments: only active ones for new service
    final availableDepartments = service == null
        ? departments.where((d) => d["isActive"] == true).toList()
        : departments;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(service == null ? "Add Service" : "Edit Service"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Service Name",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: serviceType,
                    decoration: InputDecoration(
                      labelText: "Service Type",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: "Documents", child: Text("Documents")),
                      DropdownMenuItem(value: "Fees", child: Text("Fees")),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        serviceType = value!;
                        if (serviceType == "Documents")
                          feeController.text = "0";
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDepartmentId,
                    decoration: InputDecoration(
                      labelText: "Department",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: availableDepartments.map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept["_id"],
                        child: Text(dept["name"]),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() => selectedDepartmentId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: feeController,
                    keyboardType: TextInputType.number,
                    enabled: serviceType == "Fees",
                    decoration: InputDecoration(
                      labelText: "Fee",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  SwitchListTile(
                    value: allowUrgent,
                    title: const Text("Allow Urgent"),
                    onChanged: (val) => setStateDialog(() => allowUrgent = val),
                  ),
                  SwitchListTile(
                    value: isPaused,
                    title: const Text("Paused"),
                    onChanged: (val) => setStateDialog(() => isPaused = val),
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
                  if (selectedDepartmentId == null) {
                    showBottomMessage(context, "Select department",
                        isError: true);
                    return;
                  }

                  final fee = serviceType == "Fees"
                      ? int.tryParse(feeController.text) ?? 0
                      : 0;

                  try {
                    if (service == null) {
                      await ServiceApi.createService(
                        name: nameController.text.trim(),
                        departmentId: selectedDepartmentId!,
                        serviceType: serviceType,
                        allowUrgent: allowUrgent,
                        isPaused: isPaused,
                        fee: fee,
                      );
                      showBottomMessage(context, "Service Added");
                    } else {
                      await ServiceApi.updateService(
                        id: service["_id"],
                        name: nameController.text.trim(),
                        departmentId: selectedDepartmentId!,
                        serviceType: serviceType,
                        allowUrgent: allowUrgent,
                        isPaused: isPaused,
                        fee: fee,
                      );
                      showBottomMessage(context, "Service Updated");
                    }

                    Navigator.pop(context);
                    loadData();
                  } catch (e) {
                    showBottomMessage(context, "Operation failed",
                        isError: true);
                  }
                },
                child: const Text("Save"),
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredServices = services.where((service) {
      final name = service["name"]?.toLowerCase() ?? "";
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD9CFEA),
        elevation: 0,
        centerTitle: true,
        title: const Text("Services"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE1BEE7),
        onPressed: () => openServiceDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Add Service"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: "Search service...",
                        border: InputBorder.none,
                        icon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredServices.length,
                      itemBuilder: (context, index) {
                        final service = filteredServices[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE7F6),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      service["name"] ?? "",
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () {
                                          final deptId = service["departmentId"]
                                                  is Map
                                              ? service["departmentId"]["_id"]
                                                  ?.toString()
                                              : service["departmentId"]
                                                  ?.toString();

                                          if (deptId == null) {
                                            showBottomMessage(
                                              context,
                                              "Cannot edit: department unknown",
                                              isError: true,
                                            );
                                            return;
                                          }

                                          final deptInfo =
                                              departments.firstWhere(
                                            (d) => d["_id"] == deptId,
                                            orElse: () => {"isActive": false},
                                          );

                                          if (!(deptInfo["isActive"] ??
                                              false)) {
                                            showBottomMessage(
                                              context,
                                              "Cannot edit service because department is inactive",
                                              isError: true,
                                            );
                                            return;
                                          }

                                          openServiceDialog(service: service);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            deleteService(service["_id"]),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Department: ${getDepartmentName(service["departmentId"])}",
                                style: const TextStyle(color: Colors.black54),
                              ),
                              Text(
                                "Type: ${service["serviceType"] ?? ""}",
                                style: const TextStyle(color: Colors.black54),
                              ),
                              Text(
                                "Fee: ₹${service["fee"] ?? 0}",
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                children: [
                                  if (service["allowUrgent"] == true)
                                    _chip("URGENT", Colors.orange),
                                  if (service["isPaused"] == true)
                                    _chip("PAUSED", Colors.red),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
