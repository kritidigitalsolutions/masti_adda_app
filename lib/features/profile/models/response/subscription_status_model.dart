import 'plan_model.dart';

class SubscriptionStatusResponse {
  final bool success;
  final UserSubscription? subscription;
  final int remainingDays;

  const SubscriptionStatusResponse({
    required this.success,
    this.subscription,
    required this.remainingDays,
  });

  factory SubscriptionStatusResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusResponse(
      success: json['success'] ?? false,
      subscription: json['subscription'] != null
          ? UserSubscription.fromJson(json['subscription'])
          : null,
      remainingDays: json['remainingDays'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'subscription': subscription?.toJson(),
      'remainingDays': remainingDays,
    };
  }
}

class UserSubscription {
  final String id;
  final String user;
  final SubscriptionPlan plan;
  final String status;
  final String subscriptionId;
  final String paymentId;
  final num amount;
  final String currency;
  final String? promoCode;
  final String? voucherCode;
  final String startDate;
  final String endDate;
  final String createdAt;
  final String updatedAt;

  const UserSubscription({
    required this.id,
    required this.user,
    required this.plan,
    required this.status,
    required this.subscriptionId,
    required this.paymentId,
    required this.amount,
    required this.currency,
    this.promoCode,
    this.voucherCode,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['_id'] ?? '',
      user: json['user'] ?? '',
      plan: SubscriptionPlan.fromJson(json['plan'] ?? {}),
      status: json['status'] ?? '',
      subscriptionId: json['subscriptionId'] ?? '',
      paymentId: json['paymentId'] ?? '',
      amount: json['amount'] ?? 0,
      currency: json['currency'] ?? 'INR',
      promoCode: json['promoCode'],
      voucherCode: json['voucherCode'],
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user,
      'plan': plan.toJson(),
      'status': status,
      'subscriptionId': subscriptionId,
      'paymentId': paymentId,
      'amount': amount,
      'currency': currency,
      'promoCode': promoCode,
      'voucherCode': voucherCode,
      'startDate': startDate,
      'endDate': endDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
