bool _parseBool(dynamic val) {
  if (val == null) return false;
  if (val is bool) return val;
  if (val is num) return val == 1;
  if (val is String) {
    final s = val.trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return false;
}

class MicrodramasResponse {
  final bool success;
  final List<Microdrama> microdramas;

  const MicrodramasResponse({
    required this.success,
    required this.microdramas,
  });

  factory MicrodramasResponse.fromJson(Map<String, dynamic> json) {
    return MicrodramasResponse(
      success: json['success'] ?? false,
      microdramas: (json['microdramas'] as List<dynamic>? ?? [])
          .map((e) => Microdrama.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'microdramas': microdramas.map((e) => e.toJson()).toList(),
    };
  }

  MicrodramasResponse copyWith({
    bool? success,
    List<Microdrama>? microdramas,
  }) {
    return MicrodramasResponse(
      success: success ?? this.success,
      microdramas: microdramas ?? this.microdramas,
    );
  }
}

class Microdrama {
  final String id;
  final String title;
  final String description;
  final int? releaseYear;
  final String releaseDate;
  final String duration;
  final num rating;
  final List<dynamic> genre;
  final String language;
  final String poster;
  final String banner;
  final String trailerUrl;
  final bool isComingSoon;
  final int totalEpisodes;
  final int totalViews;
  final bool isPremium;
  final int priority;
  final String status;
  final List<dynamic> cast;
  final List<dynamic> category;
  final String createdAt;
  final String updatedAt;
  final String slug;
  final int v;
  final bool isPublished;

  const Microdrama({
    required this.id,
    required this.title,
    required this.description,
    this.releaseYear,
    required this.releaseDate,
    required this.duration,
    required this.rating,
    required this.genre,
    required this.language,
    required this.poster,
    required this.banner,
    required this.trailerUrl,
    required this.isComingSoon,
    required this.totalEpisodes,
    required this.totalViews,
    required this.isPremium,
    required this.priority,
    required this.status,
    required this.cast,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    required this.slug,
    required this.v,
    required this.isPublished,
  });

  factory Microdrama.fromJson(Map<String, dynamic> json) {
    List<dynamic> parseDynamicList(dynamic val, [dynamic alt]) {
      final t = val ?? alt;
      if (t == null) return [];
      if (t is List) return List<dynamic>.from(t);
      if (t is Map) return [t];
      if (t is String && t.trim().isNotEmpty) return [t.trim()];
      return [];
    }

    return Microdrama(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      releaseYear: (json['releaseYear'] is num)
          ? (json['releaseYear'] as num).toInt()
          : int.tryParse(json['releaseYear']?.toString() ?? ''),
      releaseDate: json['releaseDate']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      genre: parseDynamicList(json['genre'], json['genres']),
      language: json['language']?.toString() ?? '',
      poster: json['poster']?.toString() ?? '',
      banner: json['banner']?.toString() ?? '',
      trailerUrl: json['trailerUrl']?.toString() ?? '',
      isComingSoon: _parseBool(
        json['isComingSoon'] ?? json['is_coming_soon'] ?? json['comingSoon'],
      ),
      totalEpisodes: (json['totalEpisodes'] is num)
          ? (json['totalEpisodes'] as num).toInt()
          : int.tryParse(json['totalEpisodes']?.toString() ?? '0') ?? 0,
      totalViews: (json['totalViews'] is num)
          ? (json['totalViews'] as num).toInt()
          : int.tryParse(json['totalViews']?.toString() ?? '0') ?? 0,
      isPremium: _parseBool(
        json['isPremium'] ??
            json['is_premium'] ??
            json['premium'] ??
            json['isPremimu'],
      ),
      priority: (json['priority'] is num)
          ? (json['priority'] as num).toInt()
          : int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? '',
      cast: parseDynamicList(json['cast']),
      category: parseDynamicList(json['category'], json['categories']),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      v: json['__v'] != null ? (int.tryParse(json['__v'].toString()) ?? 0) : 0,
      isPublished: _parseBool(
        json['isPublished'] ?? json['is_published'] ?? json['published'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'releaseYear': releaseYear,
      'releaseDate': releaseDate,
      'duration': duration,
      'rating': rating,
      'genre': genre,
      'language': language,
      'poster': poster,
      'banner': banner,
      'trailerUrl': trailerUrl,
      'isComingSoon': isComingSoon,
      'totalEpisodes': totalEpisodes,
      'totalViews': totalViews,
      'isPremium': isPremium,
      'priority': priority,
      'status': status,
      'cast': cast,
      'category': category,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'slug': slug,
      '__v': v,
      'isPublished': isPublished,
    };
  }

  Microdrama copyWith({
    String? id,
    String? title,
    String? description,
    int? releaseYear,
    String? releaseDate,
    String? duration,
    num? rating,
    List<dynamic>? genre,
    String? language,
    String? poster,
    String? banner,
    String? trailerUrl,
    bool? isComingSoon,
    int? totalEpisodes,
    int? totalViews,
    bool? isPremium,
    int? priority,
    String? status,
    List<dynamic>? cast,
    List<dynamic>? category,
    String? createdAt,
    String? updatedAt,
    String? slug,
    int? v,
    bool? isPublished,
  }) {
    return Microdrama(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      releaseYear: releaseYear ?? this.releaseYear,
      releaseDate: releaseDate ?? this.releaseDate,
      duration: duration ?? this.duration,
      rating: rating ?? this.rating,
      genre: genre ?? this.genre,
      language: language ?? this.language,
      poster: poster ?? this.poster,
      banner: banner ?? this.banner,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      isComingSoon: isComingSoon ?? this.isComingSoon,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      totalViews: totalViews ?? this.totalViews,
      isPremium: isPremium ?? this.isPremium,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      cast: cast ?? this.cast,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      slug: slug ?? this.slug,
      v: v ?? this.v,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}