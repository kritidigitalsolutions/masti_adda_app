import 'package:masti_adda_app/features/audio_play/models/audio_story_model.dart';

class AudioHomeFeedModel {
  final List<AudioStoryModel> featured;
  final List<AudioStoryModel> trending;
  final List<AudioStoryModel> recent;
  final List<AudioStoryModel> topStories;

  const AudioHomeFeedModel({
    this.featured = const [],
    this.trending = const [],
    this.recent = const [],
    this.topStories = const [],
  });

  List<AudioStoryModel> get recentlyAdded =>
      recent.isNotEmpty ? recent : featured;

  List<AudioStoryModel> get topRated => topStories.isNotEmpty
      ? topStories
      : (trending.isNotEmpty ? trending : featured);

  factory AudioHomeFeedModel.fromJson(Map<String, dynamic> json) {
    List<AudioStoryModel> parseList(dynamic raw) {
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => AudioStoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    }

    // Check if feed is nested under 'feed' key
    final feedData = json['feed'] is Map
        ? Map<String, dynamic>.from(json['feed'])
        : json;

    return AudioHomeFeedModel(
      featured: parseList(
        feedData['featured'] ?? feedData['banners'] ?? json['featured'],
      ),
      trending: parseList(
        feedData['trending'] ?? feedData['topRated'] ?? feedData['popular'],
      ),
      recent: parseList(
        feedData['recent'] ?? feedData['recentlyAdded'] ?? feedData['latest'],
      ),
      topStories: parseList(
        feedData['topStories'] ?? feedData['topRated'] ?? feedData['popular'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'featured': featured.map((e) => e.toJson()).toList(),
    'trending': trending.map((e) => e.toJson()).toList(),
    'recent': recent.map((e) => e.toJson()).toList(),
    'topStories': topStories.map((e) => e.toJson()).toList(),
  };
}
