class HelpResponse {
  final bool success;
  final int count;
  final List<HelpData> helpData;

  const HelpResponse({
    required this.success,
    required this.count,
    required this.helpData,
  });

  factory HelpResponse.fromJson(Map<String, dynamic> json) {
    return HelpResponse(
      success: json['success'] ?? false,
      count: json['count'] ?? 0,
      helpData: (json['helpData'] as List<dynamic>? ?? [])
          .map((e) => HelpData.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'count': count,
      'helpData': helpData.map((e) => e.toJson()).toList(),
    };
  }

  HelpResponse copyWith({bool? success, int? count, List<HelpData>? helpData}) {
    return HelpResponse(
      success: success ?? this.success,
      count: count ?? this.count,
      helpData: helpData ?? this.helpData,
    );
  }
}

class HelpData {
  final String id;
  final String category;
  final String question;
  final String answer;
  final String supportNumber;
  final String supportEmail; // ✅ add this
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  const HelpData({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.supportNumber,
    required this.supportEmail, // ✅ add this
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory HelpData.fromJson(Map<String, dynamic> json) {
    return HelpData(
      id: json['_id'] ?? '',
      category: json['category'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      supportNumber: json['supportNumber'] ?? '',
      supportEmail: json['supportEmail'] ?? '', // ✅ add this
      isPublished: json['isPublished'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      version: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'category': category,
      'question': question,
      'answer': answer,
      'supportNumber': supportNumber,
      'supportEmail': supportEmail, // ✅ add this
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': version,
    };
  }

  HelpData copyWith({
    String? id,
    String? category,
    String? question,
    String? answer,
    String? supportNumber,
    String? supportEmail, // ✅ add this
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
  }) {
    return HelpData(
      id: id ?? this.id,
      category: category ?? this.category,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      supportNumber: supportNumber ?? this.supportNumber,
      supportEmail: supportEmail ?? this.supportEmail, // ✅ add this
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}
