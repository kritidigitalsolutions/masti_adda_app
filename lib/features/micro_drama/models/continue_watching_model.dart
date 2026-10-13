import 'package:masti_adda_app/features/micro_drama/models/episode_detail_response.dart';
import 'package:masti_adda_app/features/micro_drama/models/micro_drama_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Request payload
// ─────────────────────────────────────────────────────────────────────────────
class SaveProgressRequest {
  final String contentId;
  final String contentType; // "movie" | "series" | "microdrama"
  final int progressSeconds;
  final int durationSeconds;
  final String? episodeId;

  const SaveProgressRequest({
    required this.contentId,
    required this.contentType,
    required this.progressSeconds,
    required this.durationSeconds,
    this.episodeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'contentType': contentType,
      'progressSeconds': progressSeconds,
      'durationSeconds': durationSeconds,
      if (episodeId != null && episodeId!.isNotEmpty) 'episodeId': episodeId,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single continue-watching item
// ─────────────────────────────────────────────────────────────────────────────
class ContinueWatchingItem {
  final String id;
  final String userId;
  final String contentId;
  final String? episodeId;
  final String contentType; // "movie", "series", "microdrama"
  final int progressSeconds;
  final int durationSeconds;
  final bool completed;
  final String lastWatchedAt;

  // Direct extracted attributes from payload
  final String directTitle;
  final String directPoster;
  final String directBanner;
  final String directVideoUrl;
  final int? directEpisodeNumber;
  final String directEpisodeTitle;

  /// Populated content objects if available
  final Microdrama? content;
  final MicroDramaEpisode? episode;

  const ContinueWatchingItem({
    required this.id,
    required this.userId,
    required this.contentId,
    this.episodeId,
    required this.contentType,
    required this.progressSeconds,
    required this.durationSeconds,
    required this.completed,
    required this.lastWatchedAt,
    this.directTitle = '',
    this.directPoster = '',
    this.directBanner = '',
    this.directVideoUrl = '',
    this.directEpisodeNumber,
    this.directEpisodeTitle = '',
    this.content,
    this.episode,
  });

  bool get isMicroDrama {
    final t = contentType.toLowerCase().replaceAll('-', '_').trim();
    return t == 'microdrama' || t == 'micro_drama' || t == 'drama';
  }

  bool get isMovie {
    final t = contentType.toLowerCase().trim();
    return t == 'movie';
  }

  bool get isSeries {
    final t = contentType.toLowerCase().replaceAll('-', '_').trim();
    return t == 'series' || t == 'web_series' || t == 'webseries';
  }

  /// Progress as a value between 0.0 – 1.0
  double get progressRatio =>
      durationSeconds > 0
          ? (progressSeconds / durationSeconds).clamp(0.0, 1.0)
          : 0.0;

  int get progressPercentage => (progressRatio * 100).round();

  String get displayTitle {
    if (content != null && content!.title.isNotEmpty) {
      return content!.title;
    }
    if (directTitle.isNotEmpty) {
      return directTitle;
    }
    return 'Untitled';
  }

  String get displayPoster {
    if (episode != null && episode!.thumbnail.isNotEmpty) {
      return episode!.thumbnail;
    }
    if (content != null && content!.banner.isNotEmpty) {
      return content!.banner;
    }
    if (content != null && content!.poster.isNotEmpty) {
      return content!.poster;
    }
    if (directBanner.isNotEmpty) {
      return directBanner;
    }
    if (directPoster.isNotEmpty) {
      return directPoster;
    }
    return '';
  }

  int? get displayEpisodeNumber {
    if (episode != null) return episode!.episodeNumber;
    return directEpisodeNumber;
  }

  String get displayEpisodeTitle {
    if (episode != null && episode!.title.isNotEmpty) return episode!.title;
    return directEpisodeTitle;
  }

  factory ContinueWatchingItem.fromJson(Map<String, dynamic> json) {
    Microdrama? content;
    String directTitle = '';
    String directPoster = '';
    String directBanner = '';
    String directVideoUrl = '';

    final rawContent = json['contentId'];
    if (rawContent is Map<String, dynamic>) {
      directTitle = rawContent['title']?.toString() ??
          rawContent['name']?.toString() ??
          '';
      directPoster = rawContent['poster']?.toString() ??
          rawContent['image']?.toString() ??
          '';
      directBanner = rawContent['banner']?.toString() ?? '';
      directVideoUrl = rawContent['videoUrl']?.toString() ??
          rawContent['video_url']?.toString() ??
          '';
      try {
        content = Microdrama.fromJson(rawContent);
      } catch (_) {}
    }

    MicroDramaEpisode? episode;
    int? directEpisodeNumber;
    String directEpisodeTitle = '';

    final rawEpisode = json['episodeId'];
    if (rawEpisode is Map<String, dynamic>) {
      directEpisodeTitle = rawEpisode['title']?.toString() ??
          rawEpisode['name']?.toString() ??
          '';
      if (rawEpisode['episodeNumber'] is num) {
        directEpisodeNumber = (rawEpisode['episodeNumber'] as num).toInt();
      } else if (rawEpisode['episode_number'] is num) {
        directEpisodeNumber = (rawEpisode['episode_number'] as num).toInt();
      }
      if (directVideoUrl.isEmpty) {
        directVideoUrl = rawEpisode['videoUrl']?.toString() ??
            rawEpisode['video_url']?.toString() ??
            '';
      }
      try {
        episode = MicroDramaEpisode.fromJson(rawEpisode);
      } catch (_) {}
    }

    final rawContentType = (json['contentType'] ?? json['type'] ?? 'movie')
        .toString()
        .toLowerCase();

    return ContinueWatchingItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId'] is Map
          ? (json['userId']['_id']?.toString() ?? '')
          : (json['userId']?.toString() ?? ''),
      contentId: rawContent is Map
          ? (rawContent['_id']?.toString() ?? rawContent['id']?.toString() ?? '')
          : (rawContent?.toString() ?? ''),
      episodeId: rawEpisode is Map
          ? (rawEpisode['_id']?.toString() ?? rawEpisode['id']?.toString() ?? '')
          : (rawEpisode is String ? rawEpisode : null),
      contentType: rawContentType,
      progressSeconds: (json['progressSeconds'] is num)
          ? (json['progressSeconds'] as num).toInt()
          : (int.tryParse(json['progressSeconds']?.toString() ?? '0') ?? 0),
      durationSeconds: (json['durationSeconds'] is num)
          ? (json['durationSeconds'] as num).toInt()
          : (int.tryParse(json['durationSeconds']?.toString() ?? '0') ?? 0),
      completed: json['completed'] == true,
      lastWatchedAt: json['lastWatchedAt']?.toString() ??
          json['updatedAt']?.toString() ??
          '',
      directTitle: directTitle,
      directPoster: directPoster,
      directBanner: directBanner,
      directVideoUrl: directVideoUrl,
      directEpisodeNumber: directEpisodeNumber,
      directEpisodeTitle: directEpisodeTitle,
      content: content,
      episode: episode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'contentId': contentId,
      if (episodeId != null) 'episodeId': episodeId,
      'contentType': contentType,
      'progressSeconds': progressSeconds,
      'durationSeconds': durationSeconds,
      'completed': completed,
      'lastWatchedAt': lastWatchedAt,
    };
  }

  ContinueWatchingItem copyWith({
    String? id,
    String? userId,
    String? contentId,
    String? episodeId,
    String? contentType,
    int? progressSeconds,
    int? durationSeconds,
    bool? completed,
    String? lastWatchedAt,
    String? directTitle,
    String? directPoster,
    String? directBanner,
    String? directVideoUrl,
    int? directEpisodeNumber,
    String? directEpisodeTitle,
    Microdrama? content,
    MicroDramaEpisode? episode,
  }) {
    return ContinueWatchingItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contentId: contentId ?? this.contentId,
      episodeId: episodeId ?? this.episodeId,
      contentType: contentType ?? this.contentType,
      progressSeconds: progressSeconds ?? this.progressSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completed: completed ?? this.completed,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      directTitle: directTitle ?? this.directTitle,
      directPoster: directPoster ?? this.directPoster,
      directBanner: directBanner ?? this.directBanner,
      directVideoUrl: directVideoUrl ?? this.directVideoUrl,
      directEpisodeNumber: directEpisodeNumber ?? this.directEpisodeNumber,
      directEpisodeTitle: directEpisodeTitle ?? this.directEpisodeTitle,
      content: content ?? this.content,
      episode: episode ?? this.episode,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List response
// ─────────────────────────────────────────────────────────────────────────────
class ContinueWatchingResponse {
  final bool success;
  final List<ContinueWatchingItem> items;

  const ContinueWatchingResponse({
    required this.success,
    required this.items,
  });

  factory ContinueWatchingResponse.fromDynamic(dynamic json) {
    if (json is List) {
      return ContinueWatchingResponse(
        success: true,
        items: json
            .whereType<Map<String, dynamic>>()
            .map((e) => ContinueWatchingItem.fromJson(e))
            .toList(),
      );
    }
    if (json is Map<String, dynamic>) {
      final rawList = json['data'] ??
          json['continueWatching'] ??
          json['items'] ??
          json['result'] ??
          json['progress'] ??
          [];
      if (rawList is List) {
        return ContinueWatchingResponse(
          success: json['success'] ?? true,
          items: rawList
              .whereType<Map<String, dynamic>>()
              .map((e) => ContinueWatchingItem.fromJson(e))
              .toList(),
        );
      }
    }
    return const ContinueWatchingResponse(success: false, items: []);
  }

  factory ContinueWatchingResponse.fromJson(Map<String, dynamic> json) =>
      ContinueWatchingResponse.fromDynamic(json);
}
