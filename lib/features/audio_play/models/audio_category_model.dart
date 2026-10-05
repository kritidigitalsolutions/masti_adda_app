class AudioCategoryModel {
  final String id;
  final String name;
  final String slug;
  final num priority;
  final String description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int v;

  const AudioCategoryModel({
    required this.id,
    required this.name,
    this.slug = '',
    this.priority = 0,
    this.description = '',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.v = 0,
  });

  factory AudioCategoryModel.fromJson(Map<String, dynamic> json) {
    return AudioCategoryModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      priority: (json['priority'] as num?) ?? 0,
      description: json['description']?.toString() ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      v: (json['__v'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'slug': slug,
    'priority': priority,
    'description': description,
    'isActive': isActive,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    '__v': v,
  };

  AudioCategoryModel copyWith({
    String? id,
    String? name,
    String? slug,
    num? priority,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
  }) {
    return AudioCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
    );
  }
}
