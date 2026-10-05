import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/profile/controllers/subscription_status_controller.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/utils/text_style.dart';

/// Checks whether a given path or URL represents a local file on the device storage.
bool isLocalFilePath(String? path) {
  if (path == null || path.trim().isEmpty) return false;
  final clean = path.trim();
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return false;
  }
  if (clean.startsWith('file://') ||
      clean.startsWith('/data/') ||
      clean.startsWith('/storage/') ||
      clean.startsWith('/sdcard/') ||
      clean.startsWith('/var/') ||
      clean.startsWith('/private/') ||
      RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(clean)) {
    return true;
  }
  try {
    return File(clean).existsSync();
  } catch (_) {
    return false;
  }
}

/// Formats media URLs to ensure relative paths from backend (e.g. /uploads/...)
/// are properly prefixed with AppUrl.baseUrl.
/// Preserves local device file paths untouched so offline media plays correctly.
String formatMediaUrl(String? url) {
  if (url == null || url.trim().isEmpty) return '';
  final trimmed = url.trim();

  // Preserves local device file paths untouched so offline media plays correctly.
  if (isLocalFilePath(trimmed)) {
    return trimmed;
  }

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    // Upgrade http to https for golidoli domain to prevent mixed-content blocking on web
    if (trimmed.startsWith('http://api.mastiadda.com') ||
        trimmed.startsWith('http://mastiadda.com')) {
      return trimmed.replaceFirst('http://', 'https://');
    }
    // Fix any localhost or local IP URLs coming from test databases
    if (trimmed.contains('localhost') ||
        trimmed.contains('127.0.0.1') ||
        trimmed.contains('192.168.')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        return '${AppUrl.baseUrl}${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
      }
    }
    return trimmed;
  }

  if (trimmed.startsWith('/')) {
    return '${AppUrl.baseUrl}$trimmed';
  }
  return '${AppUrl.baseUrl}/$trimmed';
}

/// Returns standard HTTP headers required by CDNs (such as Bunny Stream)
/// for playing video streams smoothly and preventing 403 Forbidden errors.
Map<String, String> getVideoPlayerHeaders([String? url]) {
  return const {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': '*/*',
    'Referer': 'https://mastiadda.com/',
    'Origin': 'https://mastiadda.com',
  };
}

/// Checks if content can be downloaded.
/// If content is premium and user is unsubscribed, shows a subscription bottom sheet prompt and returns false.
bool checkDownloadable(
  BuildContext context, {
  required bool isPremium,
  String? title,
}) {
  if (!isPremium) return true;

  final subController = Get.isRegistered<SubscriptionStatusController>()
      ? Get.find<SubscriptionStatusController>()
      : Get.put(SubscriptionStatusController());
  if (subController.isPremiumUser.value) {
    return true;
  }

  showPremiumPrompt(
    context,
    title: title,
    description: title != null
        ? '“$title” is premium content. Subscribe to a Premium Plan to download and watch offline.'
        : 'This content is premium. Subscribe to a Premium Plan to download and watch offline.',
  );
  return false;
}

/// Checks if content is playable.
/// If content is premium and user is unsubscribed, shows a subscription bottom sheet prompt and returns false.
bool checkPlayable(
  BuildContext context, {
  required bool isPremium,
  String? title,
}) {
  if (!isPremium) return true;

  final subController = Get.isRegistered<SubscriptionStatusController>()
      ? Get.find<SubscriptionStatusController>()
      : Get.put(SubscriptionStatusController());
  if (subController.isPremiumUser.value) {
    return true;
  }

  showPremiumPrompt(context, title: title);
  return false;
}

/// Shows a beautiful premium upgrade prompt bottom sheet.
void showPremiumPrompt(
  BuildContext context, {
  String? title,
  String? description,
}) {
  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 50),
      decoration: const BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.borderColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(
            Icons.stars_rounded,
            color: AppColors.primaryColor,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'Premium Content',
            style: text18(fontWeight: FontWeight.bold, color: AppColors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            description ??
                (title != null
                    ? '“$title” is a premium title. Subscribe to a Premium Plan to unlock this and all other movies, series, and micro dramas!'
                    : 'This content is premium. Subscribe to a Premium Plan to unlock this and all other movies, series, and micro dramas!'),
            style: text13(color: AppColors.secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: text14(
                          color: AppColors.secondaryTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Get.back();
                    Get.toNamed(AppRoutes.subscription);
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentColor, Color(0xFFFF5E97)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Subscribe Now',
                        style: text14(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
    isScrollControlled: true,
  );
}
