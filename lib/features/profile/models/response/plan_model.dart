class SubscriptionPlansResponse {
  final bool success;
  final String planType;
  final int count;
  final List<SubscriptionPlan> plans;

  const SubscriptionPlansResponse({
    required this.success,
    required this.planType,
    required this.count,
    required this.plans,
  });

  factory SubscriptionPlansResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlansResponse(
      success: json['success'] ?? false,
      planType: json['planType'] ?? '',
      count: json['count'] ?? 0,
      plans: (json['plans'] as List<dynamic>? ?? [])
          .map((e) => SubscriptionPlan.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'planType': planType,
      'count': count,
      'plans': plans.map((e) => e.toJson()).toList(),
    };
  }

  SubscriptionPlansResponse copyWith({
    bool? success,
    String? planType,
    int? count,
    List<SubscriptionPlan>? plans,
  }) {
    return SubscriptionPlansResponse(
      success: success ?? this.success,
      planType: planType ?? this.planType,
      count: count ?? this.count,
      plans: plans ?? this.plans,
    );
  }
}

class SubscriptionPlan {
  final String id;
  final String name;
  final num price;
  final int duration;
  final List<String> features;
  final bool isActive;
  final String planType;
  final int sortOrder;
  final bool isRecommended;
  final String createdAt;
  final String updatedAt;
  final int version;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.features,
    required this.isActive,
    required this.planType,
    required this.sortOrder,
    required this.isRecommended,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      duration: json['duration'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
      isActive: json['isActive'] ?? false,
      planType: json['planType'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
      isRecommended: json['isRecommended'] ?? false,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      version: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'duration': duration,
      'features': features,
      'isActive': isActive,
      'planType': planType,
      'sortOrder': sortOrder,
      'isRecommended': isRecommended,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': version,
    };
  }

  SubscriptionPlan copyWith({
    String? id,
    String? name,
    num? price,
    int? duration,
    List<String>? features,
    bool? isActive,
    String? planType,
    int? sortOrder,
    bool? isRecommended,
    String? createdAt,
    String? updatedAt,
    int? version,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
      planType: planType ?? this.planType,
      sortOrder: sortOrder ?? this.sortOrder,
      isRecommended: isRecommended ?? this.isRecommended,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}
