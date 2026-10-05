import 'package:get/get.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/features/home/controllers/home_controller.dart';
import 'package:masti_adda_app/features/movie/models/MovieModel.dart';
import 'package:masti_adda_app/features/movie/repositories/movie_datasource.dart';
import 'package:masti_adda_app/shared/models/like_dislike_response.dart';

class MovieController extends GetxController {
  // ── State ─────────────────────────────────────────────────────────────────
  final allMoviesStatus = Status.init.obs;
  final RxList<MovieModel> allMovies = <MovieModel>[].obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  int currentPage = 1;
  static const int pageSize = 12;

  final movieDetailStatus = Status.init.obs;
  final Rx<MovieModel?> movieDetail = Rx(null);
  final RxBool isInteracting = false.obs;

  // ── Search & Filter State ──────────────────────────────────────────────────
  final searchStatus = Status.init.obs;
  final RxList<MovieModel> searchedMovies = <MovieModel>[].obs;
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
    for (final m in allMovies.where((m) => m.isVisible)) {
      for (final g in m.genre) {
        final str = g.trim();
        if (str.isNotEmpty && !list.contains(str)) {
          list.add(str);
        }
      }
    }
    return list;
  }

  final MovieDatasource _api = MovieDatasource();

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
    searchedMovies.clear();
    searchStatus.value = Status.init;
  }

  void clearSearch() {
    currentSearchQuery.value = '';
    searchedMovies.clear();
    searchStatus.value = Status.init;
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> searchMovies(String query) async {
    final q = query.trim();
    currentSearchQuery.value = q;

    if (q.isEmpty) {
      searchStatus.value = Status.init;
      searchedMovies.clear();
      return;
    }

    searchStatus.value = Status.loading;
    try {
      final apiResults = await _api.searchMovies(q);
      if (apiResults.isNotEmpty) {
        searchedMovies.assignAll(apiResults);
        searchStatus.value = Status.success;
        return;
      }
    } catch (_) {}

    // Fallback to local match in loaded movies
    final qLower = q.toLowerCase();
    final localMatches = allMovies.where((m) {
      if (!m.isVisible) return false;
      final titleMatch = m.title.toLowerCase().contains(qLower);
      final genreMatch = m.genre.any((g) => g.toLowerCase().contains(qLower));
      final descMatch = m.description.toLowerCase().contains(qLower);
      final langMatch = m.language.toLowerCase().contains(qLower);
      final castMatch =
          m.cast.any((c) => c.toString().toLowerCase().contains(qLower));
      final yearMatch = m.releaseYear.toString().contains(qLower);
      return titleMatch ||
          genreMatch ||
          descMatch ||
          langMatch ||
          castMatch ||
          yearMatch;
    }).toList();

    searchedMovies.assignAll(localMatches);
    searchStatus.value = Status.success;
  }

  List<MovieModel> get filteredMovies {
    final query = currentSearchQuery.value.trim().toLowerCase();
    final selectedCategory = currentCategoryName;

    // Combine server search results with local list (deduplicated)
    final Set<String> seenIds = {};
    final List<MovieModel> combinedList = [];

    if (query.isNotEmpty) {
      for (final m in searchedMovies) {
        if (m.isVisible && seenIds.add(m.id)) combinedList.add(m);
      }
      for (final m in allMovies) {
        if (m.isVisible && seenIds.add(m.id)) combinedList.add(m);
      }
    } else {
      combinedList.addAll(allMovies.where((m) => m.isVisible));
    }

    final matched = combinedList.where((movie) {
      if (!movie.isVisible) return false;
      final matchesCategory = selectedCategory == 'All' ||
          _matchesMovieCategoryName(movie, selectedCategory);

      if (!matchesCategory) return false;

      if (query.isEmpty) return true;

      final titleMatch = movie.title.toLowerCase().contains(query);
      final genreMatch =
          movie.genre.any((g) => g.toLowerCase().contains(query));
      final descMatch = movie.description.toLowerCase().contains(query);
      final langMatch = movie.language.toLowerCase().contains(query);
      final castMatch =
          movie.cast.any((c) => c.toString().toLowerCase().contains(query));
      final yearMatch = movie.releaseYear.toString().contains(query);

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

  bool _matchesMovieCategoryName(MovieModel movie, String catName) {
    String clean(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final target = clean(catName);

    for (final c in movie.category) {
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
    for (final g in movie.genre) {
      if (g.toLowerCase() == catName.toLowerCase() ||
          (target.isNotEmpty && clean(g) == target)) {
        return true;
      }
    }
    if (movie.slug.isNotEmpty &&
        (movie.slug.toLowerCase() == catName.toLowerCase() ||
            (target.isNotEmpty && clean(movie.slug) == target))) {
      return true;
    }
    return false;
  }

  Future<void> fetchAllMovies() async {
    currentPage = 1;
    hasMore.value = true;
    allMoviesStatus.value = Status.loading;
    try {
      final result = await _api.allMovie(page: 1, limit: pageSize);
      allMovies.assignAll(result);
      if (result.length < pageSize) {
        hasMore.value = false;
      }
      allMoviesStatus.value = Status.success;
    } catch (_) {
      allMoviesStatus.value = Status.error;
    }
  }

  Future<void> fetchMoreMovies() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final nextPage = currentPage + 1;
      final result = await _api.allMovie(page: nextPage, limit: pageSize);
      if (result.isNotEmpty) {
        // Filter out any duplicates
        final existingIds = allMovies.map((m) => m.id).toSet();
        final newItems = result.where((m) => !existingIds.contains(m.id)).toList();
        if (newItems.isNotEmpty) {
          allMovies.addAll(newItems);
          currentPage = nextPage;
        } else {
          hasMore.value = false;
        }
        if (result.length < pageSize) {
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

  Future<void> fetchMovieDetail(String id) async {
    movieDetailStatus.value = Status.loading;
    final result = await _api.movieDetail(id: id);
    if (result != null) {
      movieDetail.value = result;
      movieDetailStatus.value = Status.success;
    } else {
      movieDetailStatus.value = Status.error;
    }
  }

  Future<LikeDislikeResponse?> toggleLike(String id) async {
    isInteracting.value = true;
    try {
      final res = await _api.toggleLike(id);
      if (res != null && res.success) {
        if (movieDetail.value != null && movieDetail.value!.id == id) {
          movieDetail.value = movieDetail.value!.copyWith(
            likes: res.totalLikes,
            dislikes: res.totalDislikes,
          );
        }
        final index = allMovies.indexWhere((m) => m.id == id);
        if (index != -1) {
          allMovies[index] = allMovies[index].copyWith(
            likes: res.totalLikes,
            dislikes: res.totalDislikes,
          );
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
        if (movieDetail.value != null && movieDetail.value!.id == id) {
          movieDetail.value = movieDetail.value!.copyWith(
            likes: res.totalLikes,
            dislikes: res.totalDislikes,
          );
        }
        final index = allMovies.indexWhere((m) => m.id == id);
        if (index != -1) {
          allMovies[index] = allMovies[index].copyWith(
            likes: res.totalLikes,
            dislikes: res.totalDislikes,
          );
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

