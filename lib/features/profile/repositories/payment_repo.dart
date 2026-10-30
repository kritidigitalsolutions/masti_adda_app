import 'package:flutter/foundation.dart';
import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';

class PaymentRepo {
  final NetworkApiService _apiService = NetworkApiService();

  /// Creates payment order on the backend for the selected plan.
  /// Supports both SabPaisa PG 3.0 (/api/payment/initiate) and legacy (/api/payment/create-order).
  Future<SabPaisaOrderResponse?> createOrder({
    required String planId,
    String? promoCode,
    String? userName,
    String? userEmail,
    String? userContact,
    String? callbackUrl,
  }) async {
    final origin = kIsWeb ? Uri.base.origin : AppUrl.webBaseUrl;
    final frontendReturn = '$origin/subscription';

    // 1. First attempt: SabPaisa PG 3.0 initiate API (/api/payment/initiate)
    try {
      debugPrint(
        "🚀 [PaymentRepo] Calling SabPaisa PG 3.0 initiate: ${AppUrl.initiatePayment}",
      );
      final initiatePayload = {
        'planId': planId,
        'promoCode': promoCode ?? '',
        'returnUrl': frontendReturn,
        if (userName != null && userName.isNotEmpty) 'userName': userName,
        if (userEmail != null && userEmail.isNotEmpty) 'userEmail': userEmail,
        if (userContact != null && userContact.isNotEmpty)
          'userContact': userContact,
      };
      final response = await _apiService.postApi(
        AppUrl.initiatePayment,
        initiatePayload,
      );
      debugPrint("✅ [PaymentRepo] Initiate response: $response");
      if (response != null &&
          (response['success'] == true ||
              response['checkoutUrl'] != null ||
              response['paymentUrl'] != null)) {
        final order = SabPaisaOrderResponse.fromJson(response);
        if (order.paymentUrl.isNotEmpty) {
          return order;
        }
      }
    } catch (e) {
      debugPrint(
        "⚠️ [PaymentRepo] PG 3.0 initiate failed, trying fallback: $e",
      );
    }

    // 2. Fallback attempt: Legacy create-order API (/api/payment/create-order)
    try {
      final backendCallback = '${AppUrl.baseUrl}/api/payment/callback';
      final finalCallback = callbackUrl ?? backendCallback;

      debugPrint(
        "🚀 [PaymentRepo] Calling legacy create-order: ${AppUrl.createOrder}",
      );
      final response = await _apiService.postApi(AppUrl.createOrder, {
        'planId': planId,
        'promoCode': promoCode ?? '',
        if (userName != null && userName.isNotEmpty) 'userName': userName,
        if (userEmail != null && userEmail.isNotEmpty) 'userEmail': userEmail,
        if (userContact != null && userContact.isNotEmpty)
          'userContact': userContact,
        'callbackUrl': finalCallback,
        'returnUrl': frontendReturn,
        'redirectUrl': frontendReturn,
        'frontendUrl': frontendReturn,
      });
      return SabPaisaOrderResponse.fromJson(response);
    } catch (e) {
      debugPrint('❌ [PaymentRepo.createOrder] All attempts failed => $e');
      return null;
    }
  }

  /// Verifies payment using PG 3.0 status check or legacy verify API
  Future<VerifyPaymentResponse?> verifyPayment({
    required String transactionId,
    required String planId,
    String? paymentId,
    Map<String, dynamic>? extraData,
  }) async {
    final cleanTxnId = transactionId.trim();
    if (cleanTxnId.isEmpty) {
      return const VerifyPaymentResponse(
        success: false,
        message: 'No transaction ID to verify',
      );
    }

    // 1. Try PG 3.0 status enquiry: GET /api/payment/status/:clientTxnId
    try {
      final statusUrl = AppUrl.paymentStatus(cleanTxnId);
      debugPrint("🔍 [PaymentRepo] Checking PG 3.0 status: $statusUrl");
      final res = await _apiService.getApi(statusUrl);
      if (res != null) {
        final statusStr = (res['status'] ?? '').toString().toLowerCase().trim();
        final statusCode = (res['statusCode'] ?? '').toString().trim();
        final isSuccess = res['success'] == true &&
            (statusStr == 'success' || statusCode == '0000');

        // If backend explicitly returned status, respect it directly without blind fallback
        return VerifyPaymentResponse(
          success: isSuccess,
          message: (res['message'] ?? (isSuccess ? 'Payment verified successfully' : 'Payment was not successful')).toString(),
        );
      }
    } catch (e) {
      debugPrint("⚠️ [PaymentRepo] PG 3.0 status check failed, trying fallback verify API: $e");
    }

    // 2. Fallback to POST /api/payment/verify
    try {
      final payload = <String, dynamic>{
        'transactionId': cleanTxnId,
        'clientTxnId': cleanTxnId,
        'merchantTxnId': cleanTxnId,
        'paymentId': paymentId ?? cleanTxnId,
        if (extraData != null && extraData.containsKey('paymentId'))
          'paymentId': extraData['paymentId'],
        'orderId': cleanTxnId,
        'txnId': cleanTxnId,
        'planId': planId,
        ...?extraData,
      };
      final response = await _apiService.postApi(AppUrl.verifyPayment, payload);
      return VerifyPaymentResponse.fromJson(response);
    } catch (e) {
      debugPrint('PaymentRepo.verifyPayment error => $e');
      return null;
    }
  }

  // Alias for backward compatibility
  Future<SabPaisaOrderResponse?> createSabPaisaOrder({
    required String planId,
    String? promoCode,
    String? userName,
    String? userEmail,
    String? userContact,
  }) async {
    return createOrder(
      planId: planId,
      promoCode: promoCode,
      userName: userName,
      userEmail: userEmail,
      userContact: userContact,
    );
  }

  Future<VerifyPaymentResponse?> verifySabPaisaPayment({
    required String transactionId,
    required String planId,
    Map<String, dynamic>? extraData,
  }) async {
    return verifyPayment(
      transactionId: transactionId,
      planId: planId,
      extraData: extraData,
    );
  }
}

class VerifyPaymentResponse {
  const VerifyPaymentResponse({required this.success, required this.message});

  final bool success;
  final String message;

  factory VerifyPaymentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final statusStr = (data['status'] ?? json['status'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    final statusCode = (data['statusCode'] ?? json['statusCode'] ?? '')
        .toString()
        .trim();

    // If status explicitly says failed, cancelled, pending, etc., it is NOT a success
    if (statusStr == 'failed' ||
        statusStr == 'failure' ||
        statusStr == 'cancelled' ||
        statusStr == 'canceled' ||
        statusStr == 'pending' ||
        statusStr == 'aborted') {
      return VerifyPaymentResponse(
        success: false,
        message: (json['message'] ??
                data['message'] ??
                'Payment was not completed or was cancelled')
            .toString(),
      );
    }

    final isSuccess = statusStr == 'success' ||
        statusStr == 'paid' ||
        statusStr == 'completed' ||
        statusCode == '0000' ||
        (json['success'] == true && (json['subscription'] != null || data['subscription'] != null));

    return VerifyPaymentResponse(
      success: isSuccess,
      message: (json['message'] ??
              data['message'] ??
              json['msg'] ??
              data['msg'] ??
              '')
          .toString(),
    );
  }
}

class SabPaisaOrderResponse {
  const SabPaisaOrderResponse({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.paymentUrl,
    required this.clientCode,
    required this.encData,
    required this.transId,
    required this.paymentId,
    required this.rawData,
  });

  final String orderId;
  final double amount;
  final String currency;
  final String paymentUrl;
  final String clientCode;
  final String encData;
  final String transId;
  final String paymentId;
  final Map<String, dynamic> rawData;

  factory SabPaisaOrderResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return SabPaisaOrderResponse(
      orderId:
          (data['orderId'] ??
                  data['id'] ??
                  data['order_id'] ??
                  data['clientTxnId'] ??
                  '')
              .toString(),
      amount:
          double.tryParse('${data['amount'] ?? data['finalAmount'] ?? 0}') ??
          0.0,
      currency: (data['currency'] ?? 'INR').toString(),
      paymentUrl:
          (data['paymentUrl'] ??
                  data['checkoutUrl'] ??
                  data['url'] ??
                  data['payment_url'] ??
                  '')
              .toString(),
      clientCode: (data['clientCode'] ?? data['merchantId'] ?? '').toString(),
      encData: (data['encData'] ?? '').toString(),
      transId:
          (data['transId'] ??
                  data['clientTxnId'] ??
                  data['transactionId'] ??
                  '')
              .toString(),
      paymentId: (data['paymentId'] ?? data['sppayId'] ?? data['id'] ?? '')
          .toString(),
      rawData: data,
    );
  }
}
