import 'package:flutter/foundation.dart';
import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';

class PaymentRepo {
  final NetworkApiService _apiService = NetworkApiService();

  /// Creates payment order on the backend for the selected plan using AppUrl.createOrder
  Future<SabPaisaOrderResponse?> createOrder({
    required String planId,
    String? promoCode,
    String? userName,
    String? userEmail,
    String? userContact,
    String? callbackUrl,
  }) async {
    try {
      final origin = kIsWeb ? Uri.base.origin : AppUrl.webBaseUrl;
      final backendCallback = '${AppUrl.baseUrl}/api/payment/callback';
      final frontendReturn = '$origin/subscription';
      final finalCallback = callbackUrl ?? backendCallback;

      final response = await _apiService.postApi(AppUrl.createOrder, {
        'planId': planId,
        'promoCode': promoCode ?? '',
        if (userName != null && userName.isNotEmpty) 'userName': userName,
        if (userEmail != null && userEmail.isNotEmpty) 'userEmail': userEmail,
        if (userContact != null && userContact.isNotEmpty) 'userContact': userContact,
        'callbackUrl': finalCallback,
        'returnUrl': frontendReturn,
        'redirectUrl': frontendReturn,
        'frontendUrl': frontendReturn,
      });
      return SabPaisaOrderResponse.fromJson(response);
    } catch (e) {
      debugPrint('PaymentRepo.createOrder error => $e');
      return null;
    }
  }

  /// Verifies payment using AppUrl.verifyPayment
  Future<VerifyPaymentResponse?> verifyPayment({
    required String transactionId,
    required String planId,
    String? paymentId,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final payload = <String, dynamic>{
        'transactionId': transactionId,
        'clientTxnId': transactionId,
        'merchantTxnId': transactionId,
        'paymentId': paymentId ?? transactionId,
        if (extraData != null && extraData.containsKey('paymentId')) 'paymentId': extraData['paymentId'],
        'orderId': transactionId,
        'txnId': transactionId,
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
    return verifyPayment(transactionId: transactionId, planId: planId, extraData: extraData);
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
    final statusStr = (data['status'] ?? json['status'] ?? '').toString().toLowerCase();
    final isSuccess = json['success'] == true ||
        data['success'] == true ||
        statusStr == 'success' ||
        statusStr == 'paid' ||
        statusStr == 'completed';

    return VerifyPaymentResponse(
      success: isSuccess,
      message: (json['message'] ?? data['message'] ?? json['msg'] ?? data['msg'] ?? '').toString(),
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
      orderId: (data['orderId'] ?? data['id'] ?? data['order_id'] ?? data['clientTxnId'] ?? '').toString(),
      amount: double.tryParse('${data['amount'] ?? data['finalAmount'] ?? 0}') ?? 0.0,
      currency: (data['currency'] ?? 'INR').toString(),
      paymentUrl: (data['paymentUrl'] ?? data['checkoutUrl'] ?? data['url'] ?? data['payment_url'] ?? '').toString(),
      clientCode: (data['clientCode'] ?? data['merchantId'] ?? '').toString(),
      encData: (data['encData'] ?? '').toString(),
      transId: (data['transId'] ?? data['clientTxnId'] ?? data['transactionId'] ?? '').toString(),
      paymentId: (data['paymentId'] ?? data['sppayId'] ?? data['id'] ?? '').toString(),
      rawData: data,
    );
  }
}
