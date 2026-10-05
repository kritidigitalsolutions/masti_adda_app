import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';
import '../models/category_model.dart';
import '../models/category_detail_model.dart';
import '../models/content_model.dart';

import '../models/home_banner_model.dart';
import 'package:masti_adda_app/shared/models/like_dislike_response.dart';

class HomeDatasource {
  final NetworkApiService _apiService = NetworkApiService();

  Future<HomeBannerResponse?> fetchHomeBanners() async {
    try {
      final json = await _apiService.getApi(AppUrl.homeBanners);
      if (json != null) {
        return HomeBannerResponse.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<CategoriesResponse?> allCategories() async {
    try {
      final json = await _apiService.getApi(AppUrl.allCategories);
      if (json != null) {
        return CategoriesResponse.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<CategoryContentResponse?> categoryDetail({
    required String id,
    required int page,
    required int size,
  }) async {
    try {
      final json = await _apiService.getApi(
        AppUrl.categoryDetail(id: id, page: page, size: size),
      );
      if (json != null) {
        return CategoryContentResponse.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Future<HomeContentResponse?> allContent() async {
  //   try {
  //     final json = await _apiService.getApi(AppUrl.allContentApi);
  //     if (json != null) {
  //       return HomeContentResponse.fromJson(json);
  //     }
  //     return null;
  //   } catch (e) {
  //     return null;
  //   }
  // }

  Future<HomeContentResponse?> searchContent(String query) async {
    try {
      final json = await _apiService.getApi(AppUrl.searchContent(query: query));
      if (json != null) {
        return HomeContentResponse.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<LikeDislikeResponse?> toggleLike(String contentId) async {
    try {
      final response = await _apiService.postApi(
        AppUrl.toggleLike(contentId),
        {},
      );
      if (response != null && response is Map) {
        return LikeDislikeResponse.fromJson(Map<String, dynamic>.from(response));
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<LikeDislikeResponse?> toggleDislike(String contentId) async {
    try {
      final response = await _apiService.postApi(
        AppUrl.toggleDislike(contentId),
        {},
      );
      if (response != null && response is Map) {
        return LikeDislikeResponse.fromJson(Map<String, dynamic>.from(response));
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
