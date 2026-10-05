import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/core/services/app_download_service.dart';
import 'package:masti_adda_app/features/micro_drama/controllers/continue_watching_controller.dart';
import 'package:masti_adda_app/features/micro_drama/controllers/micro_drama_controller.dart';
import 'package:masti_adda_app/features/micro_drama/models/episode_detail_response.dart';
import 'package:masti_adda_app/features/profile/controllers/subscription_status_controller.dart';
import 'package:masti_adda_app/features/profile/controllers/watchlist_controller.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:video_player/video_player.dart';

String formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

class MicroDramaPlayerScreen extends StatefulWidget {
  final String dramaId;
  final int initialIndex;
  final int? initialPositionSeconds;
  final List<MicroDramaEpisode>? offlineEpisodes;

  const MicroDramaPlayerScreen({
    super.key,
    required this.dramaId,
    this.initialIndex = 0,
    this.initialPositionSeconds,
    this.offlineEpisodes,
  });

  @override
  State<MicroDramaPlayerScreen> createState() => _MicroDramaPlayerScreenState();
}

class _MicroDramaPlayerScreenState extends State<MicroDramaPlayerScreen> {
  late final PageController _pageController;
  late final MicroDramaController _controller;
  late final ContinueWatchingController _cwController;
  final RxInt currentIndex = 0.obs;
  final RxSet<int> likedIndices = <int>{}.obs;

  // Stable per-index keys so we can explicitly command play/pause on the
  // exact item, regardless of build/scroll timing.
  final Map<int, GlobalKey<_DramaReelItemState>> _itemKeys = {};

  GlobalKey<_DramaReelItemState> _keyFor(int index) {
    return _itemKeys.putIfAbsent(index, () => GlobalKey<_DramaReelItemState>());
  }

  @override
  void initState() {
    super.initState();
    // Strictly lock orientation to vertical portrait for micro drama
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    currentIndex.value = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _controller = Get.isRegistered<MicroDramaController>()
        ? Get.find<MicroDramaController>()
        : Get.put(MicroDramaController());
    _cwController = Get.isRegistered<ContinueWatchingController>()
        ? Get.find<ContinueWatchingController>()
        : Get.put(ContinueWatchingController());

    if (widget.offlineEpisodes == null || widget.offlineEpisodes!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.episodeDetail.value == null ||
            _controller.episodeDetail.value?.episodes.isEmpty == true) {
          _controller.fetchEpisodeDetail(widget.dramaId);
        }
      });
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  void _onPageChanged(int index) {
    currentIndex.value = index;
    // The new current page is guaranteed to be mounted by now — command
    // play explicitly instead of relying on didUpdateWidget/init race.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyFor(index).currentState?.ensurePlaying();
    });
  }

  void _toggleLike(int index) {
    if (likedIndices.contains(index)) {
      likedIndices.remove(index);
    } else {
      likedIndices.add(index);
    }
  }

  void _onBack() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    Navigator.of(context).maybePop();
  }

  void _onEpisodeComplete(int index, int totalEpisodes) {
    if (index + 1 < totalEpisodes) {
      final nextIndex = index + 1;
      _pageController
          .animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          )
          .then((_) {
            // Safety net in case onPageChanged's post-frame call raced with
            // the video still initializing.
            _keyFor(nextIndex).currentState?.ensurePlaying();
          });
    } else {
      // Last episode finished — auto back
      _onBack();
    }
  }

  Widget _buildEpisodeList(List<MicroDramaEpisode> episodes) {
    return SafeArea(
      child: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: episodes.length,
        onPageChanged: _onPageChanged,
        controller: _pageController,
        itemBuilder: (_, index) {
          final episode = episodes[index];
          final isInitialItem = widget.initialIndex == index;
          return _DramaReelItem(
            key: _keyFor(index),
            episode: episode,
            dramaId: widget.dramaId,
            episodeIndex: index,
            totalEpisodes: episodes.length,
            isActive: currentIndex.value == index,
            isLiked: likedIndices.contains(index),
            onToggleLike: () => _toggleLike(index),
            onBack: _onBack,
            cwController: _cwController,
            initialPositionSeconds: isInitialItem
                ? widget.initialPositionSeconds
                : null,
            onEpisodeComplete: () =>
                _onEpisodeComplete(index, episodes.length),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.offlineEpisodes != null && widget.offlineEpisodes!.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.black,
        body: _buildEpisodeList(widget.offlineEpisodes!),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Obx(() {
        if (_controller.episodeDetailStatus.value == Status.loading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accentColor),
          );
        }

        if (_controller.episodeDetailStatus.value == Status.error ||
            _controller.episodeDetail.value == null) {
          final downloaded = AppDownloadService.to.microDramaDownloads
              .where((d) =>
                  d.extra['dramaId']?.toString() == widget.dramaId ||
                  d.id == widget.dramaId)
              .toList();

          if (downloaded.isNotEmpty) {
            downloaded.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
            final offline = downloaded.map((d) {
              return MicroDramaEpisode(
                id: d.id,
                tvShowId: widget.dramaId,
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
            return _buildEpisodeList(offline);
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load episodes',
                  style: text15(color: AppColors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _controller.fetchEpisodeDetail(widget.dramaId);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final episodes = _controller.episodeDetail.value!.episodes;
        if (episodes.isEmpty) {
          return const Center(
            child: Text(
              'No episodes available',
              style: TextStyle(color: AppColors.white),
            ),
          );
        }

        return _buildEpisodeList(episodes);
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reel Item
// ─────────────────────────────────────────────────────────────────────────────
class _DramaReelItem extends StatefulWidget {
  final MicroDramaEpisode episode;
  final String dramaId;
  final int episodeIndex;
  final int totalEpisodes;
  final bool isActive;
  final bool isLiked;
  final VoidCallback onToggleLike;
  final VoidCallback onBack;
  final VoidCallback onEpisodeComplete;
  final ContinueWatchingController cwController;
  final int? initialPositionSeconds;

  const _DramaReelItem({
    super.key,
    required this.episode,
    required this.dramaId,
    required this.episodeIndex,
    required this.totalEpisodes,
    required this.isActive,
    required this.isLiked,
    required this.onToggleLike,
    required this.onBack,
    required this.onEpisodeComplete,
    required this.cwController,
    this.initialPositionSeconds,
  });

  @override
  State<_DramaReelItem> createState() => _DramaReelItemState();
}

class _DramaReelItemState extends State<_DramaReelItem> {
  late VideoPlayerController _vpc;
  final RxBool isInitialized = false.obs;
  final RxBool showPlayPauseIcon = false.obs;
  final RxBool showControls = true.obs;
  final RxBool isMuted = false.obs;
  final RxBool isInWatchlist = false.obs;
  final RxBool isDownloaded = false.obs;

  Timer? _hideControlsTimer;
  Timer? _progressTimer; // fires every 15 s to save progress
  bool _hasCompleted = false;
  bool _autoPlayPending = false;

  bool get isEpisodeLocked {
    if (AppDownloadService.to.isDownloaded(widget.episode.id) ||
        isLocalFilePath(widget.episode.videoUrl)) {
      return false;
    }
    final subController = Get.isRegistered<SubscriptionStatusController>()
        ? Get.find<SubscriptionStatusController>()
        : Get.put(SubscriptionStatusController());
    final isPrem = widget.episode.isPremium || widget.episode.isLocked;
    return isPrem && !subController.isPremiumUser.value;
  }

  @override
  void initState() {
    super.initState();
    final localPath = AppDownloadService.to.getLocalFilePath(widget.episode.id);
    final isLocal =
        localPath != null &&
        localPath.isNotEmpty &&
        File(localPath).existsSync();

    final isEpLocal = isLocalFilePath(widget.episode.videoUrl);

    if (isLocal) {
      _vpc = VideoPlayerController.file(File(localPath));
    } else if (isEpLocal) {
      final clean = widget.episode.videoUrl.startsWith('file://')
          ? widget.episode.videoUrl.replaceFirst('file://', '')
          : widget.episode.videoUrl;
      _vpc = VideoPlayerController.file(File(clean));
    } else {
      final videoUrl = formatMediaUrl(widget.episode.videoUrl);
      _vpc = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: getVideoPlayerHeaders(videoUrl),
      );
    }

    _vpc
        .initialize()
        .then((_) {
          if (!mounted) return;
          isInitialized.value = true;
          if ((widget.isActive || _autoPlayPending) && !isEpisodeLocked) {
            _autoPlayPending = false;
            _vpc.setLooping(false);
            if (widget.initialPositionSeconds != null &&
                widget.initialPositionSeconds! > 0) {
              final startPos = Duration(
                seconds: widget.initialPositionSeconds!,
              );
              if (startPos < _vpc.value.duration) {
                _vpc.seekTo(startPos);
              }
            }
            _vpc.play();
            _startHideControlsTimer();
            _startProgressTimer();
          }
          _vpc.addListener(_onVideoTick);
        })
        .catchError((err) {
          debugPrint("Error initializing video player: $err");
        });
  }

  /// Explicitly commanded by the parent when this page becomes the current
  /// page (swipe or auto-advance). Deterministic — no reliance on rebuild
  /// timing vs. video-initialize timing.
  void ensurePlaying() {
    if (!mounted) return;
    _hasCompleted = false;
    if (isEpisodeLocked) {
      if (isInitialized.value) _vpc.pause();
      return;
    }
    if (isInitialized.value) {
      _vpc.setLooping(false);
      _vpc.play();
      _startHideControlsTimer();
      _startProgressTimer();
    } else {
      _autoPlayPending = true;
    }
  }

  void _onVideoTick() {
    if (!_vpc.value.isInitialized || _hasCompleted) return;
    final duration = _vpc.value.duration;
    final position = _vpc.value.position;
    if (duration.inMilliseconds > 0 &&
        position.inMilliseconds >= duration.inMilliseconds - 200) {
      _hasCompleted = true;
      _stopProgressTimer();
      // Save ≥ 95% so backend marks as completed
      _saveProgress(forceComplete: true);
      widget.onEpisodeComplete();
    }
  }

  // ── Progress saving ───────────────────────────────────────────────────────

  void _startProgressTimer() {
    _progressTimer?.cancel();
    // Save progress shortly after start (after duration is known)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && isInitialized.value) {
        _saveProgress();
      }
    });
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _saveProgress();
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void _saveProgress({bool forceComplete = false}) {
    if (!isInitialized.value) return;
    final position = _vpc.value.position;
    final duration = _vpc.value.duration;
    if (duration.inSeconds <= 0) return;

    final progressSecs = forceComplete
        ? (duration.inSeconds * 0.96)
              .round() // ensure ≥ 95%
        : position.inSeconds;

    widget.cwController.saveProgress(
      contentId: widget.dramaId,
      contentType: 'microdrama',
      episodeId: widget.episode.id,
      progressSeconds: progressSecs,
      durationSeconds: duration.inSeconds,
    );
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    showControls.value = true;
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (isInitialized.value && _vpc.value.isPlaying) {
        showControls.value = false;
      }
    });
  }

  @override
  void didUpdateWidget(covariant _DramaReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive && isInitialized.value) {
      _vpc.pause();
      _hideControlsTimer?.cancel();
      _stopProgressTimer();
      // Save progress when leaving this episode
      _saveProgress();
      showControls.value = true;
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _stopProgressTimer();
    _saveProgress();
    _vpc.removeListener(_onVideoTick);
    _vpc.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!isInitialized.value) return;
    if (_vpc.value.isPlaying) {
      _vpc.pause();
      _hideControlsTimer?.cancel();
      _stopProgressTimer();
      _saveProgress();
      showControls.value = true;
    } else {
      _vpc.play();
      _startHideControlsTimer();
      _startProgressTimer();
    }
    showPlayPauseIcon.value = true;
    Future.delayed(const Duration(milliseconds: 700), () {
      showPlayPauseIcon.value = false;
    });
  }

  void _toggleMute() {
    isMuted.value = !isMuted.value;
    _vpc.setVolume(isMuted.value ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final episode = widget.episode;
    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Video player or loader ─────────────────────────────────────
          Obx(() {
            if (isInitialized.value) {
              return Center(
                child: AspectRatio(
                  aspectRatio: _vpc.value.aspectRatio,
                  child: VideoPlayer(_vpc),
                ),
              );
            }
            return Container(
              color: AppColors.black,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accentColor),
              ),
            );
          }),

          // ── Tap to Play/Pause ────────────────────────────────────────────
          GestureDetector(
            onTap: _togglePlayPause,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),

          // ── Play/Pause Icon overlay (animated) ────────────────────────────
          Obx(() {
            if (!isInitialized.value) return const SizedBox.shrink();
            return IgnorePointer(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: showPlayPauseIcon.value
                      ? Container(
                          key: ValueKey(_vpc.value.isPlaying),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _vpc.value.isPlaying
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            color: Colors.white,
                            size: 44,
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ),
            );
          }),

          // ── Top Bar: Back button & Episode title ─────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    AppBackButton(
                      isOverlay: true,
                      onPressed: widget.onBack,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(
                        () => AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: showControls.value ? 1.0 : 0.0,
                          child: Text(
                            episode.title.isNotEmpty
                                ? episode.title
                                : 'Micro Drama',
                            style: text14(
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Right side actions (auto-hides) ──────────────────────────────
          Positioned(
            right: 12,
            bottom: 50,
            child: Obx(
              () => AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: showControls.value ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !showControls.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Obx(() {
                        final watchlistCtrl =
                            Get.isRegistered<WatchlistController>()
                            ? Get.find<WatchlistController>()
                            : Get.put(WatchlistController());
                        final isSaved = watchlistCtrl.isItemInWatchlist(
                          widget.dramaId,
                        );

                        return _ActionButton(
                          icon: isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          iconColor: isSaved
                              ? AppColors.primaryColor
                              : AppColors.white,
                          label: isSaved ? 'Saved' : 'Watchlist',
                          onTap: () =>
                              watchlistCtrl.toggleWatchlist(widget.dramaId),
                        );
                      }),
                      const SizedBox(height: 20),
                      Obx(() {
                        final downloadService = AppDownloadService.to;
                        final isDownloaded = downloadService.isDownloaded(
                          widget.episode.id,
                        );
                        final isDownloading = downloadService.isDownloading(
                          widget.episode.id,
                        );
                        final progress = downloadService.getProgress(
                          widget.episode.id,
                        );

                        return _ActionButton(
                          icon: isDownloading
                              ? Icons.hourglass_top_rounded
                              : (isDownloaded
                                    ? Icons.download_done_rounded
                                    : Icons.download_rounded),
                          iconColor: isDownloaded
                              ? AppColors.primaryColor
                              : (isDownloading
                                    ? AppColors.primaryColor
                                    : AppColors.white),
                          label: isDownloading
                              ? '${(progress * 100).toInt()}%'
                              : (isDownloaded ? 'Saved' : 'Download'),
                          onTap: () {
                            if (isDownloaded) {
                              downloadService.removeDownload(widget.episode.id);
                            } else {
                              final dramaController =
                                  Get.isRegistered<MicroDramaController>()
                                  ? Get.find<MicroDramaController>()
                                  : null;
                              final drama = dramaController
                                  ?.dramaDetail
                                  .value
                                  ?.microdrama;
                              final isEpPrem = widget.episode.isPremium ||
                                  widget.episode.isLocked ||
                                  (drama?.isPremium ?? false);

                              if (!checkDownloadable(
                                context,
                                isPremium: isEpPrem,
                                title: widget.episode.title.isNotEmpty
                                    ? widget.episode.title
                                    : drama?.title,
                              )) {
                                return;
                              }

                              downloadService.downloadMedia(
                                id: widget.episode.id,
                                title: widget.episode.title.isNotEmpty
                                    ? widget.episode.title
                                    : 'Episode ${widget.episode.episodeNumber}',
                                parentTitle: drama?.title ?? 'Micro Drama',
                                coverImage: widget.episode.thumbnail.isNotEmpty
                                    ? formatMediaUrl(widget.episode.thumbnail)
                                    : (drama?.poster ?? drama?.banner ?? ''),
                                remoteUrl: widget.episode.videoUrl,
                                mediaType: DownloadMediaType.microDrama,
                                durationSeconds:
                                    int.tryParse(widget.episode.duration) ?? 0,
                                episodeNumber: widget.episode.episodeNumber,
                                extra: {'dramaId': widget.dramaId},
                                isPremium: isEpPrem,
                              );
                            }
                          },
                        );
                      }),
                      const SizedBox(height: 20),
                      Obx(
                        () => _ActionButton(
                          icon: isMuted.value
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          iconColor: AppColors.white,
                          label: isMuted.value ? 'Muted' : 'Sound',
                          onTap: _toggleMute,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom info: episode number / total (always visible) ─────────
          Positioned(
            left: 16,
            right: 70,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ep ${episode.episodeNumber} / ${widget.totalEpisodes}',
                  style: text13(color: AppColors.secondaryTextColor),
                ),
              ],
            ),
          ),

          // ── Progress bar (always visible) ─────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Obx(() {
              if (isInitialized.value) {
                return ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _vpc,
                  builder: (_, val, _) {
                    final progress = val.duration.inMilliseconds > 0
                        ? val.position.inMilliseconds /
                              val.duration.inMilliseconds
                        : 0.0;
                    return LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.accentColor,
                      ),
                      minHeight: 3,
                    );
                  },
                );
              }
              return LinearProgressIndicator(
                value: 0,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation(AppColors.accentColor),
                minHeight: 3,
              );
            }),
          ),

          // ── Premium Lock Overlay ──────────────────────────────────────────
          if (isEpisodeLocked)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.92),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.6),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Colors.amber,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Premium Episode',
                        style: text20(
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Episode ${widget.episode.episodeNumber} is for Premium members. Subscribe now to unlock unlimited streaming.',
                        style: text13(color: AppColors.secondaryTextColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          showPremiumPrompt(
                            context,
                            title: widget.episode.title,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(
                          Icons.stars_rounded,
                          color: Colors.black,
                        ),
                        label: Text(
                          'Unlock with Premium',
                          style: text13(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action button
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 4),
          Text(label, style: text10(color: AppColors.white)),
        ],
      ),
    );
  }
}
