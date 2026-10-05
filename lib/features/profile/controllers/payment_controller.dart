import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/services/storage_service.dart';
import 'package:masti_adda_app/features/profile/controllers/subscription_status_controller.dart';
import 'package:masti_adda_app/features/profile/models/response/plan_model.dart';

class PaymentController extends GetxController with WidgetsBindingObserver {
  final RxBool isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("App resumed from website — checking subscription status...");
      checkAndUpdateStatus();
    }
  }

  /// Initiates payment for a SubscriptionPlan.
  /// Direct flow: Opens the website subscription/payment page directly on https://mastiadda.com without calling createOrder API.
  Future<void> startPayment({
    required SubscriptionPlan plan,
    String? promoCode,
    String? userEmail,
    String? userContact,
    String? userName,
  }) async {
    isProcessing.value = true;

    try {
      final token = await StorageService.getToken();
      final queryParams = <String, String>{
        'planId': plan.id,
        if (token != null && token.isNotEmpty) 'token': token,
        if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
        'source': 'app',
      };
      final uri = Uri.parse(AppUrl.webSubscription).replace(queryParameters: queryParams);
      debugPrint("🚀 Redirecting to Web URL => $uri");

      isProcessing.value = false;
      Get.snackbar(
        'Redirecting to Website',
        'Opening payment page on mastiadda.com...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint("Launch external application error: $e");
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (e2) {
          debugPrint("Launch platform default error: $e2");
          Get.snackbar(
            'Payment Error',
            'Could not open website payment page.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      isProcessing.value = false;
      debugPrint("PaymentController error: $e");
      Get.snackbar(
        'Payment Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  SubscriptionStatusController get _subController =>
      Get.isRegistered<SubscriptionStatusController>()
          ? Get.find<SubscriptionStatusController>()
          : Get.put(SubscriptionStatusController(), permanent: true);

  /// Manually verifies and checks subscription status upon returning from website
  Future<void> checkAndUpdateStatus() async {
    try {
      await _subController.checkStatus(verify: true);
      final isSubscribed = _subController.isPremiumUser.value;
      if (isSubscribed) {
        _subController.markAsPremium();
        Get.snackbar(
          'Subscription Active',
          'Your VIP subscription is successfully active!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("Check status error: $e");
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
