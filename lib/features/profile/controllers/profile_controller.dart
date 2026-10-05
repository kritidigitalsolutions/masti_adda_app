import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/core/services/app_download_service.dart';
import 'package:masti_adda_app/features/audio_play/models/audio_story_model.dart';
import 'package:masti_adda_app/features/micro_drama/models/episode_detail_response.dart';
import 'package:masti_adda_app/features/micro_drama/views/micro_drama_player_screen.dart';
import 'package:masti_adda_app/features/movie/views/movie_player_screen.dart';
import 'package:masti_adda_app/features/auth/models/response/user_model.dart';
import 'package:masti_adda_app/features/auth/repositories/auth_datasource.dart';
import 'package:masti_adda_app/features/profile/controllers/help_controller.dart';
import 'package:masti_adda_app/features/profile/controllers/notification_settings_controller.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/utils/text_style.dart';

import 'package:masti_adda_app/features/home/controllers/ai_reels_controller.dart';
import '../../../core/services/storage_service.dart';

// =================================────────────────────────────────────────────
// 1. Profile Controller
// =================================────────────────────────────────────────────
class ProfileController extends GetxController {
  final RxString selectedLanguage = 'English'.obs;

  final List<Map<String, dynamic>> menuItems = [
    {'icon': 'edit', 'label': 'Edit Profile'},
    {'icon': 'subscription', 'label': 'Subscription'},
    {'icon': 'language', 'label': 'Language', 'trailing': 'English'},
    {'icon': 'download', 'label': 'Downloads'},
    {'icon': 'content', 'label': 'Content Preference'},
    {'icon': 'settings', 'label': 'Notifications Settings'},
    {'icon': 'privacy', 'label': 'Privacy Policy'},
    {'icon': 'terms', 'label': 'Terms & Conditions'},
    {'icon': "FAQ's", 'label': "FAQ's"},
    {'icon': 'refund', 'label': 'Refund Policy'},
  ];

  void onMenuTap(String label) {
    final routes = {
      'Edit Profile': AppRoutes.editProfile,
      'Subscription': AppRoutes.subscription,
      'Language': AppRoutes.language,
      'Downloads': AppRoutes.downloads,
      'Content Preference': AppRoutes.contentPreference,
      'Notifications Settings': AppRoutes.notificationSettings,
      'Privacy Policy': AppRoutes.privacyPolicy,
      'Terms & Conditions': AppRoutes.termsConditions,
      "FAQ's": AppRoutes.faq,
      'Refund Policy': AppRoutes.refundPolicy,
    };

    final route = routes[label];
    if (route != null) {
      Get.toNamed(route);
    }
  }

  void onLogOut() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: AppColors.accentColor,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text('Log Out', style: text18(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to log out from Masti Adda?',
                style: text13(color: AppColors.secondaryTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.borderColor.withOpacity(0.5),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: text13(
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
                      onTap: () async {
                        await StorageService.logout();
                        if (Get.isRegistered<AiReelsController>()) {
                          Get.find<AiReelsController>().resetState();
                          Get.delete<AiReelsController>(force: true);
                        }
                        Get.back();
                        print("token deleted!");
                        Get.offAllNamed(AppRoutes.login);
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Log Out',
                            style: text13(
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
            ],
          ),
        ),
      ),
    );
  }

  final AuthDatasource _datasource = AuthDatasource();

  /// Loading State
  final RxBool isLoading = false.obs;

  /// User Data
  final Rxn<UserModel> user = Rxn<UserModel>();

  /// Error Message
  final RxString error = "".obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
    NotificationSettingsController.to.fetchSettings(silent: true);
    HelpController.to;
  }

  Future<void> fetchProfile() async {
    try {
      // Load cached user instantly to avoid UI delay
      final cachedUser = await StorageService.getUser();
      if (cachedUser != null) {
        user.value = cachedUser;
      }

      isLoading.value = user.value == null;
      error.value = "";

      final result = await _datasource.fetchProfile();

      if (result != null) {
        user.value = result;
      } else if (user.value == null) {
        error.value = "Unable to fetch profile.";
      }
    } catch (e) {
      debugPrint("Profile Controller Error: $e");
      if (user.value == null) {
        error.value = e.toString();
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh Profile
  Future<void> refreshProfile() async {
    await fetchProfile();
  }

  /// Update locally using copyWith()
  void updateUser(UserModel updatedUser) {
    user.value = updatedUser;
  }

  /// Example
  void updateName(String name) {
    if (user.value == null) return;

    user.value = user.value!.copyWith(name: name);
  }

  void updateProfileImage(String image) {
    if (user.value == null) return;

    user.value = user.value!.copyWith(profileImage: image);
  }
}

// =================================────────────────────────────────────────────
// 2. Content Preference Controller
// =================================────────────────────────────────────────────
class ContentPreferenceController extends GetxController {
  final genres = const ['Romance', 'Thriller', 'Drama', 'Action', 'Comedy'];
  final contentTypes = const ['Movies', 'Web Series', 'Micro Dramas'];
  final RxSet<String> selectedPreferences = <String>{
    'Romance',
    'Drama',
    'Movies',
  }.obs;

  void togglePreference(String value) {
    if (selectedPreferences.contains(value)) {
      selectedPreferences.remove(value);
    } else {
      selectedPreferences.add(value);
    }
  }

  void savePreference() {
    Get.snackbar('Preferences Updated', 'Your content choices are saved.');
  }
}

// =================================────────────────────────────────────────────
// 3. Downloads Controller
// =================================────────────────────────────────────────────
class DownloadsController extends GetxController {
  AppDownloadService get appDownload => AppDownloadService.to;

  final RxString selectedCategory = 'All'.obs;
  final List<String> categories = const ['All', 'Audio', 'Movies', 'Web Series', 'Micro Drama'];

  List<DownloadedMediaItem> get filteredDownloads {
    final cat = selectedCategory.value;
    if (cat == 'Audio') return appDownload.audioDownloads;
    if (cat == 'Movies') return appDownload.movieDownloads;
    if (cat == 'Web Series') return appDownload.webSeriesDownloads;
    if (cat == 'Micro Drama') return appDownload.microDramaDownloads;
    return appDownload.downloadedItems;
  }

  void selectCategory(String cat) {
    selectedCategory.value = cat;
  }

  void removeDownload(String id) {
    appDownload.removeDownload(id);
  }

  void playDownloadedItem(BuildContext context, DownloadedMediaItem item) {
    switch (item.mediaType) {
      case DownloadMediaType.audio:
        final ep = AudioEpisodeModel(
          id: item.id,
          title: item.title,
          storyId: item.extra['storyId']?.toString() ?? '',
          storyTitle: item.parentTitle,
          storyCoverImage: item.coverImage,
          episodeNumber: item.episodeNumber,
          durationSeconds: item.durationSeconds,
          audioUrl: item.localFilePath,
          coverImage: item.coverImage,
        );
        final story = AudioStoryModel(
          id: item.extra['storyId']?.toString() ?? item.id,
          title: item.parentTitle.isNotEmpty ? item.parentTitle : 'Audio Story',
          coverImage: item.coverImage,
          episodes: [ep],
        );
        Get.toNamed(
          AppRoutes.audioPlayer,
          arguments: {
            'story': story,
            'storyId': story.id,
            'episodeId': item.id,
            'episode': ep,
          },
        );
        break;

      case DownloadMediaType.movie:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MoviePlayerScreen(
              videoUrl: item.localFilePath,
              title: item.title,
              contentId: item.id,
              contentType: 'movie',
            ),
          ),
        );
        break;

      case DownloadMediaType.webSeries:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MoviePlayerScreen(
              videoUrl: item.localFilePath,
              title: item.title,
              contentId: item.extra['seriesId']?.toString() ?? item.id,
              contentType: 'series',
              episodeId: item.id,
            ),
          ),
        );
        break;

      case DownloadMediaType.microDrama:
        final dramaId = item.extra['dramaId']?.toString() ?? '';
        final dramaEpisodes = appDownload.microDramaDownloads
            .where((d) => dramaId.isNotEmpty
                ? (d.extra['dramaId']?.toString() == dramaId)
                : (d.parentTitle.isNotEmpty && d.parentTitle == item.parentTitle))
            .toList();

        final listToUse = dramaEpisodes.isNotEmpty ? dramaEpisodes : [item];
        listToUse.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

        final offlineEpisodes = listToUse.map((d) {
          return MicroDramaEpisode(
            id: d.id,
            tvShowId: dramaId.isNotEmpty ? dramaId : d.id,
            episodeNumber: d.episodeNumber,
            title: d.title,
            description: '',
            videoUrl: d.localFilePath,
            thumbnail: d.coverImage,
            duration: d.durationSeconds.toString(),
            isPremium: false,
            isLocked: false,
            isVertical: true,
            views: 0,
            likes: 0,
            createdAt: d.downloadedAt.toIso8601String(),
            updatedAt: d.downloadedAt.toIso8601String(),
            version: 1,
          );
        }).toList();

        final selectedIndex = listToUse.indexWhere((d) => d.id == item.id);
        final initialIndex = selectedIndex >= 0 ? selectedIndex : 0;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MicroDramaPlayerScreen(
              dramaId: dramaId.isNotEmpty ? dramaId : item.id,
              initialIndex: initialIndex,
              offlineEpisodes: offlineEpisodes,
            ),
          ),
        );
        break;
    }
  }
}

// =================================────────────────────────────────────────────
// 5. Language Controller
// =================================────────────────────────────────────────────
class LanguageController extends GetxController {
  final languages = const ['English', 'Hindi', 'Tamil', 'Telugu', 'Bengali'];
  final RxString selectedLanguage = 'English'.obs;

  void selectLanguage(String language) {
    selectedLanguage.value = language;
  }
}
