import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/features/audio_play/controllers/audio_stories_controller.dart';
import 'package:masti_adda_app/features/audio_play/models/audio_story_model.dart';
import 'package:masti_adda_app/features/audio_play/repositories/audio_repository.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/utils/helpers.dart';

class AudioDetailController extends GetxController {
  final AudioRepository _repository = AudioRepository();

  final Rxn<AudioStoryModel> story = Rxn<AudioStoryModel>();
  final RxBool isLoading = true.obs;
  final RxBool showFullDescription = false.obs;
  final RxList<AudioStoryModel> moreLikeThis = <AudioStoryModel>[].obs;
  final RxString storyId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is AudioStoryModel) {
      story.value = args;
      storyId.value = args.id;
      isLoading.value = false;
      if (args.episodes.isEmpty && args.id.isNotEmpty) {
        fetchStoryDetail(args.id);
      } else {
        fetchMoreLikeThis();
      }
    } else if (args is String) {
      storyId.value = args;
      if (Get.isRegistered<AudioStoriesController>()) {
        try {
          final cached = Get.find<AudioStoriesController>().getStoryById(args);
          if (cached != null) {
            story.value = cached;
            isLoading.value = false;
          }
        } catch (_) {}
      }
      fetchStoryDetail(storyId.value);
    } else if (args is Map) {
      if (args['story'] is AudioStoryModel) {
        story.value = args['story'];
        storyId.value = story.value!.id;
        isLoading.value = false;
      } else if (args['id'] != null) {
        storyId.value = args['id'].toString();
      } else if (args['storyId'] != null) {
        storyId.value = args['storyId'].toString();
      }
      if (story.value == null && storyId.value.isNotEmpty && Get.isRegistered<AudioStoriesController>()) {
        try {
          final cached = Get.find<AudioStoriesController>().getStoryById(storyId.value);
          if (cached != null) {
            story.value = cached;
            isLoading.value = false;
          }
        } catch (_) {}
      }
      if (storyId.value.isNotEmpty) {
        fetchStoryDetail(storyId.value);
      } else {
        isLoading.value = false;
      }
    } else {
      isLoading.value = false;
    }
  }

  Future<void> fetchStoryDetail(String id) async {
    if (id.isEmpty) return;
    try {
      if (story.value == null) {
        isLoading.value = true;
      }
      final result = await _repository.getAudioStoryDetail(id);
      if (result != null) {
        story.value = result;
      }

      // If episodes are still empty, try fetching them separately
      if (story.value == null || story.value!.episodes.isEmpty) {
        final episodes = await _repository.fetchAudioEpisodes(id);
        if (episodes.isNotEmpty) {
          if (story.value != null) {
            story.value = story.value!.copyWith(
              episodes: episodes,
              totalEpisodes: episodes.length,
            );
          } else {
            // Create a basic story model if none exists
            story.value = AudioStoryModel(
              id: id,
              title: 'Audio Story',
              episodes: episodes,
              totalEpisodes: episodes.length,
            );
          }
        }
      }
      await fetchMoreLikeThis();
    } catch (e) {
      debugPrint("fetchStoryDetail error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMoreLikeThis() async {
    try {
      final current = story.value;
      final stories = await _repository.getAudioStories(
        categoryId: current?.categoryId,
        limit: 6,
      );
      moreLikeThis.assignAll(
        stories.where((s) => s.id != current?.id).toList(),
      );
    } catch (e) {
      debugPrint("fetchMoreLikeThis error: $e");
    }
  }

  void toggleDescription() {
    showFullDescription.value = !showFullDescription.value;
  }

  void onPlayNow(BuildContext context) {
    final current = story.value;
    if (current == null) return;

    if (current.episodes.isNotEmpty) {
      final firstEp = current.episodes.first;
      if (!checkPlayable(context, isPremium: firstEp.isPremium, title: firstEp.title)) {
        return;
      }
      Get.toNamed(
        AppRoutes.audioPlayer,
        arguments: {
          'story': current,
          'storyId': current.id,
          'episodeIndex': 0,
        },
      );
    } else {
      Get.toNamed(
        AppRoutes.audioPlayer,
        arguments: {
          'story': current,
          'storyId': current.id,
          'episodeIndex': 0,
        },
      );
    }
  }

  void playEpisode(BuildContext context, int index) {
    final current = story.value;
    if (current == null || index >= current.episodes.length) return;

    final ep = current.episodes[index];
    if (!checkPlayable(context, isPremium: ep.isPremium, title: ep.title)) {
      return;
    }

    Get.toNamed(
      AppRoutes.audioPlayer,
      arguments: {
        'story': current,
        'storyId': current.id,
        'episodeIndex': index,
      },
    );
  }

  void onMoreLikeThisTap(AudioStoryModel s) {
    Get.toNamed(AppRoutes.audioDetail, arguments: s.id.isNotEmpty ? s.id : s, preventDuplicates: false);
  }

  Future<void> toggleLike() async {
    final current = story.value;
    if (current == null || current.id.isEmpty) return;
    final res = await _repository.toggleLike(current.id);
    if (res != null && res.success) {
      story.value = current.copyWith(likes: res.totalLikes);
    }
  }

  Future<void> toggleDislike() async {
    final current = story.value;
    if (current == null || current.id.isEmpty) return;
    final res = await _repository.toggleDislike(current.id);
    if (res != null && res.success) {
      story.value = current.copyWith(likes: res.totalLikes);
    }
  }
}
