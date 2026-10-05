import 'package:flutter/foundation.dart';
import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';
import 'package:masti_adda_app/features/micro_drama/models/continue_watching_model.dart';

class ContinueWatchingDatasource {
  final NetworkApiService _api = NetworkApiService();

  /// POST `/api/continue-watching/progress`
  /// Saves or updates watch progress for any content type.
  Future<void> saveProgress(SaveProgressRequest request) async {
    try {
      await _api.postApi(AppUrl.saveWatchProgress, request.toJson());
    } catch (e) {
      debugPrint('ContinueWatching.saveProgress error: $e');
    }
  }

  /// GET `/api/continue-watching?limit={limit}`
  /// Returns uncompleted active progress items sorted by last watched.
  Future<ContinueWatchingResponse?> getContinueWatchingList({
    int limit = 20,
  }) async {
    try {
      final json = await _api.getApi(
        '${AppUrl.continueWatchingList}?limit=$limit',
      );
      if (json != null) {
        return ContinueWatchingResponse.fromDynamic(json);
      }
      return null;
    } catch (e) {
      debugPrint('ContinueWatching.getList error: $e');
      return null;
    }
  }

  /// GET /api/continue-watching/progress/:contentId?episodeId=<id>
  /// Fetches saved progress for a specific piece of content/episode.
  Future<ContinueWatchingItem?> getProgressForContent(
    String contentId, {
    String? episodeId,
  }) async {
    try {
      final url = episodeId != null && episodeId.isNotEmpty
          ? '${AppUrl.watchProgressForContent(contentId)}?episodeId=$episodeId'
          : AppUrl.watchProgressForContent(contentId);
      final json = await _api.getApi(url);
      if (json != null) {
        // Backend may wrap in { success, data: {...} } or return item directly
        final raw = json['data'] ?? json;
        if (raw is Map<String, dynamic> && raw.isNotEmpty) {
          return ContinueWatchingItem.fromJson(raw);
        }
      }
      return null;
    } catch (e) {
      debugPrint('ContinueWatching.getProgress error: $e');
      return null;
    }
  }

  /// PATCH /api/continue-watching/complete/:progressId
  /// Manually marks a progress record as completed.
  Future<void> markCompleted(String progressId) async {
    try {
      await _api.pacthApi(AppUrl.markWatchCompleted(progressId), null);
    } catch (e) {
      debugPrint('ContinueWatching.markCompleted error: $e');
    }
  }

  /// DELETE /api/continue-watching/:progressId
  /// Removes an item from the user's Continue Watching list.
  Future<void> deleteItem(String progressId) async {
    try {
      await _api.deleteApi(AppUrl.deleteWatchProgress(progressId), null);
    } catch (e) {
      debugPrint('ContinueWatching.deleteItem error: $e');
    }
  }
}
