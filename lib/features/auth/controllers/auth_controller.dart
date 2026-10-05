import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/core/services/firebase_service.dart';
import 'package:masti_adda_app/core/services/google_auth_service.dart';
import 'package:masti_adda_app/features/auth/repositories/auth_datasource.dart';
import 'package:masti_adda_app/features/home/controllers/ai_reels_controller.dart';
import 'package:masti_adda_app/routes/app_routes.dart';

import '../../../core/services/storage_service.dart';
import '../models/response/user_model.dart';

// ── Splash Controller ──────────────────────────────────────────
class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;

  @override
  void onInit() {
    super.onInit();
    _setupAnimations();
    _navigateAfterDelay();
  }

  void _setupAnimations() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeIn,
    );

    scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeOutBack),
    );

    animationController.forward();
  }

  void _navigateAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      Get.offNamed(AppRoutes.onboarding);
    });
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}

// ── Onboarding Controller & Model ──────────────────────────────
class OnboardingPage {
  final String title;
  final String titleHighlight;
  final String subtitle;
  final String? imagePath;
  final String? imageUrl;
  final Color accentColor;

  const OnboardingPage({
    required this.title,
    this.titleHighlight = '',
    this.subtitle = '',
    this.imagePath,
    this.imageUrl,
    this.accentColor = const Color(0xFFFF0564),
  });
}

class OnboardingController extends GetxController {
  final AuthDatasource _authDatasource = AuthDatasource();
  final PageController pageController = PageController();

  final RxInt currentPage = 0.obs;

  final RxList<OnboardingPage> pages = <OnboardingPage>[
    const OnboardingPage(
      title: 'Blockbuster Movies',
      titleHighlight: '& Web Series',
      subtitle: 'Enjoy premium entertainment in\ncinematic widescreen format.',
      imagePath: 'assets/auth/onborading1.png',
      accentColor: Color(0xFFFF0564),
    ),
    const OnboardingPage(
      title: 'Short Vertical',
      titleHighlight: 'Dramas',
      subtitle: 'Binge addictive stories\nanytime, anywhere.',
      imagePath: 'assets/auth/onb2.png',
      accentColor: Color(0xFFFED301),
    ),
  ].obs;

  @override
  void onInit() {
    super.onInit();
    fetchIntroScreens();
  }

  Future<void> fetchIntroScreens() async {
    try {
      final response = await _authDatasource.fetchIntroScreens();
      if (response != null &&
          response.data != null &&
          response.data!.isNotEmpty) {
        final List<OnboardingPage> apiPages = response.data!.map((item) {
          return OnboardingPage(
            title: item.title ?? 'Welcome',
            imageUrl: item.image,
            accentColor: (item.order ?? 1) % 2 == 0
                ? const Color(0xFFFED301)
                : const Color(0xFFFF0564),
          );
        }).toList();
        pages.assignAll(apiPages);
      }
    } catch (e) {
      debugPrint("Error fetching intro screens: $e");
    }
  }

  bool get isLastPage => currentPage.value >= pages.length - 1;
  int get totalPages => pages.length;

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void nextPage() {
    if (isLastPage) {
      Get.toNamed(AppRoutes.login);
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

// ── Auth Controller (Login, OTP, Google Auth) ──────────────────
class AuthController extends GetxController {
  final AuthDatasource authDatasource = AuthDatasource();
  final GoogleAuthService googleAuthService = GoogleAuthService();

  // ── State ───────────────────────────────────────────
  final RxBool isLoading = false.obs;
  final Rx<UserModel?> userData = Rx<UserModel?>(null);
  final RxBool isLoggedIn = false.obs;

  // ── Website Auto-Login ──────────────────────────────
  Future<bool> websiteLogin(String token) async {
    isLoading.value = true;
    try {
      await StorageService.saveToken(token);
      authDatasource.setToken(token);

      final response = await authDatasource.websiteLogin();
      if (response != null && response.success) {
        if (response.user != null) {
          userData.value = response.user;
          await StorageService.saveUser(response.user!);
        }
        isLoggedIn.value = true;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Website Login Error: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Google Sign-In ──────────────────────────────────
  final RxBool isGoogleLoading = false.obs;

  // ── Mobile ──────────────────────────────────────────
  final TextEditingController mobileController = TextEditingController();
  final RxString mobileNumber = ''.obs;
  final RxBool isMobileValid = false.obs;
  final RxString mobileError = ''.obs;
  final RxBool sendOtpStatus = false.obs;
  final RxBool resendOtpStatus = false.obs;

  // ── OTP ──────────────────────────────────────────────
  final List<TextEditingController> otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> otpFocusNodes = List.generate(4, (_) => FocusNode());
  final RxString otp = ''.obs;
  final RxBool isOtpValid = false.obs;
  final RxString otpError = ''.obs;
  final RxBool verifyOtpStatus = false.obs;

  // ── Timer ────────────────────────────────────────────
  Timer? _timer;
  final RxInt secondsRemaining = 30.obs;
  final RxBool canResend = false.obs;

  String get formattedTimer {
    final min = (secondsRemaining.value ~/ 60).toString().padLeft(2, '0');
    final sec = (secondsRemaining.value % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments['mobile'] != null) {
      mobileNumber.value = Get.arguments['mobile'].toString();
      mobileController.text = mobileNumber.value;
    }
  }

  // ── Mobile Validation ────────────────────────────────
  void validateMobile(String value) {
    mobileNumber.value = value.trim();

    if (value.isEmpty) {
      mobileError.value = "Mobile number is required";
      isMobileValid.value = false;
    } else if (value.length != 10) {
      mobileError.value = "Enter valid 10-digit mobile number";
      isMobileValid.value = false;
    } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
      mobileError.value = "Indian mobile numbers must start with 6, 7, 8, or 9";
      isMobileValid.value = false;
    } else {
      mobileError.value = "";
      isMobileValid.value = true;
    }
  }

  // ── Send OTP ─────────────────────────────────────────
  Future<void> sendOTP() async {
    if (!isMobileValid.value) {
      Get.snackbar(
        "Error",
        mobileError.value.isNotEmpty
            ? mobileError.value
            : "Enter valid mobile number",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      sendOtpStatus.value = true;
      final result = await authDatasource.sendOtp(phone: mobileNumber.value);
      sendOtpStatus.value = false;

      if (result) {
        startTimer();
        Get.toNamed(
          AppRoutes.verifyOtp,
          arguments: {"mobile": mobileNumber.value},
        );
      } else {
        Get.snackbar(
          "Error",
          "Failed to send OTP",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      sendOtpStatus.value = false;
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ── OTP Changed ──────────────────────────────────────
  void onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 3) {
      otpFocusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }

    otp.value = otpControllers.map((e) => e.text).join();
    isOtpValid.value = otp.value.length == 4;

    if (!isOtpValid.value) {
      otpError.value = "Enter valid OTP";
    } else {
      otpError.value = "";
      otpFocusNodes[index].unfocus();
      verifyOTP(); // auto-trigger verification
    }
  }

  // ── Verify OTP ───────────────────────────────────────
  Future<void> verifyOTP() async {
    if (!isOtpValid.value) {
      otpError.value = "Please enter a valid OTP";
      return;
    }

    try {
      verifyOtpStatus.value = true;
      final enteredOtp = otpControllers.map((e) => e.text).join();

      final result = await authDatasource.verifyOtp(
        phone: mobileNumber.value,
        otp: enteredOtp,
      );

      verifyOtpStatus.value = false;

      if (result.success) {
        _timer?.cancel();
        if (Get.isRegistered<AiReelsController>()) {
          Get.find<AiReelsController>().resetState();
          Get.delete<AiReelsController>(force: true);
        }
        if (!result.profileComplete) {
          Get.offAllNamed(
            AppRoutes.createAccount,
            arguments: {"mobile": mobileNumber.value},
          );
        } else {
          Get.offAllNamed(AppRoutes.home);
        }
      } else {
        Get.snackbar(
          "Error",
          result.message ?? "Invalid OTP",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      verifyOtpStatus.value = false;
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ── Timer & Resend OTP ───────────────────────────────
  void startTimer() {
    _timer?.cancel();
    canResend.value = false;
    secondsRemaining.value = 30;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value <= 1) {
        secondsRemaining.value = 0;
        canResend.value = true;
        timer.cancel();
      } else {
        secondsRemaining.value--;
      }
    });
  }

  Future<void> resendOtp() async {
    if (!canResend.value || resendOtpStatus.value) return;

    if (mobileNumber.value.isEmpty) {
      if (Get.arguments != null && Get.arguments['mobile'] != null) {
        mobileNumber.value = Get.arguments['mobile'].toString();
      }
    }

    try {
      resendOtpStatus.value = true;
      final result = await authDatasource.sendOtp(phone: mobileNumber.value);
      resendOtpStatus.value = false;

      if (result) {
        for (var e in otpControllers) {
          e.clear();
        }

        otp.value = "";
        otpError.value = "";
        isOtpValid.value = false;

        startTimer();

        if (otpFocusNodes.isNotEmpty) {
          otpFocusNodes.first.requestFocus();
        }

        Get.snackbar(
          "Success",
          "OTP sent again successfully",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          "Error",
          "Failed to resend OTP",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      resendOtpStatus.value = false;
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ── Google Sign-In ──────────────────────────────────
  Future<void> loginWithGoogle() async {
    if (isGoogleLoading.value) return;

    try {
      isGoogleLoading.value = true;
      final account = await googleAuthService.signIn();

      if (account == null) {
        // User cancelled sign-in
        isGoogleLoading.value = false;
        return;
      }

      final auth = await googleAuthService.getAuthentication(account);
      final idToken = (auth?.idToken != null && auth!.idToken!.isNotEmpty)
          ? auth.idToken!
          : (auth?.accessToken ?? '');

      if (idToken.isEmpty) {
        isGoogleLoading.value = false;
        Get.snackbar(
          "Login Failed",
          "Failed to get Google token. Please try again.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }

      // Fetch FCM Token if available
      String? fcmToken;
      try {
        if (Get.isRegistered<NotificationService>()) {
          fcmToken = await NotificationService.to.getFcmToken();
        }
      } catch (e) {
        debugPrint("FCM token fetch error on Google Login: $e");
      }

      final result = await authDatasource.googleLogin(
        idToken: idToken,
        accessToken: auth?.accessToken,
        email: account.email,
        name: account.displayName,
        photoUrl: account.photoUrl,
        googleId: account.id,
        fcmToken: fcmToken,
      );

      isGoogleLoading.value = false;

      if (result.success) {
        // Sync FCM token if NotificationService is initialized
        try {
          if (Get.isRegistered<NotificationService>()) {
            NotificationService.to.uploadToken();
          }
        } catch (e) {
          debugPrint("FCM upload error on Google Login: $e");
        }

        if (Get.isRegistered<AiReelsController>()) {
          Get.find<AiReelsController>().resetState();
          Get.delete<AiReelsController>(force: true);
        }

        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.snackbar(
          "Login Failed",
          result.message ?? "Failed to sign in with Google. Please try again.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      isGoogleLoading.value = false;
      debugPrint("Google Sign In Exception: $e");
      Get.snackbar(
        "Error",
        "Google Sign-In failed: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // ── Verified screen helper ───────────────────────────
  void continueToHome() {
    Get.offAllNamed(AppRoutes.createAccount);
  }

  @override
  void onClose() {
    _timer?.cancel();
    mobileController.dispose();
    for (final c in otpControllers) {
      c.dispose();
    }
    for (final f in otpFocusNodes) {
      f.dispose();
    }
    super.onClose();
  }
}
