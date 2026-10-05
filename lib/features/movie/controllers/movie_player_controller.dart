import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:video_player/video_player.dart';

class MoviePlayerController extends GetxController {
  final qualityUrls = const {
    'Auto': 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    '360p': 'https://sample-videos.com/video321/mp4/360/big_buck_bunny_360p_1mb.mp4',
    '720p': 'https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4',
    '1080p': 'https://sample-videos.com/video321/mp4/1080/big_buck_bunny_1080p_1mb.mp4',
  };

  late VideoPlayerController videoController;

  final RxBool isInitialized = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool showControls = true.obs;
  final RxBool isMuted = false.obs;
  final RxBool isFullscreen = false.obs;
  final RxString selectedQuality = 'Auto'.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;

  @override
  void onInit() {
    super.onInit();
    _initializePlayer(qualityUrls[selectedQuality.value]!);
  }

  Future<void> _initializePlayer(String url, {Duration? seekTo, bool play = true}) async {
    isInitialized.value = false;
    videoController = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: getVideoPlayerHeaders(url),
    );
    await videoController.initialize();
    videoController.addListener(_videoListener);
    duration.value = videoController.value.duration;
    if (seekTo != null) {
      await videoController.seekTo(seekTo);
    }
    if (play) {
      await videoController.play();
    }
    isPlaying.value = videoController.value.isPlaying;
    isInitialized.value = true;
  }

  void _videoListener() {
    if (!videoController.value.isInitialized) return;
    position.value = videoController.value.position;
    duration.value = videoController.value.duration;
    isPlaying.value = videoController.value.isPlaying;
  }

  Future<void> changeQuality(String quality) async {
    if (quality == selectedQuality.value) return;
    final oldPosition = position.value;
    final shouldPlay = isPlaying.value;
    final wasMuted = isMuted.value;
    final oldController = videoController;
    oldController.removeListener(_videoListener);
    await oldController.pause();
    selectedQuality.value = quality;
    await _initializePlayer(qualityUrls[quality]!, seekTo: oldPosition, play: shouldPlay);
    if (wasMuted) {
      await videoController.setVolume(0);
    }
    await oldController.dispose();
  }

  Future<void> togglePlay() async {
    if (!isInitialized.value) return;
    if (videoController.value.isPlaying) {
      await videoController.pause();
    } else {
      await videoController.play();
    }
  }

  Future<void> seekTo(double value) async {
    if (!isInitialized.value) return;
    await videoController.seekTo(Duration(milliseconds: value.round()));
  }

  Future<void> forward() async {
    await videoController.seekTo(position.value + const Duration(seconds: 10));
  }

  Future<void> rewind() async {
    final target = position.value - const Duration(seconds: 10);
    await videoController.seekTo(target.isNegative ? Duration.zero : target);
  }

  Future<void> toggleMute() async {
    isMuted.toggle();
    await videoController.setVolume(isMuted.value ? 0 : 1);
  }

  Future<void> toggleFullscreen() async {
    isFullscreen.toggle();
    if (isFullscreen.value) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  void toggleControls() {
    showControls.toggle();
  }

  String formatDuration(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (value.inHours > 0) {
      return '${value.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void onClose() {
    videoController.removeListener(_videoListener);
    videoController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.onClose();
  }
}
