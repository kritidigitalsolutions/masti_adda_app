import 'dart:convert' as convert;
import 'dart:io';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';
import 'package:masti_adda_app/core/services/storage_service.dart';
import 'package:masti_adda_app/features/auth/models/request/user_payload.dart';
import 'package:masti_adda_app/features/auth/models/response/user_model.dart';
import 'package:masti_adda_app/features/auth/models/intro_screen_model.dart';

class AuthDatasource {
  final NetworkApiService _apiService = NetworkApiService();

  void setToken(String token) {
    _apiService.setToken(token);
  }

  Future<IntroScreenResponse?> fetchIntroScreens() async {
    try {
      final response = await _apiService.getApi(AppUrl.introScreens);
      if (response != null) {
        return IntroScreenResponse.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint("Fetch Intro Screens Error: $e");
      return null;
    }
  }

  Future<bool> sendOtp({required String phone}) async {
    try {
      final response = await _apiService.postApi(AppUrl.sendOtp, {
        'phone': phone,
      });
      if (response != null) {
        debugPrint("Send OTP Response: $response");
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to send OTP: $e');
      return false;
    }
  }

  Future<VerifyOtpResult> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await _apiService.postApi(AppUrl.verifyOtp, {
        "phone": phone,
        "otp": otp,
      });

      if (response != null) {
        final token = response["token"] ?? "";
        if (token.isNotEmpty) {
          await StorageService.saveToken(token);
          _apiService.setToken(token);
        }
        await StorageService.saveLoginMethod('phone');

        UserModel? userModel;
        Map<String, dynamic>? userData;
        if (response["user"] is Map) {
          userData = Map<String, dynamic>.from(response["user"]);
          userData["authProvider"] = "phone";
          userModel = UserModel.fromJson(userData);
          await StorageService.saveUser(userModel);
        }

        final bool isNewUser = response["isNewUser"] == true ||
            (userData != null && userData["isNewUser"] == true) ||
            response["newUser"] == true ||
            (userData != null && userData["newUser"] == true) ||
            response["isRegistered"] == false ||
            (userData != null && userData["isRegistered"] == false);

        final bool isExplicitlyIncomplete =
            (userData != null &&
                (userData["profileComplete"] == false ||
                    userData["isProfileComplete"] == false ||
                    userData["profileCompleted"] == false)) ||
            response["profileComplete"] == false ||
            response["isProfileComplete"] == false ||
            response["profileCompleted"] == false;

        final bool hasExplicitProfileComplete =
            (userData != null &&
                (userData["profileComplete"] == true ||
                    userData["isProfileComplete"] == true ||
                    userData["profileCompleted"] == true)) ||
            response["profileComplete"] == true ||
            response["isProfileComplete"] == true ||
            response["profileCompleted"] == true;

        final rawName = userModel?.name.trim() ?? '';
        final bool hasValidCustomName = rawName.isNotEmpty &&
            rawName.toLowerCase() != 'user' &&
            rawName.toLowerCase() != 'new user' &&
            rawName.toLowerCase() != 'mastiadda user' &&
            rawName != userModel?.phone.trim() &&
            rawName != phone.trim();

        final bool profileComplete = !isNewUser &&
            !isExplicitlyIncomplete &&
            (hasExplicitProfileComplete || hasValidCustomName);

        return VerifyOtpResult(
          success: true,
          profileComplete: profileComplete,
          isNewUser: isNewUser,
          token: token,
          message: response["message"]?.toString(),
          user: userModel,
          rawUser: userData,
        );
      }

      return VerifyOtpResult.failure();
    } catch (e) {
      debugPrint("Verify OTP Error: $e");
      return VerifyOtpResult.failure(e.toString());
    }
  }

  Future<VerifyOtpResult> googleLogin({
    required String idToken,
    String? accessToken,
    String? email,
    String? name,
    String? photoUrl,
    String? googleId,
    String? fcmToken,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "idToken": idToken,
        "token": idToken,
        if (accessToken != null && accessToken.isNotEmpty) "accessToken": accessToken,
        if (email != null && email.isNotEmpty) "email": email,
        if (name != null && name.isNotEmpty) "name": name,
        if (photoUrl != null && photoUrl.isNotEmpty) "photoUrl": photoUrl,
        if (googleId != null && googleId.isNotEmpty) "googleId": googleId,
        if (fcmToken != null && fcmToken.isNotEmpty) "fcmToken": fcmToken,
      };

      debugPrint("Sending Google Login Payload: $body");
      final response = await _apiService.postApi(AppUrl.googleLogin, body);

      if (response != null) {
        final token = response["token"] ?? "";
        if (token.isNotEmpty) {
          await StorageService.saveToken(token);
          _apiService.setToken(token);
        }
        await StorageService.saveLoginMethod('google');

        UserModel? userModel;
        Map<String, dynamic>? userData;
        if (response["user"] is Map) {
          userData = Map<String, dynamic>.from(response["user"]);
          userData["authProvider"] = "google";
          userModel = UserModel.fromJson(userData);
          await StorageService.saveUser(userModel);
        }

        final bool isNewUser = response["isNewUser"] == true ||
            (userData != null && userData["isNewUser"] == true) ||
            response["newUser"] == true ||
            (userData != null && userData["newUser"] == true) ||
            response["isRegistered"] == false ||
            (userData != null && userData["isRegistered"] == false);

        final bool isExplicitlyIncomplete =
            (userData != null &&
                (userData["profileComplete"] == false ||
                    userData["isProfileComplete"] == false ||
                    userData["profileCompleted"] == false)) ||
            response["profileComplete"] == false ||
            response["isProfileComplete"] == false ||
            response["profileCompleted"] == false;

        final bool hasExplicitProfileComplete =
            (userData != null &&
                (userData["profileComplete"] == true ||
                    userData["isProfileComplete"] == true ||
                    userData["profileCompleted"] == true)) ||
            response["profileComplete"] == true ||
            response["isProfileComplete"] == true ||
            response["profileCompleted"] == true;

        final rawName = userModel?.name.trim() ?? '';
        final bool hasValidCustomName = rawName.isNotEmpty &&
            rawName.toLowerCase() != 'user' &&
            rawName.toLowerCase() != 'new user' &&
            rawName.toLowerCase() != 'mastiadda user' &&
            rawName != userModel?.phone.trim() &&
            rawName != (userModel?.email.trim() ?? '');

        final bool profileComplete = !isNewUser &&
            !isExplicitlyIncomplete &&
            (hasExplicitProfileComplete || hasValidCustomName);

        return VerifyOtpResult(
          success: response["success"] == true || token.isNotEmpty,
          profileComplete: profileComplete,
          isNewUser: isNewUser,
          token: token,
          message: response["message"]?.toString(),
          user: userModel,
          rawUser: userData,
        );
      }

      return VerifyOtpResult.failure("Invalid response from server");
    } catch (e) {
      debugPrint("Google Login Error: $e");
      return VerifyOtpResult.failure(e.toString());
    }
  }

  Future<bool> completeProfile({required UserPayload userPayload}) async {
    try {
      final response = await _apiService.postApi(
        AppUrl.completeProfile,
        userPayload.toJson(),
      );

      if (response != null) {
        final String token = response["token"]?.toString() ??
            response["user"]?["token"]?.toString() ??
            response["data"]?["token"]?.toString() ??
            "";
        if (token.isNotEmpty) {
          await StorageService.saveToken(token);
          _apiService.setToken(token);
        }
        await StorageService.saveLoginMethod('phone');

        if (response["user"] is Map) {
          final userData = Map<String, dynamic>.from(response["user"]);
          userData["authProvider"] = "phone";
          final userModel = UserModel.fromJson(userData);
          await StorageService.saveUser(userModel);
        } else {
          await fetchProfile();
        }
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("Complete Profile Error: $e");
      return false;
    }
  }

  Future<UserModel?> fetchProfile() async {
    try {
      final response = await _apiService.getApi(AppUrl.fetchProfile);
      if (response != null && response["user"] != null) {
        final userData = Map<String, dynamic>.from(response["user"]);
        final String ap = (userData["authProvider"] ??
                userData["provider"] ??
                userData["authType"] ??
                userData["loginType"] ??
                "")
            .toString();
        if (ap.isEmpty) {
          final savedMethod = await StorageService.getLoginMethod();
          if (savedMethod != null && savedMethod.isNotEmpty) {
            userData["authProvider"] = savedMethod;
          }
        }
        final userModel = UserModel.fromJson(userData);
        await StorageService.saveUser(userModel);
        return userModel;
      }
      return null;
    } catch (e) {
      debugPrint("Fetch Profile Error: $e");
      return null;
    }
  }

  Future<UserModel?> updateProfile({required UserPayload userPayload}) async {
    try {
      final formDataMap = <String, dynamic>{};
      final data = userPayload.toJson();

      data.forEach((key, value) {
        if (key == "profileImage" || value == null) return;
        if (value is List) {
          formDataMap[key] = convert.jsonEncode(value);
        } else {
          formDataMap[key] = value.toString();
        }
      });

      final profileImage = userPayload.profileImage;
      if (profileImage != null && profileImage.isNotEmpty) {
        final isLocalFile =
            !profileImage.startsWith("http") &&
            !profileImage.startsWith("https");

        if (isLocalFile) {
          final file = File(profileImage);
          if (await file.exists()) {
            debugPrint("🖼️ Attaching file: $profileImage");
            formDataMap["profileImage"] = await dio.MultipartFile.fromFile(
              profileImage,
              filename: profileImage.split('/').last,
            );
          } else {
            formDataMap["profileImage"] = profileImage;
          }
        } else {
          formDataMap["profileImage"] = profileImage;
        }
      }

      final formData = dio.FormData.fromMap(formDataMap);
      final response = await _apiService.pacthApi(
        AppUrl.updateProfile,
        formData,
      );

      if (response != null && response.containsKey("user")) {
        final updatedUser = UserModel.fromJson(response["user"]);
        await StorageService.saveUser(updatedUser);
        return updatedUser;
      }
      return null;
    } catch (e) {
      debugPrint("❌ Update Profile Error: $e");
      rethrow;
    }
  }

  Future<WebsiteLoginResult?> websiteLogin() async {
    try {
      debugPrint("🌐 Calling Website Login API at URL => ${AppUrl.websiteLogin}");
      final response = await _apiService.postApi(AppUrl.websiteLogin, {});
      if (response != null) {
        UserModel? userModel;
        Map<String, dynamic>? userData;
        if (response["user"] is Map) {
          userData = Map<String, dynamic>.from(response["user"]);
          userModel = UserModel.fromJson(userData);
          await StorageService.saveUser(userModel);
        }
        final bool success = response["success"] == true ||
            response["status"] == "success" ||
            userModel != null ||
            response["token"] != null;
        return WebsiteLoginResult(
          success: success,
          user: userModel,
          message: response["message"]?.toString(),
        );
      }
      return WebsiteLoginResult.failure("Invalid response from server");
    } catch (e) {
      debugPrint("❌ Website Login Error: $e");
      return WebsiteLoginResult.failure(e.toString());
    }
  }
}

class WebsiteLoginResult {
  final bool success;
  final UserModel? user;
  final String? message;

  WebsiteLoginResult({
    required this.success,
    this.user,
    this.message,
  });

  factory WebsiteLoginResult.failure([String? message]) {
    return WebsiteLoginResult(
      success: false,
      message: message,
    );
  }
}

class VerifyOtpResult {
  final bool success;
  final bool profileComplete;
  final bool isNewUser;
  final String? message;
  final String? token;
  final UserModel? user;
  final Map<String, dynamic>? rawUser;

  VerifyOtpResult({
    required this.success,
    required this.profileComplete,
    this.isNewUser = false,
    this.message,
    this.token,
    this.user,
    this.rawUser,
  });

  factory VerifyOtpResult.failure([String? message]) {
    return VerifyOtpResult(
      success: false,
      profileComplete: false,
      isNewUser: false,
      message: message,
    );
  }
}
