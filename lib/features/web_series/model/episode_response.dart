class EpisodesResponse {
  final bool success;
  final List<Episode> episodes;

  const EpisodesResponse({required this.success, required this.episodes});

  factory EpisodesResponse.fromJson(Map<String, dynamic> json) {
    return EpisodesResponse(
      success: json['success'] ?? false,
      episodes: (json['episodes'] as List<dynamic>? ?? [])
          .map((e) => Episode.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'episodes': episodes.map((e) => e.toJson()).toList(),
    };
  }

  EpisodesResponse copyWith({bool? success, List<Episode>? episodes}) {
    return EpisodesResponse(
      success: success ?? this.success,
      episodes: episodes ?? this.episodes,
    );
  }
}

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

class Episode {
  final String id;
  final String title;
  final String description;
  final String seriesId;
  final int seasonNumber;
  final int episodeNumber;
  final String videoUrl;
  final String thumbnail;
  final String duration;
  final bool isPremium;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  const Episode({
    required this.id,
    required this.title,
    required this.description,
    required this.seriesId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.videoUrl,
    required this.thumbnail,
    required this.duration,
    this.isPremium = false,
    this.isLocked = false,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      seriesId: json['seriesId'] ?? '',
      seasonNumber: json['seasonNumber'] ?? 0,
      episodeNumber: json['episodeNumber'] ?? 0,
      videoUrl: json['videoUrl'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      duration: json['duration'] ?? '',
      isPremium: _parseBool(
        json['isPremium'] ??
            json['is_premium'] ??
            json['premium'] ??
            json['isPremimu'],
      ),
      isLocked: _parseBool(json['isLocked'] ?? json['is_locked'] ?? false),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      version: json['__v'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'seriesId': seriesId,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'videoUrl': videoUrl,
      'thumbnail': thumbnail,
      'duration': duration,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': version,
    };
  }

  Episode copyWith({
    String? id,
    String? title,
    String? description,
    String? seriesId,
    int? seasonNumber,
    int? episodeNumber,
    String? videoUrl,
    String? thumbnail,
    String? duration,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
  }) {
    return Episode(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      seriesId: seriesId ?? this.seriesId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }
}
