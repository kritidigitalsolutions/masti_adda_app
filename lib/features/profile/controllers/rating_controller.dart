import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/features/profile/models/rating_response_model.dart';
import 'package:masti_adda_app/features/profile/repositories/rating_repository.dart';

class RatingController extends GetxController {
  final RatingRepository _repository = RatingRepository();

  final RxInt rating = 5.obs;
  final RxBool isSubmitting = false.obs;
  final TextEditingController feedbackController = TextEditingController();

  @override
  void onClose() {
    feedbackController.dispose();
    super.onClose();
  }

  void setRating(int value) {
    rating.value = value;
  }

  Future<RatingResponseModel?> submitRating({
    int? customRating,
    String? customReview,
  }) async {
    isSubmitting.value = true;
    try {
      final targetRating = customRating ?? rating.value;
      final targetReview = customReview ?? feedbackController.text.trim();

      final result = await _repository.submitRating(
        rating: targetRating,
        review: targetReview,
      );
      return result;
    } catch (e) {
      debugPrint("RatingController submitRating error: $e");
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }
}
