import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/features/profile/repositories/notification_repository.dart';

class NotificationSettingsController extends GetxController {
  static NotificationSettingsController get to =>
      Get.isRegistered<NotificationSettingsController>()
          ? Get.find<NotificationSettingsController>()
          : Get.put(NotificationSettingsController(), permanent: true);

  final NotificationRepository _repository = NotificationRepository();

  final RxBool newEpisodes = true.obs;
  final RxBool newMovies = true.obs;
  final RxBool recommendations = true.obs;
  final RxBool downloads = true.obs;
  final RxBool continueWatchingReminder = false.obs;
  final RxBool subscriptionAlerts = true.obs;
  final RxBool promotionalOffers = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSettings();
  }

  Future<void> fetchSettings({bool silent = false}) async {
    try {
      if (!silent) {
        isLoading.value = true;
      }
      final response = await _repository.getNotificationSettings();
      if (response != null &&
          (response['success'] == true ||
              response['status'] == true ||
              response['data'] != null ||
              response['notificationSettings'] != null ||
              response['settings'] != null)) {
        final settings = response['notificationSettings'] ??
            response['settings'] ??
            response['data'] ??
            response;

        if (settings is Map) {
          if (settings.containsKey('newEpisodes')) {
            newEpisodes.value = settings['newEpisodes'] == true;
          }
          if (settings.containsKey('newMovies')) {
            newMovies.value = settings['newMovies'] == true;
          }
          if (settings.containsKey('recommendations')) {
            recommendations.value = settings['recommendations'] == true;
          }
          if (settings.containsKey('downloads')) {
            downloads.value = settings['downloads'] == true;
          }
          if (settings.containsKey('continueWatching')) {
            continueWatchingReminder.value = settings['continueWatching'] == true;
          } else if (settings.containsKey('continueWatchingReminder')) {
            continueWatchingReminder.value =
                settings['continueWatchingReminder'] == true;
          }
          if (settings.containsKey('subscriptionAlerts')) {
            subscriptionAlerts.value = settings['subscriptionAlerts'] == true;
          }
          if (settings.containsKey('promotionalOffers')) {
            promotionalOffers.value = settings['promotionalOffers'] == true;
          }
        }
        isLoaded.value = true;
      }
    } catch (e) {
      debugPrint("Error fetching notification settings: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveChanges() async {
    try {
      isSaving.value = true;
      final response = await _repository.updateNotificationSettings({
        "newEpisodes": newEpisodes.value,
        "newMovies": newMovies.value,
        "recommendations": recommendations.value,
        "downloads": downloads.value,
        "continueWatching": continueWatchingReminder.value,
        "subscriptionAlerts": subscriptionAlerts.value,
        "promotionalOffers": promotionalOffers.value,
      });

      if (response != null && response['success'] == true) {
        Get.snackbar(
          'Saved',
          'Notification settings updated successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to update notification settings.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("Error saving notification settings: $e");
      Get.snackbar(
        'Error',
        'An error occurred while saving: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    } finally {
      isSaving.value = false;
    }
  }
}
