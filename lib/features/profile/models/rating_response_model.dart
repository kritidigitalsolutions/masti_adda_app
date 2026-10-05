class RatingResponseModel {
  final bool success;
  final String message;
  final dynamic data;

  const RatingResponseModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory RatingResponseModel.fromJson(Map<String, dynamic> json) {
    return RatingResponseModel(
      success: json['success'] ?? (json['status'] == 'success') ?? true,
      message: json['message']?.toString() ?? '',
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (data != null) 'data': data,
    };
  }
}
