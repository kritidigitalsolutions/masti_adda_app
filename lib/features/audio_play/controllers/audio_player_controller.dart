import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/features/audio_play/models/audio_story_model.dart';
import 'package:masti_adda_app/features/audio_play/repositories/audio_repository.dart';
import 'package:masti_adda_app/features/audio_play/services/audio_download_service.dart';
import 'package:masti_adda_app/features/audio_play/services/audio_handler.dart';
import 'package:masti_adda_app/features/profile/controllers/subscription_status_controller.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerController extends GetxController {
  static AudioPlayerController get to {
    if (!Get.isRegistered<AudioPlayerController>()) {
      return Get.put(AudioPlayerController(), permanent: true);
    }
    return Get.find<AudioPlayerController>();
  }

  final AudioRepository _repository = AudioRepository();

  // The audio_service handler — set from main.dart after AudioService.init()
  static GolodoliAudioHandler? _handler;
  static void setHandler(GolodoliAudioHandler handler) {
    _handler = handler;
  }

  GolodoliAudioHandler get _audio {
    assert(_handler != null, 'AudioService not initialized. Call AudioService.init() first.');
    return _handler!;
  }

  // ─── Reactive state ───────────────────────────────────────────────────────
  final Rxn<AudioStoryModel> story = Rxn<AudioStoryModel>();
  final RxInt currentEpisodeIndex = 0.obs;
  final RxBool isPlaying = false.obs;
  final RxBool isLoadingAudio = false.obs;
  final RxDouble currentPosition = 0.0.obs; // in seconds
  final RxDouble totalDuration = 0.0.obs;   // in seconds
  final RxDouble seekValue = 0.0.obs;
  final RxBool isUserSeeking = false.obs;
  final RxString currentStreamingUrl = ''.obs;
  final RxBool isMiniPlayerVisible = false.obs;

  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _customEventSub;
  Timer? _progressSaveTimer;

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
  }

  @override
  void onClose() {
    _saveProgress();
    _progressSaveTimer?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _customEventSub?.cancel();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Listeners directly from audio player streams (zero latency & no time jumps)
  // ─────────────────────────────────────────────────────────────────────────

  void _setupListeners() {
    if (_handler == null) return;

    // 1. Real-time position stream
    _positionSub = _audio.positionStream.listen((pos) {
      final posSec = pos.inSeconds.toDouble();
      currentPosition.value = posSec;
      if (!isUserSeeking.value) {
        seekValue.value = posSec;
      }
    });

    // 2. Real-time duration stream
    _durationSub = _audio.durationStream.listen((dur) {
      if (dur != null && dur.inSeconds > 0) {
        totalDuration.value = dur.inSeconds.toDouble();
      }
    });

    // 3. Player state (playing + buffering/loading)
    _stateSub = _audio.playerStateStream.listen((state) {
      isPlaying.value = state.playing;

      final isBuffering = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;

      // Only show loading if buffering and not currently playing
      isLoadingAudio.value = isBuffering;
    });

    // 4. Custom events from notification (Next / Prev / Completed)
    _customEventSub = _audio.customEvent.listen((event) {
      if (event is Map && event['action'] != null) {
        final action = event['action'] as String;
        final index = event['index'] as int? ?? currentEpisodeIndex.value;
        if (action == 'skipToNext' || action == 'skipToPrevious' || action == 'skipToQueueItem') {
          _loadEpisodeAtIndex(index);
        } else if (action == 'episodeCompleted') {
          _onEpisodeCompleted();
        }
      }
    });

    // 5. Periodic progress saver
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (isPlaying.value) _saveProgress();
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────────────────

  AudioEpisodeModel? get currentEpisode {
    final s = story.value;
    if (s != null && s.episodes.isNotEmpty && currentEpisodeIndex.value < s.episodes.length) {
      return s.episodes[currentEpisodeIndex.value];
    }
    return null;
  }

  bool get hasActiveAudio => story.value != null && currentEpisode != null;

  String get currentPositionFormatted => _formatDuration(currentPosition.value.toInt());
  String get totalDurationFormatted   => _formatDuration(totalDuration.value.toInt());

  double get progress =>
      totalDuration.value > 0 ? (currentPosition.value / totalDuration.value).clamp(0.0, 1.0) : 0.0;

  // ─────────────────────────────────────────────────────────────────────────
  // Route argument handler — called when AudioPlayerScreen opens
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> handleArguments(dynamic args) async {
    if (args == null) return;

    int initialEpisodeIndex = 0;
    int initialProgressSeconds = 0;
    AudioStoryModel? incomingStory;
    AudioEpisodeModel? incomingEpisode;
    String? incomingStoryId;
    String? incomingEpisodeId;

    if (args is AudioStoryModel) {
      incomingStory = args;
    } else if (args is Map) {
      if (args['story'] is AudioStoryModel) {
        incomingStory = args['story'] as AudioStoryModel;
      }
      if (args['episode'] is AudioEpisodeModel) {
        incomingEpisode = args['episode'] as AudioEpisodeModel;
      }
      if (args['storyId'] != null) incomingStoryId = args['storyId'].toString();
      if (args['episodeId'] != null) incomingEpisodeId = args['episodeId'].toString();
      if (args['episodeIndex'] != null) initialEpisodeIndex = args['episodeIndex'] as int;
      if (args['progressSeconds'] != null) initialProgressSeconds = args['progressSeconds'] as int;
    }

    // If incoming request is a different story or episode, instantly stop previous sound & reset UI
    final bool isDifferentTarget = (incomingStoryId != null && story.value?.id != incomingStoryId) ||
        (incomingStory != null && story.value?.id != incomingStory.id);

    if (isDifferentTarget) {
      _audio.pause();
      isPlaying.value = false;
      isLoadingAudio.value = true;
      currentPosition.value = initialProgressSeconds.toDouble();
      seekValue.value = initialProgressSeconds.toDouble();
    }

    // Fetch story detail if missing or if episodes list is empty
    final String targetStoryId = incomingStoryId ?? incomingStory?.id ?? incomingEpisode?.storyId ?? '';
    if ((incomingStory == null || incomingStory.episodes.isEmpty) && targetStoryId.isNotEmpty) {
      final detail = await _repository.getAudioStoryDetail(targetStoryId);
      if (detail != null) {
        incomingStory = detail;
      }
    }

    // Fallback if detail fetch failed but episode is provided
    if (incomingStory == null && incomingEpisode != null) {
      incomingStory = AudioStoryModel(
        id: incomingEpisode.storyId,
        title: incomingEpisode.storyTitle.isNotEmpty ? incomingEpisode.storyTitle : 'Audio Story',
        coverImage: incomingEpisode.storyCoverImage.isNotEmpty ? incomingEpisode.storyCoverImage : incomingEpisode.coverImage,
        episodes: [incomingEpisode],
      );
    } else if (incomingStory != null && incomingStory.episodes.isEmpty && incomingEpisode != null) {
      incomingStory = incomingStory.copyWith(episodes: [incomingEpisode]);
    }

    if (incomingStory != null) {
      if (incomingEpisodeId != null && incomingStory.episodes.isNotEmpty) {
        final epIdx = incomingStory.episodes.indexWhere((e) => e.id == incomingEpisodeId);
        if (epIdx >= 0) initialEpisodeIndex = epIdx;
      }

      final isSameStory = story.value?.id == incomingStory.id;
      final isSameEp = currentEpisodeIndex.value == initialEpisodeIndex;

      story.value = incomingStory;
      isMiniPlayerVisible.value = true;

      // Only load new track if story/episode changed or nothing was streaming
      if (!isSameStory || !isSameEp || (!isPlaying.value && currentStreamingUrl.value.isEmpty)) {
        if (incomingStory.episodes.isNotEmpty) {
          currentEpisodeIndex.value = initialEpisodeIndex.clamp(0, incomingStory.episodes.length - 1);
          await loadAndPlayEpisode(
            incomingStory.episodes[currentEpisodeIndex.value],
            startPositionSeconds: initialProgressSeconds,
          );
        }
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Core playback methods
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadAndPlayEpisode(AudioEpisodeModel episode, {int startPositionSeconds = 0}) async {
    try {
      // 0. Enforce Subscription Access Control for Premium Episodes / Stories
      final isPremiumEpisode = episode.isPremium ||
          (story.value?.isPremium ?? false) ||
          episode.isLocked;
      if (isPremiumEpisode) {
        final subController = Get.isRegistered<SubscriptionStatusController>()
            ? Get.find<SubscriptionStatusController>()
            : Get.put(SubscriptionStatusController());
        if (!subController.isPremiumUser.value) {
          _audio.pause();
          isPlaying.value = false;
          isLoadingAudio.value = false;
          if (Get.context != null) {
            showPremiumPrompt(Get.context!, title: episode.title);
          }
          return;
        }
      }

      // 1. INSTANTLY STOP previous playback (0ms delay) so previous audio never lingers!
      _audio.pause();
      isPlaying.value = false;
      isLoadingAudio.value = true;
      isMiniPlayerVisible.value = true;

      // 2. INSTANTLY RESET time & progress UI (0ms delay)
      final initialPos = startPositionSeconds > 0 ? startPositionSeconds.toDouble() : 0.0;
      currentPosition.value = initialPos;
      seekValue.value = initialPos;
      totalDuration.value = episode.durationSeconds > 0 ? episode.durationSeconds.toDouble() : 0.0;

      // 3. Save previous progress asynchronously in background (do NOT await/block track switch)
      unawaited(_saveProgress());

      // 4. Check if downloaded locally for offline playback or resolve remote URL
      String resolvedUrl = '';
      if (Get.isRegistered<AudioDownloadService>()) {
        final localPath = AudioDownloadService.to.getLocalFilePath(episode.id);
        if (localPath != null && localPath.isNotEmpty) {
          resolvedUrl = localPath;
        }
      }

      if (resolvedUrl.isEmpty) {
        String audioStreamUrl = episode.audioUrl;
        if (audioStreamUrl.isEmpty) {
          final fetchedUrl = await _repository.playAudioEpisode(episode.id);
          if (fetchedUrl != null && fetchedUrl.isNotEmpty) {
            audioStreamUrl = fetchedUrl;
          }
        }
        resolvedUrl = formatMediaUrl(audioStreamUrl);
      }
      currentStreamingUrl.value = resolvedUrl;

      // 5. If progress not provided and episode has saved progress, use it
      if (startPositionSeconds <= 0 && episode.progressSeconds > 0) {
        startPositionSeconds = episode.progressSeconds;
        currentPosition.value = startPositionSeconds.toDouble();
        seekValue.value = startPositionSeconds.toDouble();
      }

      // 6. Build MediaItem for system notification & lock screen
      final storyData = story.value;
      final artUri = (storyData != null && storyData.coverImage.isNotEmpty)
          ? Uri.tryParse(storyData.coverImage)
          : null;

      final mediaItem = MediaItem(
        id: episode.id,
        title: episode.title.isNotEmpty ? episode.title : 'Episode ${currentEpisodeIndex.value + 1}',
        artist: (storyData != null && storyData.narrator.isNotEmpty)
            ? storyData.narrator
            : (storyData?.author ?? ''),
        album: storyData?.title ?? '',
        artUri: artUri,
        duration: episode.durationSeconds > 0
            ? Duration(seconds: episode.durationSeconds)
            : null,
        extras: {'episodeIndex': currentEpisodeIndex.value},
      );

      // Build full queue for notification next/prev support
      final queueItems = storyData?.episodes.map((ep) {
        return MediaItem(
          id: ep.id,
          title: ep.title.isNotEmpty ? ep.title : 'Episode',
          album: storyData.title,
          artUri: artUri,
          duration: ep.durationSeconds > 0 ? Duration(seconds: ep.durationSeconds) : null,
        );
      }).toList();

      if (resolvedUrl.isNotEmpty) {
        await _audio.loadAndPlay(
          url: resolvedUrl,
          item: mediaItem,
          queue: queueItems,
          queueIndex: currentEpisodeIndex.value,
          startPosition: Duration(seconds: startPositionSeconds),
        );
      }
    } catch (e) {
      debugPrint('loadAndPlayEpisode error: $e');
    } finally {
      if (_audio.isPlaying) {
        isLoadingAudio.value = false;
      }
    }
  }

  void togglePlayPause() async {
    if (isPlaying.value) {
      await _audio.pause();
      _saveProgress();
    } else {
      if (currentStreamingUrl.value.isNotEmpty) {
        await _audio.play();
      } else if (currentEpisode != null) {
        await loadAndPlayEpisode(currentEpisode!);
      }
    }
  }

  void closeMiniPlayer() {
    _saveProgress();
    _audio.stop();
    isPlaying.value = false;
    isMiniPlayerVisible.value = false;
    currentStreamingUrl.value = '';
  }

  void seekTo(double seconds) {
    currentPosition.value = seconds;
    seekValue.value = seconds;
    isUserSeeking.value = false;
    _audio.seek(Duration(seconds: seconds.toInt()));
    _saveProgress();
  }

  void onSeekChanged(double seconds) {
    isUserSeeking.value = true;
    seekValue.value = seconds;
  }

  void skipForward([int seconds = 10]) {
    final max = totalDuration.value;
    final newPos = (currentPosition.value + seconds).clamp(0.0, max > 0 ? max : 9999.0);
    seekTo(newPos);
  }

  void skipBackward([int seconds = 10]) {
    final newPos = (currentPosition.value - seconds).clamp(0.0, totalDuration.value);
    seekTo(newPos);
  }

  void playNext() {
    final s = story.value;
    if (s != null && currentEpisodeIndex.value < s.episodes.length - 1) {
      final nextIdx = currentEpisodeIndex.value + 1;
      currentEpisodeIndex.value = nextIdx;
      loadAndPlayEpisode(s.episodes[nextIdx]);
    }
  }

  void playPrevious() {
    final s = story.value;
    if (s != null && currentEpisodeIndex.value > 0) {
      final prevIdx = currentEpisodeIndex.value - 1;
      currentEpisodeIndex.value = prevIdx;
      loadAndPlayEpisode(s.episodes[prevIdx]);
    }
  }

  void selectEpisode(int index) {
    final s = story.value;
    if (s != null && index >= 0 && index < s.episodes.length) {
      if (currentEpisodeIndex.value == index && (isPlaying.value || currentStreamingUrl.value.isNotEmpty)) {
        togglePlayPause();
        return;
      }
      currentEpisodeIndex.value = index;
      loadAndPlayEpisode(s.episodes[index]);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _loadEpisodeAtIndex(int index) {
    final s = story.value;
    if (s != null && index >= 0 && index < s.episodes.length) {
      currentEpisodeIndex.value = index;
      loadAndPlayEpisode(s.episodes[index]);
    }
  }

  Future<void> _saveProgress() async {
    final ep = currentEpisode;
    if (ep == null || ep.id.isEmpty) return;
    final prog = currentPosition.value.toInt();
    final dur  = totalDuration.value.toInt();
    if (prog <= 0) return;
    await _repository.saveAudioProgress(
      episodeId: ep.id,
      progressSeconds: prog,
      durationSeconds: dur > 0 ? dur : ep.durationSeconds,
    );
  }

  Future<void> _onEpisodeCompleted() async {
    final ep = currentEpisode;
    if (ep != null && ep.id.isNotEmpty) {
      await _repository.markEpisodeCompleted(ep.id);
    }
    // Auto advance
    playNext();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
