import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/audio_play/controllers/audio_player_controller.dart';
import 'package:masti_adda_app/features/audio_play/services/audio_download_service.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late final AudioPlayerController controller;

  @override
  void initState() {
    super.initState();
    controller = AudioPlayerController.to;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.handleArguments(Get.arguments);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Obx(() {
        final story = controller.story.value;
        final currentEp = controller.currentEpisode;

        if (story == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHero(controller, story, currentEp)),
            SliverToBoxAdapter(child: _buildNowPlaying(controller, story, currentEp)),
            SliverToBoxAdapter(child: _buildProgressBar(controller)),
            SliverToBoxAdapter(child: _buildPlayerControls(controller)),
            if (story.episodes.isNotEmpty)
              SliverToBoxAdapter(child: _buildEpisodesList(controller, story)),
            SliverToBoxAdapter(child: _buildBackToHome()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      }),
    );
  }

  Widget _buildHero(
    AudioPlayerController controller,
    dynamic story,
    dynamic currentEp,
  ) {
    final imageUrl = currentEp?.imageUrl.isNotEmpty == true
        ? currentEp!.imageUrl
        : (story?.imageUrl ?? '');

    return Stack(
      children: [
        // Cover image
        SizedBox(
          height: 250,
          width: double.infinity,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 250,
              color: AppColors.cardColor,
              child: const Center(
                child: Icon(
                  Icons.headphones_rounded,
                  color: AppColors.hintTextColor,
                  size: 60,
                ),
              ),
            ),
          ),
        ),
        // Gradient overlay
        Container(
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.backgroundColor.withValues(alpha: 0.95),
              ],
            ),
          ),
        ),
        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppBackButton(isOverlay: true),
                  Column(
                    children: [
                      Text(
                        story?.title ?? 'Audio Story',
                        style: text13(fontWeight: FontWeight.bold),
                      ),
                      if (currentEp != null)
                        Text(
                          'Episode ${currentEp.episodeNumber}',
                          style: text10(color: AppColors.secondaryTextColor),
                        ),
                    ],
                  ),
                  // Download Button
                  _buildDownloadButton(currentEp, story),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton(dynamic currentEp, dynamic story) {
    if (currentEp == null) {
      return const SizedBox(width: 36);
    }

    return Obx(() {
      final downloadService = AudioDownloadService.to;
      final epId = currentEp.id.toString();
      final isDownloaded = downloadService.isDownloaded(epId);
      final isDownloading = downloadService.isDownloading(epId);
      final progress = downloadService.getProgress(epId);

      if (isDownloading) {
        return Container(
          width: 34,
          height: 34,
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: AppColors.overlayColor,
            shape: BoxShape.circle,
          ),
          child: CircularProgressIndicator(
            value: progress > 0 ? progress : null,
            strokeWidth: 2.5,
            color: AppColors.primaryColor,
          ),
        );
      }

      return GestureDetector(
        onTap: () {
          if (isDownloaded) {
            downloadService.removeDownload(epId);
          } else if (story != null) {
            final isEpPrem = currentEp.isPremium || story.isPremium;
            if (!checkDownloadable(
              context,
              isPremium: isEpPrem,
              title: currentEp.title.isNotEmpty ? currentEp.title : story.title,
            )) {
              return;
            }
            downloadService.downloadEpisode(currentEp, story);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppColors.overlayColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDownloaded ? Icons.download_done_rounded : Icons.download_rounded,
            color: isDownloaded ? AppColors.primaryColor : AppColors.white,
            size: 18,
          ),
        ),
      );
    });
  }

  Widget _buildNowPlaying(
    AudioPlayerController controller,
    dynamic story,
    dynamic currentEp,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Text(
            currentEp?.title ?? 'Playing Audio',
            style: text20(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${story?.title ?? ''} – Episode ${currentEp?.episodeNumber ?? 1}',
            style: text13(color: AppColors.secondaryTextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(AudioPlayerController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Obx(() {
        final total = controller.totalDuration.value > 0 ? controller.totalDuration.value : 1.0;
        final sliderValue = controller.seekValue.value.clamp(0.0, total);

        return Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.primaryColor,
                inactiveTrackColor: AppColors.surfaceColor,
                thumbColor: AppColors.primaryColor,
                overlayColor: AppColors.primaryColor.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: sliderValue,
                min: 0.0,
                max: total,
                onChanged: (val) {
                  controller.onSeekChanged(val);
                },
                onChangeEnd: (val) {
                  controller.seekTo(val);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    controller.currentPositionFormatted,
                    style: text11(color: AppColors.hintTextColor),
                  ),
                  Text(
                    controller.totalDurationFormatted,
                    style: text11(color: AppColors.hintTextColor),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPlayerControls(AudioPlayerController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Obx(() {
        final story = controller.story.value;
        final hasNext = story != null && controller.currentEpisodeIndex.value < story.episodes.length - 1;
        final hasPrev = controller.currentEpisodeIndex.value > 0;
        final isPlaying = controller.isPlaying.value;
        final isLoading = controller.isLoadingAudio.value && !isPlaying;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous Episode
            IconButton(
              onPressed: hasPrev ? controller.playPrevious : null,
              icon: Icon(
                Icons.skip_previous_rounded,
                color: hasPrev ? AppColors.white : AppColors.hintTextColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),

            // Replay 10s
            IconButton(
              onPressed: () => controller.skipBackward(10),
              icon: const Icon(
                Icons.replay_10_rounded,
                color: AppColors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Play / Pause / Loading
            isLoading
                ? Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(18),
                    child: const CircularProgressIndicator(
                      color: AppColors.black,
                      strokeWidth: 3,
                    ),
                  )
                : GestureDetector(
                    onTap: controller.togglePlayPause,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: AppColors.black,
                        size: 36,
                      ),
                    ),
                  ),
            const SizedBox(width: 16),

            // Forward 10s
            IconButton(
              onPressed: () => controller.skipForward(10),
              icon: const Icon(
                Icons.forward_10_rounded,
                color: AppColors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),

            // Next Episode
            IconButton(
              onPressed: hasNext ? controller.playNext : null,
              icon: Icon(
                Icons.skip_next_rounded,
                color: hasNext ? AppColors.white : AppColors.hintTextColor,
                size: 32,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEpisodesList(
    AudioPlayerController controller,
    dynamic story,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Episodes', style: text16(fontWeight: FontWeight.bold)),
              Text(
                '${story.episodes.length} Episodes',
                style: text12(color: AppColors.hintTextColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: story.episodes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final ep = story.episodes[index];
              return Obx(() {
                final isSelected = controller.currentEpisodeIndex.value == index;

                return GestureDetector(
                  onTap: () => controller.selectEpisode(index),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor.withValues(alpha: 0.12)
                          : AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.borderColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.surfaceColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isSelected && controller.isPlaying.value
                                ? const Icon(
                                    Icons.graphic_eq_rounded,
                                    color: AppColors.black,
                                    size: 18,
                                  )
                                : Text(
                                    '${ep.episodeNumber}',
                                    style: text12(
                                      color: isSelected ? AppColors.black : AppColors.secondaryTextColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ep.title,
                                style: text13(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.primaryColor : AppColors.textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ep.durationSeconds ~/ 60}:${(ep.durationSeconds % 60).toString().padLeft(2, '0')} mins',
                                style: text10(color: AppColors.secondaryTextColor),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? (controller.isPlaying.value
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded)
                              : Icons.play_circle_outline_rounded,
                          color: isSelected ? AppColors.primaryColor : AppColors.hintTextColor,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackToHome() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: GestureDetector(
        onTap: () => Get.offAllNamed(AppRoutes.home),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.home_rounded, color: AppColors.secondaryTextColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Back to Home',
                  style: text13(
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
