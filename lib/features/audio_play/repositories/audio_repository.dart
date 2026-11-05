import 'package:flutter/foundation.dart';
import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';
import 'package:masti_adda_app/features/audio_play/models/audio_story_model.dart';
import 'package:masti_adda_app/shared/models/like_dislike_response.dart';

class AudioRepository {
  final NetworkApiService _apiService = NetworkApiService();

  /// 1. GET ALL ACTIVE CATEGORIES
  /// Endpoint: GET /api/audio-categories
  Future<List<AudioCategoryModel>> getAudioCategories() async {
    try {
      final response = await _apiService.getApi(AppUrl.audioCategories);
      if (response != null && response['success'] == true) {
        final List list = response['categories'] ?? [];
        return list
            .map((e) => AudioCategoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else if (response is List) {
        return response
            .map((e) => AudioCategoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("AudioRepository.getAudioCategories Error: $e");
      return [];
    }
  }

  /// 2. GET ALL AUDIO STORIES (With optional filters)
  /// Endpoint: GET /api/audio-stories?category={id}&language=Hindi&page=1&limit=10
  Future<List<AudioStoryModel>> getAudioStories({
    String? categoryId,
    String? language,
    int? page,
    int? limit,
  }) async {
    try {
      final url = AppUrl.audioStories(
        categoryId: categoryId,
        language: language,
        page: page,
        limit: limit,
      );
      final response = await _apiService.getApi(url);
      if (response != null && response['success'] == true) {
        final List list = response['stories'] ?? [];
        return list
            .map((e) => AudioStoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else if (response is List) {
        return response
            .map((e) => AudioStoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("AudioRepository.getAudioStories Error: $e");
      return [];
    }
  }

  /// 3. GET AUDIO STORIES HOME FEED
  /// Endpoint: GET /api/audio-stories/home
  Future<AudioHomeFeedModel?> getAudioStoriesHome() async {
    try {
      final response = await _apiService.getApi(AppUrl.audioStoriesHome);
      if (response != null && response['success'] == true) {
        return AudioHomeFeedModel.fromJson(Map<String, dynamic>.from(response));
      } else if (response is Map) {
        return AudioHomeFeedModel.fromJson(Map<String, dynamic>.from(response));
      }
      return null;
    } catch (e) {
      debugPrint("AudioRepository.getAudioStoriesHome Error: $e");
      return null;
    }
  }

  /// 4. SEARCH AUDIO STORIES
  /// Endpoint: GET /api/audio-stories/search?q={query}
  Future<List<AudioStoryModel>> searchAudioStories(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _apiService.getApi(AppUrl.searchAudioStories(query));
      if (response != null && response['success'] == true) {
        final List list = response['results'] ?? response['stories'] ?? response['data'] ?? [];
        return list
            .map((e) => AudioStoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else if (response is List) {
        return response
            .map((e) => AudioStoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("AudioRepository.searchAudioStories Error: $e");
      return [];
    }
  }

  /// 4. GET SINGLE AUDIO STORY (Includes Episodes)
  /// Endpoint: GET /api/audio-stories/{story_id}
  Future<AudioStoryModel?> getAudioStoryDetail(String storyId) async {
    try {
      final response = await _apiService.getApi(AppUrl.singleAudioStory(storyId));
      if (response != null) {
        if (response['success'] == true && response['story'] != null) {
          return AudioStoryModel.fromJson(Map<String, dynamic>.from(response['story']));
        } else if (response['data'] != null) {
          return AudioStoryModel.fromJson(Map<String, dynamic>.from(response['data']));
        } else if (response['_id'] != null || response['id'] != null) {
          return AudioStoryModel.fromJson(Map<String, dynamic>.from(response));
        }
      }
    } catch (e) {
      debugPrint("Primary getAudioStoryDetail failed: $e");
    }

    try {
      final response = await _apiService.getApi(AppUrl.audioStoryDetail(storyId));
      if (response != null) {
        if (response['success'] == true && response['story'] != null) {
          return AudioStoryModel.fromJson(Map<String, dynamic>.from(response['story']));
        } else if (response['data'] != null) {
          return AudioStoryModel.fromJson(Map<String, dynamic>.from(response['data']));
        } else if (response['_id'] != null || response['id'] != null) {
          return AudioStoryModel.fromJson(Map<String, dynamic>.from(response));
        }
      }
    } catch (e) {
      debugPrint("Fallback audioStoryDetail failed: $e");
    }

    return null;
  }

  /// 5. FETCH AUDIO EPISODES FOR A STORY
  Future<List<AudioEpisodeModel>> fetchAudioEpisodes(String storyId) async {
    final urls = [
      AppUrl.audioStoryEpisodes(storyId),
      AppUrl.audioEpisodesByStory(storyId),
      AppUrl.audioEpisodesByStoryAlt(storyId),
    ];

    for (var url in urls) {
      try {
        final response = await _apiService.getApi(url);
        if (response != null) {
          List list = [];
          if (response is List) {
            list = response;
          } else if (response['success'] == true) {
            list = response['episodes'] ?? response['data'] ?? response['list'] ?? [];
          } else if (response['episodes'] is List) {
            list = response['episodes'];
          }
          if (list.isNotEmpty) {
            return list
                .whereType<Map>()
                .map((e) => AudioEpisodeModel.fromJson(Map<String, dynamic>.from(e), parentStoryId: storyId))
                .toList();
          }
        }
      } catch (e) {
        debugPrint("fetchAudioEpisodes error for $url: $e");
      }
    }
    return [];
  }

  /// 6. PLAY/STREAM AUDIO EPISODE
  /// Endpoint: GET /api/audio-episodes/{episode_id}/play
  Future<String?> playAudioEpisode(String episodeId) async {
    try {
      final response = await _apiService.getApi(AppUrl.playAudioEpisode(episodeId));
      if (response != null && response['success'] == true) {
        return response['audioUrl']?.toString() ?? response['url']?.toString();
      } else if (response is Map && response['audioUrl'] != null) {
        return response['audioUrl']?.toString();
      }
      return null;
    } catch (e) {
      debugPrint("AudioRepository.playAudioEpisode Error: $e");
      return null;
    }
  }

  /// 7. SAVE/UPDATE LISTENING PROGRESS
  /// Endpoint: POST /api/audio-progress
  Future<bool> saveAudioProgress({
    required String episodeId,
    required int progressSeconds,
    required int durationSeconds,
  }) async {
    try {
      final response = await _apiService.postApi(AppUrl.saveAudioProgress, {
        "episodeId": episodeId,
        "progressSeconds": progressSeconds,
        "durationSeconds": durationSeconds,
      });
      return response != null && (response['success'] == true || response['status'] == true);
    } catch (e) {
      debugPrint("AudioRepository.saveAudioProgress Error: $e");
      return false;
    }
  }

  /// 8. GET CONTINUE LISTENING FEED
  /// Endpoint: GET /api/audio-progress/continue
  Future<List<AudioProgressModel>> getContinueListening() async {
    try {
      final response = await _apiService.getApi(AppUrl.continueListening);
      if (response != null && response['success'] == true) {
        final List list = response['continueListening'] ?? response['data'] ?? [];
        return list
            .map((e) => AudioProgressModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint("AudioRepository.getContinueListening Error: $e");
      return [];
    }
  }

  /// 9. MARK EPISODE AS COMPLETED
  /// Endpoint: POST /api/audio-progress/{episode_id}/complete
  Future<bool> markEpisodeCompleted(String episodeId) async {
    try {
      final response = await _apiService.postApi(
        AppUrl.markAudioEpisodeCompleted(episodeId),
        {},
      );
      return response != null && (response['success'] == true || response['status'] == true);
    } catch (e) {
      debugPrint("AudioRepository.markEpisodeCompleted Error: $e");
      return false;
    }
  }

  /// 10. GET SPECIFIC EPISODE PROGRESS
  /// Endpoint: GET /api/audio-progress/{episode_id}
  Future<AudioProgressModel?> getEpisodeProgress(String episodeId) async {
    try {
      final response = await _apiService.getApi(AppUrl.audioEpisodeProgress(episodeId));
      if (response != null && response['success'] == true && response['progress'] != null) {
        return AudioProgressModel.fromJson(Map<String, dynamic>.from(response['progress']));
      }
      return null;
    } catch (e) {
      debugPrint("AudioRepository.getEpisodeProgress Error: $e");
      return null;
    }
  }

  /// 11. TOGGLE LIKE (Auth Required)
  /// Endpoint: POST /api/interaction/toggle/like/{content_id}
  Future<LikeDislikeResponse?> toggleLike(String contentId) async {
    try {
      final response = await _apiService.postApi(
        AppUrl.toggleLike(contentId),
        {},
      );
      if (response != null && response is Map) {
        return LikeDislikeResponse.fromJson(Map<String, dynamic>.from(response));
      }
      return null;
    } catch (e) {
      debugPrint("AudioRepository.toggleLike Error: $e");
      return null;
    }
  }

  /// 12. TOGGLE DISLIKE (Auth Required)
  /// Endpoint: POST /api/interaction/toggle/dislike/{content_id}
  Future<LikeDislikeResponse?> toggleDislike(String contentId) async {
    try {
      final response = await _apiService.postApi(
        AppUrl.toggleDislike(contentId),
        {},
      );
      if (response != null && response is Map) {
        return LikeDislikeResponse.fromJson(Map<String, dynamic>.from(response));
      }
      return null;
    } catch (e) {
      debugPrint("AudioRepository.toggleDislike Error: $e");
      return null;
    }
  }
}
