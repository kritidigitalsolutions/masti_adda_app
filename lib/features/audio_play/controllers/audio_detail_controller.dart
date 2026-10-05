import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    if (args is String) {
      storyId.value = args;
      fetchStoryDetail(storyId.value);
    } else if (args is AudioStoryModel) {
      story.value = args;
      storyId.value = args.id;
      if (args.episodes.isEmpty && args.id.isNotEmpty) {
        fetchStoryDetail(args.id);
      } else {
        isLoading.value = false;
        fetchMoreLikeThis();
      }
    } else if (args is Map && args['id'] != null) {
      storyId.value = args['id'].toString();
      fetchStoryDetail(storyId.value);
    }
  }

  Future<void> fetchStoryDetail(String id) async {
    if (id.isEmpty) return;
    try {
      isLoading.value = true;
      final result = await _repository.getAudioStoryDetail(id);
      if (result != null) {
        story.value = result;
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
