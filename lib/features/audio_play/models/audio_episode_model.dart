import 'package:masti_adda_app/utils/helpers.dart';

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

class AudioEpisodeModel {
  final String id;
  final String title;
  final String storyId;
  final String storyTitle;
  final String storyCoverImage;
  final int episodeNumber;
  final int durationSeconds;
  final String audioUrl;
  final String fileSize;
  final String coverImage;
  final bool isPremium;
  final int progressSeconds;
  final bool isCompleted;
  final bool isPlaying;
  final bool isLocked;
  final String status;
  final num priority;
  final String slug;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int v;

  const AudioEpisodeModel({
    required this.id,
    required this.title,
    this.storyId = '',
    this.storyTitle = '',
    this.storyCoverImage = '',
    this.episodeNumber = 1,
    this.durationSeconds = 0,
    this.audioUrl = '',
    this.fileSize = '',
    this.coverImage = '',
    this.isPremium = false,
    this.progressSeconds = 0,
    this.isCompleted = false,
    this.isPlaying = false,
    this.isLocked = false,
    this.status = 'Published',
    this.priority = 0,
    this.slug = '',
    this.createdAt,
    this.updatedAt,
    this.v = 0,
  });

  Duration get duration => Duration(seconds: durationSeconds);

  String get imageUrl =>
      formatMediaUrl(coverImage.isNotEmpty ? coverImage : storyCoverImage);

  String get playableAudioUrl => formatMediaUrl(audioUrl);

  factory AudioEpisodeModel.fromJson(
    Map<String, dynamic> json, {
    String parentStoryId = '',
    String parentStoryTitle = '',
    String parentStoryCover = '',
  }) {
    String resolvedStoryId = parentStoryId;
    String resolvedStoryTitle = parentStoryTitle;
    String resolvedStoryCover = parentStoryCover;

    if (json['storyId'] is Map) {
      final s = json['storyId'] as Map<String, dynamic>;
      resolvedStoryId =
          s['_id']?.toString() ?? s['id']?.toString() ?? resolvedStoryId;
      resolvedStoryTitle = s['title']?.toString() ?? resolvedStoryTitle;
      resolvedStoryCover =
          s['coverImage']?.toString() ??
          s['bannerImage']?.toString() ??
          s['imageUrl']?.toString() ??
          s['poster']?.toString() ??
          s['thumbnail']?.toString() ??
          resolvedStoryCover;
    } else if (json['story'] is Map) {
      final s = json['story'] as Map<String, dynamic>;
      resolvedStoryId =
          s['_id']?.toString() ?? s['id']?.toString() ?? resolvedStoryId;
      resolvedStoryTitle = s['title']?.toString() ?? resolvedStoryTitle;
      resolvedStoryCover =
          s['coverImage']?.toString() ??
          s['bannerImage']?.toString() ??
          s['imageUrl']?.toString() ??
          s['poster']?.toString() ??
          s['thumbnail']?.toString() ??
          resolvedStoryCover;
    } else if (json['audioStory'] is Map) {
      final s = json['audioStory'] as Map<String, dynamic>;
      resolvedStoryId =
          s['_id']?.toString() ?? s['id']?.toString() ?? resolvedStoryId;
      resolvedStoryTitle = s['title']?.toString() ?? resolvedStoryTitle;
      resolvedStoryCover =
          s['coverImage']?.toString() ??
          s['bannerImage']?.toString() ??
          s['imageUrl']?.toString() ??
          s['poster']?.toString() ??
          s['thumbnail']?.toString() ??
          resolvedStoryCover;
    } else if (json['storyId'] is String && json['storyId'].toString().isNotEmpty) {
      resolvedStoryId = json['storyId'].toString();
    } else if (json['story'] is String && json['story'].toString().isNotEmpty) {
      resolvedStoryId = json['story'].toString();
    }

    final rawDuration = json['duration'] ?? json['durationSeconds'];
    int parsedDuration = 0;
    if (rawDuration is int) {
      parsedDuration = rawDuration;
    } else if (rawDuration is double) {
      parsedDuration = rawDuration.toInt();
    } else if (rawDuration is String) {
      parsedDuration = int.tryParse(rawDuration) ?? 0;
    }

    final rawProgress = json['progressSeconds'] ?? 0;
    int parsedProgress = 0;
    if (rawProgress is int) {
      parsedProgress = rawProgress;
    } else if (rawProgress is double) {
      parsedProgress = rawProgress.toInt();
    } else if (rawProgress is String) {
      parsedProgress = int.tryParse(rawProgress) ?? 0;
    }

    return AudioEpisodeModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title:
          json['title']?.toString() ?? 'Episode ${json['episodeNumber'] ?? 1}',
      storyId: resolvedStoryId,
      storyTitle: resolvedStoryTitle,
      storyCoverImage: resolvedStoryCover,
      episodeNumber: json['episodeNumber'] is int
          ? json['episodeNumber']
          : int.tryParse(json['episodeNumber']?.toString() ?? '1') ?? 1,
      durationSeconds: parsedDuration,
      audioUrl:
          json['audioUrl']?.toString() ?? json['fileUrl']?.toString() ?? '',
      fileSize: json['fileSize']?.toString() ?? '',
      coverImage:
          json['coverImage']?.toString() ??
          json['thumbnail']?.toString() ??
          json['imageUrl']?.toString() ??
          json['poster']?.toString() ??
          json['image']?.toString() ??
          '',
      isPremium: _parseBool(
        json['isPremium'] ??
            json['is_premium'] ??
            json['premium'] ??
            json['isPremimu'],
      ),
      progressSeconds: parsedProgress,
      isCompleted: _parseBool(
        json['isCompleted'] ?? json['is_completed'] ?? false,
      ),
      isPlaying: false,
      isLocked: _parseBool(json['isLocked'] ?? json['is_locked'] ?? false),
      status: json['status']?.toString() ?? 'Published',
      priority: (json['priority'] as num?) ?? 0,
      slug: json['slug']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      v: (json['__v'] as num?)?.toInt() ?? 0,
    );
  }

  AudioEpisodeModel copyWith({
    String? id,
    String? title,
    String? storyId,
    String? storyTitle,
    String? storyCoverImage,
    int? episodeNumber,
    int? durationSeconds,
    String? audioUrl,
    String? fileSize,
    String? coverImage,
    bool? isPremium,
    int? progressSeconds,
    bool? isCompleted,
    bool? isPlaying,
    bool? isLocked,
    String? status,
    num? priority,
    String? slug,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
  }) {
    return AudioEpisodeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      storyId: storyId ?? this.storyId,
      storyTitle: storyTitle ?? this.storyTitle,
      storyCoverImage: storyCoverImage ?? this.storyCoverImage,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      audioUrl: audioUrl ?? this.audioUrl,
      fileSize: fileSize ?? this.fileSize,
      coverImage: coverImage ?? this.coverImage,
      isPremium: isPremium ?? this.isPremium,
      progressSeconds: progressSeconds ?? this.progressSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      isPlaying: isPlaying ?? this.isPlaying,
      isLocked: isLocked ?? this.isLocked,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      slug: slug ?? this.slug,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'title': title,
    'storyId': storyId,
    'storyTitle': storyTitle,
    'episodeNumber': episodeNumber,
    'duration': durationSeconds,
    'audioUrl': audioUrl,
    'fileSize': fileSize,
    'coverImage': coverImage,
    'isPremium': isPremium,
    'isLocked': isLocked,
    'status': status,
    'priority': priority,
    'slug': slug,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    '__v': v,
  };
}
