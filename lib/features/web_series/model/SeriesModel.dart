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

class SeriesResponse {
  final bool success;
  final List<Series> series;

  const SeriesResponse({required this.success, required this.series});

  factory SeriesResponse.fromJson(Map<String, dynamic> json) {
    return SeriesResponse(
      success: json['success'] ?? false,
      series:
          (json['series'] as List<dynamic>?)
              ?.map((e) => Series.fromJson(e))
              .where((s) => s.isVisible)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'series': series.map((e) => e.toJson()).toList(),
    };
  }

  SeriesResponse copyWith({bool? success, List<Series>? series}) {
    return SeriesResponse(
      success: success ?? this.success,
      series: series ?? this.series,
    );
  }
}

class Series {
  final String id;
  final String title;
  final String description;
  final List<String> genre;
  final int releaseYear;
  final String duration;
  final String language;
  final String poster;
  final String banner;
  final bool isComingSoon;
  final String? releaseDate;
  final String trailerUrl;
  final bool isPremium;
  final int priority;
  final double rating;
  final bool isPopular;
  final List<dynamic> cast;
  final List<dynamic> category;
  final int likes;
  final int dislikes;
  final bool is18plus;
  final bool isHide;
  final int totalSeasons;
  final int totalEpisodes;
  final String createdAt;
  final String updatedAt;
  final String slug;
  final int v;
  final List<dynamic> seasons;

  const Series({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    required this.releaseYear,
    required this.duration,
    required this.language,
    required this.poster,
    required this.banner,
    required this.isComingSoon,
    this.releaseDate,
    required this.trailerUrl,
    required this.isPremium,
    required this.priority,
    required this.rating,
    this.isPopular = false,
    required this.cast,
    required this.category,
    this.likes = 0,
    this.dislikes = 0,
    this.is18plus = false,
    this.isHide = false,
    required this.totalSeasons,
    required this.totalEpisodes,
    required this.createdAt,
    required this.updatedAt,
    required this.slug,
    required this.v,
    required this.seasons,
  });

  /// Logic:
  /// When `is18plus` is true, whether to show this content depends on `isHide`:
  /// - `is18plus == true` && `isHide == true` => Hidden (returns false)
  /// - `is18plus == true` && `isHide == false` => Visible (returns true)
  /// - `is18plus == false` => Visible if not hidden (returns !isHide)
  bool get isVisible {
    if (is18plus) {
      return !isHide;
    }
    return !isHide;
  }

  /// Alias for `isVisible`
  bool get shouldShow => isVisible;

  /// Alias for `isVisible`
  bool get showContent => isVisible;

  factory Series.fromJson(Map<String, dynamic> json) {
    List<dynamic> parseDynamicList(dynamic val, [dynamic alt]) {
      final t = val ?? alt;
      if (t == null) return [];
      if (t is List) return List<dynamic>.from(t);
      if (t is Map) return [t];
      if (t is String && t.trim().isNotEmpty) return [t.trim()];
      return [];
    }

    List<String> parseStringList(dynamic val, [dynamic alt]) {
      final t = val ?? alt;
      if (t == null) return [];
      if (t is List) {
        return t.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      if (t is String && t.trim().isNotEmpty) {
        return t.contains(',')
            ? t.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
            : [t.trim()];
      }
      return [];
    }

    return Series(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      genre: parseStringList(json['genre'], json['genres']),
      releaseYear: json['releaseYear'] ?? 0,
      duration: json['duration'] ?? '',
      language: json['language'] ?? '',
      poster: json['poster'] ?? '',
      banner: json['banner'] ?? '',
      isComingSoon: _parseBool(
        json['isComingSoon'] ?? json['is_coming_soon'] ?? json['comingSoon'],
      ),
      releaseDate: json['releaseDate'],
      trailerUrl: json['trailerUrl'] ?? '',
      isPremium: _parseBool(
        json['isPremium'] ??
            json['is_premium'] ??
            json['premium'] ??
            json['isPremimu'],
      ),
      priority: (json['priority'] is num)
          ? (json['priority'] as num).toInt()
          : int.tryParse(json['priority']?.toString() ?? '0') ?? 0,
      rating: (json['rating'] is num)
          ? (json['rating'] as num).toDouble()
          : double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      isPopular: _parseBool(
        json['isPopular'] ?? json['is_popular'] ?? json['popularSeries'],
      ),
      cast: parseDynamicList(json['cast']),
      category: parseDynamicList(json['category'], json['categories']),
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
      is18plus: _parseBool(
        json['is18plus'] ?? json['is_18plus'] ?? json['18plus'],
      ),
      isHide: _parseBool(json['isHide'] ?? json['is_hide'] ?? json['hide']),
      totalSeasons: json['totalSeasons'] ?? 0,
      totalEpisodes: json['totalEpisodes'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      slug: json['slug'] ?? '',
      v: json['__v'] ?? 0,
      seasons: List<dynamic>.from(json['seasons'] ?? []),
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
      'trailerUrl': trailerUrl,
      'isPremium': isPremium,
      'priority': priority,
      'rating': rating,
      'isPopular': isPopular,
      'cast': cast,
      'category': category,
      'likes': likes,
      'dislikes': dislikes,
      'is18plus': is18plus,
      'isHide': isHide,
      'totalSeasons': totalSeasons,
      'totalEpisodes': totalEpisodes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'slug': slug,
      '__v': v,
      'seasons': seasons,
    };
  }

  Series copyWith({
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
    String? trailerUrl,
    bool? isPremium,
    int? priority,
    double? rating,
    bool? isPopular,
    List<dynamic>? cast,
    List<dynamic>? category,
    int? likes,
    int? dislikes,
    bool? is18plus,
    bool? isHide,
    int? totalSeasons,
    int? totalEpisodes,
    String? createdAt,
    String? updatedAt,
    String? slug,
    int? v,
    List<dynamic>? seasons,
  }) {
    return Series(
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
      trailerUrl: trailerUrl ?? this.trailerUrl,
      isPremium: isPremium ?? this.isPremium,
      priority: priority ?? this.priority,
      rating: rating ?? this.rating,
      isPopular: isPopular ?? this.isPopular,
      cast: cast ?? this.cast,
      category: category ?? this.category,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      is18plus: is18plus ?? this.is18plus,
      isHide: isHide ?? this.isHide,
      totalSeasons: totalSeasons ?? this.totalSeasons,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      slug: slug ?? this.slug,
      v: v ?? this.v,
      seasons: seasons ?? this.seasons,
    );
  }
}
