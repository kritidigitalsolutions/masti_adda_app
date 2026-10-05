import 'package:flutter/foundation.dart';
import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';
import 'package:masti_adda_app/features/profile/models/rating_response_model.dart';

class RatingRepository {
  final NetworkApiService _apiService = NetworkApiService();

  /// Submit rating and review to `/api/rating/rate`
  /// Payload: `{ "rating": rating, "review": review }`
  Future<RatingResponseModel?> submitRating({
    required int rating,
    required String review,
  }) async {
    try {
      final data = {
        "rating": rating,
        "review": review,
      };
      debugPrint("Submitting rating: $data to ${AppUrl.rateApp}");
      final response = await _apiService.postApi(AppUrl.rateApp, data);
      if (response != null && response is Map) {
        return RatingResponseModel.fromJson(Map<String, dynamic>.from(response));
      }
      return const RatingResponseModel(
        success: true,
        message: "Rating submitted successfully",
      );
    } catch (e) {
      debugPrint("RatingRepository error: $e");
      rethrow;
    }
  }
}
