import 'package:flutter/material.dart';
import 'dart:io';
import '../services/home_service.dart';
import '../services/commonservice.dart';
import '../../models/department_model.dart';

class ProfileProvider extends ChangeNotifier {
  String name = "User";
  String phone = "";
  String department = "";
  String departmentId = ""; // ✅ ADD THIS
  String? profileImage;

  /// ================= FETCH PROFILE =================
  Future<void> fetchProfile() async {
    try {
      final data = await HomeService.getMyProfile();

      // ✅ Name
      name = (data['name'] != null && data['name'].toString().isNotEmpty)
          ? data['name']
          : "User";

      phone = data['phone'] ?? "";

      /// ================= DEPARTMENT =================
      department = "";
      departmentId = ""; // ✅ RESET FIRST

      if (data['departmentId'] != null) {
        String? deptId;
        String? deptName;

        /// CASE 1: populated object
        if (data['departmentId'] is Map) {
          deptId = data['departmentId']['_id'];
          deptName = data['departmentId']['name'];
        }

        /// CASE 2: only ID
        else if (data['departmentId'] is String) {
          deptId = data['departmentId'];
        }

        /// ✅ SAVE departmentId (IMPORTANT)
        if (deptId != null) {
          departmentId = deptId;
        }

        /// Name already available
        if (deptName != null && deptName.isNotEmpty) {
          department = deptName;
        }

        /// Fetch name if missing
        else if (deptId != null) {
          try {
            Department? dept =
                await DepartmentService().getDepartmentById(deptId);

            if (dept?.name != null && dept!.name.isNotEmpty) {
              department = dept.name;
            }
          } catch (e) {}
        }
      }

      profileImage = data['profileImage'];

      notifyListeners();
    } catch (e) {
      /// Reset only if full API fails
      name = "User";
      phone = "";
      department = "";
      departmentId = ""; // ✅ RESET
      profileImage = null;

      notifyListeners();
    }
  }

  /// ================= UPDATE PROFILE =================
  Future<void> updateProfile({
    required String newName,
    required String newPhone,
    File? imageFile,
  }) async {
    try {
      await HomeService.updateProfile(
        updateData: {
          "name": newName,
          "phone": newPhone,
        },
        imageFile: imageFile,
      );

      await fetchProfile(); // refresh
    } catch (e) {
      rethrow;
    }
  }

  /// ================= CLEAR PROFILE =================
  void clearProfile() {
    name = "User";
    phone = "";
    department = "";
    departmentId = ""; // ✅ CLEAR
    profileImage = null;
    notifyListeners();
  }
}
