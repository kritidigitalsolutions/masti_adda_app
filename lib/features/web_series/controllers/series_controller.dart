import 'package:get/get.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/features/home/controllers/home_controller.dart';
import 'package:masti_adda_app/features/web_series/datasource/series_datasource.dart';
import 'package:masti_adda_app/features/web_series/model/SeriesModel.dart';
import 'package:masti_adda_app/shared/models/like_dislike_response.dart';

class SeriesController extends GetxController {
  // ── State ─────────────────────────────────────────────────────────────────
  final allSeriesStatus = Status.init.obs;
  final Rx<SeriesResponse?> allSeries = Rx(null);
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  int currentPage = 1;
  static const int pageSize = 12;

  final seriesDetailStatus = Status.init.obs;
  final Rx<Series?> seriesDetail = Rx(null);
  final RxBool isInteracting = false.obs;

  // ── Search & Filter State ──────────────────────────────────────────────────
  final searchStatus = Status.init.obs;
  final RxList<Series> searchedSeries = <Series>[].obs;
  final RxString currentSearchQuery = ''.obs;
  final RxInt selectedCategoryIndex = 0.obs;
  final RxBool isSearchOpen = false.obs;

  List<String> get categories {
    final list = <String>['All'];
    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      for (final cat in homeController.categories) {
        if (!list.contains(cat.name)) list.add(cat.name);
      }
    }
    final all = allSeries.value?.series ?? [];
    for (final s in all.where((s) => s.isVisible)) {
      for (final g in s.genre) {
        final str = g.trim();
        if (str.isNotEmpty && !list.contains(str)) {
          list.add(str);
        }
      }
    }
    return list;
  }

  final _api = SeriesDatasource();

  void selectCategory(int index) {
    selectedCategoryIndex.value = index;
  }

  void selectCategoryByName(String name, {String? slug}) {
    if (name.isEmpty && (slug == null || slug.isEmpty)) return;
    final cats = categories;
    String clean(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final targetName = clean(name);
    final targetSlug = slug != null ? clean(slug) : '';

    final index = cats.indexWhere((c) {
      final cLower = c.toLowerCase();
      final cClean = clean(c);
      return (name.isNotEmpty &&
              (cLower == name.toLowerCase() ||
                  (targetName.isNotEmpty && cClean == targetName))) ||
          (slug != null &&
              slug.isNotEmpty &&
              (cLower == slug.toLowerCase() ||
                  (targetSlug.isNotEmpty && cClean == targetSlug)));
    });
    if (index != -1) {
      selectedCategoryIndex.value = index;
    }
  }

  String get currentCategoryName {
    final cats = categories;
    if (selectedCategoryIndex.value >= 0 &&
        selectedCategoryIndex.value < cats.length) {
      return cats[selectedCategoryIndex.value];
    }
    return 'All';
  }

  void openSearch() {
    isSearchOpen.value = true;
  }

  void closeSearch() {
    isSearchOpen.value = false;
    currentSearchQuery.value = '';
    searchedSeries.clear();
    searchStatus.value = Status.init;
  }

  void clearSearch() {
    currentSearchQuery.value = '';
    searchedSeries.clear();
    searchStatus.value = Status.init;
  }

  Future<void> searchSeries(String query) async {
    final q = query.trim();
    currentSearchQuery.value = q;

    if (q.isEmpty) {
      searchStatus.value = Status.init;
      searchedSeries.clear();
      return;
    }

    searchStatus.value = Status.loading;
    try {
      final apiResults = await _api.searchSeries(q);
      if (apiResults.isNotEmpty) {
        searchedSeries.assignAll(apiResults.where((s) => s.isVisible));
        searchStatus.value = Status.success;
        return;
      }
    } catch (_) {}

    // Fallback to local match in loaded series
    final qLower = q.toLowerCase();
    final localList = allSeries.value?.series ?? [];
    final localMatches = localList.where((s) {
      if (!s.isVisible) return false;
      final titleMatch = s.title.toLowerCase().contains(qLower);
      final genreMatch = s.genre.any((g) => g.toLowerCase().contains(qLower));
      final descMatch = s.description.toLowerCase().contains(qLower);
      final langMatch = s.language.toLowerCase().contains(qLower);
      final castMatch =
          s.cast.any((c) => c.toString().toLowerCase().contains(qLower));
      final yearMatch = s.releaseYear.toString().contains(qLower);
      return titleMatch ||
          genreMatch ||
          descMatch ||
          langMatch ||
          castMatch ||
          yearMatch;
    }).toList();

    searchedSeries.assignAll(localMatches);
    searchStatus.value = Status.success;
  }

  List<Series> get filteredSeries {
    final query = currentSearchQuery.value.trim().toLowerCase();
    final selectedCategory = currentCategoryName;

    // Combine server search results with local series (deduplicated)
    final Set<String> seenIds = {};
    final List<Series> combinedList = [];

    if (query.isNotEmpty) {
      for (final s in searchedSeries) {
        if (s.isVisible && seenIds.add(s.id)) combinedList.add(s);
      }
      final local = allSeries.value?.series ?? [];
      for (final s in local) {
        if (s.isVisible && seenIds.add(s.id)) combinedList.add(s);
      }
    } else {
      combinedList.addAll((allSeries.value?.series ?? []).where((s) => s.isVisible));
    }

    final matched = combinedList.where((item) {
      if (!item.isVisible) return false;
      final matchesCategory = selectedCategory == 'All' ||
          _matchesSeriesCategoryName(item, selectedCategory);

      if (!matchesCategory) return false;

      if (query.isEmpty) return true;

      final titleMatch = item.title.toLowerCase().contains(query);
      final genreMatch =
          item.genre.any((g) => g.toLowerCase().contains(query));
      final descMatch = item.description.toLowerCase().contains(query);
      final langMatch = item.language.toLowerCase().contains(query);
      final castMatch =
          item.cast.any((c) => c.toString().toLowerCase().contains(query));
      final yearMatch = item.releaseYear.toString().contains(query);

      return titleMatch ||
          genreMatch ||
          descMatch ||
          langMatch ||
          castMatch ||
          yearMatch;
    }).toList();

    matched.sort((a, b) {
      if (a.priority != b.priority) return a.priority.compareTo(b.priority);
      return b.rating.compareTo(a.rating);
    });

    return matched;
  }

  bool _matchesSeriesCategoryName(Series series, String catName) {
    String clean(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final target = clean(catName);

    for (final c in series.category) {
      if (c == null) continue;
      if (c is String) {
        if (c.toLowerCase() == catName.toLowerCase() ||
            (target.isNotEmpty && clean(c) == target)) {
          return true;
        }
      } else if (c is Map) {
        final name = (c['name'] ?? '').toString();
        final slug = (c['slug'] ?? '').toString();
        if (name.toLowerCase() == catName.toLowerCase() ||
            slug.toLowerCase() == catName.toLowerCase() ||
            (target.isNotEmpty && clean(name) == target) ||
            (target.isNotEmpty && clean(slug) == target)) {
          return true;
        }
      }
    }
    for (final g in series.genre) {
      if (g.toLowerCase() == catName.toLowerCase() ||
          (target.isNotEmpty && clean(g) == target)) {
        return true;
      }
    }
    if (series.slug.isNotEmpty &&
        (series.slug.toLowerCase() == catName.toLowerCase() ||
            (target.isNotEmpty && clean(series.slug) == target))) {
      return true;
    }
    return false;
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> fetchAllSeries() async {
    currentPage = 1;
    hasMore.value = true;
    allSeriesStatus.value = Status.loading;
    final result = await _api.allSeries(page: 1, limit: pageSize);
    if (result != null) {
      allSeries.value = result;
      if (result.series.length < pageSize) {
        hasMore.value = false;
      }
      allSeriesStatus.value = Status.success;
    } else {
      allSeriesStatus.value = Status.error;
    }
  }

  Future<void> fetchMoreSeries() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final nextPage = currentPage + 1;
      final result = await _api.allSeries(page: nextPage, limit: pageSize);
      if (result != null && result.series.isNotEmpty) {
        final existingList = allSeries.value?.series ?? [];
        final existingIds = existingList.map((s) => s.id).toSet();
        final newItems =
            result.series.where((s) => !existingIds.contains(s.id) && s.isVisible).toList();

        if (newItems.isNotEmpty) {
          final updatedList = List<Series>.from(existingList)..addAll(newItems);
          allSeries.value = allSeries.value?.copyWith(series: updatedList);
          currentPage = nextPage;
        } else {
          hasMore.value = false;
        }
        if (result.series.length < pageSize) {
          hasMore.value = false;
        }
      } else {
        hasMore.value = false;
      }
    } catch (_) {
      // Don't mark fatal error on paginate, just stop
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> fetchSeriesDetail(String id) async {
    seriesDetailStatus.value = Status.loading;
    final result = await _api.seriesDetail(id: id);
    if (result != null) {
      seriesDetail.value = result;
      seriesDetailStatus.value = Status.success;
    } else {
      seriesDetailStatus.value = Status.error;
    }
  }

  Future<LikeDislikeResponse?> toggleLike(String id) async {
    isInteracting.value = true;
    try {
      final res = await _api.toggleLike(id);
      if (res != null && res.success) {
        if (seriesDetail.value != null && seriesDetail.value!.id == id) {
          seriesDetail.value = seriesDetail.value!.copyWith(
            likes: res.totalLikes,
            dislikes: res.totalDislikes,
          );
        }
        final currentSeries = allSeries.value?.series;
        if (currentSeries != null) {
          final index = currentSeries.indexWhere((s) => s.id == id);
          if (index != -1) {
            final updatedList = List<Series>.from(currentSeries);
            updatedList[index] = updatedList[index].copyWith(
              likes: res.totalLikes,
              dislikes: res.totalDislikes,
            );
            allSeries.value = allSeries.value?.copyWith(series: updatedList);
          }
        }
      }
      return res;
    } catch (_) {
      return null;
    } finally {
      isInteracting.value = false;
    }
  }

  Future<LikeDislikeResponse?> toggleDislike(String id) async {
    isInteracting.value = true;
    try {
      final res = await _api.toggleDislike(id);
      if (res != null && res.success) {
        if (seriesDetail.value != null && seriesDetail.value!.id == id) {
          seriesDetail.value = seriesDetail.value!.copyWith(
            likes: res.totalLikes,
            dislikes: res.totalDislikes,
          );
        }
        final currentSeries = allSeries.value?.series;
        if (currentSeries != null) {
          final index = currentSeries.indexWhere((s) => s.id == id);
          if (index != -1) {
            final updatedList = List<Series>.from(currentSeries);
            updatedList[index] = updatedList[index].copyWith(
              likes: res.totalLikes,
              dislikes: res.totalDislikes,
            );
            allSeries.value = allSeries.value?.copyWith(series: updatedList);
          }
        }
      }
      return res;
    } catch (_) {
      return null;
    } finally {
      isInteracting.value = false;
    }
  }
}
