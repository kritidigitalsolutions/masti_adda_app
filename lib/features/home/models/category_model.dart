class CategoriesResponse {
  final bool success;
  final List<CategoryModel> categories;

  const CategoriesResponse({
    required this.success,
    required this.categories,
  });

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['categories'] ?? json['data'];
    return CategoriesResponse(
      success: json['success'] ?? false,
      categories: (rawList as List<dynamic>? ?? [])
          .map((e) => CategoryModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'categories': categories.map((e) => e.toJson()).toList(),
    };
  }

  CategoriesResponse copyWith({
    bool? success,
    List<CategoryModel>? categories,
  }) {
    return CategoriesResponse(
      success: success ?? this.success,
      categories: categories ?? this.categories,
    );
  }
}

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final int priority;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final int version;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.priority,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final dynamic active = json['isActive'] ?? json['is_active'] ?? json['active'];
    final bool isActiveParsed = active == null
        ? true
        : (active == true ||
            active == 1 ||
            active.toString().toLowerCase() == 'true');

    return CategoryModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      priority: (json['priority'] is num)
          ? (json['priority'] as num).toInt()
          : int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
      isActive: isActiveParsed,
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      version: (json['__v'] is num)
          ? (json['__v'] as num).toInt()
          : int.tryParse(json['__v']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'slug': slug,
      'priority': priority,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': version,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? slug,
    int? priority,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
    int? version,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}