import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/features/profile/models/response/watchlist_model.dart';
import 'package:masti_adda_app/features/profile/repositories/watchlist_repository.dart';

class WatchlistController extends GetxController {
  final WatchlistRepository _repository = WatchlistRepository();

  final RxInt selectedTabIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxList<WatchlistItem> allItems = <WatchlistItem>[].obs;
  final RxSet<String> loadingItemIds = <String>{}.obs;

  final List<String> tabs = ['Movies', 'Series', 'Micro Dramas'];

  @override
  void onInit() {
    super.onInit();
    fetchWatchlist();
  }

  void selectTab(int index) {
    selectedTabIndex.value = index;
  }

  List<WatchlistItem> get currentList {
    switch (selectedTabIndex.value) {
      case 0:
        return allItems
            .where(
              (item) =>
                  item.itemModel?.toLowerCase() == 'movie' ||
                  item.itemModel?.toLowerCase() == 'movies',
            )
            .toList();
      case 1:
        return allItems
            .where(
              (item) =>
                  item.itemModel?.toLowerCase() == 'series' ||
                  item.itemModel?.toLowerCase() == 'web_series' ||
                  item.itemModel?.toLowerCase() == 'webseries',
            )
            .toList();
      case 2:
        return allItems
            .where(
              (item) =>
                  item.itemModel?.toLowerCase() == 'microdrama' ||
                  item.itemModel?.toLowerCase() == 'micro_drama' ||
                  item.itemModel?.toLowerCase() == 'micro-drama' ||
                  item.itemModel?.toLowerCase() == 'tvshow',
            )
            .toList();
      default:
        return allItems;
    }
  }

  Future<void> fetchWatchlist() async {
    try {
      isLoading.value = true;
      final response = await _repository.fetchWatchlist();
      if (response != null && response.data != null) {
        allItems.assignAll(response.data!);
      }
    } catch (e) {
      debugPrint("Error fetching watchlist in controller: $e");
    } finally {
      isLoading.value = false;
    }
  }

  bool isItemInWatchlist(String itemId) {
    if (itemId.isEmpty) return false;
    return allItems.any(
      (entry) => entry.item?.id == itemId || entry.id == itemId,
    );
  }

  bool isItemLoading(String itemId) {
    return loadingItemIds.contains(itemId);
  }

  WatchlistItem? getWatchlistItemByContentId(String itemId) {
    if (itemId.isEmpty) return null;
    try {
      return allItems.firstWhere(
        (entry) => entry.item?.id == itemId || entry.id == itemId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> toggleWatchlist(String itemId) async {
    if (itemId.isEmpty || loadingItemIds.contains(itemId)) return false;
    loadingItemIds.add(itemId);

    try {
      final existing = getWatchlistItemByContentId(itemId);
      if (existing != null && existing.id != null) {
        return await removeFromWatchlist(existing.id!, showFeedback: true);
      } else {
        return await addToWatchlist(itemId, showFeedback: true);
      }
    } finally {
      loadingItemIds.remove(itemId);
    }
  }

  Future<bool> addToWatchlist(String itemId, {bool showFeedback = true}) async {
    try {
      final response = await _repository.addToWatchlist(itemId);
      if (response != null &&
          (response['message'] != null ||
              response['data'] != null ||
              response['success'] == true)) {
        await fetchWatchlist();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error in addToWatchlist: $e");
      return false;
    }
  }

  Future<bool> removeFromWatchlist(
    String watchlistId, {
    bool showFeedback = true,
  }) async {
    try {
      final response = await _repository.removeFromWatchlist(watchlistId);
      if (response != null &&
          (response['message'] != null || response['success'] == true)) {
        allItems.removeWhere((element) => element.id == watchlistId);
        // if (showFeedback) {
        //   Get.snackbar(
        //     'Watchlist',
        //     response['message'] ?? 'Removed from watchlist ❌',
        //     snackPosition: SnackPosition.BOTTOM,
        //     backgroundColor: Colors.grey[800]!.withValues(alpha: 0.9),
        //     colorText: Colors.white,
        //     duration: const Duration(seconds: 2),
        //   );
        // }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error in removeFromWatchlist: $e");
      return false;
    }
  }
}
