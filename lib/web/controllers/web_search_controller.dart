import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/features/home/repositories/home_datasource.dart';
import 'package:masti_adda_app/features/movie/repositories/movie_datasource.dart';
import 'package:masti_adda_app/features/web_series/datasource/series_datasource.dart';

class SearchResultItem {
  final String id;
  final String title;
  final String? poster;
  final String type; // 'drama', 'movie', 'series'
  final String? genre;
  final double? rating;
  final String? duration;
  final int? releaseYear;
  final bool isPremium;

  SearchResultItem({
    required this.id,
    required this.title,
    this.poster,
    required this.type,
    this.genre,
    this.rating,
    this.duration,
    this.releaseYear,
    this.isPremium = false,
  });
}

class WebSearchController extends GetxController {
  final HomeDatasource _homeDatasource = HomeDatasource();
  final MovieDatasource _movieDatasource = MovieDatasource();
  final SeriesDatasource _seriesDatasource = SeriesDatasource();

  final TextEditingController searchInputController = TextEditingController();
  final RxString query = ''.obs;
  final RxString selectedTypeFilter = 'All'.obs; // 'All', 'Dramas', 'Movies', 'Series'
  final RxBool isLoading = false.obs;
  final RxList<SearchResultItem> allResults = <SearchResultItem>[].obs;

  Timer? _debounceTimer;

  @override
  void onClose() {
    _debounceTimer?.cancel();
    searchInputController.dispose();
    super.onClose();
  }

  void onQueryChanged(String value) {
    query.value = value;
    _debounceTimer?.cancel();
    if (value.trim().isEmpty) {
      allResults.clear();
      isLoading.value = false;
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      performSearch(value.trim());
    });
  }

  Future<void> performSearch(String q) async {
    if (q.isEmpty) return;

    try {
      isLoading.value = true;
      final List<SearchResultItem> items = [];

      // 1. Search via general content API
      final generalResult = await _homeDatasource.searchContent(q);
      if (generalResult != null && generalResult.content.isNotEmpty) {
        for (var c in generalResult.content) {
          final rawType = c.type.toLowerCase();
          final type = rawType.contains('drama')
              ? 'drama'
              : (rawType.contains('series') ? 'series' : 'movie');

          items.add(SearchResultItem(
            id: c.id,
            title: c.title,
            poster: c.poster.isNotEmpty ? c.poster : c.banner,
            type: type,
            genre: c.genre.isNotEmpty ? c.genre.first : null,
            rating: c.rating.toDouble(),
            duration: c.duration,
            releaseYear: c.releaseYear,
            isPremium: c.isPremium,
          ));
        }
      }

      // 2. Search movies as supplement
      try {
        final movieResults = await _movieDatasource.searchMovies(q);
        for (var m in movieResults.where((m) => m.isVisible)) {
          if (!items.any((i) => i.id == m.id)) {
            items.add(SearchResultItem(
              id: m.id,
              title: m.title,
              poster: m.poster.isNotEmpty ? m.poster : m.banner,
              type: 'movie',
              genre: m.genre.isNotEmpty ? m.genre.first : null,
              rating: m.rating,
              duration: m.duration,
              releaseYear: m.releaseYear,
              isPremium: m.isPremium,
            ));
          }
        }
      } catch (_) {}

      // 3. Search series as supplement
      try {
        final seriesResults = await _seriesDatasource.searchSeries(q);
        for (var s in seriesResults.where((s) => s.isVisible)) {
          if (!items.any((i) => i.id == s.id)) {
            items.add(SearchResultItem(
              id: s.id,
              title: s.title,
              poster: s.poster.isNotEmpty ? s.poster : s.banner,
              type: 'series',
              genre: s.genre.isNotEmpty ? s.genre.first : null,
              rating: s.rating,
              duration: s.duration,
              releaseYear: s.releaseYear,
              isPremium: s.isPremium,
            ));
          }
        }
      } catch (_) {}

      allResults.assignAll(items);
    } catch (e) {
      debugPrint("WebSearchController error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  List<SearchResultItem> get filteredResults {
    if (selectedTypeFilter.value == 'All') return allResults;
    if (selectedTypeFilter.value == 'Dramas') {
      return allResults.where((i) => i.type == 'drama').toList();
    }
    if (selectedTypeFilter.value == 'Movies') {
      return allResults.where((i) => i.type == 'movie').toList();
    }
    if (selectedTypeFilter.value == 'Series') {
      return allResults.where((i) => i.type == 'series').toList();
    }
    return allResults;
  }
}
