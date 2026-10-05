import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';
import 'package:masti_adda_app/features/movie/models/MovieModel.dart';
import 'package:masti_adda_app/shared/models/like_dislike_response.dart';

class MovieDatasource {
  final NetworkApiService _apiService = NetworkApiService();

  Future<List<MovieModel>> allMovie({int? page, int? limit, String? search}) async {
    try {
      final queryParams = <String>[];
      if (page != null) queryParams.add('page=$page');
      if (limit != null) queryParams.add('limit=$limit');
      if (search != null && search.isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(search)}');
      }
      final url = queryParams.isNotEmpty
          ? '${AppUrl.allMovies}?${queryParams.join('&')}'
          : AppUrl.allMovies;
      final jsonData = await _apiService.getApi(url);
      final List<dynamic> moviesJson = jsonData['movies'] ?? [];
      return moviesJson
          .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
          .where((m) => m.isVisible)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Search movies from backend with fallback
  Future<List<MovieModel>> searchMovies(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    // 1. Try /api/movies?search=query
    try {
      final url = '${AppUrl.allMovies}?search=${Uri.encodeComponent(q)}';
      final jsonData = await _apiService.getApi(url);
      if (jsonData != null && jsonData['movies'] is List) {
        final List<dynamic> moviesJson = jsonData['movies'];
        if (moviesJson.isNotEmpty) {
          return moviesJson
              .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
              .where((m) => m.isVisible)
              .toList();
        }
      }
    } catch (e) {
      // Continue to fallback
    }

    // 2. Try /api/content/?search=query
    try {
      final url = AppUrl.searchContent(query: q);
      final jsonData = await _apiService.getApi(url);
      if (jsonData != null && jsonData['content'] is List) {
        final List<dynamic> list = jsonData['content'];
        return list
            .where((e) {
              final type = (e['type'] ?? e['contentType'])?.toString().toLowerCase();
              return type == null || type == 'movie' || type == 'movies';
            })
            .map((e) => MovieModel.fromJson(e as Map<String, dynamic>))
            .where((m) => m.isVisible)
            .toList();
      }
    } catch (e) {
      // Continue to empty
    }

    return [];
  }

  Future<MovieModel?> movieDetail({required String id}) async {
    try {
      final jsonData = await _apiService.getApi(AppUrl.detailMovie(id));
      return MovieModel.fromJson(jsonData['movie']);
    } catch (e) {
      rethrow;
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

