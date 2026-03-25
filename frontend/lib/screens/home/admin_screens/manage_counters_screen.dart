import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:collection/collection.dart';

import '../../../models/counter_model.dart';
import '../../../services/admin_services/counter_service.dart';
import '../../../shared/widgets/bottom_message.dart';

class ManageCountersScreen extends StatefulWidget {
  const ManageCountersScreen({super.key});

  @override
  State<ManageCountersScreen> createState() => _ManageCountersScreenState();
}

class _ManageCountersScreenState extends State<ManageCountersScreen> {
  static const Color lightPurple = Color(0xFFD1C4E9);

  List<CounterModel> counters = [];
  List<CounterModel> filteredCounters = [];

  List<Map<String, dynamic>> allServices = [];
  List<Map<String, dynamic>> activeServices = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  /// ================= FETCH DATA =================
  Future<void> fetchData() async {
    setState(() => loading = true);

    try {
      allServices = await CounterService.fetchAllServices();
      activeServices = await CounterService.fetchActiveServices();

      counters = await CounterService.getCounters();
      filteredCounters = counters;
    } catch (e) {
      showBottomMessage(context, e.toString(), isError: true);
    }

    setState(() => loading = false);
  }

  /// ================= DELETE =================
  Future<void> deleteCounter(String id) async {
    try {
      await CounterService.deleteCounter(id);
      await fetchData();
      showBottomMessage(context, "Counter deleted");
    } catch (e) {
      showBottomMessage(context, e.toString(), isError: true);
    }
  }

  /// ================= LOAD STAFF =================
  Future<List<Map<String, dynamic>>> loadStaffByService(
      String serviceId) async {
    try {
      final service = allServices.firstWhereOrNull(
        (s) => s['_id'].toString() == serviceId,
      );

      if (service == null) return [];

      final department = service['departmentId'] is Map
          ? service['departmentId']['_id'].toString()
          : service['departmentId']?.toString();

      if (department == null) return [];

      return await CounterService.fetchStaffByDepartment(department);
    } catch (e) {
      return [];
    }
  }

  /// ================= SERVICE PAUSED CHECK =================
  bool isServicePaused(String? serviceId) {
    if (serviceId == null) return false;

    final service = allServices.firstWhereOrNull(
      (s) => s['_id'].toString() == serviceId,
    );

    if (service == null) return false;

    return service['isPaused'] == true;
  }

  /// ================= HELPER =================
  String getDepartmentName(dynamic service) {
    if (service['departmentId'] is Map) {
      return service['departmentId']['name'] ?? "";
    }
    return "";
  }

  /// ================= CREATE / EDIT DIALOG =================
  void showCounterDialog({CounterModel? counter}) async {
    if (counter != null && isServicePaused(counter.serviceId)) {
      showBottomMessage(context, "Service is paused. Cannot edit.",
          isError: true);
      return;
    }

    final nameController = TextEditingController(text: counter?.name ?? "");

    String? selectedServiceId = counter?.serviceId;
    bool isActive = counter?.isActive ?? true;

    List<Map<String, dynamic>> selectedStaffObjects =
        counter != null ? List.from(counter.staffObjects) : [];

    List<Map<String, dynamic>> localStaffList = [];

    if (selectedServiceId != null) {
      localStaffList = await loadStaffByService(selectedServiceId);
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            List<String> selectedStaffIds =
                selectedStaffObjects.map((e) => e['_id'].toString()).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: Text(
                counter == null ? "Create Counter" : "Edit Counter",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    /// COUNTER NAME
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Counter Name",
                        prefixIcon: const Icon(Icons.confirmation_number),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// SERVICE DROPDOWN
                    DropdownButtonFormField<String>(
                      value: selectedServiceId,
                      hint: const Text("Select Service"),
                      items: activeServices.map((s) {
                        String deptName = "";

                        /// If department already populated
                        if (s['departmentId'] is Map) {
                          deptName = s['departmentId']['name'] ?? "";
                        }

                        /// Otherwise get from allServices
                        else {
                          final fullService = allServices.firstWhereOrNull(
                            (srv) =>
                                srv['_id'].toString() == s['_id'].toString(),
                          );

                          if (fullService != null &&
                              fullService['departmentId'] is Map) {
                            deptName =
                                fullService['departmentId']['name'] ?? "";
                          }
                        }

                        return DropdownMenuItem(
                          value: s['_id'].toString(),
                          child: Text("${s['name']} ($deptName)"),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        if (value == null) return;

                        if (isServicePaused(value)) {
                          showBottomMessage(context, "This service is paused",
                              isError: true);
                          return;
                        }

                        setDialogState(() {
                          selectedServiceId = value;
                          selectedStaffObjects = [];
                          localStaffList = [];
                        });

                        final staff = await loadStaffByService(value);

                        setDialogState(() {
                          localStaffList = staff;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Service",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// STAFF MULTI SELECT
                    if (selectedServiceId != null)
                      MultiSelectDialogField<String>(
                        items: localStaffList
                            .map((staff) => MultiSelectItem<String>(
                                  staff['_id'].toString(),
                                  "${staff['name']} (${staff['email'] ?? ''})",
                                ))
                            .toList(),
                        initialValue: selectedStaffIds,
                        title: const Text("Select Staff"),
                        searchable: true,
                        listType: MultiSelectListType.CHIP,
                        buttonText: const Text("Select Staff"),
                        onConfirm: (values) {
                          setDialogState(() {
                            selectedStaffObjects = localStaffList
                                .where((staff) =>
                                    values.contains(staff['_id'].toString()))
                                .toList();
                          });
                        },
                      ),

                    const SizedBox(height: 15),

                    /// ACTIVE SWITCH
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Active"),
                        Switch(
                          value: isActive,
                          activeColor: lightPurple,
                          onChanged: (val) {
                            setDialogState(() {
                              isActive = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /// ACTION BUTTONS
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightPurple,
                  ),
                  child: const Text("Save"),
                  onPressed: () async {
                    if (nameController.text.isEmpty ||
                        selectedServiceId == null ||
                        selectedStaffObjects.isEmpty) {
                      showBottomMessage(context, "Fill all fields",
                          isError: true);
                      return;
                    }

                    try {
                      final staffIds = selectedStaffObjects
                          .map((s) => s['_id'].toString())
                          .toList();

                      if (counter == null) {
                        await CounterService.createCounter(
                          name: nameController.text,
                          serviceId: selectedServiceId!,
                          staffIds: staffIds,
                          isActive: isActive,
                        );
                      } else {
                        await CounterService.updateCounter(
                          id: counter.id,
                          name: nameController.text,
                          serviceId: selectedServiceId!,
                          staffIds: staffIds,
                          isActive: isActive,
                        );
                      }

                      Navigator.pop(context);
                      await fetchData();

                      showBottomMessage(context, "Saved successfully");
                    } catch (e) {
                      showBottomMessage(context, e.toString(), isError: true);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ================= COUNTER CARD =================
  Widget buildCounterCard(CounterModel counter) {
    final staffNames = counter.staffObjects.isNotEmpty
        ? counter.staffObjects
            .map((s) => "${s['name']} (${s['email'] ?? ''})")
            .join(', ')
        : "No staff assigned";

    final service = allServices
        .firstWhereOrNull((s) => s['_id'].toString() == counter.serviceId);

    String serviceLabel = counter.serviceName;

    if (service != null) {
      final dept = getDepartmentName(service);
      serviceLabel = "${service['name']} ($dept)";
    }

    final bool paused = isServicePaused(counter.serviceId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(
          counter.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Service: $serviceLabel"),
            Text(
              "Staff: $staffNames",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text("Status: ${counter.isActive ? "Active" : "Inactive"}"),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit,
                color: paused ? Colors.grey : lightPurple,
              ),
              onPressed: paused
                  ? () {
                      showBottomMessage(
                          context, "Service paused. Edit disabled",
                          isError: true);
                    }
                  : () {
                      showCounterDialog(counter: counter);
                    },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => deleteCounter(counter.id),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Counters"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: filteredCounters.length,
              itemBuilder: (context, index) =>
                  buildCounterCard(filteredCounters[index]),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: lightPurple,
        onPressed: () => showCounterDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
