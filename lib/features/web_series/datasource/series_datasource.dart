import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';
import 'package:masti_adda_app/features/web_series/model/SeriesModel.dart';
import 'package:masti_adda_app/features/web_series/model/episode_model.dart';
import 'package:masti_adda_app/features/web_series/model/episode_response.dart';
import 'package:masti_adda_app/shared/models/like_dislike_response.dart';

class SeriesDatasource {
  final NetworkApiService _apiService = NetworkApiService();

  Future<SeriesResponse?> allSeries({int? page, int? limit, String? search}) async {
    try {
      final queryParams = <String>[];
      if (page != null) queryParams.add('page=$page');
      if (limit != null) queryParams.add('limit=$limit');
      if (search != null && search.isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(search)}');
      }
      final url = queryParams.isNotEmpty
          ? '${AppUrl.allSeries}?${queryParams.join('&')}'
          : AppUrl.allSeries;
      final json = await _apiService.getApi(url);
      if (json != null) {
        return SeriesResponse.fromJson(json);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Search web series from backend with fallback
  Future<List<Series>> searchSeries(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    // 1. Try /api/series?search=query
    try {
      final url = '${AppUrl.allSeries}?search=${Uri.encodeComponent(q)}';
      final json = await _apiService.getApi(url);
      if (json != null) {
        final parsed = SeriesResponse.fromJson(json);
        if (parsed.series.isNotEmpty) {
          return parsed.series;
        }
      }
    } catch (_) {}

    // 2. Try /api/content/?search=query
    try {
      final url = AppUrl.searchContent(query: q);
      final json = await _apiService.getApi(url);
      if (json != null && json['content'] is List) {
        final List<dynamic> list = json['content'];
        return list
            .where((e) {
              final type =
                  (e['type'] ?? e['contentType'])?.toString().toLowerCase();
              return type == 'series' ||
                  type == 'webseries' ||
                  type == 'web_series';
            })
            .map((e) => Series.fromJson(e as Map<String, dynamic>))
            .where((s) => s.isVisible)
            .toList();
      }
    } catch (_) {}

    return [];
  }

  Future<Series?> seriesDetail({required String id}) async {
    try {
      final json = await _apiService.getApi(AppUrl.seriesDetail(id));
      if (json != null) {
        return Series.fromJson(json['series']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<EpisodesResponse?> allEpisode({required String id}) async {
    try {
      final json = await _apiService.getApi(AppUrl.episodes(id));
      if (json != null) {
        return EpisodesResponse.fromJson(json);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<EpisodeModel?> singleEpisode({required String id}) async {
    try {
      final json = await _apiService.getApi(AppUrl.singleEpisode(id: id));
      if (json != null) {
        return EpisodeModel.fromJson(json);
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
