class HomeContentResponse {
  final bool success;
  final int moviesCount;
  final int seriesCount;
  final int microdramasCount;
  final int seriesEpisodesCount;
  final int microdramasEpisodesCount;
  final List<HomeContent> content;

  const HomeContentResponse({
    required this.success,
    required this.moviesCount,
    required this.seriesCount,
    required this.microdramasCount,
    required this.seriesEpisodesCount,
    required this.microdramasEpisodesCount,
    required this.content,
  });

  factory HomeContentResponse.fromJson(Map<String, dynamic> json) {
    return HomeContentResponse(
      success: json['success'] ?? false,
      moviesCount: json['moviesCount'] ?? 0,
      seriesCount: json['seriesCount'] ?? 0,
      microdramasCount: json['microdramasCount'] ?? 0,
      seriesEpisodesCount: json['seriesEpisodesCount'] ?? 0,
      microdramasEpisodesCount: json['microdramasEpisodesCount'] ?? 0,
      content: (json['content'] as List<dynamic>? ?? [])
          .map((e) => HomeContent.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "moviesCount": moviesCount,
    "seriesCount": seriesCount,
    "microdramasCount": microdramasCount,
    "seriesEpisodesCount": seriesEpisodesCount,
    "microdramasEpisodesCount": microdramasEpisodesCount,
    "content": content.map((e) => e.toJson()).toList(),
  };

  HomeContentResponse copyWith({
    bool? success,
    int? moviesCount,
    int? seriesCount,
    int? microdramasCount,
    int? seriesEpisodesCount,
    int? microdramasEpisodesCount,
    List<HomeContent>? content,
  }) {
    return HomeContentResponse(
      success: success ?? this.success,
      moviesCount: moviesCount ?? this.moviesCount,
      seriesCount: seriesCount ?? this.seriesCount,
      microdramasCount: microdramasCount ?? this.microdramasCount,
      seriesEpisodesCount:
      seriesEpisodesCount ?? this.seriesEpisodesCount,
      microdramasEpisodesCount:
      microdramasEpisodesCount ?? this.microdramasEpisodesCount,
      content: content ?? this.content,
    );
  }
}

class HomeContent {
  final String id;
  final String title;
  final String description;
  final List<String> genre;
  final int? releaseYear;
  final String? releaseDate;
  final String duration;
  final String language;
  final String poster;
  final String banner;
  final String videoUrl;
  final String trailerUrl;
  final bool isComingSoon;
  final bool isPremium;
  final int priority;
  final num rating;
  final List<dynamic> cast;
  final List<String> category;
  final int likes;
  final int dislikes;
  final String createdAt;
  final String updatedAt;
  final String slug;
  final bool isPublished;
  final String type;
  final bool isTrending;

  // Series
  final int? totalSeasons;

  // Series + Microdrama
  final int? totalEpisodes;

  // Microdrama
  final int? totalViews;
  final String? status;

  final List<EpisodeModel> episodes;

  const HomeContent({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    this.releaseYear,
    this.releaseDate,
    required this.duration,
    required this.language,
    required this.poster,
    required this.banner,
    required this.videoUrl,
    required this.trailerUrl,
    required this.isComingSoon,
    required this.isPremium,
    required this.priority,
    required this.rating,
    required this.cast,
    required this.category,
    this.likes = 0,
    this.dislikes = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.slug,
    required this.isPublished,
    required this.type,
    required this.isTrending,
    this.totalSeasons,
    this.totalEpisodes,
    this.totalViews,
    this.status,
    required this.episodes,
  });

  factory HomeContent.fromJson(Map<String, dynamic> json) {
    return HomeContent(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      genre: List<String>.from(json['genre'] ?? []),
      releaseYear: json['releaseYear'],
      releaseDate: json['releaseDate'],
      duration: json['duration'] ?? '',
      language: json['language'] ?? '',
      poster: json['poster'] ?? '',
      banner: json['banner'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      trailerUrl: json['trailerUrl'] ?? '',
      isComingSoon: json['isComingSoon'] ?? false,
      isPremium: json['isPremium'] ?? false,
      priority: json['priority'] ?? 0,
      rating: json['rating'] ?? 0,
      cast: List<dynamic>.from(json['cast'] ?? []),
      category: List<String>.from(json['category'] ?? []),
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
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      slug: json['slug'] ?? '',
      isPublished: json['isPublished'] ?? false,
      type: json['type'] ?? '',
      isTrending: json['isTrending'] ?? false,
      totalSeasons: json['totalSeasons'],
      totalEpisodes: json['totalEpisodes'],
      totalViews: json['totalViews'],
      status: json['status'],
      episodes: (json['episodes'] as List<dynamic>? ?? [])
          .map((e) => EpisodeModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {};
}

class EpisodeModel {
  final String id;
  final String title;
  final String description;

  final String? seriesId;
  final String? tvShowId;

  final int? seasonNumber;
  final int episodeNumber;

  final String videoUrl;
  final String thumbnail;
  final String duration;

  final bool? isLocked;
  final bool? isVertical;
  final int? views;
  final int? likes;

  final String createdAt;
  final String updatedAt;
  final int version;

  const EpisodeModel({
    required this.id,
    required this.title,
    required this.description,
    this.seriesId,
    this.tvShowId,
    this.seasonNumber,
    required this.episodeNumber,
    required this.videoUrl,
    required this.thumbnail,
    required this.duration,
    this.isLocked,
    this.isVertical,
    this.views,
    this.likes,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      seriesId: json['seriesId'],
      tvShowId: json['tvShowId'],
      seasonNumber: json['seasonNumber'],
      episodeNumber: json['episodeNumber'] ?? 0,
      videoUrl: json['videoUrl'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      duration: json['duration'] ?? '',
      isLocked: json['isLocked'],
      isVertical: json['isVertical'],
      views: (json['views'] is num)
          ? (json['views'] as num).toInt()
          : (json['views'] is List
              ? (json['views'] as List).length
              : int.tryParse(json['views']?.toString() ?? '')),
      likes: (json['likes'] is num)
          ? (json['likes'] as num).toInt()
          : (json['likes'] is List
              ? (json['likes'] as List).length
              : int.tryParse(json['likes']?.toString() ?? '')),
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      version: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {};
}