import 'package:flutter/foundation.dart';
import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';
import 'package:masti_adda_app/shared/models/like_dislike_response.dart';

class InteractionDatasource {
  final NetworkApiService _apiService = NetworkApiService();

  /// 1. TOGGLE LIKE (Auth Required)
  /// Endpoint: POST /api/interaction/toggle/like/:contentId
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
      debugPrint("InteractionDatasource.toggleLike Error: $e");
      rethrow;
    }
  }

  /// 2. TOGGLE DISLIKE (Auth Required)
  /// Endpoint: POST /api/interaction/toggle/dislike/:contentId
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
      debugPrint("InteractionDatasource.toggleDislike Error: $e");
      rethrow;
    }
  }
}
