import 'package:masti_adda_app/features/web_series/model/episode_response.dart';

class EpisodeModel {
  final bool success;
  final Episode episode;

  const EpisodeModel({required this.success, required this.episode});

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      success: json['success'] ?? false,
      episode: Episode.fromJson(json['episode'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'episode': episode.toJson()};
  }

  EpisodeModel copyWith({bool? success, Episode? episode}) {
    return EpisodeModel(
      success: success ?? this.success,
      episode: episode ?? this.episode,
    );
  }
}
