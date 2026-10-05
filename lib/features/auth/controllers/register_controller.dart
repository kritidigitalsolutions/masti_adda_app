import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:get/get_utils/src/get_utils/get_utils.dart';
import 'package:masti_adda_app/constants/app_images.dart';
import 'package:masti_adda_app/features/auth/models/request/user_payload.dart';
import 'package:masti_adda_app/features/auth/repositories/auth_datasource.dart';
import 'package:masti_adda_app/routes/app_routes.dart';

class InterestItem {
  final String label;
  final String image;

  const InterestItem({required this.label, required this.image});
}

class RegistrationController extends GetxController {
  final AuthDatasource authDatasource = AuthDatasource();

  // ── Create Account fields ─────────────────────────────
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final RxBool isTermsAccepted = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isCompleteProfileLoading = false.obs;

  // Reactive field values for validation
  final RxString name = ''.obs;
  final RxString email = ''.obs;
  final RxString nameError = ''.obs;
  final RxString emailError = ''.obs;

  bool get isFormValid {
    final nameValid = name.value.trim().length >= 3;
    final emailText = email.value.trim();
    final emailValid = emailText.isEmpty || GetUtils.isEmail(emailText);
    return nameValid && emailValid && isTermsAccepted.value;
  }

  // ── Interests ─────────────────────────────────────────
  final List<InterestItem> interests = const [
    InterestItem(label: 'Movies', image: AppImages.film),
    InterestItem(label: 'Web Series', image: AppImages.videoEditing),
    InterestItem(label: 'Micro Dramas', image: AppImages.video),
    InterestItem(label: 'Action', image: AppImages.actionMovie),
    InterestItem(label: 'Romance', image: AppImages.romance),
    InterestItem(label: 'Thriller', image: AppImages.thriller),
    InterestItem(label: 'Comedy', image: AppImages.comedy),
    InterestItem(label: 'Bold Content', image: AppImages.plus18Movie),
    InterestItem(label: 'Suspense', image: AppImages.thinking),
    InterestItem(label: 'Horror', image: AppImages.horror),
    InterestItem(label: 'Fantasy', image: AppImages.magical),
  ];

  // Kept as index-based for the grid UI
  final RxList<int> selectedInterests = <int>[].obs;

  bool isInterestSelected(int index) => selectedInterests.contains(index);

  void toggleInterest(int index) {
    if (selectedInterests.contains(index)) {
      selectedInterests.remove(index);
    } else {
      selectedInterests.add(index);
    }
  }

  bool get hasSelectedInterests => selectedInterests.isNotEmpty;

  // Convert selected indices -> labels for the API payload
  List<String> get selectedInterestLabels =>
      selectedInterests.map((i) => interests[i].label).toList();

  void toggleTerms(bool? val) {
    isTermsAccepted.value = val ?? false;
  }

  void nextFromCreateAccount() async {
    if (!isFormValid) return;
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 800));
    isLoading.value = false;
    Get.toNamed(AppRoutes.selectInterests);
  }

  Future<void> continueFromInterests() async {
    if (!hasSelectedInterests) return;
    final ok = await completeProfile();
    if (ok) Get.offAllNamed(AppRoutes.allSet);
  }

  Future<void> skipInterests() async {
    final ok = await completeProfile();
    if (ok) Get.offAllNamed(AppRoutes.allSet);
  }

  void startWatching() {
    Get.offAllNamed(AppRoutes.home);
  }

  @override
  void onInit() {
    super.onInit();
    loadArguments();

    nameController.addListener(() {
      final val = nameController.text.trim();
      name.value = val;
      if (val.isEmpty) {
        nameError.value = '';
      } else if (val.length < 3) {
        nameError.value = 'Name must be at least 3 characters';
      } else {
        nameError.value = '';
      }
    });

    emailController.addListener(() {
      final val = emailController.text.trim();
      email.value = val;
      if (val.isEmpty) {
        emailError.value = '';
      } else if (!GetUtils.isEmail(val)) {
        emailError.value = 'Please enter a valid email address';
      } else {
        emailError.value = '';
      }
    });
  }

  void loadArguments() {
    if (Get.arguments != null) {
      if (Get.arguments['mobile'] != null &&
          phoneController.text.trim().isEmpty) {
        phoneController.text = Get.arguments['mobile'].toString();
      }
      if (Get.arguments['name'] != null &&
          Get.arguments['name'].toString().isNotEmpty) {
        nameController.text = Get.arguments['name'].toString();
        name.value = nameController.text.trim();
      }
      if (Get.arguments['email'] != null &&
          Get.arguments['email'].toString().isNotEmpty) {
        emailController.text = Get.arguments['email'].toString();
        email.value = emailController.text.trim();
      }
    }
  }

  // Relaxed: interests are optional now (skip flow allowed)
  Future<bool> completeProfile() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar("Error", "Please enter your name");
      return false;
    }

    if (emailController.text.trim().isNotEmpty &&
        !GetUtils.isEmail(emailController.text.trim())) {
      Get.snackbar("Error", "Please enter a valid email address");
      return false;
    }

    isCompleteProfileLoading.value = true;

    final request = UserPayload(
      phone: phoneController.text.trim(),
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      interests: selectedInterestLabels,
    );
    debugPrint("Complete Profile Request: ${request.toJson()}");

    final success = await authDatasource.completeProfile(userPayload: request);

    isCompleteProfileLoading.value = false;

    if (!success) {
      Get.snackbar("Error", "Something went wrong");
    }

    return success;
  }
}
