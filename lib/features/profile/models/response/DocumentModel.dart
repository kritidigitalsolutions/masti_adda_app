class DocumentModel {
  final bool success;
  final List<Document> documents;

  const DocumentModel({required this.success, required this.documents});

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      success: json['success'] ?? false,
      documents: (json['documents'] as List<dynamic>? ?? [])
          .map((e) => Document.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'documents': documents.map((e) => e.toJson()).toList(),
    };
  }

  DocumentModel copyWith({bool? success, List<Document>? documents}) {
    return DocumentModel(
      success: success ?? this.success,
      documents: documents ?? this.documents,
    );
  }
}

class Document {
  final String id;
  final String type;
  final String title;
  final String content;
  final String lastUpdatedBy;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  const Document({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.lastUpdatedBy,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      lastUpdatedBy: json['lastUpdatedBy'] ?? '',
      isPublished: json['isPublished'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      version: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'title': title,
      'content': content,
      'lastUpdatedBy': lastUpdatedBy,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': version,
    };
  }

  Document copyWith({
    String? id,
    String? type,
    String? title,
    String? content,
    String? lastUpdatedBy,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
  }) {
    return Document(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}
