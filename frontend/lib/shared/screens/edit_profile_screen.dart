import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../provider/profile_provider.dart';
import '../../shared/widgets/bottom_message.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  File? profileImage;
  String? networkImage;

  bool isLoading = false;
  bool isFetching = true;

  static const Color primary = Color(0xFF4FB6A8);
  static const Color bg = Color(0xFFF3F8F6);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  /// LOAD PROFILE DATA
  void _loadProfile() {
    final profile = context.read<ProfileProvider>();

    nameController.text = profile.name;
    phoneController.text = profile.phone;
    networkImage = profile.profileImage;

    setState(() {
      isFetching = false;
    });
  }

  /// PICK IMAGE
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        profileImage = File(picked.path);
      });
    }
  }

  /// UPDATE PROFILE
  Future<void> update() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty) {
      showBottomMessage(context, "Name is required", isError: true);
      return;
    }

    if (name.length < 2) {
      showBottomMessage(
        context,
        "Name must be at least 2 characters",
        isError: true,
      );
      return;
    }

    if (name.length > 50) {
      showBottomMessage(
        context,
        "Name must be less than 50 characters",
        isError: true,
      );
      return;
    }

    final phoneRegex = RegExp(r'^[6-9]\d{9}$');

    if (phone.isNotEmpty && !phoneRegex.hasMatch(phone)) {
      showBottomMessage(
        context,
        "Phone number must be 10-digit Indian mobile number starting with 6-9",
        isError: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await context.read<ProfileProvider>().updateProfile(
            newName: name,
            newPhone: phone,
            imageFile: profileImage,
          );

      _loadProfile();

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showBottomMessage(context, "Profile updated successfully");

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showBottomMessage(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
        isError: true,
      );
    }
  }

  InputDecoration input(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF7FCFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: primary.withOpacity(0.6),
          width: 1.2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isFetching) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: pickImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: primary.withOpacity(0.2),
                        backgroundImage: profileImage != null
                            ? FileImage(profileImage!) as ImageProvider
                            : networkImage != null && networkImage!.isNotEmpty
                                ? NetworkImage(
                                    networkImage! +
                                        "?v=${DateTime.now().millisecondsSinceEpoch}",
                                  ) as ImageProvider
                                : null,
                        child: profileImage == null &&
                                (networkImage == null || networkImage!.isEmpty)
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: primary,
                              )
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: nameController,
                  decoration: input("Name"),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: input("Phone"),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : update,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Save Changes",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
