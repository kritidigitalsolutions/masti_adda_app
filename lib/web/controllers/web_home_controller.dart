import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/features/home/models/category_model.dart';
import 'package:masti_adda_app/features/home/models/category_detail_model.dart';
import 'package:masti_adda_app/features/home/models/home_banner_model.dart';
import 'package:masti_adda_app/features/home/repositories/home_datasource.dart';
import 'package:masti_adda_app/features/micro_drama/datasource/micro_drama_datasource.dart';
import 'package:masti_adda_app/features/micro_drama/models/micro_drama_model.dart';
import 'package:masti_adda_app/features/movie/models/MovieModel.dart';
import 'package:masti_adda_app/features/movie/repositories/movie_datasource.dart';
import 'package:masti_adda_app/features/web_series/datasource/series_datasource.dart';
import 'package:masti_adda_app/features/web_series/model/SeriesModel.dart';

class WebHomeController extends GetxController {
  final HomeDatasource _homeDatasource = HomeDatasource();
  final MicroDramaDatasource _dramaDatasource = MicroDramaDatasource();
  final MovieDatasource _movieDatasource = MovieDatasource();
  final SeriesDatasource _seriesDatasource = SeriesDatasource();

  Timer? _bannerAutoRefreshTimer;

  // Banners
  final RxList<HomeBannerItem> banners = <HomeBannerItem>[].obs;
  final RxBool isBannersLoading = false.obs;

  // Content Lists
  final RxList<Microdrama> dramas = <Microdrama>[].obs;
  final RxBool isDramasLoading = false.obs;

  final RxList<MovieModel> movies = <MovieModel>[].obs;
  final RxBool isMoviesLoading = false.obs;

  final RxList<Series> series = <Series>[].obs;
  final RxBool isSeriesLoading = false.obs;

  // Categories & Category-specific content
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxMap<String, List<ContentModel>> categoryContents = <String, List<ContentModel>>{}.obs;
  final RxBool isCategoriesLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (banners.isEmpty && movies.isEmpty && series.isEmpty && dramas.isEmpty) {
      fetchAllHomeData();
    }
    _startBannerAutoRefresh();
  }

  void _startBannerAutoRefresh() {
    _bannerAutoRefreshTimer?.cancel();
    // Silently re-fetch banners every 60 seconds to ensure any pre-signed S3 / CloudFront URLs are always renewed
    _bannerAutoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      fetchBanners(isSilent: true);
    });
  }

  @override
  void onClose() {
    _bannerAutoRefreshTimer?.cancel();
    super.onClose();
  }

  Future<void> fetchAllHomeData() async {
    fetchBanners();
    fetchDramas();
    fetchMovies();
    fetchSeries();
    fetchCategories();
  }

  Future<void> fetchBanners({bool isSilent = false}) async {
    try {
      if (!isSilent && banners.isEmpty) {
        isBannersLoading.value = true;
      }
      final response = await _homeDatasource.fetchHomeBanners();
      if (response != null && response.data != null && response.data!.isNotEmpty) {
        banners.assignAll(response.data!);
      }
    } catch (e) {
      debugPrint("Web Home: fetchBanners error: $e");
    } finally {
      if (!isSilent) {
        isBannersLoading.value = false;
      }
    }
  }

  Future<void> fetchDramas() async {
    try {
      isDramasLoading.value = true;
      final response = await _dramaDatasource.allMicroDrama(limit: 30);
      if (response != null && response.microdramas.isNotEmpty) {
        final list = List<Microdrama>.from(response.microdramas)
          ..sort((a, b) {
            if (a.priority != b.priority) return a.priority.compareTo(b.priority);
            return b.rating.compareTo(a.rating);
          });
        dramas.assignAll(list);
      }
    } catch (e) {
      debugPrint("Web Home: fetchDramas error: $e");
    } finally {
      isDramasLoading.value = false;
    }
  }

  Future<void> fetchMovies() async {
    try {
      isMoviesLoading.value = true;
      final response = await _movieDatasource.allMovie(limit: 30);
      if (response.isNotEmpty) {
        final list = response.where((m) => m.isVisible).toList()
          ..sort((a, b) {
            if (a.priority != b.priority) return a.priority.compareTo(b.priority);
            return b.rating.compareTo(a.rating);
          });
        movies.assignAll(list);
      }
    } catch (e) {
      debugPrint("Web Home: fetchMovies error: $e");
    } finally {
      isMoviesLoading.value = false;
    }
  }

  Future<void> fetchSeries() async {
    try {
      isSeriesLoading.value = true;
      final response = await _seriesDatasource.allSeries(limit: 30);
      if (response != null && response.series.isNotEmpty) {
        final list = response.series.where((s) => s.isVisible).toList()
          ..sort((a, b) {
            if (a.priority != b.priority) return a.priority.compareTo(b.priority);
            return b.rating.compareTo(a.rating);
          });
        series.assignAll(list);
      }
    } catch (e) {
      debugPrint("Web Home: fetchSeries error: $e");
    } finally {
      isSeriesLoading.value = false;
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

        // Fetch contents for each category in parallel
        await Future.wait(
          categories.map((cat) => _fetchCategoryContent(cat.id)),
        );
      }
    } catch (e) {
      debugPrint("Web Home: fetchCategories error: $e");
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  Future<void> _fetchCategoryContent(String categoryId) async {
    try {
      final response = await _homeDatasource.categoryDetail(
        id: categoryId,
        page: 0,
        size: 20,
      );
      if (response != null && response.content.isNotEmpty) {
        categoryContents[categoryId] = response.content;
      }
    } catch (e) {
      debugPrint("Web Home: fetchCategoryContent for $categoryId error: $e");
    }
  }
}
