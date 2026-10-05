import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/core/services/storage_service.dart';
import 'package:masti_adda_app/features/profile/controllers/subscription_status_controller.dart';
import 'package:masti_adda_app/web/routes/web_routes.dart';
import 'package:masti_adda_app/web/screens/auth/web_login_dialog.dart';

class WebAuthGuard {
  /// Checks if a valid auth token exists.
  static Future<bool> isAuthenticated() async {
    final token = await StorageService.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Checks if the logged-in user has an active VIP subscription plan.
  static Future<bool> isSubscribed() async {
    final subController = Get.isRegistered<SubscriptionStatusController>()
        ? Get.find<SubscriptionStatusController>()
        : Get.put(SubscriptionStatusController());

    if (subController.subscriptionStatus.value == null) {
      await subController.checkStatus();
    }
    return subController.isPremiumUser.value;
  }

  /// Requires authentication before performing an action (e.g. Play/Watch).
  /// If not authenticated, displays the WebLoginDialog.
  /// If the user successfully logs in, [onSuccess] is invoked.
  static Future<void> requireAuth({
    required BuildContext context,
    required VoidCallback onSuccess,
    String message = 'Please sign in to watch and enjoy unlimited content on Masti Adda.',
  }) async {
    final loggedIn = await isAuthenticated();
    if (loggedIn) {
      onSuccess();
      return;
    }

    if (!context.mounted) return;

    // Show login dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => WebLoginDialog(customMessage: message),
    );

    if (result == true) {
      onSuccess();
    }
  }

  /// Checks authentication AND subscription for premium content.
  /// If unauthenticated -> prompts login modal.
  /// If content is premium AND user does NOT have active subscription -> directly navigates to /subscription!
  /// If content is free OR user is an active VIP subscriber -> calls [onSuccess].
  static Future<void> requireAuthAndSubscription({
    required BuildContext context,
    required bool isPremium,
    required VoidCallback onSuccess,
    String? contentTitle,
  }) async {
    await requireAuth(
      context: context,
      message: isPremium
          ? 'Sign in to access VIP premium content on Masti Adda.'
          : 'Please sign in to watch and enjoy unlimited content on Masti Adda.',
      onSuccess: () async {
        if (!isPremium) {
          onSuccess();
          return;
        }

        final subscribed = await isSubscribed();
        if (subscribed) {
          onSuccess();
        } else {
          // User has not purchased a plan -> directly navigate to subscription page!
          Get.snackbar(
            'VIP Subscription Required',
            contentTitle != null && contentTitle.isNotEmpty
                ? '“$contentTitle” is a premium title. Please subscribe to a VIP plan to watch.'
                : 'This content requires an active VIP subscription plan.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.primaryPink.withOpacity(0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );

          if (Get.currentRoute != WebRoutes.subscription) {
            Get.toNamed(WebRoutes.subscription);
          }
        }
      },
    );
  }
}
