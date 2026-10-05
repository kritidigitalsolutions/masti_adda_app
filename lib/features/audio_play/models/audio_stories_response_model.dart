import 'package:masti_adda_app/features/audio_play/models/audio_story_model.dart';

class AudioStoriesResponseModel {
  final bool success;
  final List<AudioStoryModel> stories;
  final String message;

  const AudioStoriesResponseModel({
    this.success = false,
    this.stories = const [],
    this.message = '',
  });

  factory AudioStoriesResponseModel.fromJson(Map<String, dynamic> json) {
    List<AudioStoryModel> parsedStories = [];
    if (json['stories'] is List) {
      parsedStories = (json['stories'] as List)
          .whereType<Map>()
          .map((e) => AudioStoryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else if (json['data'] is List) {
      parsedStories = (json['data'] as List)
          .whereType<Map>()
          .map((e) => AudioStoryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return AudioStoriesResponseModel(
      success: json['success'] == true,
      stories: parsedStories,
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'stories': stories.map((e) => e.toJson()).toList(),
    'message': message,
  };
}
