import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/core/services/app_download_service.dart';
import 'package:masti_adda_app/features/micro_drama/controllers/continue_watching_controller.dart';
import 'package:masti_adda_app/features/micro_drama/controllers/micro_drama_controller.dart';
import 'package:masti_adda_app/features/micro_drama/models/episode_detail_response.dart';
import 'package:masti_adda_app/features/micro_drama/models/micro_drama_detail_response.dart';
import 'package:masti_adda_app/features/micro_drama/views/micro_drama_player_screen.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:masti_adda_app/features/profile/controllers/watchlist_controller.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/shared/controllers/interaction_controller.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/shared/widgets/shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MicroDramaDetailScreen extends StatefulWidget {
  final String id;

  const MicroDramaDetailScreen({super.key, required this.id});

  @override
  State<MicroDramaDetailScreen> createState() => _MicroDramaDetailScreenState();
}

class _MicroDramaDetailScreenState extends State<MicroDramaDetailScreen> {
  final WatchlistController _watchlistController =
      Get.isRegistered<WatchlistController>()
      ? Get.find<WatchlistController>()
      : Get.put(WatchlistController());
  final RxInt selectedEpisode = 0.obs;
  late final MicroDramaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<MicroDramaController>()
        ? Get.find<MicroDramaController>()
        : Get.put(MicroDramaController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchDramaDetail(widget.id);
      _controller.fetchAllMicroDrama();
      _controller.fetchEpisodeDetail(widget.id);
      _watchlistController.fetchWatchlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Obx(() {
        // Loading state
        if (_controller.detailDramaStatus.value == Status.loading) {
          return const MicroDramaDetailShimmer();
        }

        // Error state
        if (_controller.detailDramaStatus.value == Status.error ||
            _controller.dramaDetail.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load drama details',
                  style: text15(color: AppColors.secondaryTextColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _controller.fetchDramaDetail(widget.id);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final drama = _controller.dramaDetail.value!.microdrama;
        final allDramas = _controller.allMicroDrama.value?.microdramas ?? [];
        final similarDramas = allDramas
            .where(
              (d) =>
                  d.id != drama.id &&
                  d.genre.any((g) => drama.genre.contains(g)),
            )
            .toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHero(drama)),
            SliverToBoxAdapter(child: _buildRatingAndTags(drama)),
            SliverToBoxAdapter(child: _buildStory(drama)),
            SliverToBoxAdapter(child: _buildActions(drama)),
            SliverToBoxAdapter(child: _buildEpisodes(drama)),
            if (similarDramas.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildSimilarDramas(similarDramas, drama.id),
              ),
            SliverToBoxAdapter(child: _buildExploreMore()),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        );
      }),
    );
  }

  // ── Hero cover ─────────────────────────────────────────────────────────────
  Widget _buildHero(Microdrama drama) {
    final bannerUrl = formatMediaUrl(
      drama.banner.isNotEmpty ? drama.banner : drama.poster,
    );
    return Stack(
      children: [
        SizedBox(
          height: 280,
          width: double.infinity,
          child: bannerUrl.isNotEmpty
              ? Image.network(
                  bannerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 280,
                    color: AppColors.cardColor,
                    child: const Center(
                      child: Icon(
                        Icons.movie_outlined,
                        color: AppColors.hintTextColor,
                        size: 60,
                      ),
                    ),
                  ),
                )
              : Container(
                  height: 280,
                  color: AppColors.cardColor,
                  child: const Center(
                    child: Icon(
                      Icons.movie_outlined,
                      color: AppColors.hintTextColor,
                      size: 60,
                    ),
                  ),
                ),
        ),
        // Bottom gradient
        Container(
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, AppColors.backgroundColor],
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
                  _iconBtn(Icons.share_outlined, () async {
                    try {
                      final imageUrl = formatMediaUrl(
                        drama.banner.isNotEmpty ? drama.banner : drama.poster,
                      );
                      final response = await http.get(Uri.parse(imageUrl));

                      if (response.statusCode != 200) {
                        debugPrint("⚠️ Failed to download poster for sharing");
                        return;
                      }

                      final tempDir = await getTemporaryDirectory();
                      final file = File(
                        '${tempDir.path}/goliDoli_poster_${drama.id}.jpg',
                      );
                      await file.writeAsBytes(response.bodyBytes);

                      final shareText = drama.title.isNotEmpty
                          ? 'Check out "${drama.title}" on Masti Adda!'
                          : 'Check out this show on Masti Adda!';

                      await SharePlus.instance.share(
                        ShareParams(
                          files: [XFile(file.path)],
                          text: shareText,
                          subject: drama.title.isNotEmpty
                              ? drama.title
                              : 'Web Series',
                        ),
                      );
                    } catch (e) {
                      debugPrint("⚠️ Error sharing poster: $e");
                    }
                  }),
                ],
              ),
            ),
          ),
        ),
        // Title at bottom of hero
        Positioned(
          bottom: 14,
          left: 16,
          right: 16,
          child: Text(
            drama.title,
            style: text22(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ── Rating & tags ──────────────────────────────────────────────────────────
  Widget _buildRatingAndTags(Microdrama drama) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Rating star
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: AppColors.ratingColor, size: 16),
              const SizedBox(width: 3),
              Text(
                drama.rating.toStringAsFixed(1),
                style: text12(
                  color: AppColors.ratingColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '(${_formatNum(drama.totalViews)})',
                style: text11(color: AppColors.hintTextColor),
              ),
            ],
          ),
          // Tags from genre list
          ...drama.genre.map((genre) => _buildTag(genre.toString())),
          // Additional tags: total episodes, language, etc.
          _buildTag('${drama.totalEpisodes} Episodes'),
          _buildTag(drama.language),
          if (drama.isComingSoon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Coming Soon',
                style: text10(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          // Premium badge (Uncomment if needed in future):
          /*
          if (drama.isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PREMIUM',
                style: text10(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          */
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: text11(color: AppColors.secondaryTextColor)),
    );
  }

  // ── Story ──────────────────────────────────────────────────────────────────
  Widget _buildStory(Microdrama drama) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Story', style: text15(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            drama.description,
            style: text13(color: AppColors.secondaryTextColor),
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Widget _buildActions(Microdrama drama) {
    final dramaId = drama.id.isNotEmpty ? drama.id : widget.id;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          // Primary "Start Watching" Button
          GestureDetector(
            onTap: _onStartWatching,
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.accentColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Start Watching',
                    style: text15(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Modern Quick Actions Row (Watchlist, Like, Dislike, Share)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Watchlist
              Obx(() {
                final bool isInWatchlist =
                    dramaId.isNotEmpty &&
                    _watchlistController.isItemInWatchlist(dramaId);
                final bool isLoading =
                    dramaId.isNotEmpty &&
                    _watchlistController.isItemLoading(dramaId);

                return _buildQuickActionItem(
                  icon: isInWatchlist
                      ? Icons.bookmark_added_rounded
                      : Icons.bookmark_add_outlined,
                  label: isInWatchlist ? 'Saved' : 'Watchlist',
                  isSelected: isInWatchlist,
                  isLoading: isLoading,
                  onTap: () {
                    if (dramaId.isNotEmpty && !isLoading) {
                      _watchlistController.toggleWatchlist(dramaId);
                    }
                  },
                );
              }),
              // 2. Like
              Obx(() {
                final interactionCtrl = InteractionController.to;
                final isLiked = interactionCtrl.isLiked(dramaId);
                final likes = interactionCtrl.getLikes(dramaId, 0);
                final isLoading = interactionCtrl.isLikeLoading(dramaId);

                return _buildQuickActionItem(
                  icon: isLiked
                      ? Icons.thumb_up_alt_rounded
                      : Icons.thumb_up_alt_outlined,
                  label: likes > 0 ? '$likes' : 'Like',
                  isSelected: isLiked,
                  isLoading: isLoading,
                  onTap: () {
                    interactionCtrl.toggleLike(dramaId, showToast: true);
                  },
                );
              }),
              // 3. Dislike
              Obx(() {
                final interactionCtrl = InteractionController.to;
                final isDisliked = interactionCtrl.isDisliked(dramaId);
                final dislikes = interactionCtrl.getDislikes(dramaId, 0);
                final isLoading = interactionCtrl.isDislikeLoading(dramaId);

                return _buildQuickActionItem(
                  icon: isDisliked
                      ? Icons.thumb_down_alt_rounded
                      : Icons.thumb_down_alt_outlined,
                  label: dislikes > 0 ? '$dislikes' : 'Dislike',
                  isSelected: isDisliked,
                  activeColor: AppColors.errorColor,
                  isLoading: isLoading,
                  onTap: () {
                    interactionCtrl.toggleDislike(dramaId, showToast: true);
                  },
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
    Color activeColor = AppColors.primaryColor,
    Color inactiveColor = AppColors.secondaryTextColor,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? activeColor.withValues(alpha: 0.16)
                    : AppColors.surfaceColor,
                border: Border.all(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.7)
                      : AppColors.borderColor.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: activeColor,
                        ),
                      )
                    : Icon(
                        icon,
                        color: isSelected ? activeColor : inactiveColor,
                        size: 16,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: text10(
                color: isSelected ? activeColor : AppColors.secondaryTextColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Episodes list & grid ───────────────────────────────────────────────────
  Widget _buildEpisodes(Microdrama drama) {
    final status = _controller.episodeDetailStatus.value;
    final episodes = _controller.episodeDetail.value?.episodes ?? [];

    if (status == Status.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accentColor),
        ),
      );
    }

    if (episodes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Episodes', style: text15(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'No episodes available yet',
                  style: text13(color: AppColors.secondaryTextColor),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Episodes (${episodes.length})',
                style: text15(fontWeight: FontWeight.bold),
              ),
              Text(
                'Tap to play',
                style: text12(color: AppColors.hintTextColor),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Quick-Select Chips ────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(episodes.length, (i) {
              final ep = episodes[i];
              final isSelected = selectedEpisode.value == i;

              return GestureDetector(
                onTap: () => _onEpisodeTap(i, ep.isLocked),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentColor
                        : ep.isLocked
                        ? AppColors.cardColor
                        : AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentColor
                          : AppColors.borderColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'E${ep.episodeNumber}',
                        style: text12(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.black
                              : ep.isLocked
                              ? AppColors.disabledColor
                              : AppColors.textColor,
                        ),
                      ),
                      if (ep.isLocked) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.lock_rounded,
                          size: 11,
                          color: isSelected
                              ? AppColors.black
                              : AppColors.disabledColor,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // ── Detailed Episode Cards ────────────────────────────────────
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: episodes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final ep = episodes[i];
              final isSelected = selectedEpisode.value == i;
              final thumbUrl = formatMediaUrl(
                ep.thumbnail.isNotEmpty
                    ? ep.thumbnail
                    : (drama.poster.isNotEmpty ? drama.poster : drama.banner),
              );

              return GestureDetector(
                onTap: () => _onEpisodeTap(i, ep.isLocked),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentColor.withValues(alpha: 0.12)
                        : AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentColor
                          : AppColors.borderColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Episode Thumbnail with Play icon or Lock
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            thumbUrl.isNotEmpty
                                ? Image.network(
                                    thumbUrl,
                                    width: 100,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 100,
                                      height: 60,
                                      color: AppColors.cardColor,
                                      child: const Center(
                                        child: Icon(
                                          Icons.movie_outlined,
                                          color: AppColors.hintTextColor,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 100,
                                    height: 60,
                                    color: AppColors.cardColor,
                                    child: const Center(
                                      child: Icon(
                                        Icons.movie_outlined,
                                        color: AppColors.hintTextColor,
                                      ),
                                    ),
                                  ),
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    ep.isLocked
                                        ? Icons.lock_rounded
                                        : Icons.play_arrow_rounded,
                                    color: ep.isLocked
                                        ? AppColors.disabledColor
                                        : AppColors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            if (ep.duration.isNotEmpty)
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    ep.duration,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Episode Title, Number & Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EP ${ep.episodeNumber}: ${ep.title}',
                              style: text13(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.accentColor
                                    : AppColors.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (ep.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                ep.description,
                                style: text11(
                                  color: AppColors.secondaryTextColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Download Action
                      Obx(() {
                        final downloadService = AppDownloadService.to;
                        final isDownloaded = downloadService.isDownloaded(
                          ep.id,
                        );
                        final isDownloading = downloadService.isDownloading(
                          ep.id,
                        );
                        final progress = downloadService.getProgress(ep.id);

                        if (isDownloading) {
                          return Container(
                            width: 26,
                            height: 26,
                            padding: const EdgeInsets.all(4),
                            margin: const EdgeInsets.only(right: 6),
                            child: CircularProgressIndicator(
                              value: progress > 0 ? progress : null,
                              strokeWidth: 2,
                              color: AppColors.primaryColor,
                            ),
                          );
                        }

                        if (isDownloaded) {
                          return IconButton(
                            icon: const Icon(
                              Icons.download_done_rounded,
                              color: AppColors.primaryColor,
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _showEpisodeDownloadOptions(
                                context,
                                ep,
                                downloadService,
                              );
                            },
                          );
                        }

                        return IconButton(
                          icon: const Icon(
                            Icons.download_outlined,
                            color: AppColors.hintTextColor,
                            size: 22,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            final isEpPrem = ep.isPremium || ep.isLocked || drama.isPremium;
                            if (!checkDownloadable(
                              context,
                              isPremium: isEpPrem,
                              title: ep.title.isNotEmpty ? ep.title : drama.title,
                            )) {
                              return;
                            }
                            downloadService.downloadMedia(
                              id: ep.id,
                              title: ep.title.isNotEmpty
                                  ? ep.title
                                  : 'Episode ${ep.episodeNumber}',
                              parentTitle: drama.title,
                              coverImage: thumbUrl,
                              remoteUrl: ep.videoUrl,
                              mediaType: DownloadMediaType.microDrama,
                              episodeNumber: ep.episodeNumber,
                              extra: {'dramaId': drama.id},
                              isPremium: isEpPrem,
                            );
                          },
                        );
                      }),
                      const SizedBox(width: 8),

                      // Right Action
                      Icon(
                        Icons.play_circle_fill_rounded,
                        color: isSelected
                            ? AppColors.accentColor
                            : AppColors.hintTextColor,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEpisodeDownloadOptions(
    BuildContext context,
    MicroDramaEpisode ep,
    AppDownloadService downloadService,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ep.title, style: text16(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Downloaded for offline viewing',
              style: text12(color: AppColors.secondaryTextColor),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.primaryColor,
              ),
              title: Text(
                'Watch Offline',
                style: text14(color: AppColors.white),
              ),
              onTap: () {
                Get.back();
                final localPath = downloadService.getLocalFilePath(ep.id);
                if (localPath != null && localPath.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MicroDramaPlayerScreen(
                        dramaId: widget.id,
                        initialIndex: 0,
                        offlineEpisodes: [
                          MicroDramaEpisode(
                            id: ep.id,
                            tvShowId: widget.id,
                            episodeNumber: ep.episodeNumber,
                            title: ep.title,
                            description: ep.description,
                            videoUrl: localPath,
                            thumbnail: ep.thumbnail,
                            duration: ep.duration,
                            isPremium: false,
                            isLocked: false,
                            isVertical: true,
                            views: ep.views,
                            likes: ep.likes,
                            createdAt: ep.createdAt,
                            updatedAt: ep.updatedAt,
                            version: ep.version,
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.errorColor,
              ),
              title: Text(
                'Delete Download',
                style: text14(color: AppColors.errorColor),
              ),
              onTap: () {
                Get.back();
                downloadService.removeDownload(ep.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Similar dramas ─────────────────────────────────────────────────────────
  Widget _buildSimilarDramas(List<dynamic> similarDramas, String currentId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Similar Dramas', style: text15(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: similarDramas.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (_, i) {
              final item = similarDramas[i];
              final rawPoster =
                  (item.poster != null && item.poster.toString().isNotEmpty)
                  ? item.poster.toString()
                  : (item.banner != null ? item.banner.toString() : '');
              final imageUrl = formatMediaUrl(rawPoster);

              return GestureDetector(
                onTap: () => _onSimilarDramaTap(item),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: AppColors.cardColor,
                                child: const Center(
                                  child: Icon(
                                    Icons.movie_outlined,
                                    color: AppColors.hintTextColor,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.cardColor,
                              child: const Center(
                                child: Icon(
                                  Icons.movie_outlined,
                                  color: AppColors.hintTextColor,
                                ),
                              ),
                            ),
                      // Gradient
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppColors.backgroundColor.withValues(alpha: 0.85),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        left: 6,
                        right: 6,
                        child: Text(
                          (item.title ?? '').toString().toUpperCase(),
                          style: text8(fontWeight: FontWeight.bold),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Explore More ──────────────────────────────────────────────────────────
  Widget _buildExploreMore() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: GestureDetector(
        onTap: () {
          Get.toNamed(AppRoutes.microDrama);
        },
        child: Center(
          child: Text(
            'Explore More Dramas',
            style: text13(
              color: AppColors.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.overlayColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.white, size: 18),
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  // ── Callbacks ──────────────────────────────────────────────────────────────

  // "Start Watching" begins from Episode 1 (index 0)
  void _onStartWatching() {
    final drama = _controller.dramaDetail.value?.microdrama;
    final isDramaPremium = drama?.isPremium ?? false;
    if (checkPlayable(
      context,
      isPremium: isDramaPremium,
      title: drama?.title,
    )) {
      _openPlayer(initialIndex: 0);
    }
  }

  // Tapping a specific episode chip both highlights it and opens the
  // player starting exactly at that episode.
  void _onEpisodeTap(int index, bool isLocked) {
    selectedEpisode.value = index;

    final drama = _controller.dramaDetail.value?.microdrama;
    final isDramaPremium = drama?.isPremium ?? false;
    final requiresSub = isDramaPremium || isLocked;

    if (requiresSub) {
      if (checkPlayable(context, isPremium: true, title: drama?.title)) {
        _openPlayer(initialIndex: index);
      }
    } else {
      _openPlayer(initialIndex: index);
    }
  }

  void _openPlayer({required int initialIndex}) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => MicroDramaPlayerScreen(
              dramaId: widget.id,
              initialIndex: initialIndex,
            ),
          ),
        )
        .then((_) {
          if (Get.isRegistered<ContinueWatchingController>()) {
            Get.find<ContinueWatchingController>().fetchContinueWatching();
          }
        });
  }

  void _onSimilarDramaTap(dynamic item) {
    final dramaId = item.id?.toString() ?? '';
    if (dramaId.isNotEmpty) {
      Get.to(
        () => MicroDramaDetailScreen(id: dramaId),
        preventDuplicates: false,
      );
    }
  }
}

// ── Local text style helpers (already defined elsewhere) ──────────────────
// Remove these if they already exist in your project.

TextStyle text22({
  FontWeight fontWeight = FontWeight.bold,
  Color color = AppColors.textColor,
}) => appTextStyle(fontSize: 22, fontWeight: fontWeight, color: color);

TextStyle text8({
  FontWeight fontWeight = FontWeight.normal,
  Color color = AppColors.textColor,
}) => appTextStyle(fontSize: 8, fontWeight: fontWeight, color: color);
