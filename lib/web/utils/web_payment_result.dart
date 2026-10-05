class WebPaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? errorMessage;

  WebPaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorMessage,
  });
}
