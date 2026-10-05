import 'package:get/get.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/features/micro_drama/datasource/continue_watching_datasource.dart';
import 'package:masti_adda_app/features/micro_drama/models/continue_watching_model.dart';

class ContinueWatchingController extends GetxController {
  // ── State ─────────────────────────────────────────────────────────────────

  /// Used in Micro Drama screen — only microdrama items
  final fetchStatus = Status.init.obs;
  final RxList<ContinueWatchingItem> continueWatchingList =
      <ContinueWatchingItem>[].obs;

  /// Used in Home tab & View All screen — all content types (movie + series + microdrama)
  final homeFetchStatus = Status.init.obs;
  final RxList<ContinueWatchingItem> homeList = <ContinueWatchingItem>[].obs;

  final _datasource = ContinueWatchingDatasource();

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Fetches & filters microdrama-only items (for the Micro Drama screen).
  Future<void> fetchContinueWatching() async {
    fetchStatus.value = Status.loading;
    final result = await _datasource.getContinueWatchingList(limit: 50);
    if (result != null) {
      continueWatchingList.value = result.items
          .where((item) => item.isMicroDrama && !item.completed)
          .toList();
      fetchStatus.value = Status.success;
    } else {
      fetchStatus.value = Status.error;
    }
  }

  /// Fetches Movie + Web Series items (for the Home tab & Continue Watching screen).
  Future<void> fetchForHome() async {
    homeFetchStatus.value = Status.loading;
    final result = await _datasource.getContinueWatchingList(limit: 50);
    if (result != null) {
      homeList.value = result.items
          .where((item) => (item.isMovie || item.isSeries) && !item.completed)
          .toList();
      homeFetchStatus.value = Status.success;
    } else {
      homeFetchStatus.value = Status.error;
    }
  }

  /// Saves progress for any content type (movie / series / microdrama).
  /// Fire-and-forget — caller does not need to await.
  Future<void> saveProgress({
    required String contentId,
    required String contentType, // "movie" | "series" | "microdrama"
    required int progressSeconds,
    required int durationSeconds,
    String? episodeId,
  }) async {
    await _datasource.saveProgress(
      SaveProgressRequest(
        contentId: contentId,
        episodeId: episodeId,
        contentType: contentType,
        progressSeconds: progressSeconds,
        durationSeconds: durationSeconds,
      ),
    );

    final isCompleted = durationSeconds > 0 &&
        progressSeconds / durationSeconds >= 0.95;

    final isNewForMicroDrama = contentType == 'microdrama' &&
        !continueWatchingList.any((item) =>
            item.contentId == contentId &&
            (episodeId == null || item.episodeId == episodeId));

    final isNewForHome = (contentType == 'movie' || contentType == 'series') &&
        !homeList.any((item) =>
            item.contentId == contentId &&
            (episodeId == null || item.episodeId == episodeId));

    _updateLocalList(
      continueWatchingList,
      contentId: contentId,
      episodeId: episodeId,
      progressSeconds: progressSeconds,
      durationSeconds: durationSeconds,
      isCompleted: isCompleted,
    );
    _updateLocalList(
      homeList,
      contentId: contentId,
      episodeId: episodeId,
      progressSeconds: progressSeconds,
      durationSeconds: durationSeconds,
      isCompleted: isCompleted,
    );

    // If item was newly added, refresh from backend to get populated titles/thumbnails
    if (!isCompleted) {
      if (isNewForMicroDrama) {
        fetchContinueWatching();
      }
      if (isNewForHome) {
        fetchForHome();
      }
    }
  }

  void _updateLocalList(
    RxList<ContinueWatchingItem> list, {
    required String contentId,
    required String? episodeId,
    required int progressSeconds,
    required int durationSeconds,
    required bool isCompleted,
  }) {
    if (isCompleted) {
      list.removeWhere(
        (item) =>
            item.contentId == contentId &&
            (episodeId == null || item.episodeId == episodeId),
      );
    } else {
      final idx = list.indexWhere(
        (item) =>
            item.contentId == contentId &&
            (episodeId == null || item.episodeId == episodeId),
      );
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          progressSeconds: progressSeconds,
          durationSeconds: durationSeconds,
        );
      }
    }
  }

  /// Removes an item from both lists locally + backend.
  Future<void> deleteItem(ContinueWatchingItem item) async {
    continueWatchingList.removeWhere((i) => i.id == item.id);
    homeList.removeWhere((i) => i.id == item.id);
    await _datasource.deleteItem(item.id);
  }

  /// Clears all continue watching items locally & on backend.
  Future<void> clearAll({String? contentType}) async {
    if (contentType != null && contentType.isNotEmpty) {
      final toDelete = homeList.where((i) => i.contentType == contentType).toList();
      homeList.removeWhere((i) => i.contentType == contentType);
      continueWatchingList.removeWhere((i) => i.contentType == contentType);
      for (final item in toDelete) {
        _datasource.deleteItem(item.id);
      }
    } else {
      final toDelete = List<ContinueWatchingItem>.from(homeList);
      homeList.clear();
      continueWatchingList.clear();
      for (final item in toDelete) {
        _datasource.deleteItem(item.id);
      }
    }
  }

  /// Marks an item as manually completed.
  Future<void> markCompleted(ContinueWatchingItem item) async {
    continueWatchingList.removeWhere((i) => i.id == item.id);
    homeList.removeWhere((i) => i.id == item.id);
    await _datasource.markCompleted(item.id);
  }
}
