import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/core/services/storage_service.dart';
import 'package:masti_adda_app/features/home/controllers/home_controller.dart';
import 'package:masti_adda_app/features/home/models/ai_reel_model.dart';
import 'package:masti_adda_app/features/home/repositories/ai_reels_datasource.dart';

class AiReelsController extends GetxController {
  static AiReelsController get to => Get.isRegistered<AiReelsController>()
      ? Get.find<AiReelsController>()
      : Get.put(AiReelsController());

  final AiReelsDatasource _datasource = AiReelsDatasource();

  // State
  final RxList<AiReelModel> reels = <AiReelModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isFetchingNextBatch = false.obs;
  final RxString sessionId = ''.obs;
  final RxBool hasMore = true.obs;
  final RxBool allWatched = false.obs;
  final RxBool hasUnwatched = true.obs;
  final RxInt currentIndex = 0.obs;
  final RxInt selectedFeedTab = 1.obs; // 0 = For You, 1 = Trending
  final RxBool isReplayMode = false.obs;
  final RxBool isMuted = false.obs;

  // Track interactions locally per session to avoid duplicate API calls
  final Set<String> _viewedReelIds = <String>{};
  final Set<String> _completedReelIds = <String>{};

  // Local likes, shares & comments tracking
  final RxMap<String, int> likesCountMap = <String, int>{}.obs;
  final RxMap<String, bool> isLikedMap = <String, bool>{}.obs;
  final RxMap<String, bool> isLikeLoadingMap = <String, bool>{}.obs;
  final RxMap<String, int> sharesCountMap = <String, int>{}.obs;
  final RxMap<String, int> commentsCountMap = <String, int>{}.obs;

  void toggleMute() {
    isMuted.value = !isMuted.value;
  }

  @override
  void onInit() {
    super.onInit();
    _loadSavedLikes();
    fetchInitialFeed();
  }

  /// Load persisted liked reel IDs from local storage
  Future<void> _loadSavedLikes() async {
    try {
      final savedLikes = await StorageService.getLikedAiReels();
      for (final reelId in savedLikes) {
        isLikedMap[reelId] = true;
      }
    } catch (e) {
      debugPrint("⚠️ Error loading saved liked AI reels: $e");
    }
  }

  /// Reset all state when switching accounts / logging out
  void resetState() {
    reels.clear();
    _viewedReelIds.clear();
    _completedReelIds.clear();
    sessionId.value = '';
    currentIndex.value = 0;
    hasMore.value = true;
    allWatched.value = false;
    hasUnwatched.value = true;
    isReplayMode.value = false;
    likesCountMap.clear();
    isLikedMap.clear();
    isLikeLoadingMap.clear();
    sharesCountMap.clear();
    commentsCountMap.clear();
  }

  /// Initial load when user opens AI Reels
  Future<void> fetchInitialFeed({bool isReplay = false}) async {
    try {
      isLoading.value = true;
      if (!isReplay) {
        sessionId.value = '';
      }
      _viewedReelIds.clear();
      _completedReelIds.clear();
      currentIndex.value = 0;
      isReplayMode.value = isReplay;

      // Ensure saved likes are loaded
      final savedLikes = await StorageService.getLikedAiReels();
      for (final id in savedLikes) {
        isLikedMap[id] = true;
      }

      final response = await _datasource.fetchAiReels(
        limit: 10,
        sessionId: isReplay ? sessionId.value : null,
        replay: isReplay,
      );

      sessionId.value = response.pagination.sessionId;
      hasMore.value = response.pagination.hasMore;
      allWatched.value = response.meta.allWatched;
      hasUnwatched.value = response.meta.hasUnwatched;

      // If fresh feed is empty or all reels are watched, seamlessly load replay feed so user gets full reels list
      if (!isReplay &&
          response.data.isEmpty &&
          (response.meta.allWatched ||
              !response.meta.hasUnwatched ||
              response.meta.replayAvailable ||
              response.meta.watchedPublished > 0)) {
        debugPrint(
          "🎬 All fresh reels watched or empty, automatically loading replay feed...",
        );
        await fetchInitialFeed(isReplay: true);
        return;
      }

      reels.assignAll(response.data);

      // Initialize like, share & comment maps without losing user state
      for (final r in response.data) {
        likesCountMap[r.id] = r.likes;
        if (savedLikes.contains(r.id)) {
          isLikedMap[r.id] = true;
        } else if (r.isLiked) {
          isLikedMap[r.id] = true;
          StorageService.setAiReelLiked(r.id, true);
        } else if (!isLikedMap.containsKey(r.id)) {
          isLikedMap[r.id] = false;
        }
        sharesCountMap[r.id] = r.shares;
        if (!commentsCountMap.containsKey(r.id)) {
          commentsCountMap[r.id] =
              r.totalComments > 0 ? r.totalComments : r.commentsCount;
        }
      }

      // Automatically record view for the first reel if available
      if (reels.isNotEmpty) {
        recordView(reels.first.id);
      }

      // If initial response has few items (< 4) and more fresh items exist, prefetch immediately
      if (reels.length < 4 && hasMore.value) {
        fetchNextBatch();
      } else if (!isReplay &&
          reels.length < 4 &&
          (response.meta.replayAvailable ||
              response.meta.allWatched ||
              response.meta.watchedPublished > 0)) {
        // Fresh list is short because user already watched other reels — seamlessly load replay reels so list is full
        _seamlesslyLoadReplayReels();
      }

      if (response.data.isEmpty && allWatched.value) {
        if (isReelsTabActive) {
          showAllWatchedPrompt();
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching initial AI Reels: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Seamlessly fetch replay reels and append unique items to current feed
  Future<void> _seamlesslyLoadReplayReels() async {
    if (isFetchingNextBatch.value) return;
    try {
      isFetchingNextBatch.value = true;
      debugPrint("🔄 Seamlessly prefetching replay reels to populate feed...");
      final savedLikes = await StorageService.getLikedAiReels();
      final replayResponse = await _datasource.fetchAiReels(
        limit: 10,
        replay: true,
      );

      if (replayResponse.data.isNotEmpty) {
        final existingIds = reels.map((r) => r.id).toSet();
        final replayNew = replayResponse.data
            .where((r) => !existingIds.contains(r.id))
            .toList();

        if (replayNew.isNotEmpty) {
          for (final r in replayNew) {
            likesCountMap[r.id] = r.likes;
            if (savedLikes.contains(r.id)) {
              isLikedMap[r.id] = true;
            } else if (r.isLiked) {
              isLikedMap[r.id] = true;
              StorageService.setAiReelLiked(r.id, true);
            } else if (!isLikedMap.containsKey(r.id)) {
              isLikedMap[r.id] = false;
            }
            sharesCountMap[r.id] = r.shares;
            if (!commentsCountMap.containsKey(r.id)) {
              commentsCountMap[r.id] =
                  r.totalComments > 0 ? r.totalComments : r.commentsCount;
            }
          }
          reels.addAll(replayNew);
          hasMore.value = replayResponse.pagination.hasMore;
          debugPrint("✅ Appended ${replayNew.length} replay reels (total: ${reels.length})");
        }
      }
    } catch (e) {
      debugPrint("⚠️ Failed to seamlessly load replay reels: $e");
    } finally {
      isFetchingNextBatch.value = false;
    }
  }

  /// Background prefetch for next batch with the SAME sessionId
  Future<void> fetchNextBatch() async {
    if (isFetchingNextBatch.value) {
      return;
    }

    if (!hasMore.value || allWatched.value) {
      // If fresh is finished, check if we should seamlessly load replay reels
      if (!isReplayMode.value && reels.length < 5) {
        await _seamlesslyLoadReplayReels();
      }
      return;
    }

    try {
      isFetchingNextBatch.value = true;
      debugPrint(
        "🔄 Background prefetching next AI Reels batch with sessionId: ${sessionId.value}",
      );

      final savedLikes = await StorageService.getLikedAiReels();

      final response = await _datasource.fetchAiReels(
        limit: 10,
        sessionId: sessionId.value,
        replay: isReplayMode.value,
      );

      // Keep the same session ID
      if (response.pagination.sessionId.isNotEmpty) {
        sessionId.value = response.pagination.sessionId;
      }
      hasMore.value = response.pagination.hasMore;
      allWatched.value = response.meta.allWatched;
      hasUnwatched.value = response.meta.hasUnwatched;

      if (response.data.isNotEmpty) {
        // Append unique items only
        final existingIds = reels.map((r) => r.id).toSet();
        final newItems = response.data
            .where((r) => !existingIds.contains(r.id))
            .toList();

        for (final r in newItems) {
          likesCountMap[r.id] = r.likes;
          if (savedLikes.contains(r.id)) {
            isLikedMap[r.id] = true;
          } else if (r.isLiked) {
            isLikedMap[r.id] = true;
            StorageService.setAiReelLiked(r.id, true);
          } else if (!isLikedMap.containsKey(r.id)) {
            isLikedMap[r.id] = false;
          }
          sharesCountMap[r.id] = r.shares;
          if (!commentsCountMap.containsKey(r.id)) {
            commentsCountMap[r.id] =
                r.totalComments > 0 ? r.totalComments : r.commentsCount;
          }
        }

        reels.addAll(newItems);
      } else {
        hasMore.value = false;
        if (response.meta.allWatched) {
          allWatched.value = true;
        }

        // If fresh list reached end and user only has a few reels, seamlessly fetch replay reels
        if (!isReplayMode.value &&
            (response.meta.replayAvailable ||
                response.meta.allWatched ||
                response.meta.watchedPublished > 0)) {
          isFetchingNextBatch.value = false;
          await _seamlesslyLoadReplayReels();
          return;
        }
      }
    } catch (e) {
      debugPrint("❌ Error prefetching next batch: $e");
    } finally {
      isFetchingNextBatch.value = false;
    }
  }

  /// Called when user swipes to a page
  void onPageChanged(int index) {
    currentIndex.value = index;

    if (index >= 0 && index < reels.length) {
      final currentReel = reels[index];
      recordView(currentReel.id);
    }

    // Prefetch next batch 2-3 reels before the end
    if (index >= reels.length - 3) {
      if (hasMore.value && !isFetchingNextBatch.value) {
        fetchNextBatch();
      } else if (!hasMore.value &&
          !isReplayMode.value &&
          !isFetchingNextBatch.value) {
        _seamlesslyLoadReplayReels();
      }
    }
  }

  /// Record view in the background without blocking UI
  void recordView(String reelId) {
    if (reelId.isEmpty || _viewedReelIds.contains(reelId)) return;
    _viewedReelIds.add(reelId);
    _datasource.recordView(reelId);
  }

  /// Record reel complete in the background when finished
  void recordComplete(String reelId) {
    if (reelId.isEmpty || _completedReelIds.contains(reelId)) return;
    _completedReelIds.add(reelId);
    _datasource.recordComplete(reelId);

    // If on the last reel and no more items / allWatched is true, show prompt
    if (currentIndex.value >= reels.length - 1 &&
        (allWatched.value || !hasMore.value)) {
      showAllWatchedPrompt();
    }
  }

  /// Toggle like for reel via API: POST /api/interaction/toggle/like/aiReel/:id
  Future<void> toggleReelLike(String reelId) async {
    if (reelId.isEmpty) return;
    if (isLikeLoadingMap[reelId] == true) return;

    isLikeLoadingMap[reelId] = true;

    final wasLiked = isLikedMap[reelId] ?? false;
    final prevCount = likesCountMap[reelId] ?? 0;

    // Optimistic UI update & immediate local persistence
    if (wasLiked) {
      isLikedMap[reelId] = false;
      likesCountMap[reelId] = (prevCount - 1).clamp(0, 99999999);
      StorageService.setAiReelLiked(reelId, false);
    } else {
      isLikedMap[reelId] = true;
      likesCountMap[reelId] = prevCount + 1;
      StorageService.setAiReelLiked(reelId, true);
    }

    try {
      final response = await _datasource.toggleLike(reelId);
      if (response != null && response.success) {
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
          isLikedMap[reelId] = serverIsLiked;
          StorageService.setAiReelLiked(reelId, serverIsLiked);
        }
        if (response.totalLikes >= 0) {
          likesCountMap[reelId] = response.totalLikes;
        }
      } else {
        // Rollback on non-success
        isLikedMap[reelId] = wasLiked;
        likesCountMap[reelId] = prevCount;
        StorageService.setAiReelLiked(reelId, wasLiked);
      }
    } catch (e) {
      debugPrint("⚠️ toggleReelLike error: $e");
      // Rollback on error
      isLikedMap[reelId] = wasLiked;
      likesCountMap[reelId] = prevCount;
      StorageService.setAiReelLiked(reelId, wasLiked);
    } finally {
      isLikeLoadingMap[reelId] = false;
    }
  }

  /// Helper for double-tap on screen (only likes if not already liked)
  Future<void> likeReelIfNotLiked(String reelId) async {
    if (reelId.isEmpty) return;
    final isAlreadyLiked = isLikedMap[reelId] ?? false;
    if (!isAlreadyLiked) {
      await toggleReelLike(reelId);
    }
  }

  /// Record and increment share count via API: POST /api/ai-reels/:id/share
  Future<void> recordShare(String reelId) async {
    if (reelId.isEmpty) return;

    // Optimistic increment
    final currentShares = sharesCountMap[reelId] ?? 0;
    sharesCountMap[reelId] = currentShares + 1;

    // Call API in background
    try {
      final response = await _datasource.recordShare(reelId);
      if (response != null && response.success) {
        sharesCountMap[reelId] = response.shares;
      }
    } catch (e) {
      debugPrint("⚠️ recordShare error: $e");
    }
  }

  int getLikes(String reelId, int fallback) {
    return likesCountMap[reelId] ?? fallback;
  }

  bool isLiked(String reelId) {
    return isLikedMap[reelId] ?? false;
  }

  int getShares(String reelId, int fallback) {
    return sharesCountMap[reelId] ?? fallback;
  }

  int getComments(String reelId, int fallback) {
    return commentsCountMap[reelId] ?? fallback;
  }

  void updateCommentsCount(String reelId, int count) {
    if (reelId.isEmpty) return;
    commentsCountMap[reelId] = count.clamp(0, 99999999);
  }

  void incrementCommentsCount(String reelId) {
    if (reelId.isEmpty) return;
    final current = commentsCountMap[reelId] ?? 0;
    commentsCountMap[reelId] = current + 1;
  }

  void decrementCommentsCount(String reelId) {
    if (reelId.isEmpty) return;
    final current = commentsCountMap[reelId] ?? 0;
    commentsCountMap[reelId] = (current - 1).clamp(0, 99999999);
  }

  /// Whether the user is currently viewing the AI Reels tab (index 2)
  bool get isReelsTabActive {
    if (Get.isRegistered<HomeController>()) {
      return Get.find<HomeController>().selectedIndex.value == 2;
    }
    return true;
  }

  /// Shows the "All Watched" congratulations modal
  void showAllWatchedPrompt() {
    if (!isReelsTabActive) return;
    if (Get.isDialogOpen == true) return;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.2),
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Congratulations!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "You've watched all available Reels. Would you like to watch again?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'No, Thanks',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        restartReplay();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B70),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Watch Again',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  /// Restart in replay mode
  void restartReplay() {
    fetchInitialFeed(isReplay: true);
  }
}
