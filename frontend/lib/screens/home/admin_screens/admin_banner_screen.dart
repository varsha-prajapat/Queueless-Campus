import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/banner_model.dart';
import '../../../services/admin_services/banner_service.dart';
import '../../../services/commonservice.dart';
import '../../../shared/widgets/bottom_message.dart';

class AdminBannerScreen extends StatefulWidget {
  const AdminBannerScreen({super.key});

  @override
  State<AdminBannerScreen> createState() => _AdminBannerScreenState();
}

class _AdminBannerScreenState extends State<AdminBannerScreen> {
  final BannerService _service = BannerService();
  final ImagePicker _picker = ImagePicker();

  List<BannerModel> banners = [];
  List<Map<String, dynamic>> departments = [];
  bool isLoading = true;

  String resolveImage(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http")) return path;
    const baseUrl = "http://localhost:3005/api/v1/";
    final cleanPath = path.startsWith("/") ? path.substring(1) : path;
    return "$baseUrl$cleanPath";
  }

  @override
  void initState() {
    super.initState();
    loadDepartments();
    fetchBanners();
  }

  Future<void> loadDepartments() async {
    try {
      final deptData = await DepartmentService().getDepartments();

      setState(() {
        departments = [
          {"_id": "ALL", "name": "All Departments", "isActive": true},
          ...deptData.map<Map<String, dynamic>>((dept) {
            final status = (dept.status ?? "active").toLowerCase();

            return {
              "_id": dept.id,
              "name": dept.name,
              "isActive": status == "active"
            };
          }).toList()
        ];
      });
    } catch (e) {
      showBottomMessage(context, "Failed to load departments", isError: true);
    }
  }

  Future<void> fetchBanners() async {
    setState(() => isLoading = true);

    try {
      final data = await _service.getBanners();

      setState(() {
        banners = data ?? [];
      });
    } catch (e) {
      showBottomMessage(context, "Failed to load banners", isError: true);
    }

    setState(() => isLoading = false);
  }

  String getDepartmentName(String? departmentId) {
    if (departmentId == null || departmentId == "ALL") {
      return "All Departments";
    }

    final dept = departments.firstWhere(
      (d) => d["_id"] == departmentId,
      orElse: () => {},
    );

    if (dept.isEmpty) return "All Departments";

    final name = dept["name"] ?? "Unknown";
    final isActive = dept["isActive"] ?? true;

    return isActive ? name : "$name (Inactive)";
  }

  Future<void> deleteBanner(String id) async {
    await _service.deleteBanner(id);
    fetchBanners();
  }

  /// BANNER IMAGE WIDGET FIXED: instantly remove broken/empty images
  Widget bannerImage(String? path) {
    final url = resolveImage(path);
    if (url.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        // instantly remove space if image fails
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const SizedBox.shrink(); // remove reserved space while loading
        },
      ),
    );
  }

  /// CREATE / EDIT DIALOG
  Future<void> openBannerDialog({BannerModel? banner}) async {
    final titleController = TextEditingController(text: banner?.title ?? "");
    final descController =
        TextEditingController(text: banner?.description ?? "");

    String targetRole = banner?.targetRole ?? "ALL";
    bool isActive = banner?.isActive ?? true;

    String selectedDepartmentId = banner?.departmentId ?? "ALL";

    File? selectedImage;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(banner == null ? "Add Banner" : "Edit Banner"),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// IMAGE PICKER
                    GestureDetector(
                      onTap: () async {
                        final picked = await _picker.pickImage(
                            source: ImageSource.gallery);

                        if (picked != null) {
                          setStateDialog(() {
                            selectedImage = File(picked.path);
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.grey.shade200,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: selectedImage != null
                              ? Image.file(selectedImage!, fit: BoxFit.contain)
                              : (banner?.image ?? "").isNotEmpty
                                  ? Image.network(
                                      resolveImage(banner!.image),
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          const SizedBox.shrink(),
                                    )
                                  : const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo, size: 36),
                                          SizedBox(height: 6),
                                          Text("Tap to select banner image"),
                                        ],
                                      ),
                                    ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                          labelText: "Title", border: OutlineInputBorder()),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                          labelText: "Description",
                          border: OutlineInputBorder()),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedDepartmentId,
                      decoration: const InputDecoration(
                          labelText: "Department",
                          border: OutlineInputBorder()),
                      items: departments.map((dept) {
                        return DropdownMenuItem<String>(
                          value: dept["_id"],
                          child: Text(dept["name"]),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setStateDialog(() => selectedDepartmentId = val!),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: targetRole,
                      decoration: const InputDecoration(
                          labelText: "Target Role",
                          border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: "ALL", child: Text("ALL")),
                        DropdownMenuItem(value: "ADMIN", child: Text("ADMIN")),
                        DropdownMenuItem(value: "STAFF", child: Text("STAFF")),
                        DropdownMenuItem(
                            value: "STUDENT", child: Text("STUDENT")),
                      ],
                      onChanged: (val) =>
                          setStateDialog(() => targetRole = val!),
                    ),

                    SwitchListTile(
                      value: isActive,
                      title: const Text("Active Banner"),
                      onChanged: (val) => setStateDialog(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                child: const Text("Save"),
                onPressed: () async {
                  if (titleController.text.trim().isEmpty) {
                    showBottomMessage(context, "Title required", isError: true);

                    return;
                  }

                  if (banner == null && selectedImage == null) {
                    showBottomMessage(context, "Please select image",
                        isError: true);

                    return;
                  }

                  /// Ensure ALL goes to backend
                  final deptToSend = (selectedDepartmentId == "ALL")
                      ? "ALL"
                      : selectedDepartmentId;

                  try {
                    if (banner == null) {
                      await _service.createBanner(
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        role: targetRole,
                        departmentId: deptToSend,
                        isActive: isActive,
                        imageFile: selectedImage!,
                      );
                    } else {
                      await _service.updateBanner(
                        id: banner.id,
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        role: targetRole,
                        departmentId: deptToSend,
                        isActive: isActive,
                        imageFile: selectedImage,
                      );
                    }

                    Navigator.pop(context);
                    fetchBanners();
                  } catch (e) {
                    showBottomMessage(context, "Operation failed",
                        isError: true);
                  }
                },
              )
            ],
          );
        },
      ),
    );
  }

  /// BANNER CARD
  Widget buildBannerCard(BannerModel banner) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bannerImage(banner.image), // fixed image widget
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        banner.title,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Chip(
                      label: Text(
                        banner.isActive ? "Active" : "Inactive",
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor:
                          banner.isActive ? Colors.green : Colors.red,
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Text(banner.description),
                const SizedBox(height: 8),
                Text("Department: ${getDepartmentName(banner.departmentId)}"),
                Text("Role: ${banner.targetRole}"),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => openBannerDialog(banner: banner)),
                    IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteBanner(banner.id))
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Banner Management"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openBannerDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Add Banner"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: banners.length,
              itemBuilder: (context, index) => buildBannerCard(banners[index]),
            ),
    );
  }
}
