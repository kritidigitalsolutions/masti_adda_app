import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:masti_adda_app/features/auth/models/response/user_model.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _likedAiReelsKey = 'liked_ai_reels_ids';
  static const String _likedContentKey = 'liked_content_ids';
  static const String _dislikedContentKey = 'disliked_content_ids';
  static const String _loginMethodKey = 'auth_login_method';
  static const String _pendingTxnIdKey = 'pending_txn_id';
  static const String _pendingPlanIdKey = 'pending_plan_id';
  static const String _pendingPaymentIdKey = 'pending_payment_id';

  // Save pending payment for verification
  static Future<void> savePendingPayment({required String txnId, required String planId, String? paymentId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingTxnIdKey, txnId);
    await prefs.setString(_pendingPlanIdKey, planId);
    if (paymentId != null && paymentId.isNotEmpty) {
      await prefs.setString(_pendingPaymentIdKey, paymentId);
    }
  }

  static Future<Map<String, String>?> getPendingPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final txnId = prefs.getString(_pendingTxnIdKey);
    final planId = prefs.getString(_pendingPlanIdKey);
    final paymentId = prefs.getString(_pendingPaymentIdKey);
    if (txnId != null && txnId.isNotEmpty && planId != null && planId.isNotEmpty) {
      final map = <String, String>{
        'txnId': txnId,
        'planId': planId,
      };
      if (paymentId != null && paymentId.isNotEmpty) {
        map['paymentId'] = paymentId;
      }
      return map;
    }
    return null;
  }

  static Future<void> clearPendingPayment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingTxnIdKey);
    await prefs.remove(_pendingPlanIdKey);
    await prefs.remove(_pendingPaymentIdKey);
  }

  // Save and get login method ('phone' or 'google')
  static Future<void> saveLoginMethod(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_loginMethodKey, method);
  }

  static Future<String?> getLoginMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_loginMethodKey);
  }

  // Save the token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Get the token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Save user model
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // Get user model
  static Future<UserModel?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString(_userKey);
      if (userString != null && userString.isNotEmpty) {
        return UserModel.fromJson(jsonDecode(userString));
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // AI Reels Like Persistence
  static Future<Set<String>> getLikedAiReels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_likedAiReelsKey) ?? [];
      return list.toSet();
    } catch (e) {
      return {};
    }
  }

  static Future<void> setAiReelLiked(String reelId, bool isLiked) async {
    if (reelId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final set = (prefs.getStringList(_likedAiReelsKey) ?? []).toSet();
      if (isLiked) {
        set.add(reelId);
      } else {
        set.remove(reelId);
      }
      await prefs.setStringList(_likedAiReelsKey, set.toList());
    } catch (e) {
      // ignore
    }
  }

  static Future<void> saveLikedAiReels(Set<String> reelIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_likedAiReelsKey, reelIds.toList());
    } catch (e) {
      // ignore
    }
  }

  // General Content (Movies, WebSeries, MicroDrama, Audio) Like & Dislike Persistence
  static Future<Set<String>> getLikedContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_likedContentKey) ?? [];
      return list.toSet();
    } catch (e) {
      return {};
    }
  }

  static Future<void> setContentLiked(String contentId, bool isLiked) async {
    if (contentId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final set = (prefs.getStringList(_likedContentKey) ?? []).toSet();
      if (isLiked) {
        set.add(contentId);
      } else {
        set.remove(contentId);
      }
      await prefs.setStringList(_likedContentKey, set.toList());
    } catch (e) {
      // ignore
    }
  }

  static Future<Set<String>> getDislikedContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_dislikedContentKey) ?? [];
      return list.toSet();
    } catch (e) {
      return {};
    }
  }

  static Future<void> setContentDisliked(String contentId, bool isDisliked) async {
    if (contentId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final set = (prefs.getStringList(_dislikedContentKey) ?? []).toSet();
      if (isDisliked) {
        set.add(contentId);
      } else {
        set.remove(contentId);
      }
      await prefs.setStringList(_dislikedContentKey, set.toList());
    } catch (e) {
      // ignore
    }
  }

  // Delete token & user data (Logout)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_likedAiReelsKey);
    await prefs.remove(_likedContentKey);
    await prefs.remove(_dislikedContentKey);
    await prefs.remove(_loginMethodKey);
  }
}
