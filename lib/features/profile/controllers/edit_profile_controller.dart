import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/core/data/exception/app_exception.dart';
import 'package:masti_adda_app/core/services/storage_service.dart';
import 'package:masti_adda_app/features/auth/models/request/user_payload.dart';
import 'package:masti_adda_app/features/auth/models/response/user_model.dart';
import 'package:masti_adda_app/features/auth/repositories/auth_datasource.dart';

class EditProfileController extends GetxController {
  // ── State ─────────────────────────────────────────────────────────────────
  final Rx<UserModel?> user = Rx(null);
  final Rx<File?> localImageFile = Rx(null);
  final status = Status.init.obs;
  final RxString errorMessage = ''.obs;

  // ── Actions ───────────────────────────────────────────────────────────────
  void initialize(UserModel userModel) {
    user.value = userModel;
    localImageFile.value = null;
    status.value = Status.init;
    errorMessage.value = '';
  }

  void changeLocalImage(File imageFile) {
    localImageFile.value = imageFile;
  }

  final AuthDatasource _api = AuthDatasource();

  Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final original = user.value;
    if (original == null) return;

    status.value = Status.loading;
    errorMessage.value = '';

    try {
      final trimmedName = name.trim();
      final trimmedEmail = email.trim();
      final trimmedPhone = phone.trim();
      final newImagePath = localImageFile.value?.path;

      // Determine login method: Phone vs Google/Email
      final loginMethod = await StorageService.getLoginMethod();
      final isPhoneAuth = original.isPhoneAuth || loginMethod == 'phone';

      // Phone can only be updated if user logged in via Email/Google
      final String? phoneToSend = (!isPhoneAuth &&
              trimmedPhone.isNotEmpty &&
              trimmedPhone != original.phone)
          ? trimmedPhone
          : null;

      final payload = UserPayload(
        name: trimmedName.isNotEmpty && trimmedName != original.name
            ? trimmedName
            : null,
        email: trimmedEmail.isNotEmpty && trimmedEmail != original.email
            ? trimmedEmail
            : null,
        phone: phoneToSend,
        interests: null,
        profileImage: newImagePath,
      );

      final result = await _api.updateProfile(userPayload: payload);

      if (result != null) {
        user.value = result;
        status.value = Status.success;
      } else {
        status.value = Status.error;
        errorMessage.value = 'Failed to update profile. Please try again.';
      }
    } catch (e) {
      status.value = Status.error;
      if (e is AppException) {
        errorMessage.value = e.message;
      } else {
        final errStr = e.toString();
        final cleanMsg =
            errStr.replaceFirst(RegExp(r'^[a-zA-Z]+Exception:\s*'), '').trim();
        errorMessage.value = cleanMsg.isNotEmpty
            ? cleanMsg
            : 'Failed to update profile. Please try again.';
      }
      debugPrint("❌ Profile update failed: ${errorMessage.value}");
    }
  }
}
