import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/core/services/storage_service.dart';
import 'package:masti_adda_app/features/profile/models/response/subscription_status_model.dart';
import 'package:masti_adda_app/features/profile/repositories/payment_repo.dart';
import 'package:masti_adda_app/features/profile/repositories/profile_datasource.dart';

class SubscriptionStatusController extends GetxController {
  final ProfileDatasource _datasource = ProfileDatasource();
  final PaymentRepo _paymentRepo = PaymentRepo();

  final RxBool isLoading = false.obs;
  final Rxn<SubscriptionStatusResponse> subscriptionStatus = Rxn<SubscriptionStatusResponse>();
  final RxBool isPremiumUser = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkStatus(verify: false);
  }

  void markAsPremium() {
    isPremiumUser.value = true;
  }

  Future<void> checkStatus({bool verify = false}) async {
    try {
      isLoading.value = true;

      // Only verify pending payment if explicitly requested (e.g. returning from payment gateway or manual refresh)
      if (verify) {
        final pending = await StorageService.getPendingPayment();
        if (pending != null) {
          final txnId = pending['txnId'];
          final planId = pending['planId'];
          if (txnId != null && txnId.isNotEmpty && planId != null && planId.isNotEmpty) {
            debugPrint("Verifying pending payment: txnId=$txnId, planId=$planId");
            final verifyRes = await _paymentRepo.verifyPayment(
              transactionId: txnId,
              planId: planId,
            );
            if (verifyRes != null && verifyRes.success) {
              await StorageService.clearPendingPayment();
              isPremiumUser.value = true; // Force active immediately on successful verification
            }
          }
        }
      }

      final result = await _datasource.fetchSubscriptionStatus();
      if (result != null) {
        subscriptionStatus.value = result;
        // A user is premium if the API returns success and the active subscription exists and is active.
        final serverIsActive = result.success &&
            result.subscription != null &&
            result.subscription!.status.toLowerCase() == 'active';
        
        if (serverIsActive) {
          isPremiumUser.value = true;
          await StorageService.clearPendingPayment();
        } else if (!isPremiumUser.value) {
          isPremiumUser.value = false;
        }
      } else {
        if (!isPremiumUser.value) {
          isPremiumUser.value = false;
        }
        subscriptionStatus.value = null;
      }
    } catch (e) {
      debugPrint("SubscriptionStatusController checkStatus error: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
