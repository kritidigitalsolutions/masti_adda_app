import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/features/home/models/home_banner_model.dart';
import 'package:masti_adda_app/web/datasource/web_layout_datasource.dart';
import 'package:masti_adda_app/web/models/web_layout_model.dart';

class WebHomeController extends GetxController {
  final WebLayoutDatasource _layoutDatasource = WebLayoutDatasource();

  Timer? _bannerAutoRefreshTimer;

  // 1. Hero Banners: GET /api/webpage-layout/banners
  final RxList<HomeBannerItem> banners = <HomeBannerItem>[].obs;
  final RxBool isBannersLoading = false.obs;

  // 2. All Carousel Rows / Sections: GET /api/webpage-layout/sections
  final RxList<WebLayoutSection> sections = <WebLayoutSection>[].obs;
  final RxBool isSectionsLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (banners.isEmpty && sections.isEmpty) {
      fetchAllHomeData();
    }
    _startBannerAutoRefresh();
  }

  void _startBannerAutoRefresh() {
    _bannerAutoRefreshTimer?.cancel();
    // Silently refresh banners every 60 seconds so CDN tokens/pre-signed URLs remain fresh
    _bannerAutoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      fetchBanners(isSilent: true);
    });
  }

  @override
  void onClose() {
    _bannerAutoRefreshTimer?.cancel();
    super.onClose();
  }

  Future<void> fetchAllHomeData({bool isSilent = false}) async {
    await Future.wait([
      fetchBanners(isSilent: isSilent),
      fetchSections(isSilent: isSilent),
    ]);
  }

  /// 1. Hero Banners Only: GET /api/webpage-layout/banners
  Future<void> fetchBanners({bool isSilent = false}) async {
    try {
      if (!isSilent && banners.isEmpty) {
        isBannersLoading.value = true;
      }
      final response = await _layoutDatasource.fetchBanners();
      if (response != null && response.heroBanners.isNotEmpty) {
        banners.assignAll(response.heroBanners);
      }
    } catch (e) {
      debugPrint("Web Home: fetchBanners error: $e");
    } finally {
      if (!isSilent) {
        isBannersLoading.value = false;
      }
    }
  }

  /// 2. All Carousel Rows: GET /api/webpage-layout/sections
  Future<void> fetchSections({bool isSilent = false}) async {
    try {
      if (!isSilent && sections.isEmpty) {
        isSectionsLoading.value = true;
      }
      final response = await _layoutDatasource.fetchSections();
      if (response != null && response.sections.isNotEmpty) {
        final activeSections =
            response.sections
                .where((s) => s.isActive && s.items.isNotEmpty)
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order));
        sections.assignAll(activeSections);
      }
    } catch (e) {
      debugPrint("Web Home: fetchSections error: $e");
    } finally {
      if (!isSilent) {
        isSectionsLoading.value = false;
      }
    }
  }

  /// 3. Fetch Section by Slug: GET /api/webpage-layout/sections/:slug
  Future<WebLayoutSection?> fetchSectionBySlug(String slug) async {
    return await _layoutDatasource.fetchSectionBySlug(slug);
  }
}
