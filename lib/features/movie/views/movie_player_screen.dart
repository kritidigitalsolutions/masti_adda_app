import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/micro_drama/controllers/continue_watching_controller.dart';
import 'package:masti_adda_app/features/movie/controllers/movie_controller.dart';
import 'package:masti_adda_app/features/profile/controllers/subscription_status_controller.dart';
import 'package:masti_adda_app/features/web_series/controllers/episode_controller.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:video_player/video_player.dart';

import '../../../constants/enums.dart';

class MoviePlayerScreen extends StatefulWidget {
  const MoviePlayerScreen({
    super.key,
    this.episodeId,
    this.videoUrl,
    this.title,
    this.contentId,
    this.contentType = 'movie', // "movie" or "series"
    this.initialPositionSeconds,
  });

  final String? episodeId;
  final String? videoUrl;
  final String? title;
  final String? contentId; // movie._id or series._id for progress tracking
  final String contentType;
  final int? initialPositionSeconds;

  @override
  State<MoviePlayerScreen> createState() => _MoviePlayerScreenState();
}

class _MoviePlayerScreenState extends State<MoviePlayerScreen> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _showControls = true;
  bool _isFullscreen = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String _selectedQuality = 'Auto';
  final Map<String, String> _qualityUrls = {};
  bool _isLoading = true;
  String? _errorMessage;
  EpisodeController? _episodeController;
  Worker? _statusWorker;
  Timer? _progressTimer; // fires every 15 s to save progress
  Timer? _hideControlsTimer;
  ContinueWatchingController? _cwController;

  @override
  void initState() {
    super.initState();
    // Default to fullscreen landscape mode on playback start
    _isFullscreen = true;
    _lockLandscape();

    // Init CW controller if available
    _cwController = Get.isRegistered<ContinueWatchingController>()
        ? Get.find<ContinueWatchingController>()
        : null;

    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      final rawUrl = widget.videoUrl!.trim();
      final isLocal = isLocalFilePath(rawUrl);
      final playUrl = isLocal ? rawUrl : formatMediaUrl(rawUrl);
      _qualityUrls[isLocal ? 'Offline' : 'Auto'] = playUrl;
      _selectedQuality = isLocal ? 'Offline' : 'Auto';
      _initializePlayer(playUrl);
    } else if (widget.episodeId != null && widget.episodeId!.isNotEmpty) {
      _episodeController = Get.put(EpisodeController());

      _statusWorker = ever(_episodeController!.detailEpisodeStatus, (
        Status status,
      ) {
        if (status == Status.success &&
            _episodeController!.episodeDetail.value != null) {
          final episodeDetailVal = _episodeController!.episodeDetail.value!;
          if (episodeDetailVal.episode.isPremium) {
            final subController =
                Get.isRegistered<SubscriptionStatusController>()
                ? Get.find<SubscriptionStatusController>()
                : Get.put(SubscriptionStatusController());
            if (!subController.isPremiumUser.value) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'Premium subscription required';
                });
                showPremiumPrompt(
                  context,
                  title: episodeDetailVal.episode.title,
                );
              }
              return;
            }
          }
          final videoUrl = formatMediaUrl(episodeDetailVal.episode.videoUrl);
          if (videoUrl.isNotEmpty) {
            _qualityUrls['Auto'] = videoUrl;
            _selectedQuality = 'Auto';
            _initializePlayer(videoUrl);
          } else {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'No video URL available';
              });
            }
          }
        } else if (status == Status.error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Failed to load episode details';
            });
          }
          Get.snackbar(
            "Error",
            "Failed to load episode details",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      });

      _episodeController!.fetchEpisodeDetail(widget.episodeId!);
    } else if (widget.contentId != null && widget.contentId!.isNotEmpty) {
      // ContentId given without videoUrl (e.g. from Continue Watching movie item)
      final movieController = Get.isRegistered<MovieController>()
          ? Get.find<MovieController>()
          : Get.put(MovieController());

      _statusWorker = ever(movieController.movieDetailStatus, (Status status) {
        if (status == Status.success &&
            movieController.movieDetail.value != null) {
          final movie = movieController.movieDetail.value!;
          final videoUrl = formatMediaUrl(movie.videoUrl);
          if (videoUrl.isNotEmpty) {
            _qualityUrls['Auto'] = videoUrl;
            _selectedQuality = 'Auto';
            _initializePlayer(videoUrl);
          } else {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'No video URL available for this movie';
              });
            }
          }
        } else if (status == Status.error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Failed to load movie details';
            });
          }
        }
      });

      movieController.fetchMovieDetail(widget.contentId!);
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No video URL or episode ID provided';
        });
      }
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _progressTimer?.cancel();
    // Save final progress on exit
    _saveProgress();
    _statusWorker?.dispose();
    _videoController?.dispose();
    _restorePortrait();
    super.dispose();
  }

  void _lockPortrait() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
  }

  void _lockLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _restorePortrait() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
  }

  Future<void> _handleBack() async {
    _restorePortrait();
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      _lockLandscape();
    } else {
      _lockPortrait();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls && _isPlaying) {
        _startHideControlsTimer();
      } else {
        _hideControlsTimer?.cancel();
      }
    });
  }

  void _togglePlay() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
        _hideControlsTimer?.cancel();
        _progressTimer?.cancel();
        _saveProgress();
      } else {
        _videoController!.play();
        _isPlaying = true;
        _startHideControlsTimer();
        _startProgressTimer();
      }
    });
  }

  void _toggleMute() {
    if (_videoController == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _videoController!.setVolume(_isMuted ? 0 : 1);
    });
  }

  void _rewind() {
    if (_videoController == null) return;
    final newPosition = _position - const Duration(seconds: 10);
    _videoController!.seekTo(newPosition);
    if (_isPlaying) _startHideControlsTimer();
  }

  void _forward() {
    if (_videoController == null) return;
    final newPosition = _position + const Duration(seconds: 10);
    _videoController!.seekTo(newPosition);
    if (_isPlaying) _startHideControlsTimer();
  }

  void _seekTo(double value) {
    if (_videoController == null) return;
    final position = Duration(milliseconds: value.toInt());
    _videoController!.seekTo(position);
    if (_isPlaying) _startHideControlsTimer();
  }

  // ── Progress saving helpers ──────────────────────────────────────────────

  void _startProgressTimer() {
    _progressTimer?.cancel();
    // Save once at start, then periodic
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isInitialized) {
        _saveProgress();
      }
    });
    _progressTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _saveProgress();
    });
  }

  void _saveProgress() {
    if (_cwController == null) return;
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    final contentId = widget.contentId;
    if (contentId == null || contentId.isEmpty) return;

    final pos = _videoController!.value.position;
    final dur = _videoController!.value.duration;
    if (dur.inSeconds <= 0) return;

    final episodeId = widget.episodeId; // non-null for series episodes
    _cwController!.saveProgress(
      contentId: contentId,
      contentType: widget.contentType,
      progressSeconds: pos.inSeconds,
      durationSeconds: dur.inSeconds,
      episodeId: episodeId,
    );
  }

  // ── ─────────────────────────────────────────────────────────────────────

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getFullUrl(String videoUrl) {
    if (isLocalFilePath(videoUrl)) return videoUrl;
    return formatMediaUrl(videoUrl);
  }

  void _initializePlayer(String videoUrl) {
    try {
      final isLocal = isLocalFilePath(videoUrl);
      if (isLocal) {
        final cleanPath = videoUrl.startsWith('file://')
            ? videoUrl.replaceFirst('file://', '')
            : videoUrl;
        final file = File(cleanPath);
        if (file.existsSync()) {
          _videoController = VideoPlayerController.file(file);
        } else {
          debugPrint('❌ Local video file not found: $cleanPath');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Downloaded video file not found on device.';
            });
          }
          return;
        }
      } else {
        final fullUrl = _getFullUrl(videoUrl);
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(fullUrl),
          httpHeaders: getVideoPlayerHeaders(fullUrl),
        );
      }

      _videoController!
        .initialize()
            .then((_) {
              if (mounted) {
                setState(() {
                  _isInitialized = true;
                  _isLoading = false;
                  _duration = _videoController!.value.duration;
                });
                _videoController!.addListener(() {
                  if (mounted) {
                    setState(() {
                      _position = _videoController!.value.position;
                      _duration = _videoController!.value.duration;
                      _isPlaying = _videoController!.value.isPlaying;
                    });
                  }
                });

                // Resume from initial position if provided
                if (widget.initialPositionSeconds != null &&
                    widget.initialPositionSeconds! > 0) {
                  final startPos = Duration(
                    seconds: widget.initialPositionSeconds!,
                  );
                  if (startPos < _videoController!.value.duration) {
                    _videoController!.seekTo(startPos);
                  }
                }

                _videoController!.play();
                _isPlaying = true;
                _startHideControlsTimer();
                _startProgressTimer();
              }
            })
            .catchError((e) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'Failed to load video: ${e.toString()}';
                });
              }
              debugPrint('❌ Error initializing video: $e');
            });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
      debugPrint('❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final title =
        widget.title ??
        args?['title'] as String? ??
        (_episodeController?.episodeDetail.value?.episode.title) ??
        'Masti Adda Player';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _restorePortrait();
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            return SafeArea(
              top: !isLandscape,
              bottom: !isLandscape,
              left: false,
              right: false,
              child: isLandscape
                  ? SizedBox.expand(
                      child: _PlayerSurface(
                        title: title,
                        showOverlayHeader: true,
                        onBack: _handleBack,
                        onToggleFullscreen: _toggleFullscreen,
                        isFullscreen: true,
                        isInitialized: _isInitialized,
                        isLoading: _isLoading,
                        errorMessage: _errorMessage,
                        videoController: _videoController,
                        showControls: _showControls,
                        isPlaying: _isPlaying,
                        isMuted: _isMuted,
                        position: _position,
                        duration: _duration,
                        selectedQuality: _selectedQuality,
                        qualityUrls: _qualityUrls,
                        toggleControls: _toggleControls,
                        togglePlay: _togglePlay,
                        toggleMute: _toggleMute,
                        rewind: _rewind,
                        forward: _forward,
                        seekTo: _seekTo,
                        formatDuration: _formatDuration,
                        changeQuality: _changeQuality,
                      ),
                    )
                  : Column(
                      children: [
                        _TopBar(title: title, onBack: _handleBack),
                        Expanded(
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: _PlayerSurface(
                                title: title,
                                showOverlayHeader: false,
                                onBack: _handleBack,
                                onToggleFullscreen: _toggleFullscreen,
                                isFullscreen: false,
                                isInitialized: _isInitialized,
                                isLoading: _isLoading,
                                errorMessage: _errorMessage,
                                videoController: _videoController,
                                showControls: _showControls,
                                isPlaying: _isPlaying,
                                isMuted: _isMuted,
                                position: _position,
                                duration: _duration,
                                selectedQuality: _selectedQuality,
                                qualityUrls: _qualityUrls,
                                toggleControls: _toggleControls,
                                togglePlay: _togglePlay,
                                toggleMute: _toggleMute,
                                rewind: _rewind,
                                forward: _forward,
                                seekTo: _seekTo,
                                formatDuration: _formatDuration,
                                changeQuality: _changeQuality,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  void _changeQuality(String quality) {
    setState(() {
      _selectedQuality = quality;
      if (_qualityUrls.containsKey(quality)) {
        final newUrl = _qualityUrls[quality]!;
        final currentPosition = _position;
        _videoController?.dispose();
        _videoController = null;
        _isInitialized = false;
        _initializePlayer(newUrl);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_videoController != null &&
              _videoController!.value.isInitialized) {
            _videoController!.seekTo(currentPosition);
          }
        });
      }
    });
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final Future<void> Function() onBack;

  const _TopBar({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Row(
        children: [
          AppBackButton(
            isOverlay: true,
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: text16(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerSurface extends StatelessWidget {
  final String title;
  final bool showOverlayHeader;
  final Future<void> Function() onBack;
  final VoidCallback onToggleFullscreen;
  final bool isFullscreen;
  final bool isInitialized;
  final bool isLoading;
  final String? errorMessage;
  final VideoPlayerController? videoController;
  final bool showControls;
  final bool isPlaying;
  final bool isMuted;
  final Duration position;
  final Duration duration;
  final String selectedQuality;
  final Map<String, String> qualityUrls;
  final VoidCallback toggleControls;
  final VoidCallback togglePlay;
  final VoidCallback toggleMute;
  final VoidCallback rewind;
  final VoidCallback forward;
  final void Function(double) seekTo;
  final String Function(Duration) formatDuration;
  final void Function(String) changeQuality;

  const _PlayerSurface({
    required this.title,
    required this.showOverlayHeader,
    required this.onBack,
    required this.onToggleFullscreen,
    required this.isFullscreen,
    required this.isInitialized,
    required this.isLoading,
    required this.errorMessage,
    required this.videoController,
    required this.showControls,
    required this.isPlaying,
    required this.isMuted,
    required this.position,
    required this.duration,
    required this.selectedQuality,
    required this.qualityUrls,
    required this.toggleControls,
    required this.togglePlay,
    required this.toggleMute,
    required this.rewind,
    required this.forward,
    required this.seekTo,
    required this.formatDuration,
    required this.changeQuality,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggleControls,
      child: Container(
        color: AppColors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isInitialized && videoController != null)
              Center(
                child: AspectRatio(
                  aspectRatio: videoController!.value.aspectRatio > 0
                      ? videoController!.value.aspectRatio
                      : 16 / 9,
                  child: VideoPlayer(videoController!),
                ),
              )
            else if (isLoading)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryColor),
                    SizedBox(height: 16),
                    Text(
                      'Loading video...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              )
            else if (errorMessage != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[400], size: 48),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            if (isInitialized &&
                videoController != null &&
                videoController!.value.isBuffering)
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                  strokeWidth: 3,
                ),
              ),
            if (showControls && isInitialized)
              _ControlsOverlay(
                title: title,
                showHeader: showOverlayHeader,
                onBack: onBack,
                onToggleFullscreen: onToggleFullscreen,
                isFullscreen: isFullscreen,
                isPlaying: isPlaying,
                isMuted: isMuted,
                position: position,
                duration: duration,
                selectedQuality: selectedQuality,
                qualityUrls: qualityUrls,
                togglePlay: togglePlay,
                toggleMute: toggleMute,
                rewind: rewind,
                forward: forward,
                seekTo: seekTo,
                formatDuration: formatDuration,
                changeQuality: changeQuality,
              ),
          ],
        ),
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  final String title;
  final bool showHeader;
  final Future<void> Function() onBack;
  final VoidCallback onToggleFullscreen;
  final bool isFullscreen;
  final bool isPlaying;
  final bool isMuted;
  final Duration position;
  final Duration duration;
  final String selectedQuality;
  final Map<String, String> qualityUrls;
  final VoidCallback togglePlay;
  final VoidCallback toggleMute;
  final VoidCallback rewind;
  final VoidCallback forward;
  final void Function(double) seekTo;
  final String Function(Duration) formatDuration;
  final void Function(String) changeQuality;

  const _ControlsOverlay({
    required this.title,
    required this.showHeader,
    required this.onBack,
    required this.onToggleFullscreen,
    required this.isFullscreen,
    required this.isPlaying,
    required this.isMuted,
    required this.position,
    required this.duration,
    required this.selectedQuality,
    required this.qualityUrls,
    required this.togglePlay,
    required this.toggleMute,
    required this.rewind,
    required this.forward,
    required this.seekTo,
    required this.formatDuration,
    required this.changeQuality,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.72),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.82),
          ],
        ),
      ),
      child: Column(
        children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: text14(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (qualityUrls.isNotEmpty)
                    _QualityMenu(
                      selectedQuality: selectedQuality,
                      qualityUrls: qualityUrls,
                      onQualitySelected: changeQuality,
                    ),
                ],
              ),
            ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: rewind,
                icon: const Icon(
                  Icons.replay_10_rounded,
                  color: AppColors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: togglePlay,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: AppColors.white,
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                onPressed: forward,
                icon: const Icon(
                  Icons.forward_10_rounded,
                  color: AppColors.white,
                  size: 36,
                ),
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      formatDuration(position),
                      style: text11(color: AppColors.white),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.0,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                        ),
                        child: Slider(
                          value: position.inMilliseconds
                              .clamp(0, duration.inMilliseconds)
                              .toDouble(),
                          min: 0,
                          max: duration.inMilliseconds <= 0
                              ? 1
                              : duration.inMilliseconds.toDouble(),
                          activeColor: AppColors.accentColor,
                          inactiveColor: AppColors.white.withValues(alpha: 0.28),
                          onChanged: seekTo,
                        ),
                      ),
                    ),
                    Text(
                      formatDuration(duration),
                      style: text11(color: AppColors.white),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _SmallAction(
                      icon: isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      onTap: toggleMute,
                    ),
                    if (qualityUrls.length > 1)
                      _SmallAction(
                        icon: Icons.hd_rounded,
                        onTap: () => _showQualitySheet(context),
                      ),
                    _SmallAction(
                      icon: isFullscreen
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      onTap: onToggleFullscreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQualitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceColor,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quality', style: text18(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...qualityUrls.keys.map(
                (quality) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(quality, style: text14()),
                  trailing: selectedQuality == quality
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primaryColor,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    changeQuality(quality);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QualityMenu extends StatelessWidget {
  final String selectedQuality;
  final Map<String, String> qualityUrls;
  final void Function(String) onQualitySelected;

  const _QualityMenu({
    required this.selectedQuality,
    required this.qualityUrls,
    required this.onQualitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppColors.surfaceColor,
      initialValue: selectedQuality,
      onSelected: onQualitySelected,
      itemBuilder: (_) => qualityUrls.keys
          .map(
            (quality) => PopupMenuItem(
              value: quality,
              child: Row(
                children: [
                  Expanded(child: Text(quality, style: text13())),
                  if (selectedQuality == quality)
                    const Icon(
                      Icons.check,
                      color: AppColors.primaryColor,
                      size: 18,
                    ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.44),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hd_rounded, color: AppColors.white, size: 16),
            const SizedBox(width: 5),
            Text(selectedQuality, style: text11()),
          ],
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.white, size: 21),
    );
  }
}
