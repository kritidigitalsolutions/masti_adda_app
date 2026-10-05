import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/home/controllers/ai_reels_controller.dart';
import 'package:masti_adda_app/features/home/controllers/home_controller.dart';
import 'package:masti_adda_app/features/home/models/ai_reel_model.dart';
import 'package:masti_adda_app/features/home/views/widgets/ai_reel_comments_sheet.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class ReelsTab extends StatefulWidget {
  const ReelsTab({super.key});

  @override
  State<ReelsTab> createState() => _ReelsTabState();
}

class _ReelsTabState extends State<ReelsTab> {
  final AiReelsController _reelsController = Get.put(AiReelsController());
  late PageController _pageController;
  Worker? _tabWorker;
  bool _isWheeling = false;
  Timer? _wheelDebounce;

  // Video controller cache: Map<index, VideoPlayerController>
  final Map<int, VideoPlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _reelsController.currentIndex.value,
    );

    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController());

    _tabWorker = ever(homeController.selectedIndex, (index) {
      if (index == 2) {
        _checkAndShowAllWatchedPrompt();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (homeController.selectedIndex.value == 2) {
        _checkAndShowAllWatchedPrompt();
      }
    });
  }

  void _goToNextReel() {
    if (!_pageController.hasClients) return;
    final total = _reelsController.reels.length;
    final current =
        _pageController.page?.round() ?? _reelsController.currentIndex.value;
    if (current < total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToPrevReel() {
    if (!_pageController.hasClients) return;
    final current =
        _pageController.page?.round() ?? _reelsController.currentIndex.value;
    if (current > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      if (_isWheeling) return;
      if (event.scrollDelta.dy > 15) {
        _isWheeling = true;
        _goToNextReel();
        _wheelDebounce?.cancel();
        _wheelDebounce = Timer(const Duration(milliseconds: 350), () {
          _isWheeling = false;
        });
      } else if (event.scrollDelta.dy < -15) {
        _isWheeling = true;
        _goToPrevReel();
        _wheelDebounce?.cancel();
        _wheelDebounce = Timer(const Duration(milliseconds: 350), () {
          _isWheeling = false;
        });
      }
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.pageDown ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _goToNextReel();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.pageUp) {
        _goToPrevReel();
      }
    }
  }

  void _checkAndShowAllWatchedPrompt() {
    if (_reelsController.allWatched.value &&
        _reelsController.reels.isEmpty &&
        !_reelsController.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reelsController.showAllWatchedPrompt();
      });
    }
  }

  @override
  void dispose() {
    _tabWorker?.dispose();
    _pageController.dispose();
    _disposeAllControllers();
    super.dispose();
  }

  void _disposeAllControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  /// Keep only adjacent controllers alive, dispose distant ones
  void _manageControllers(int currentIndex, List<AiReelModel> reels) {
    // Keys to keep: currentIndex - 1, currentIndex, currentIndex + 1
    final keysToKeep = {currentIndex - 1, currentIndex, currentIndex + 1};

    // Dispose old controllers
    final keysToRemove = _controllers.keys
        .where((k) => !keysToKeep.contains(k))
        .toList();
    for (final k in keysToRemove) {
      _controllers[k]?.dispose();
      _controllers.remove(k);
    }

    // Preload next controller (currentIndex + 1)
    if (currentIndex + 1 < reels.length &&
        !_controllers.containsKey(currentIndex + 1)) {
      _initController(
        currentIndex + 1,
        reels[currentIndex + 1],
        autoPlay: false,
      );
    }
  }

  Future<VideoPlayerController?> _initController(
    int index,
    AiReelModel reel, {
    bool autoPlay = false,
  }) async {
    if (reel.fullVideoUrl.isEmpty) return null;
    if (_controllers.containsKey(index)) return _controllers[index];

    try {
      final vpc = VideoPlayerController.networkUrl(
        Uri.parse(reel.fullVideoUrl),
        httpHeaders: getVideoPlayerHeaders(reel.fullVideoUrl),
      );
      _controllers[index] = vpc;

      await vpc.initialize();
      vpc.setLooping(true);

      if (autoPlay && mounted) {
        vpc.play();
      }

      if (mounted) setState(() {});
      return vpc;
    } catch (e) {
      debugPrint("⚠️ Error initializing reel video at index $index: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isLoading = _reelsController.isLoading.value;
      final reels = _reelsController.reels;

      if (isLoading && reels.isEmpty) {
        return const Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.accentColor),
          ),
        );
      }

      if (reels.isEmpty) {
        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: AppColors.hintTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _reelsController.allWatched.value
                        ? "You've watched all Reels!"
                        : "No AI Reels available right now",
                    textAlign: TextAlign.center,
                    style: text16(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _reelsController.allWatched.value
                        ? "Check back later for new reels or replay old ones."
                        : "Please check your connection and try again.",
                    textAlign: TextAlign.center,
                    style: text12(color: AppColors.secondaryTextColor),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_reelsController.allWatched.value) {
                        _reelsController.restartReplay();
                      } else {
                        _reelsController.fetchInitialFeed();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _reelsController.allWatched.value
                          ? 'Watch Again'
                          : 'Refresh',
                      style: text14(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Listener(
        onPointerSignal: _handlePointerSignal,
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            _handleKeyEvent(event);
            return KeyEventResult.ignored;
          },
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                itemCount: reels.length,
                onPageChanged: (i) {
                  _reelsController.onPageChanged(i);
                  _manageControllers(i, reels);
                },
                itemBuilder: (_, index) {
                  final reel = reels[index];

                  return _ReelItem(
                    key: ValueKey(reel.id),
                    reel: reel,
                    index: index,
                    onControllerCreated: (vpc) {
                      _controllers[index] = vpc;
                    },
                    cachedController: _controllers[index],
                    onCompleted: () => _reelsController.recordComplete(reel.id),
                  );
                },
              ),

              // ── Top pills: Trending (floating glassmorphic bar) ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 15),
                        _FeedTogglePill(
                          label: 'Trending',
                          isSelected: true,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Prefetching Indicator (small subtle bar at top if fetching in background)
              if (_reelsController.isFetchingNextBatch.value)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentColor.withValues(alpha: 0.6),
                      ),
                      minHeight: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trending floating pill
// ─────────────────────────────────────────────────────────────────────────────
class _FeedTogglePill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FeedTogglePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isSelected ? 1 : 0.75,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                // Glass background
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                // Glass border
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                label,
                style: text13(
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Reel Item with Preloading and Completion Listener
// ─────────────────────────────────────────────────────────────────────────────
class _ReelItem extends StatefulWidget {
  final AiReelModel reel;
  final int index;
  final VideoPlayerController? cachedController;
  final ValueChanged<VideoPlayerController> onControllerCreated;
  final VoidCallback onCompleted;

  const _ReelItem({
    super.key,
    required this.reel,
    required this.index,
    required this.onControllerCreated,
    required this.onCompleted,
    this.cachedController,
  });

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem> {
  VideoPlayerController? _vpc;
  bool _initialized = false;
  bool _completedTriggered = false;
  bool _showHeartAnimation = false;
  Timer? _heartTimer;
  Worker? _activeWorker;
  Worker? _tabWorker;
  Worker? _muteWorker;

  bool get _isActive {
    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : null;
    final isTabVisible =
        homeController == null || homeController.selectedIndex.value == 2;
    return isTabVisible &&
        AiReelsController.to.currentIndex.value == widget.index;
  }

  void _syncPlayState() {
    if (_initialized && _vpc != null) {
      if (_isActive) {
        _vpc!.setVolume(AiReelsController.to.isMuted.value ? 0.0 : 1.0);
        _vpc!.play();
      } else {
        _vpc!.pause();
      }
    }
  }

  void _onDoubleTap() {
    AiReelsController.to.likeReelIfNotLiked(widget.reel.id);
    _heartTimer?.cancel();
    setState(() {
      _showHeartAnimation = true;
    });
    _heartTimer = Timer(const Duration(milliseconds: 750), () {
      if (mounted) {
        setState(() {
          _showHeartAnimation = false;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _activeWorker = ever(AiReelsController.to.currentIndex, (idx) {
      if (!mounted) return;
      _syncPlayState();
    });

    final homeController = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : null;
    if (homeController != null) {
      _tabWorker = ever(homeController.selectedIndex, (idx) {
        if (!mounted) return;
        _syncPlayState();
      });
    }

    _muteWorker = ever(AiReelsController.to.isMuted, (muted) {
      if (_initialized && _vpc != null) {
        _vpc!.setVolume(muted ? 0.0 : 1.0);
      }
    });

    _setupController();
  }

  void _setupController() {
    final reelsController = AiReelsController.to;
    if (widget.cachedController != null &&
        widget.cachedController!.value.isInitialized) {
      _vpc = widget.cachedController;
      _initialized = true;
      _vpc?.setVolume(reelsController.isMuted.value ? 0.0 : 1.0);
      _attachListener();
      if (_isActive) {
        _vpc?.play();
      }
    } else {
      final videoUrl = widget.reel.fullVideoUrl;
      if (videoUrl.isNotEmpty) {
        _vpc = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
          httpHeaders: getVideoPlayerHeaders(videoUrl),
        );
        widget.onControllerCreated(_vpc!);
        _vpc!
            .initialize()
            .then((_) {
              if (mounted) {
                setState(() => _initialized = true);
                _vpc!.setLooping(true);
                _vpc!.setVolume(reelsController.isMuted.value ? 0.0 : 1.0);
                _attachListener();
                if (_isActive) {
                  _vpc!.play();
                }
              }
            })
            .catchError((e) {
              debugPrint("⚠️ Video load error for ${widget.reel.title}: $e");
            });
      }
    }
  }

  void _attachListener() {
    _vpc?.addListener(_videoListener);
  }

  void _videoListener() {
    if (_vpc == null || !_vpc!.value.isInitialized) return;

    final val = _vpc!.value;
    if (val.duration.inMilliseconds > 0) {
      final pos = val.position.inMilliseconds;
      final dur = val.duration.inMilliseconds;

      // Mark completed when user watches 90%+ of the reel
      if (pos >= dur * 0.9 && !_completedTriggered) {
        _completedTriggered = true;
        widget.onCompleted();
      }
    }
  }

  @override
  void didUpdateWidget(covariant _ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_initialized && _vpc != null) {
      _vpc!.setVolume(AiReelsController.to.isMuted.value ? 0.0 : 1.0);
      _syncPlayState();
    }
  }

  @override
  void dispose() {
    _heartTimer?.cancel();
    _activeWorker?.dispose();
    _tabWorker?.dispose();
    _muteWorker?.dispose();
    _vpc?.removeListener(_videoListener);
    // Note: Do not dispose _vpc directly here if managed in parent cache
    super.dispose();
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final reel = widget.reel;
    final reelsController = AiReelsController.to;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Video Player or Thumbnail Poster
          _initialized && _vpc != null
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _vpc!.value.size.width > 0
                        ? _vpc!.value.size.width
                        : size.width,
                    height: _vpc!.value.size.height > 0
                        ? _vpc!.value.size.height
                        : size.height,
                    child: VideoPlayer(_vpc!),
                  ),
                )
              : Image.network(
                  formatMediaUrl(reel.fullThumbnailUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.cardColor,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentColor,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),

          // 2. Gradient Overlay for text contrast
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.25, 0.55, 1.0],
              ),
            ),
          ),

          // 3. Tap to toggle Play / Pause & Double-tap to Like
          GestureDetector(
            onTap: () {
              if (_initialized && _vpc != null) {
                setState(() {
                  if (_vpc!.value.isPlaying) {
                    _vpc!.pause();
                  } else {
                    _vpc!.play();
                  }
                });
              }
            },
            onDoubleTap: _onDoubleTap,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),

          // 4. Double-tap pop heart animation overlay
          if (_showHeartAnimation)
            IgnorePointer(
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.2, end: 1.25),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: const Icon(
                    Icons.favorite_rounded,
                    size: 110,
                    color: AppColors.accentColor,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 24,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Center Play / Stop (Pause) Indicator
          if (_initialized && _vpc != null)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _vpc!,
              builder: (_, value, _) {
                if (value.isPlaying) return const SizedBox.shrink();
                return Center(
                  child: GestureDetector(
                    onTap: () {
                      _vpc!.play();
                      setState(() {});
                    },
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          // 6. Right Action Buttons (Like, Comments, Share)
          Positioned(
            right: 14,
            bottom: 90,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Like Button
                Obx(() {
                  final isLiked = reelsController.isLiked(reel.id);
                  final likesCount = reelsController.getLikes(
                    reel.id,
                    reel.likes,
                  );

                  return _IconAction(
                    label: _fmt(likesCount),
                    onTap: () => reelsController.toggleReelLike(reel.id),
                    child: AnimatedScale(
                      scale: isLiked ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.elasticOut,
                      child: Icon(
                        isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isLiked ? AppColors.accentColor : Colors.white,
                        size: 30,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // Comment Button
                Obx(() {
                  final fallbackComments =
                      reel.totalComments > 0 ? reel.totalComments : reel.commentsCount;
                  final commentsCount = reelsController.getComments(
                    reel.id,
                    fallbackComments,
                  );

                  return _IconAction(
                    label: _fmt(commentsCount),
                    onTap: () {
                      AiReelCommentsSheet.show(
                        context,
                        contentId: reel.id,
                      );
                    },
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 28,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // Share Button
                Obx(() {
                  final sharesCount = reelsController.getShares(
                    reel.id,
                    reel.shares,
                  );

                  return _IconAction(
                    flip: true,
                    label: _fmt(sharesCount),
                    onTap: () async {
                      final shareText = reel.title.isNotEmpty
                          ? 'Check out "${reel.title}" on Masti Adda!\n${reel.fullVideoUrl}'
                          : 'Check out this AI Reel on Masti Adda!\n${reel.fullVideoUrl}';

                      try {
                        final result = await SharePlus.instance.share(
                          ShareParams(
                            text: shareText,
                            subject: reel.title.isNotEmpty
                                ? reel.title
                                : 'AI Reel',
                          ),
                        );

                        if (result.status == ShareResultStatus.success) {
                          reelsController.recordShare(reel.id);
                        }
                      } catch (e) {
                        debugPrint("⚠️ Error sharing reel: $e");
                      }
                    },
                    child: const Icon(
                      Icons.reply_rounded,
                      color: Colors.white,
                      size: 28,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                Obx(() {
                  final isMuted = reelsController.isMuted.value;
                  // Sync volume to controller
                  if (_vpc != null && _initialized) {
                    _vpc!.setVolume(isMuted ? 0.0 : 1.0);
                  }

                  return GestureDetector(
                    onTap: () {
                      reelsController.toggleMute();
                      final newMuted = reelsController.isMuted.value;
                      _vpc?.setVolume(newMuted ? 0.0 : 1.0);
                      setState(() {});
                    },
                    child: Icon(
                      isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  );
                }),
              ],
            ),
          ),

          // 5. Bottom Info (Username, Title, Description)
          Positioned(
            left: 16,
            right: 80,
            bottom: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar + username row
                Row(
                  children: [
                    // ClipOval(
                    //   child: Image.network(
                    //     reel.fullThumbnailUrl,
                    //     width: 28,
                    //     height: 28,
                    //     fit: BoxFit.cover,
                    //     errorBuilder: (_, _, _) => Container(
                    //       width: 28,
                    //       height: 28,
                    //       color: AppColors.cardColor,
                    //       child: const Icon(
                    //         Icons.person,
                    //         size: 16,
                    //         color: Colors.white70,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    //const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reel.title.isNotEmpty ? reel.title : '@ai.creations',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text13(
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (reel.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          reel.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text12(
                            color: AppColors.white,
                          ).copyWith(height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 6. Bottom Linear Progress Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _initialized && _vpc != null
                ? ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: _vpc!,
                    builder: (_, val, _) {
                      final p = val.duration.inMilliseconds > 0
                          ? val.position.inMilliseconds /
                                val.duration.inMilliseconds
                          : 0.0;
                      return LinearProgressIndicator(
                        value: p.clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.accentColor,
                        ),
                        minHeight: 3,
                      );
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final Widget child;
  final String label;
  final VoidCallback onTap;
  final bool flip;

  const _IconAction({
    required this.child,
    required this.label,
    required this.onTap,
    this.flip = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform(
            alignment: Alignment.center,
            transform: flip
                ? (Matrix4.diagonal3Values(-1.0, 1.0, 1.0))
                : Matrix4.identity(),
            child: child,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: text11(color: AppColors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
