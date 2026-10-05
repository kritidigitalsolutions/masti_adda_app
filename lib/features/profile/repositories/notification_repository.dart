import 'package:flutter/foundation.dart';
import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';

class NotificationRepository {
  final NetworkApiService _apiService = NetworkApiService();

  /// 📡 Upload FCM Token to Backend
  Future<dynamic> uploadFcmToken(String fcmToken) async {
    try {
      return await _apiService.postApi(AppUrl.fcmToken, {
        'fcmToken': fcmToken,
      });
    } catch (e) {
      debugPrint("Error in uploadFcmToken: $e");
      return {"success": false, "message": e.toString()};
    }
  }

  /// 📥 Fetch Notifications list from Backend
  Future<dynamic> fetchNotifications() async {
    try {
      return await _apiService.getApi(AppUrl.notifications);
    } catch (e) {
      debugPrint("Error in fetchNotifications: $e");
      return null;
    }
  }

  /// 📥 Fetch Unread Notifications Count from Backend
  Future<dynamic> fetchUnreadCount() async {
    try {
      return await _apiService.getApi(AppUrl.unreadNotificationsCount);
    } catch (e) {
      debugPrint("Error in fetchUnreadCount: $e");
      return null;
    }
  }

  /// ✅ Mark Single Notification as Read
  Future<dynamic> markNotificationRead(String id) async {
    try {
      return await _apiService.pacthApi(
        AppUrl.markNotificationRead(id),
        {},
      );
    } catch (e) {
      debugPrint("Error in markNotificationRead: $e");
      return {"success": false, "message": e.toString()};
    }
  }

  /// ✅ Mark All Notifications as Read
  Future<dynamic> markAllNotificationsRead() async {
    try {
      return await _apiService.pacthApi(
        AppUrl.markAllNotificationsRead,
        {},
      );
    } catch (e) {
      debugPrint("Error in markAllNotificationsRead: $e");
      return {"success": false, "message": e.toString()};
    }
  }

  /// ❌ Delete Single Notification
  Future<dynamic> deleteNotification(String id) async {
    try {
      return await _apiService.deleteApi(
        AppUrl.deleteNotification(id),
        {},
      );
    } catch (e) {
      debugPrint("Error in deleteNotification: $e");
      return {"success": false, "message": e.toString()};
    }
  }

  /// ⚙️ Get Notification Settings Preferences
  Future<dynamic> getNotificationSettings() async {
    try {
      return await _apiService.getApi(AppUrl.notificationSettings);
    } catch (e) {
      debugPrint("Error in getNotificationSettings: $e");
      return null;
    }
  }

  /// ⚙️ Update Notification Settings Preferences
  Future<dynamic> updateNotificationSettings(Map<String, dynamic> body) async {
    try {
      return await _apiService.pacthApi(
        AppUrl.notificationSettings,
        body,
      );
    } catch (e) {
      debugPrint("Error in updateNotificationSettings: $e");
      return {"success": false, "message": e.toString()};
    }
  }
}
