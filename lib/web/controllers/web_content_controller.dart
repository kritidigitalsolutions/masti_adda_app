import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/features/home/models/category_model.dart';
import 'package:masti_adda_app/features/home/repositories/home_datasource.dart';
import 'package:masti_adda_app/features/micro_drama/datasource/micro_drama_datasource.dart';
import 'package:masti_adda_app/features/micro_drama/models/micro_drama_model.dart';
import 'package:masti_adda_app/features/movie/models/MovieModel.dart';
import 'package:masti_adda_app/features/movie/repositories/movie_datasource.dart';
import 'package:masti_adda_app/features/web_series/datasource/series_datasource.dart';
import 'package:masti_adda_app/features/web_series/model/SeriesModel.dart';
import 'package:masti_adda_app/web/utils/web_category_helper.dart';

class WebContentController extends GetxController {
  final HomeDatasource _homeDatasource = HomeDatasource();
  final MicroDramaDatasource _dramaDatasource = MicroDramaDatasource();
  final MovieDatasource _movieDatasource = MovieDatasource();
  final SeriesDatasource _seriesDatasource = SeriesDatasource();

  // Categories
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isCategoriesLoading = false.obs;

  // Dramas
  final RxList<Microdrama> dramas = <Microdrama>[].obs;
  final RxBool isDramasLoading = false.obs;
  final RxString selectedDramaGenre = 'All'.obs;

  // Movies
  final RxList<MovieModel> movies = <MovieModel>[].obs;
  final RxBool isMoviesLoading = false.obs;
  final RxString selectedMovieGenre = 'All'.obs;

  // Series
  final RxList<Series> series = <Series>[].obs;
  final RxBool isSeriesLoading = false.obs;
  final RxString selectedSeriesGenre = 'All'.obs;

  @override
  void onInit() {
    super.onInit();
    if (categories.isEmpty && movies.isEmpty && series.isEmpty && dramas.isEmpty) {
      fetchCategories();
      fetchDramas();
      fetchMovies();
      fetchSeries();
    }
  }

  Future<void> fetchCategories() async {
    try {
      isCategoriesLoading.value = true;
      final response = await _homeDatasource.allCategories();
      if (response != null && response.categories.isNotEmpty) {
        var activeCats = response.categories
            .where((cat) => cat.isActive)
            .toList();
        if (activeCats.isEmpty) {
          activeCats = List<CategoryModel>.from(response.categories);
        }
        activeCats.sort((a, b) => a.priority.compareTo(b.priority));
        categories.assignAll(activeCats);
      }
    } catch (e) {
      debugPrint("WebContentController: fetchCategories error: $e");
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  Future<void> fetchDramas() async {
    try {
      isDramasLoading.value = true;
      final response = await _dramaDatasource.allMicroDrama(limit: 50);
      if (response != null && response.microdramas.isNotEmpty) {
        final list = List<Microdrama>.from(response.microdramas)
          ..sort((a, b) {
            if (a.priority != b.priority) return a.priority.compareTo(b.priority);
            return b.rating.compareTo(a.rating);
          });
        dramas.assignAll(list);
      }
    } catch (e) {
      debugPrint("WebContentController: fetchDramas error: $e");
    } finally {
      isDramasLoading.value = false;
    }
  }

  Future<void> fetchMovies() async {
    try {
      isMoviesLoading.value = true;
      final response = await _movieDatasource.allMovie(limit: 50);
      if (response.isNotEmpty) {
        final list = response.where((m) => m.isVisible).toList()
          ..sort((a, b) {
            if (a.priority != b.priority) return a.priority.compareTo(b.priority);
            return b.rating.compareTo(a.rating);
          });
        movies.assignAll(list);
      }
    } catch (e) {
      debugPrint("WebContentController: fetchMovies error: $e");
    } finally {
      isMoviesLoading.value = false;
    }
  }

  Future<void> fetchSeries() async {
    try {
      isSeriesLoading.value = true;
      final response = await _seriesDatasource.allSeries(limit: 50);
      if (response != null && response.series.isNotEmpty) {
        final list = response.series.where((s) => s.isVisible).toList()
          ..sort((a, b) {
            if (a.priority != b.priority) return a.priority.compareTo(b.priority);
            return b.rating.compareTo(a.rating);
          });
        series.assignAll(list);
      }
    } catch (e) {
      debugPrint("WebContentController: fetchSeries error: $e");
    } finally {
      isSeriesLoading.value = false;
    }
  }

  List<String> get dramaGenres {
    final list = <String>['All'];
    // Add active categories ordered by priority first
    for (final cat in categories) {
      if (!list.contains(cat.name)) list.add(cat.name);
    }
    // Also add genres present in data
    for (var d in dramas) {
      for (var g in d.genre) {
        final str = g.toString().trim();
        if (str.isNotEmpty && !list.contains(str)) {
          list.add(str);
        }
      }
    }
    return list;
  }

  List<String> get movieGenres {
    final list = <String>['All'];
    // Add active categories ordered by priority first
    for (final cat in categories) {
      if (!list.contains(cat.name)) list.add(cat.name);
    }
    // Also add genres present in data
    for (var m in movies.where((m) => m.isVisible)) {
      for (var g in m.genre) {
        final str = g.trim();
        if (str.isNotEmpty && !list.contains(str)) {
          list.add(str);
        }
      }
    }
    return list;
  }

  List<String> get seriesGenres {
    final list = <String>['All'];
    // Add active categories ordered by priority first
    for (final cat in categories) {
      if (!list.contains(cat.name)) list.add(cat.name);
    }
    // Also add genres present in data
    for (var s in series.where((s) => s.isVisible)) {
      for (var g in s.genre) {
        final str = g.trim();
        if (str.isNotEmpty && !list.contains(str)) {
          list.add(str);
        }
      }
    }
    return list;
  }

  List<Microdrama> get filteredDramas {
    final selected = selectedDramaGenre.value.trim();
    if (selected.toLowerCase() == 'all' || selected.isEmpty) return dramas;

    final matchedCategory = categories.firstWhereOrNull(
      (c) => c.name.toLowerCase() == selected.toLowerCase() ||
          c.slug.toLowerCase() == selected.toLowerCase(),
    );

    final result = dramas.where((d) {
      if (matchedCategory != null) {
        return WebCategoryHelper.matchesDrama(d, matchedCategory);
      }
      return WebCategoryHelper.stringMatchesCategoryOrGenre(d.category, selected) ||
          WebCategoryHelper.stringMatchesCategoryOrGenre(d.genre, selected) ||
          WebCategoryHelper.stringMatchesCategoryOrGenre(d.slug, selected);
    }).toList();

    result.sort((a, b) {
      if (a.priority != b.priority) return a.priority.compareTo(b.priority);
      return b.rating.compareTo(a.rating);
    });

    return result;
  }

  List<MovieModel> get filteredMovies {
    final selected = selectedMovieGenre.value.trim();
    final visibleMovies = movies.where((m) => m.isVisible).toList();
    if (selected.toLowerCase() == 'all' || selected.isEmpty) return visibleMovies;

    final matchedCategory = categories.firstWhereOrNull(
      (c) => c.name.toLowerCase() == selected.toLowerCase() ||
          c.slug.toLowerCase() == selected.toLowerCase(),
    );

    final result = visibleMovies.where((m) {
      if (matchedCategory != null) {
        return WebCategoryHelper.matchesMovie(m, matchedCategory);
      }
      return WebCategoryHelper.stringMatchesCategoryOrGenre(m.category, selected) ||
          WebCategoryHelper.stringMatchesCategoryOrGenre(m.genre, selected) ||
          WebCategoryHelper.stringMatchesCategoryOrGenre(m.slug, selected);
    }).toList();

    result.sort((a, b) {
      if (a.priority != b.priority) return a.priority.compareTo(b.priority);
      return b.rating.compareTo(a.rating);
    });

    return result;
  }

  List<Series> get filteredSeries {
    final selected = selectedSeriesGenre.value.trim();
    final visibleSeries = series.where((s) => s.isVisible).toList();
    if (selected.toLowerCase() == 'all' || selected.isEmpty) return visibleSeries;

    final matchedCategory = categories.firstWhereOrNull(
      (c) => c.name.toLowerCase() == selected.toLowerCase() ||
          c.slug.toLowerCase() == selected.toLowerCase(),
    );

    final result = visibleSeries.where((s) {
      if (matchedCategory != null) {
        return WebCategoryHelper.matchesSeries(s, matchedCategory);
      }
      return WebCategoryHelper.stringMatchesCategoryOrGenre(s.category, selected) ||
          WebCategoryHelper.stringMatchesCategoryOrGenre(s.genre, selected) ||
          WebCategoryHelper.stringMatchesCategoryOrGenre(s.slug, selected);
    }).toList();

    result.sort((a, b) {
      if (a.priority != b.priority) return a.priority.compareTo(b.priority);
      return b.rating.compareTo(a.rating);
    });

    return result;
  }
}
