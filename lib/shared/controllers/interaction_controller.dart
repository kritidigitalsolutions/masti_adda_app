import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/core/services/storage_service.dart';
import 'package:masti_adda_app/shared/models/like_dislike_response.dart';
import 'package:masti_adda_app/shared/repositories/interaction_datasource.dart';

class InteractionController extends GetxController {
  static InteractionController get to {
    if (Get.isRegistered<InteractionController>()) {
      return Get.find<InteractionController>();
    }
    return Get.put(InteractionController(), permanent: true);
  }

  final InteractionDatasource _datasource = InteractionDatasource();

  final RxMap<String, int> likesCount = <String, int>{}.obs;
  final RxMap<String, int> dislikesCount = <String, int>{}.obs;
  final RxMap<String, bool> isLikedMap = <String, bool>{}.obs;
  final RxMap<String, bool> isDislikedMap = <String, bool>{}.obs;
  final RxMap<String, bool> isLikeLoadingMap = <String, bool>{}.obs;
  final RxMap<String, bool> isDislikeLoadingMap = <String, bool>{}.obs;
  final RxMap<String, bool> loadingMap = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedInteractions();
  }

  Future<void> _loadSavedInteractions() async {
    try {
      final likedSet = await StorageService.getLikedContent();
      for (final id in likedSet) {
        isLikedMap[id] = true;
      }
      final dislikedSet = await StorageService.getDislikedContent();
      for (final id in dislikedSet) {
        isDislikedMap[id] = true;
      }
    } catch (e) {
      debugPrint("⚠️ Error loading saved interactions: $e");
    }
  }

  void initContent({
    required String contentId,
    int initialLikes = 0,
    int initialDislikes = 0,
    bool initialIsLiked = false,
    bool initialIsDisliked = false,
  }) {
    if (contentId.isEmpty) return;
    likesCount.putIfAbsent(contentId, () => initialLikes);
    dislikesCount.putIfAbsent(contentId, () => initialDislikes);
    if (initialIsLiked) {
      isLikedMap[contentId] = true;
      StorageService.setContentLiked(contentId, true);
    } else {
      isLikedMap.putIfAbsent(contentId, () => false);
    }
    if (initialIsDisliked) {
      isDislikedMap[contentId] = true;
      StorageService.setContentDisliked(contentId, true);
    } else {
      isDislikedMap.putIfAbsent(contentId, () => false);
    }
  }

  int getLikes(String contentId, [int fallback = 0]) =>
      likesCount[contentId] ?? fallback;

  int getDislikes(String contentId, [int fallback = 0]) =>
      dislikesCount[contentId] ?? fallback;

  bool isLiked(String contentId) => isLikedMap[contentId] ?? false;

  bool isDisliked(String contentId) => isDislikedMap[contentId] ?? false;

  bool isLikeLoading(String contentId) => isLikeLoadingMap[contentId] ?? false;

  bool isDislikeLoading(String contentId) =>
      isDislikeLoadingMap[contentId] ?? false;

  bool isLoading(String contentId) =>
      isLikeLoading(contentId) || isDislikeLoading(contentId);

  Future<LikeDislikeResponse?> toggleLike(
    String contentId, {
    bool showToast = false,
  }) async {
    if (contentId.isEmpty) return null;
    if (isLikeLoading(contentId)) return null;

    final wasLiked = isLiked(contentId);
    final wasDisliked = isDisliked(contentId);
    final prevLikes = getLikes(contentId);
    final prevDislikes = getDislikes(contentId);

    // Optimistic UI update & immediate persistence
    if (wasLiked) {
      isLikedMap[contentId] = false;
      likesCount[contentId] = (prevLikes - 1).clamp(0, 9999999);
      StorageService.setContentLiked(contentId, false);
    } else {
      isLikedMap[contentId] = true;
      likesCount[contentId] = prevLikes + 1;
      StorageService.setContentLiked(contentId, true);
      if (wasDisliked) {
        isDislikedMap[contentId] = false;
        dislikesCount[contentId] = (prevDislikes - 1).clamp(0, 9999999);
        StorageService.setContentDisliked(contentId, false);
      }
    }

    isLikeLoadingMap[contentId] = true;
    loadingMap[contentId] = true;

    try {
      final response = await _datasource.toggleLike(contentId);
      if (response != null && response.success) {
        likesCount[contentId] = response.totalLikes;
        dislikesCount[contentId] = response.totalDislikes;

        bool? serverIsLiked = response.isLiked;
        if (serverIsLiked == null) {
          final msg = response.message.toLowerCase();
          if (msg.contains("added") ||
              msg.contains("liked") ||
              (msg.contains("like") &&
                  !msg.contains("removed") &&
                  !msg.contains("unliked") &&
                  !msg.contains("dislike"))) {
            serverIsLiked = true;
          } else if (msg.contains("removed") || msg.contains("unliked")) {
            serverIsLiked = false;
          }
        }

        if (serverIsLiked != null) {
          isLikedMap[contentId] = serverIsLiked;
          StorageService.setContentLiked(contentId, serverIsLiked);
          if (serverIsLiked) {
            isDislikedMap[contentId] = false;
            StorageService.setContentDisliked(contentId, false);
          }
        }

        if (showToast && response.message.isNotEmpty) {
          Get.snackbar(
            'Like',
            response.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.black87,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        // Rollback on non-success
        isLikedMap[contentId] = wasLiked;
        isDislikedMap[contentId] = wasDisliked;
        likesCount[contentId] = prevLikes;
        dislikesCount[contentId] = prevDislikes;
        StorageService.setContentLiked(contentId, wasLiked);
        StorageService.setContentDisliked(contentId, wasDisliked);
      }
      return response;
    } catch (e) {
      debugPrint("InteractionController.toggleLike Error: $e");
      // Rollback on error
      isLikedMap[contentId] = wasLiked;
      isDislikedMap[contentId] = wasDisliked;
      likesCount[contentId] = prevLikes;
      dislikesCount[contentId] = prevDislikes;
      StorageService.setContentLiked(contentId, wasLiked);
      StorageService.setContentDisliked(contentId, wasDisliked);

      Get.snackbar(
        'Error',
        'Could not update like. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
      );
      return null;
    } finally {
      isLikeLoadingMap[contentId] = false;
      loadingMap[contentId] = isDislikeLoading(contentId);
    }
  }

  Future<LikeDislikeResponse?> toggleDislike(
    String contentId, {
    bool showToast = false,
  }) async {
    if (contentId.isEmpty) return null;
    if (isDislikeLoading(contentId)) return null;

    final wasLiked = isLiked(contentId);
    final wasDisliked = isDisliked(contentId);
    final prevLikes = getLikes(contentId);
    final prevDislikes = getDislikes(contentId);

    // Optimistic UI update & immediate persistence
    if (wasDisliked) {
      isDislikedMap[contentId] = false;
      dislikesCount[contentId] = (prevDislikes - 1).clamp(0, 9999999);
      StorageService.setContentDisliked(contentId, false);
    } else {
      isDislikedMap[contentId] = true;
      dislikesCount[contentId] = prevDislikes + 1;
      StorageService.setContentDisliked(contentId, true);
      if (wasLiked) {
        isLikedMap[contentId] = false;
        likesCount[contentId] = (prevLikes - 1).clamp(0, 9999999);
        StorageService.setContentLiked(contentId, false);
      }
    }

    isDislikeLoadingMap[contentId] = true;
    loadingMap[contentId] = true;

    try {
      final response = await _datasource.toggleDislike(contentId);
      if (response != null && response.success) {
        likesCount[contentId] = response.totalLikes;
        dislikesCount[contentId] = response.totalDislikes;

        bool? serverIsDisliked = response.isDisliked;
        if (serverIsDisliked == null) {
          final msg = response.message.toLowerCase();
          if (msg.contains("added") ||
              msg.contains("disliked") ||
              (msg.contains("dislike") &&
                  !msg.contains("removed") &&
                  !msg.contains("undisliked"))) {
            serverIsDisliked = true;
          } else if (msg.contains("removed") || msg.contains("undisliked")) {
            serverIsDisliked = false;
          }
        }

        if (serverIsDisliked != null) {
          isDislikedMap[contentId] = serverIsDisliked;
          StorageService.setContentDisliked(contentId, serverIsDisliked);
          if (serverIsDisliked) {
            isLikedMap[contentId] = false;
            StorageService.setContentLiked(contentId, false);
          }
        }

        if (showToast && response.message.isNotEmpty) {
          Get.snackbar(
            'Dislike',
            response.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.black87,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        // Rollback on non-success
        isLikedMap[contentId] = wasLiked;
        isDislikedMap[contentId] = wasDisliked;
        likesCount[contentId] = prevLikes;
        dislikesCount[contentId] = prevDislikes;
        StorageService.setContentLiked(contentId, wasLiked);
        StorageService.setContentDisliked(contentId, wasDisliked);
      }
      return response;
    } catch (e) {
      debugPrint("InteractionController.toggleDislike Error: $e");
      // Rollback on error
      isLikedMap[contentId] = wasLiked;
      isDislikedMap[contentId] = wasDisliked;
      likesCount[contentId] = prevLikes;
      dislikesCount[contentId] = prevDislikes;
      StorageService.setContentLiked(contentId, wasLiked);
      StorageService.setContentDisliked(contentId, wasDisliked);

      Get.snackbar(
        'Error',
        'Could not update dislike. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
      );
      return null;
    } finally {
      isDislikeLoadingMap[contentId] = false;
      loadingMap[contentId] = isLikeLoading(contentId);
    }
  }
}
