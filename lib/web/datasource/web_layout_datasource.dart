import 'package:flutter/foundation.dart';
import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';
import 'package:masti_adda_app/web/models/web_layout_model.dart';

class WebLayoutDatasource {
  final NetworkApiService _apiService = NetworkApiService();

  /// 1. Fetch hero banners: GET /api/webpage-layout/banners
  Future<WebLayoutBannersResponse?> fetchBanners() async {
    try {
      debugPrint(
        "🌐 [WebLayout] Fetching banners: ${AppUrl.webpageLayoutBanners}",
      );
      final response = await _apiService.getApi(AppUrl.webpageLayoutBanners);
      if (response != null && response is Map<String, dynamic>) {
        return WebLayoutBannersResponse.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint("❌ [WebLayout] fetchBanners error: $e");
      return null;
    }
  }

  /// 2. Fetch all carousel rows / sections: GET /api/webpage-layout/sections
  Future<WebLayoutSectionsResponse?> fetchSections() async {
    try {
      debugPrint(
        "🌐 [WebLayout] Fetching sections: ${AppUrl.webpageLayoutSections}",
      );
      final response = await _apiService.getApi(AppUrl.webpageLayoutSections);
      if (response != null && response is Map<String, dynamic>) {
        return WebLayoutSectionsResponse.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint("❌ [WebLayout] fetchSections error: $e");
      return null;
    }
  }

  /// 3. Fetch section by slug: GET /api/webpage-layout/sections/:slug
  Future<WebLayoutSection?> fetchSectionBySlug(String slug) async {
    try {
      final url = AppUrl.webpageLayoutSectionDetail(slug);
      debugPrint("🌐 [WebLayout] Fetching section by slug: $url");
      final response = await _apiService.getApi(url);
      if (response != null && response is Map<String, dynamic>) {
        final sectionData = response['section'] ?? response['data'] ?? response;
        if (sectionData is Map<String, dynamic>) {
          return WebLayoutSection.fromJson(sectionData);
        }
      }
      return null;
    } catch (e) {
      debugPrint("❌ [WebLayout] fetchSectionBySlug ($slug) error: $e");
      return null;
    }
  }
}
