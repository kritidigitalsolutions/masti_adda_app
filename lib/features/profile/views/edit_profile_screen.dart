import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/features/profile/controllers/edit_profile_controller.dart';
import 'package:masti_adda_app/features/auth/models/response/user_model.dart';
import 'package:masti_adda_app/features/profile/controllers/profile_controller.dart';
import 'package:masti_adda_app/shared/widgets/custom_image_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:masti_adda_app/constants/app_colors.dart';

import 'package:masti_adda_app/features/profile/widgets/profile_page_scaffold.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileController fetchController = Get.find();

  late final EditProfileController _editController = Get.put(
    EditProfileController(),
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Worker? _userWorker;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    // _editController = Get.find<EditProfileController>();

    // Seed the form once from whatever user data is already available.
    final existingUser = fetchController.user.value;
    if (existingUser != null) {
      _editController.initialize(existingUser);
      _nameController.text = existingUser.name;
      _emailController.text = existingUser.email;
      _phoneController.text = existingUser.phone;
      _seeded = true;
    } else {
      // Not loaded yet — wait for the first successful fetch, seed once,
      // then stop listening so later refreshes don't clobber user edits.
      _userWorker = ever<UserModel?>(fetchController.user, (userData) {
        if (!_seeded && userData != null) {
          _editController.initialize(userData);
          _nameController.text = userData.name;
          _emailController.text = userData.email;
          _phoneController.text = userData.phone;
          _seeded = true;
          _userWorker?.dispose();
          _userWorker = null;
        }
      });
    }

    // Set up a listener for controller status to go back on success
    ever(_editController.status, (Status status) {
      if (status == Status.success) {
        final updatedUser = _editController.user.value;
        if (updatedUser != null) {
          fetchController.updateUser(updatedUser);
        }
        Get.back();
        Get.snackbar(
          "Success",
          "Profile updated successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );
      } else if (status == Status.error) {
        final errorMsg = _editController.errorMessage.value.isNotEmpty
            ? _editController.errorMessage.value
            : "Failed to update profile";
        Get.snackbar(
          "Update Failed",
          errorMsg,
          backgroundColor: AppColors.errorColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          icon: const Icon(Icons.error_outline, color: Colors.white),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 4),
        );
      }
    });
  }

  @override
  void dispose() {
    _userWorker?.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    _editController.changeLocalImage(File(picked.path));
  }

  void _onSave() {
    _editController.saveProfile(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfilePageScaffold(
      title: 'Edit Profile',
      children: [
        Obx(() {
          final user = _editController.user.value;
          final localImageFile = _editController.localImageFile.value;
          final status = _editController.status.value;
          final errorMsg = _editController.errorMessage.value;

          if (fetchController.isLoading.value && user == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (fetchController.error.value.isNotEmpty && user == null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Text(
                    fetchController.error.value,
                    style: text14(color: AppColors.secondaryTextColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: fetchController.refreshProfile,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final bool isPhoneAuth = user?.isPhoneAuth ?? true;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CustomImagePicker(
                  imageFile: localImageFile,
                  imageUrl: user?.profileImage ?? "",
                  onTap: _pickAndUploadImage,
                  radius: 42,
                ),
              ),
              const SizedBox(height: 22),

              // Error display box if update failed
              if (errorMsg.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.errorColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          errorMsg,
                          style: text13(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              _InputField(label: 'Full Name', controller: _nameController),
              if (isPhoneAuth)
                _InputField(
                  label: 'Mobile Number',
                  controller: _phoneController,
                  enabled: false,
                  keyboardType: TextInputType.phone,
                  helperText:
                      'Mobile number cannot be changed for phone login accounts',
                ),
              _InputField(
                label: 'Email Address',
                controller: _emailController,
                enabled: isPhoneAuth,
                keyboardType: TextInputType.emailAddress,
                helperText: !isPhoneAuth
                    ? 'Email address cannot be changed for Google login accounts'
                    : null,
              ),
              const SizedBox(height: 18),
              ProfilePrimaryButton(
                title: status == Status.loading ? 'Saving...' : 'Save Changes',
                onTap: status == Status.loading ? () {} : _onSave,
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? helperText;
  final TextInputType? keyboardType;

  const _InputField({
    required this.label,
    required this.controller,
    this.enabled = true,
    this.helperText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: text12(color: AppColors.secondaryTextColor)),
              if (!enabled) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: AppColors.hintTextColor,
                ),
              ],
            ],
          ),
          const SizedBox(height: 7),
          TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: text14(
              color: enabled
                  ? AppColors.white
                  : AppColors.white.withValues(alpha: 0.5),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled
                  ? AppColors.surfaceColor
                  : AppColors.surfaceColor.withValues(alpha: 0.4),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.borderColor.withValues(alpha: 0.6),
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.borderColor.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.accentColor),
              ),
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 4),
            Text(
              helperText!,
              style: text11(color: AppColors.hintTextColor),
            ),
          ],
        ],
      ),
    );
  }
}
