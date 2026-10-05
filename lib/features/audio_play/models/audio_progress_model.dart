import 'package:masti_adda_app/features/audio_play/models/audio_episode_model.dart';
import 'package:masti_adda_app/utils/helpers.dart';

class AudioProgressModel {
  final String id;
  final String episodeId;
  final String storyId;
  final String storyTitle;
  final String storyCoverImage;
  final String coverImage;
  final int progressSeconds;
  final int durationSeconds;
  final bool isCompleted;
  final AudioEpisodeModel? episode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AudioProgressModel({
    required this.id,
    required this.episodeId,
    this.storyId = '',
    this.storyTitle = '',
    this.storyCoverImage = '',
    this.coverImage = '',
    required this.progressSeconds,
    required this.durationSeconds,
    required this.isCompleted,
    this.episode,
    this.createdAt,
    this.updatedAt,
  });

  double get progressPercentage => durationSeconds > 0
      ? (progressSeconds / durationSeconds).clamp(0.0, 1.0)
      : 0.0;

  String get imageUrl {
    if (episode != null && episode!.imageUrl.isNotEmpty) {
      return episode!.imageUrl;
    }
    if (coverImage.isNotEmpty) {
      return formatMediaUrl(coverImage);
    }
    if (storyCoverImage.isNotEmpty) {
      return formatMediaUrl(storyCoverImage);
    }
    return '';
  }

  factory AudioProgressModel.fromJson(Map<String, dynamic> json) {
    AudioEpisodeModel? parsedEpisode;
    String epId = json['episodeId']?.toString() ?? '';
    String stId = json['storyId']?.toString() ?? '';
    String stTitle = json['storyTitle']?.toString() ?? '';
    String stCover = json['coverImage']?.toString() ??
        json['imageUrl']?.toString() ??
        json['thumbnail']?.toString() ??
        json['poster']?.toString() ??
        json['bannerImage']?.toString() ??
        '';

    // 1. Check if story or storyId is an object at root
    if (json['storyId'] is Map) {
      final s = Map<String, dynamic>.from(json['storyId']);
      stId = s['_id']?.toString() ?? s['id']?.toString() ?? stId;
      stTitle = s['title']?.toString() ?? stTitle;
      stCover = s['coverImage']?.toString() ??
          s['bannerImage']?.toString() ??
          s['imageUrl']?.toString() ??
          s['poster']?.toString() ??
          s['thumbnail']?.toString() ??
          stCover;
    } else if (json['story'] is Map) {
      final s = Map<String, dynamic>.from(json['story']);
      stId = s['_id']?.toString() ?? s['id']?.toString() ?? stId;
      stTitle = s['title']?.toString() ?? stTitle;
      stCover = s['coverImage']?.toString() ??
          s['bannerImage']?.toString() ??
          s['imageUrl']?.toString() ??
          s['poster']?.toString() ??
          s['thumbnail']?.toString() ??
          stCover;
    } else if (json['audioStory'] is Map) {
      final s = Map<String, dynamic>.from(json['audioStory']);
      stId = s['_id']?.toString() ?? s['id']?.toString() ?? stId;
      stTitle = s['title']?.toString() ?? stTitle;
      stCover = s['coverImage']?.toString() ??
          s['bannerImage']?.toString() ??
          s['imageUrl']?.toString() ??
          s['poster']?.toString() ??
          s['thumbnail']?.toString() ??
          stCover;
    }

    // 2. Parse episode
    if (json['episode'] is Map) {
      parsedEpisode = AudioEpisodeModel.fromJson(
        Map<String, dynamic>.from(json['episode']),
        parentStoryId: stId,
        parentStoryTitle: stTitle,
        parentStoryCover: stCover,
      );
      epId = parsedEpisode.id;
    } else if (json['episodeId'] is Map) {
      parsedEpisode = AudioEpisodeModel.fromJson(
        Map<String, dynamic>.from(json['episodeId']),
        parentStoryId: stId,
        parentStoryTitle: stTitle,
        parentStoryCover: stCover,
      );
      epId = parsedEpisode.id;
    } else if (json['audioEpisode'] is Map) {
      parsedEpisode = AudioEpisodeModel.fromJson(
        Map<String, dynamic>.from(json['audioEpisode']),
        parentStoryId: stId,
        parentStoryTitle: stTitle,
        parentStoryCover: stCover,
      );
      epId = parsedEpisode.id;
    }

    // If storyId/storyCover was parsed inside episode, pull it up if empty
    if (parsedEpisode != null) {
      if (stId.isEmpty && parsedEpisode.storyId.isNotEmpty) {
        stId = parsedEpisode.storyId;
      }
      if (stTitle.isEmpty && parsedEpisode.storyTitle.isNotEmpty) {
        stTitle = parsedEpisode.storyTitle;
      }
      if (stCover.isEmpty && parsedEpisode.storyCoverImage.isNotEmpty) {
        stCover = parsedEpisode.storyCoverImage;
      }
    }

    final rawProg = json['progressSeconds'] ?? json['progress'] ?? 0;
    final rawDur = json['durationSeconds'] ?? json['duration'] ?? 0;

    return AudioProgressModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      episodeId: epId,
      storyId: stId,
      storyTitle: stTitle,
      storyCoverImage: stCover,
      coverImage: json['coverImage']?.toString() ??
          json['thumbnail']?.toString() ??
          json['imageUrl']?.toString() ??
          '',
      progressSeconds: rawProg is int
          ? rawProg
          : (int.tryParse(rawProg.toString()) ?? 0),
      durationSeconds: rawDur is int
          ? rawDur
          : (int.tryParse(rawDur.toString()) ?? 0),
      isCompleted: json['isCompleted'] == true,
      episode: parsedEpisode,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'episodeId': episodeId,
    'storyId': storyId,
    'storyTitle': storyTitle,
    'storyCoverImage': storyCoverImage,
    'coverImage': coverImage,
    'progressSeconds': progressSeconds,
    'durationSeconds': durationSeconds,
    'isCompleted': isCompleted,
    if (episode != null) 'episode': episode!.toJson(),
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  AudioProgressModel copyWith({
    String? id,
    String? episodeId,
    String? storyId,
    String? storyTitle,
    String? storyCoverImage,
    String? coverImage,
    int? progressSeconds,
    int? durationSeconds,
    bool? isCompleted,
    AudioEpisodeModel? episode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AudioProgressModel(
      id: id ?? this.id,
      episodeId: episodeId ?? this.episodeId,
      storyId: storyId ?? this.storyId,
      storyTitle: storyTitle ?? this.storyTitle,
      storyCoverImage: storyCoverImage ?? this.storyCoverImage,
      coverImage: coverImage ?? this.coverImage,
      progressSeconds: progressSeconds ?? this.progressSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      episode: episode ?? this.episode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
