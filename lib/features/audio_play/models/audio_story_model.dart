import 'package:masti_adda_app/features/audio_play/models/audio_category_model.dart';
import 'package:masti_adda_app/features/audio_play/models/audio_episode_model.dart';
import 'package:masti_adda_app/utils/helpers.dart';

export 'package:masti_adda_app/features/audio_play/models/audio_category_model.dart';
export 'package:masti_adda_app/features/audio_play/models/audio_episode_model.dart';
export 'package:masti_adda_app/features/audio_play/models/audio_home_feed_model.dart';
export 'package:masti_adda_app/features/audio_play/models/audio_progress_model.dart';
export 'package:masti_adda_app/features/audio_play/models/audio_stories_response_model.dart';

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

class AudioStoryModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String author;
  final String narrator;
  final String coverImage;
  final String bannerImage;
  final List<AudioCategoryModel> categories;
  final String categoryId;
  final String genre;
  final String language;
  final double rating;
  final int totalEpisodes;
  final String duration;
  final int totalPlays;
  final String status;
  final bool isPremium;
  final bool isPublished;
  final num priority;
  final int likes;
  final String slug;
  final int v;
  final bool isLocked;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AudioEpisodeModel> episodes;

  const AudioStoryModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.author = '',
    this.narrator = '',
    this.coverImage = '',
    this.bannerImage = '',
    this.categories = const [],
    this.categoryId = '',
    this.genre = 'Audio Story',
    this.language = 'Hindi',
    this.rating = 0.0,
    this.totalEpisodes = 0,
    this.duration = '',
    this.totalPlays = 0,
    this.status = 'Published',
    this.isPremium = false,
    this.isPublished = true,
    this.priority = 0,
    this.likes = 0,
    this.slug = '',
    this.v = 0,
    this.isLocked = false,
    this.createdAt,
    this.updatedAt,
    this.episodes = const [],
  });

  String get imageUrl => formatMediaUrl(
    coverImage.isNotEmpty
        ? coverImage
        : (bannerImage.isNotEmpty ? bannerImage : ''),
  );

  String get bannerUrl => formatMediaUrl(
    bannerImage.isNotEmpty
        ? bannerImage
        : (coverImage.isNotEmpty ? coverImage : ''),
  );

  String get primaryCategoryName =>
      categories.isNotEmpty ? categories.first.name : genre;

  String get primaryCategoryId =>
      categories.isNotEmpty ? categories.first.id : categoryId;

  factory AudioStoryModel.fromJson(Map<String, dynamic> json) {
    // 1. Parse Categories
    List<AudioCategoryModel> parsedCategories = [];
    String parsedGenre = 'Audio Story';
    String parsedCategoryId = '';

    if (json['categories'] is List) {
      final rawList = json['categories'] as List;
      for (var c in rawList) {
        if (c is Map) {
          parsedCategories.add(AudioCategoryModel.fromJson(Map<String, dynamic>.from(c)));
        } else if (c != null && c.toString().isNotEmpty) {
          parsedCategories.add(AudioCategoryModel(id: c.toString(), name: ''));
        }
      }
      if (parsedCategories.isNotEmpty) {
        final named = parsedCategories.firstWhere(
          (c) => c.name.isNotEmpty,
          orElse: () => parsedCategories.first,
        );
        if (named.name.isNotEmpty) parsedGenre = named.name;
        if (named.id.isNotEmpty) parsedCategoryId = named.id;
      }
    } else if (json['category'] is Map) {
      final cat = AudioCategoryModel.fromJson(
        Map<String, dynamic>.from(json['category']),
      );
      parsedCategories = [cat];
      parsedGenre = cat.name.isNotEmpty ? cat.name : 'Audio Story';
      parsedCategoryId = cat.id;
    } else if (json['category'] is String) {
      final catStr = json['category'].toString();
      if (catStr.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(catStr)) {
        parsedCategoryId = catStr;
      } else {
        parsedGenre = catStr;
      }
    }

    if (json['genre'] is List) {
      final list = (json['genre'] as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      if (list.isNotEmpty) parsedGenre = list.join(', ');
    } else if (json['genre'] != null && json['genre'].toString().isNotEmpty) {
      parsedGenre = json['genre'].toString();
    }

    if (json['categoryId'] != null && json['categoryId'].toString().isNotEmpty) {
      parsedCategoryId = json['categoryId'].toString();
    }

    final storyId = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final storyTitle = json['title']?.toString() ?? '';
    final rawCover =
        json['coverImage']?.toString() ??
        json['imageUrl']?.toString() ??
        json['poster']?.toString() ??
        json['thumbnail']?.toString() ??
        '';
    final rawBanner = json['bannerImage']?.toString() ?? '';

    // 2. Parse Episodes
    List<AudioEpisodeModel> parsedEpisodes = [];
    if (json['episodes'] is List) {
      parsedEpisodes = (json['episodes'] as List)
          .whereType<Map>()
          .map(
            (e) => AudioEpisodeModel.fromJson(
              Map<String, dynamic>.from(e),
              parentStoryId: storyId,
              parentStoryTitle: storyTitle,
              parentStoryCover: rawCover,
            ),
          )
          .toList();
    }

    // 3. Parse Rating
    final rawRating = json['rating'] ?? json['averageRating'];
    double parsedRating = 0.0;
    if (rawRating is num) {
      parsedRating = rawRating.toDouble();
    } else if (rawRating is String) {
      parsedRating = double.tryParse(rawRating) ?? 0.0;
    }

    // 4. Parse Plays
    final rawPlays = json['totalPlays'] ?? json['plays'] ?? json['views'] ?? 0;
    int parsedPlays = 0;
    if (rawPlays is int) {
      parsedPlays = rawPlays;
    } else if (rawPlays is double) {
      parsedPlays = rawPlays.toInt();
    } else if (rawPlays is String) {
      parsedPlays = int.tryParse(rawPlays) ?? 0;
    }

    // 5. Total Episodes
    final int epCount = parsedEpisodes.isNotEmpty
        ? parsedEpisodes.length
        : (json['totalEpisodes'] is int
              ? json['totalEpisodes']
              : int.tryParse(json['totalEpisodes']?.toString() ?? '0') ?? 0);

    // 6. Subtitle / Tagline fallback
    final parsedSubtitle =
        json['subtitle']?.toString() ??
        json['tagline']?.toString() ??
        (parsedGenre.isNotEmpty ? parsedGenre : 'Audio Story');

    // 7. Likes
    final rawLikes = json['likes'];
    int parsedLikes = 0;
    if (rawLikes is num) {
      parsedLikes = rawLikes.toInt();
    } else if (rawLikes is List) {
      parsedLikes = rawLikes.length;
    } else if (rawLikes is String) {
      parsedLikes = int.tryParse(rawLikes) ?? 0;
    }

    return AudioStoryModel(
      id: storyId,
      title: storyTitle,
      subtitle: parsedSubtitle,
      description: json['description']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      narrator: json['narrator']?.toString() ?? '',
      coverImage: rawCover,
      bannerImage: rawBanner,
      categories: parsedCategories,
      categoryId: parsedCategoryId,
      genre: parsedGenre,
      language: json['language']?.toString() ?? 'Hindi',
      rating: parsedRating,
      totalEpisodes: epCount,
      duration:
          json['duration']?.toString() ??
          (epCount > 0 ? '$epCount Episodes' : ''),
      totalPlays: parsedPlays,
      status: json['status']?.toString() ?? 'Published',
      isPremium: _parseBool(
        json['isPremium'] ??
            json['is_premium'] ??
            json['premium'] ??
            json['isPremimu'],
      ),
      isPublished: _parseBool(
        json['isPublished'] ?? json['is_published'] ?? true,
      ),
      priority: (json['priority'] as num?) ?? 0,
      likes: parsedLikes,
      slug: json['slug']?.toString() ?? '',
      v: (json['__v'] as num?)?.toInt() ?? 0,
      isLocked: _parseBool(json['isLocked'] ?? json['is_locked'] ?? false),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      episodes: parsedEpisodes,
    );
  }

  AudioStoryModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? author,
    String? narrator,
    String? coverImage,
    String? bannerImage,
    List<AudioCategoryModel>? categories,
    String? categoryId,
    String? genre,
    String? language,
    double? rating,
    int? totalEpisodes,
    String? duration,
    int? totalPlays,
    String? status,
    bool? isPremium,
    bool? isPublished,
    num? priority,
    int? likes,
    String? slug,
    int? v,
    bool? isLocked,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AudioEpisodeModel>? episodes,
  }) {
    return AudioStoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      author: author ?? this.author,
      narrator: narrator ?? this.narrator,
      coverImage: coverImage ?? this.coverImage,
      bannerImage: bannerImage ?? this.bannerImage,
      categories: categories ?? this.categories,
      categoryId: categoryId ?? this.categoryId,
      genre: genre ?? this.genre,
      language: language ?? this.language,
      rating: rating ?? this.rating,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      duration: duration ?? this.duration,
      totalPlays: totalPlays ?? this.totalPlays,
      status: status ?? this.status,
      isPremium: isPremium ?? this.isPremium,
      isPublished: isPublished ?? this.isPublished,
      priority: priority ?? this.priority,
      likes: likes ?? this.likes,
      slug: slug ?? this.slug,
      v: v ?? this.v,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      episodes: episodes ?? this.episodes,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'subtitle': subtitle,
    'description': description,
    'author': author,
    'narrator': narrator,
    'coverImage': coverImage,
    'bannerImage': bannerImage,
    'categories': categories.map((c) => c.toJson()).toList(),
    'category': genre,
    'language': language,
    'rating': rating,
    'totalEpisodes': totalEpisodes,
    'duration': duration,
    'totalPlays': totalPlays,
    'status': status,
    'isPremium': isPremium,
    'isPublished': isPublished,
    'priority': priority,
    'likes': likes,
    'slug': slug,
    '__v': v,
    'isLocked': isLocked,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    'episodes': episodes.map((e) => e.toJson()).toList(),
  };
}
