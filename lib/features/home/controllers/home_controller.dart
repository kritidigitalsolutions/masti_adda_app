import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/features/home/models/category_detail_model.dart';
import 'package:masti_adda_app/features/home/models/category_model.dart';
import 'package:masti_adda_app/features/home/models/home_banner_model.dart';
import 'package:masti_adda_app/features/home/repositories/home_datasource.dart';
import 'package:masti_adda_app/features/micro_drama/controllers/continue_watching_controller.dart';

class HomeController extends GetxController {
  final HomeDatasource _homeDatasource = HomeDatasource();

  final RxInt pageIndex = 0.obs;
  final RxInt currentBannerIndex = 0.obs;
  final RxInt selectedTabIndex = 0.obs;

  final RxList<HomeBannerItem> banners = <HomeBannerItem>[].obs;
  final RxBool isBannersLoading = false.obs;

  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isCategoriesLoading = false.obs;

  final RxMap<String, List<ContentModel>> categoryContents =
      <String, List<ContentModel>>{}.obs;
  final RxBool isCategoryContentsLoading = false.obs;

  RxInt get selectedIndex => pageIndex;

  final List<String> tabs = [
    'For You',
    'Movies',
    'Web Series',
  ];

  // ── Continue Watching via shared controller ──────────────────────────────
  ContinueWatchingController get cwController =>
      Get.isRegistered<ContinueWatchingController>()
          ? Get.find<ContinueWatchingController>()
          : Get.put(ContinueWatchingController());

  @override
  void onInit() {
    super.onInit();
    fetchHomeBanners();
    fetchCategories();
    cwController.fetchForHome();
  }

  Future<void> fetchHomeBanners() async {
    try {
      isBannersLoading.value = true;
      final response = await _homeDatasource.fetchHomeBanners();
      if (response != null &&
          response.data != null &&
          response.data!.isNotEmpty) {
        banners.assignAll(response.data!);
      }
    } catch (e) {
      debugPrint("Error fetching home banners: $e");
    } finally {
      isBannersLoading.value = false;
    }
  }

  Future<void> fetchCategories() async {
    try {
      isCategoriesLoading.value = true;
      final response = await _homeDatasource.allCategories();
      if (response != null && response.categories.isNotEmpty) {
        // Active categories sorted by priority (lowest number = highest priority)
        var topCats = response.categories
            .where((cat) => cat.isActive)
            .toList();
        if (topCats.isEmpty) {
          topCats = List<CategoryModel>.from(response.categories);
        }
        topCats.sort((a, b) => a.priority.compareTo(b.priority));
        categories.assignAll(topCats);

        // Fetch contents for active categories in parallel in background
        _fetchCategoriesContent(topCats);
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  Future<void> _fetchCategoriesContent(List<CategoryModel> cats) async {
    try {
      isCategoryContentsLoading.value = true;
      await Future.wait(
        cats.map((cat) => _fetchCategoryContent(cat.id)),
      );
    } catch (e) {
      debugPrint("Error fetching category contents: $e");
    } finally {
      isCategoryContentsLoading.value = false;
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
      debugPrint("Error fetching category content for $categoryId: $e");
    }
  }

  void onTabSelected(int index) => selectedTabIndex.value = index;
  void onBannerChanged(int index) => currentBannerIndex.value = index;
  void changePage(int index) => pageIndex.value = index;
  void changeTab(int index) => changePage(index);
}
