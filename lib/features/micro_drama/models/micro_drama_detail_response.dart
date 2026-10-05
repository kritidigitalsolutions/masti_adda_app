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

class MicrodramaDetailResponse {
  final bool success;
  final Microdrama microdrama;

  const MicrodramaDetailResponse({
    required this.success,
    required this.microdrama,
  });

  factory MicrodramaDetailResponse.fromJson(Map<String, dynamic> json) {
    return MicrodramaDetailResponse(
      success: json['success'] ?? false,
      microdrama: Microdrama.fromJson(json['microdrama'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'microdrama': microdrama.toJson(),
    };
  }

  MicrodramaDetailResponse copyWith({
    bool? success,
    Microdrama? microdrama,
  }) {
    return MicrodramaDetailResponse(
      success: success ?? this.success,
      microdrama: microdrama ?? this.microdrama,
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
  final int version;
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
    required this.version,
    required this.isPublished,
  });

  factory Microdrama.fromJson(Map<String, dynamic> json) {
    return Microdrama(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      releaseYear: json['releaseYear'],
      releaseDate: json['releaseDate'] ?? '',
      duration: json['duration'] ?? '',
      rating: json['rating'] ?? 0,
      genre: List<dynamic>.from(json['genre'] ?? []),
      language: json['language'] ?? '',
      poster: json['poster'] ?? '',
      banner: json['banner'] ?? '',
      trailerUrl: json['trailerUrl'] ?? '',
      isComingSoon: _parseBool(
        json['isComingSoon'] ?? json['is_coming_soon'] ?? json['comingSoon'],
      ),
      totalEpisodes: json['totalEpisodes'] ?? 0,
      totalViews: json['totalViews'] ?? 0,
      isPremium: _parseBool(
        json['isPremium'] ??
            json['is_premium'] ??
            json['premium'] ??
            json['isPremimu'],
      ),
      priority: json['priority'] ?? 0,
      status: json['status'] ?? '',
      cast: List<dynamic>.from(json['cast'] ?? []),
      category: List<dynamic>.from(json['category'] ?? []),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      slug: json['slug'] ?? '',
      version: json['__v'] ?? 0,
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
      '__v': version,
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
    int? version,
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
      version: version ?? this.version,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}