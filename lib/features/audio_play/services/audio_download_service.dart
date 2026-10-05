import 'package:get/get.dart';
import 'package:masti_adda_app/core/services/app_download_service.dart';
import 'package:masti_adda_app/features/audio_play/models/audio_story_model.dart';
import 'package:masti_adda_app/features/audio_play/repositories/audio_repository.dart';

/// Adapter service providing audio-specific helper methods over AppDownloadService.
class AudioDownloadService extends GetxService {
  static AudioDownloadService get to {
    if (!Get.isRegistered<AudioDownloadService>()) {
      return Get.put(AudioDownloadService(), permanent: true);
    }
    return Get.find<AudioDownloadService>();
  }

  AppDownloadService get _appDownload => AppDownloadService.to;
  final AudioRepository _repository = AudioRepository();

  Future<AudioDownloadService> init() async {
    return this;
  }

  bool isDownloaded(String episodeId) => _appDownload.isDownloaded(episodeId);
  bool isDownloading(String episodeId) => _appDownload.isDownloading(episodeId);
  double getProgress(String episodeId) => _appDownload.getProgress(episodeId);
  String? getLocalFilePath(String episodeId) => _appDownload.getLocalFilePath(episodeId);

  List<DownloadedMediaItem> get downloadedEpisodes => _appDownload.audioDownloads;

  Future<void> downloadEpisode(
    AudioEpisodeModel episode,
    AudioStoryModel? story,
  ) async {
    if (episode.id.isEmpty) return;

    // Resolve streaming URL if not present
    String audioUrl = episode.audioUrl;
    if (audioUrl.isEmpty) {
      final fetched = await _repository.playAudioEpisode(episode.id);
      if (fetched != null && fetched.isNotEmpty) {
        audioUrl = fetched;
      }
    }

    final isPrem = episode.isPremium || (story?.isPremium ?? false);

    await _appDownload.downloadMedia(
      id: episode.id,
      title: episode.title.isNotEmpty ? episode.title : 'Episode ${episode.episodeNumber}',
      parentTitle: story?.title ?? episode.storyTitle,
      coverImage: story?.coverImage ?? episode.storyCoverImage,
      remoteUrl: audioUrl,
      mediaType: DownloadMediaType.audio,
      durationSeconds: episode.durationSeconds,
      episodeNumber: episode.episodeNumber,
      extra: {
        'storyId': story?.id ?? episode.storyId,
        'storyTitle': story?.title ?? episode.storyTitle,
        'storyCoverImage': story?.coverImage ?? episode.storyCoverImage,
      },
      isPremium: isPrem,
    );
  }

  Future<void> removeDownload(String episodeId) => _appDownload.removeDownload(episodeId);
}
