import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/core/services/firebase_service.dart';

class NotificationsController extends GetxController {
  final NotificationService _service = Get.find<NotificationService>();

  RxList<Map<String, dynamic>> get notifications => _service.notifications;
  RxBool get isLoading => _service.isLoading;

  @override
  void onInit() {
    super.onInit();
    try {
      _service.fetchNotifications();
    } catch (e) {
      debugPrint("Error fetching notifications in controller: $e");
    }
  }

  Future<void> clearAll() async {
    try {
      isLoading.value = true;
      await _service.markAllAsRead();
    } catch (e) {
      debugPrint("Error clearing notifications: $e");
      Get.snackbar(
        'Error',
        'Could not mark notifications read: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAll() async {
    try {
      isLoading.value = true;
      await _service.clearNotifications();
    } catch (e) {
      debugPrint("Error deleting all notifications: $e");
      Get.snackbar(
        'Error',
        'Could not delete all notifications: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteNotification(int index) async {
    try {
      await _service.deleteSingleNotification(index);
    } catch (e) {
      debugPrint("Error deleting notification at index $index: $e");
      Get.snackbar(
        'Error',
        'Could not delete notification: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> markRead(int index) async {
    try {
      await _service.markAsRead(index);
    } catch (e) {
      debugPrint("Error marking notification read at index $index: $e");
    }
  }
}
