import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/services/storage_service.dart';
import 'package:masti_adda_app/features/profile/models/response/plan_model.dart';
import 'package:masti_adda_app/features/profile/repositories/payment_repo.dart';
import 'package:masti_adda_app/web/utils/web_payment_result.dart';

class WebPaymentHelper {
  static final PaymentRepo _paymentRepo = PaymentRepo();

  static String? getLocalStorageItem(String key) {
    try {
      return web.window.localStorage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  static void removeLocalStorageItem(String key) {
    try {
      web.window.localStorage.removeItem(key);
    } catch (_) {}
  }

  /// Navigates to SabPaisa payment gateway for a given subscription plan on Web in the same tab by default
  static Future<WebPaymentResult> purchasePlan({
    required SubscriptionPlan plan,
    String? userName,
    String? userEmail,
    String? userContact,
    bool openInSameTab = true,
  }) async {
    web.Window? newWindow;
    if (!openInSameTab) {
      // Open a blank tab immediately within the user gesture context if opening in a new tab
      newWindow = web.window.open('about:blank', '_blank');
    }

    try {
      final callbackUrl = '${AppUrl.baseUrl}/api/payment/callback';
      final order = await _paymentRepo.createOrder(
        planId: plan.id,
        userName: userName,
        userEmail: userEmail,
        userContact: userContact,
        callbackUrl: callbackUrl,
      );

      if (order == null || order.paymentUrl.isEmpty) {
        newWindow?.close();
        return WebPaymentResult(
          success: false,
          errorMessage: 'Failed to initialize payment order on server',
        );
      }

      final txnId = order.transId.isNotEmpty ? order.transId : order.orderId;

      // Synchronously write to web window.localStorage as a fail-safe before page unloads
      if (txnId.isNotEmpty) {
        web.window.localStorage.setItem('pending_txn_id', txnId);
        web.window.localStorage.setItem('pending_plan_id', plan.id);
        if (order.paymentId.isNotEmpty) {
          web.window.localStorage.setItem('pending_payment_id', order.paymentId);
        }

        await StorageService.savePendingPayment(
          txnId: txnId,
          planId: plan.id,
          paymentId: order.paymentId,
        );
      }

      final target = openInSameTab ? '_self' : '_blank';

      if (order.encData.isNotEmpty) {
        // Form POST method (SabPaisa encrypted request)
        if (!openInSameTab) newWindow?.close();
        final form = web.document.createElement('form') as web.HTMLFormElement
          ..method = 'POST'
          ..action = order.paymentUrl
          ..target = target;

        order.rawData.forEach((key, value) {
          if (key != 'paymentUrl' &&
              key != 'url' &&
              key != 'checkoutUrl' &&
              key != 'success' &&
              key != 'plan' &&
              key != 'appliedPromo' &&
              value != null) {
            final input = web.document.createElement('input') as web.HTMLInputElement
              ..type = 'hidden'
              ..name = key
              ..value = value.toString();
            form.appendChild(input);
          }
        });

        web.document.body!.appendChild(form);
        form.submit();
        form.remove();
      } else {
        // Direct checkout URL method
        if (openInSameTab) {
          web.window.location.href = order.paymentUrl;
        } else {
          if (newWindow != null) {
            newWindow.location.href = order.paymentUrl;
          } else {
            web.window.open(order.paymentUrl, '_blank');
          }
        }
      }

      return WebPaymentResult(
        success: true,
        orderId: txnId,
        paymentId: order.paymentId,
      );
    } catch (e) {
      newWindow?.close();
      debugPrint("SabPaisa web payment error: $e");
      return WebPaymentResult(
        success: false,
        errorMessage: 'Payment error: ${e.toString()}',
      );
    }
  }
}
