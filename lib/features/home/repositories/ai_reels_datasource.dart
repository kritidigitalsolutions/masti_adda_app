import 'package:flutter/foundation.dart';
import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';
import 'package:masti_adda_app/features/home/models/ai_reel_comment_model.dart';
import 'package:masti_adda_app/features/home/models/ai_reel_model.dart';
import 'package:masti_adda_app/shared/models/like_dislike_response.dart';

class AiReelsDatasource {
  final NetworkApiService _apiService = NetworkApiService();

  /// Fetch a batch of AI Reels (with initial or persistent sessionId)
  Future<AiReelsResponse> fetchAiReels({
    int limit = 10,
    String? sessionId,
    bool? replay,
  }) async {
    final url = AppUrl.aiReelsFeed(
      limit: limit,
      sessionId: sessionId,

      replay: replay,
    );
    debugPrint("🎬 Fetching AI Reels from: $url");
    final dynamic response = await _apiService.getApi(url);
    if (response is Map<String, dynamic>) {
      return AiReelsResponse.fromJson(response);
    }
    throw Exception("Invalid response format from AI Reels API");
  }

  /// Fire-and-forget: record view for a reel
  Future<void> recordView(String reelId) async {
    if (reelId.isEmpty) return;
    try {
      final url = AppUrl.aiReelView(reelId);
      debugPrint("👁️ Recording view for reel: $reelId ($url)");
      await _apiService.postApi(url, {});
    } catch (e) {
      debugPrint("⚠️ Failed to record reel view: $e");
    }
  }

  /// Fire-and-forget: record watch completion for a reel
  Future<void> recordComplete(String reelId) async {
    if (reelId.isEmpty) return;
    try {
      final url = AppUrl.aiReelComplete(reelId);
      debugPrint("✅ Recording complete for reel: $reelId ($url)");
      await _apiService.postApi(url, {});
    } catch (e) {
      debugPrint("⚠️ Failed to record reel complete: $e");
    }
  }

  /// Toggle Like for an AI Reel: POST /api/interaction/toggle/like/aiReel/:id
  Future<LikeDislikeResponse?> toggleLike(String reelId) async {
    if (reelId.isEmpty) return null;
    try {
      final url = AppUrl.toggleLikeAiReel(reelId);
      debugPrint("❤️ Toggling like for AI Reel: $reelId ($url)");
      final dynamic response = await _apiService.postApi(url, {});
      if (response is Map<String, dynamic>) {
        return LikeDislikeResponse.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint("⚠️ Failed to toggle like for AI reel: $e");
      return null;
    }
  }

  /// Record share increment for an AI Reel: POST /api/ai-reels/:id/share
  Future<AiReelShareResponse?> recordShare(String reelId) async {
    if (reelId.isEmpty) return null;
    try {
      final url = AppUrl.aiReelShare(reelId);
      debugPrint("📤 Recording share for AI Reel: $reelId ($url)");
      final dynamic response = await _apiService.postApi(url, {});
      if (response is Map<String, dynamic>) {
        return AiReelShareResponse.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint("⚠️ Failed to record share for AI reel: $e");
      return null;
    }
  }

  /// Fetch comments for a reel/content: GET /api/v1/app/comments/:contentId
  Future<AiReelCommentsResponse> fetchComments(
    String contentId, {
    int page = 1,
    int limit = 20,
    String? episodeId,
  }) async {
    final url = AppUrl.commentsByContent(
      contentId,
      page: page,
      limit: limit,
      episodeId: episodeId,
    );
    debugPrint("💬 Fetching Comments from: $url");
    final dynamic response = await _apiService.getApi(url);
    if (response is Map<String, dynamic>) {
      return AiReelCommentsResponse.fromJson(response);
    }
    throw Exception("Invalid comments response format");
  }

  /// Post a new comment: POST /api/v1/app/comments
  Future<PostCommentResponse> postComment({
    required String contentId,
    String? episodeId,
    required String text,
  }) async {
    final url = AppUrl.postComment;
    final payload = <String, dynamic>{
      "contentId": contentId,
      if (episodeId != null && episodeId.isNotEmpty) "episodeId": episodeId,
      "text": text,
    };
    debugPrint("💬 Posting Comment to $url with payload: $payload");
    final dynamic response = await _apiService.postApi(url, payload);
    if (response is Map<String, dynamic>) {
      return PostCommentResponse.fromJson(response);
    }
    throw Exception("Invalid post comment response format");
  }

  /// Delete a comment: DELETE /api/v1/app/comments/:commentId
  Future<DeleteCommentResponse> deleteComment(String commentId) async {
    final url = AppUrl.deleteComment(commentId);
    debugPrint("🗑️ Deleting Comment from: $url");
    final dynamic response = await _apiService.deleteApi(url, {});
    if (response is Map<String, dynamic>) {
      return DeleteCommentResponse.fromJson(response);
    }
    throw Exception("Invalid delete comment response format");
  }
}
