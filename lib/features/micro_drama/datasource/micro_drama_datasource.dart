import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';
import 'package:masti_adda_app/features/micro_drama/models/episode_detail_response.dart';
import 'package:masti_adda_app/features/micro_drama/models/micro_drama_detail_response.dart';
import 'package:masti_adda_app/features/micro_drama/models/micro_drama_model.dart';
import 'package:masti_adda_app/shared/models/like_dislike_response.dart';

class MicroDramaDatasource {
  final NetworkApiService _apiService = NetworkApiService();

  Future<MicrodramasResponse?> allMicroDrama({int? page, int? limit}) async {
    try {
      final url = (page != null)
          ? '${AppUrl.allMicroDramaApis}?page=$page&limit=${limit ?? 10}'
          : AppUrl.allMicroDramaApis;
      final json = await _apiService.getApi(url);
      if (json != null) {
        return MicrodramasResponse.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<MicrodramaDetailResponse?> dramaDetail({required String id}) async {
    try {
      final json = await _apiService.getApi(AppUrl.singleMicroDrama(id: id));
      if (json != null) {
        return MicrodramaDetailResponse.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<MicroDramaEpisodesResponse?> episodeDetail({required String id}) async {
    try {
      final json = await _apiService.getApi(
        AppUrl.microDramaEpisodeDetail(id: id),
      );
      if (json != null) {
        return MicroDramaEpisodesResponse.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

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
      rethrow;
    }
  }

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
      rethrow;
    }
  }
}

