class CategoryContentResponse {
  final bool success;
  final Category category;
  final List<ContentModel> content;

  const CategoryContentResponse({
    required this.success,
    required this.category,
    required this.content,
  });

  factory CategoryContentResponse.fromJson(Map<String, dynamic> json) {
    final rawContent = json['data'] ?? json['content'];
    return CategoryContentResponse(
      success: json['success'] ?? false,
      category: Category.fromJson(json['category'] ?? {}),
      content: (rawContent as List<dynamic>? ?? [])
          .map((e) => ContentModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'category': category.toJson(),
      'content': content.map((e) => e.toJson()).toList(),
    };
  }

  CategoryContentResponse copyWith({
    bool? success,
    Category? category,
    List<ContentModel>? content,
  }) {
    return CategoryContentResponse(
      success: success ?? this.success,
      category: category ?? this.category,
      content: content ?? this.content,
    );
  }
}

class Category {
  final String id;
  final String name;
  final String slug;
  final int priority;
  final bool isActive;
  final bool isHide;
  final String createdAt;
  final String updatedAt;
  final int version;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.priority,
    required this.isActive,
    this.isHide = false,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  bool get isVisible => isActive && !isHide;

  factory Category.fromJson(Map<String, dynamic> json) {
    final dynamic active = json['isActive'] ?? json['is_active'] ?? json['active'];
    final bool isActiveParsed = active == null
        ? true
        : (active == true ||
            active == 1 ||
            active.toString().toLowerCase() == 'true');

    final dynamic hide = json['isHide'] ?? json['is_hide'] ?? json['hide'];
    final bool isHideParsed = hide == true || hide == 1 || hide.toString().toLowerCase() == 'true';

    return Category(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      priority: (json['priority'] is num)
          ? (json['priority'] as num).toInt()
          : int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
      isActive: isActiveParsed,
      isHide: isHideParsed,
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
      'isHide': isHide,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': version,
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? slug,
    int? priority,
    bool? isActive,
    bool? isHide,
    String? createdAt,
    String? updatedAt,
    int? version,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      isHide: isHide ?? this.isHide,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}

class ContentModel {
  final String id;
  final String title;
  final String description;
  final List<String> genre;
  final int? releaseYear;
  final String duration;
  final String language;
  final String poster;
  final String banner;
  final bool isComingSoon;
  final String? releaseDate;
  final int priority;
  final int position;
  final bool isPremium;
  final num rating;
  final List<dynamic> cast;
  final List<String> category;
  final int likes;
  final int dislikes;
  final String createdAt;
  final String updatedAt;
  final String slug;
  final bool isPublished;
  final bool isHide;
  final bool is18plus;
  final String type;

  const ContentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    this.releaseYear,
    required this.duration,
    required this.language,
    required this.poster,
    required this.banner,
    required this.isComingSoon,
    this.releaseDate,
    required this.priority,
    this.position = 0,
    required this.isPremium,
    required this.rating,
    required this.cast,
    required this.category,
    this.likes = 0,
    this.dislikes = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.slug,
    required this.isPublished,
    this.isHide = false,
    this.is18plus = false,
    required this.type,
  });

  bool get isVisible => !isHide;

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic val) {
      if (val == null) return [];
      if (val is List) {
        return val.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      if (val is String && val.trim().isNotEmpty) {
        return [val.trim()];
      }
      return [];
    }

    final dynamic hide = json['isHide'] ?? json['is_hide'] ?? json['hide'];
    final bool isHideParsed = hide == true || hide == 1 || hide.toString().toLowerCase() == 'true';

    final dynamic is18 = json['is18plus'] ?? json['is_18_plus'] ?? json['is18Plus'];
    final bool is18plusParsed = is18 == true || is18 == 1 || is18.toString().toLowerCase() == 'true';

    return ContentModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      genre: parseStringList(json['genre'] ?? json['genres']),
      releaseYear: (json['releaseYear'] is num)
          ? (json['releaseYear'] as num).toInt()
          : int.tryParse(json['releaseYear']?.toString() ?? ''),
      duration: (json['duration'] ?? '').toString(),
      language: (json['language'] ?? '').toString(),
      poster: (json['poster'] ?? '').toString(),
      banner: (json['banner'] ?? '').toString(),
      isComingSoon: json['isComingSoon'] == true ||
          json['is_coming_soon'] == true ||
          json['comingSoon'] == true,
      releaseDate: json['releaseDate']?.toString(),
      priority: (json['priority'] is num)
          ? (json['priority'] as num).toInt()
          : int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
      position: (json['position'] is num)
          ? (json['position'] as num).toInt()
          : int.tryParse(json['position']?.toString() ?? '0') ?? 0,
      isPremium: json['isPremium'] == true ||
          json['is_premium'] == true ||
          json['premium'] == true,
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      cast: List<dynamic>.from(json['cast'] is List ? json['cast'] : []),
      category: parseStringList(json['category'] ?? json['categories']),
      likes: (json['likes'] is num)
          ? (json['likes'] as num).toInt()
          : (json['likes'] is List
              ? (json['likes'] as List).length
              : int.tryParse(json['likes']?.toString() ?? '0') ?? 0),
      dislikes: (json['dislikes'] is num)
          ? (json['dislikes'] as num).toInt()
          : (json['dislikes'] is List
              ? (json['dislikes'] as List).length
              : int.tryParse(json['dislikes']?.toString() ?? '0') ?? 0),
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      isPublished: json['isPublished'] == true ||
          json['is_published'] == true ||
          json['published'] == true,
      isHide: isHideParsed,
      is18plus: is18plusParsed,
      type: (json['contentType'] ?? json['type'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'genre': genre,
      'releaseYear': releaseYear,
      'duration': duration,
      'language': language,
      'poster': poster,
      'banner': banner,
      'isComingSoon': isComingSoon,
      'releaseDate': releaseDate,
      'priority': priority,
      'position': position,
      'isPremium': isPremium,
      'rating': rating,
      'cast': cast,
      'category': category,
      'likes': likes,
      'dislikes': dislikes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'slug': slug,
      'isPublished': isPublished,
      'isHide': isHide,
      'is18plus': is18plus,
      'type': type,
    };
  }

  ContentModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? genre,
    int? releaseYear,
    String? duration,
    String? language,
    String? poster,
    String? banner,
    bool? isComingSoon,
    String? releaseDate,
    int? priority,
    int? position,
    bool? isPremium,
    num? rating,
    List<dynamic>? cast,
    List<String>? category,
    int? likes,
    int? dislikes,
    String? createdAt,
    String? updatedAt,
    String? slug,
    bool? isPublished,
    bool? isHide,
    bool? is18plus,
    String? type,
  }) {
    return ContentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      genre: genre ?? this.genre,
      releaseYear: releaseYear ?? this.releaseYear,
      duration: duration ?? this.duration,
      language: language ?? this.language,
      poster: poster ?? this.poster,
      banner: banner ?? this.banner,
      isComingSoon: isComingSoon ?? this.isComingSoon,
      releaseDate: releaseDate ?? this.releaseDate,
      priority: priority ?? this.priority,
      position: position ?? this.position,
      isPremium: isPremium ?? this.isPremium,
      rating: rating ?? this.rating,
      cast: cast ?? this.cast,
      category: category ?? this.category,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      slug: slug ?? this.slug,
      isPublished: isPublished ?? this.isPublished,
      isHide: isHide ?? this.isHide,
      is18plus: is18plus ?? this.is18plus,
      type: type ?? this.type,
    );
  }
}
