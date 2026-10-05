import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/audio_play/controllers/audio_player_controller.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class AudioMiniPlayer extends StatelessWidget {
  final bool withSystemPadding;

  const AudioMiniPlayer({super.key, this.withSystemPadding = false});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AudioPlayerController>()) {
      return const SizedBox.shrink();
    }

    final controller = AudioPlayerController.to;
    final bottomPad = withSystemPadding
        ? MediaQuery.of(context).padding.bottom
        : 0.0;

    return Obx(() {
      if (!controller.isMiniPlayerVisible.value || !controller.hasActiveAudio) {
        return SizedBox(height: bottomPad);
      }

      final ep = controller.currentEpisode;
      final story = controller.story.value;
      final imageUrl = ep?.imageUrl.isNotEmpty == true
          ? ep!.imageUrl
          : (story?.imageUrl ?? '');

      final hasNext =
          story != null &&
          controller.currentEpisodeIndex.value < story.episodes.length - 1;
      final hasPrev = controller.currentEpisodeIndex.value > 0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.audioPlayer),
            child: Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A1A00), Color(0xFF1C1C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, -2),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Main Row ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
                      child: Row(
                        children: [
                          // ── Thumbnail with glow ──────────────────────────
                          _buildThumbnail(imageUrl),
                          const SizedBox(width: 10),

                          // ── Title & Subtitle ─────────────────────────────
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ep?.title.isNotEmpty == true
                                      ? ep!.title
                                      : story?.title ?? 'Audio Story',
                                  style: text13(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.headphones_rounded,
                                      size: 11,
                                      color: AppColors.primaryColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        story?.title ?? 'Now Playing',
                                        style: text10(
                                          color: AppColors.secondaryTextColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ── Controls Row: Prev + Play/Pause + Next + Close ──
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _CtrlBtn(
                                icon: Icons.skip_previous_rounded,
                                size: 22,
                                color: hasPrev
                                    ? AppColors.white
                                    : AppColors.hintTextColor,
                                onPressed: hasPrev
                                    ? controller.playPrevious
                                    : null,
                              ),
                              // Play/Pause — highlighted circle
                              GestureDetector(
                                onTap: controller.togglePlayPause,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryColor
                                            .withValues(alpha: 0.5),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: (controller.isLoadingAudio.value && !controller.isPlaying.value)
                                      ? const Padding(
                                          padding: EdgeInsets.all(9),
                                          child: CircularProgressIndicator(
                                            color: AppColors.black,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Icon(
                                          controller.isPlaying.value
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: AppColors.black,
                                          size: 22,
                                        ),
                                ),
                              ),
                              _CtrlBtn(
                                icon: Icons.skip_next_rounded,
                                size: 22,
                                color: hasNext
                                    ? AppColors.white
                                    : AppColors.hintTextColor,
                                onPressed: hasNext ? controller.playNext : null,
                              ),
                              const SizedBox(width: 2),
                              GestureDetector(
                                onTap: controller.closeMiniPlayer,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.hintTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Seekable Progress Bar ────────────────────────────────
                    _SeekBar(controller: controller),
                  ],
                ),
              ),
            ),
          ),
          // System nav bar padding
          SizedBox(height: bottomPad),
        ],
      );
    });
  }

  Widget _buildThumbnail(String imageUrl) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF2B2000),
      child: const Center(
        child: Icon(
          Icons.headphones_rounded,
          color: AppColors.primaryColor,
          size: 22,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slim seekable progress bar at bottom of mini player
// ─────────────────────────────────────────────────────────────────────────────
class _SeekBar extends StatefulWidget {
  final AudioPlayerController controller;
  const _SeekBar({required this.controller});

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final progress = _dragValue ?? widget.controller.progress;
      return SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2.5,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
          thumbColor: AppColors.primaryColor,
          activeTrackColor: AppColors.primaryColor,
          inactiveTrackColor: AppColors.cardColor,
          overlayColor: AppColors.primaryColor.withValues(alpha: 0.2),
        ),
        child: Slider(
          value: progress.clamp(0.0, 1.0),
          min: 0.0,
          max: 1.0,
          onChanged: (v) => setState(() => _dragValue = v),
          onChangeEnd: (v) {
            final targetSec = v * widget.controller.totalDuration.value;
            widget.controller.seekTo(targetSec);
            setState(() => _dragValue = null);
          },
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact icon button
// ─────────────────────────────────────────────────────────────────────────────
class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback? onPressed;

  const _CtrlBtn({
    required this.icon,
    required this.size,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Icon(icon, size: size, color: color),
      ),
    );
  }
}
