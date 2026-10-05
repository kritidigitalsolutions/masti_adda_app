import 'package:masti_adda_app/features/audio_play/models/audio_story_model.dart';

class AudioHomeFeedModel {
  final List<AudioStoryModel> featured;
  final List<AudioStoryModel> recentlyAdded;
  final List<AudioStoryModel> topRated;

  const AudioHomeFeedModel({
    this.featured = const [],
    this.recentlyAdded = const [],
    this.topRated = const [],
  });

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

    return AudioHomeFeedModel(
      featured: parseList(json['featured'] ?? json['banners']),
      recentlyAdded: parseList(json['recentlyAdded'] ?? json['latest']),
      topRated: parseList(
        json['topRated'] ?? json['popular'] ?? json['trending'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'featured': featured.map((e) => e.toJson()).toList(),
    'recentlyAdded': recentlyAdded.map((e) => e.toJson()).toList(),
    'topRated': topRated.map((e) => e.toJson()).toList(),
  };
}
