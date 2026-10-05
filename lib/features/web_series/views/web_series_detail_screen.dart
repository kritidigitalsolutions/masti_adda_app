import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/core/services/app_download_service.dart';
import 'package:masti_adda_app/features/web_series/controllers/series_controller.dart';
import 'package:masti_adda_app/features/web_series/controllers/episode_controller.dart';
import 'package:masti_adda_app/features/web_series/model/SeriesModel.dart';
import 'package:masti_adda_app/features/web_series/model/episode_response.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/enums.dart';
import '../../movie/views/movie_player_screen.dart';
import 'package:masti_adda_app/features/profile/controllers/watchlist_controller.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/shared/controllers/interaction_controller.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/shared/widgets/shimmer/shimmer.dart';

class WebSeriesDetailScreen extends StatefulWidget {
  const WebSeriesDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<WebSeriesDetailScreen> createState() => _WebSeriesDetailScreenState();
}

class _WebSeriesDetailScreenState extends State<WebSeriesDetailScreen> {
  final WatchlistController _watchlistController = Get.put(
    WatchlistController(),
  );
  int _selectedSeasonIndex = 0;
  final SeriesController _seriesController = Get.put(SeriesController());
  final EpisodeController _episodeController = Get.put(EpisodeController());

  @override
  void initState() {
    super.initState();
    _seriesController.fetchSeriesDetail(widget.id);
    _episodeController.fetchAllEpisodes(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Obx(() {
        final seriesStatus = _seriesController.seriesDetailStatus.value;

        // Check for loading state
        if (seriesStatus == Status.loading) {
          return const DetailScreenShimmer();
        }

        // Check for error state
        if (seriesStatus == Status.error) {
          return Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.errorColor,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Failed to load series details",
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _seriesController.fetchSeriesDetail(widget.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Get series detail with null safety
        final seriesDetail = _seriesController.seriesDetail.value;

        // Check if series detail is null
        if (seriesDetail == null) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundColor,
            body: Center(
              child: Text(
                "No data available",
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        // Data loaded successfully
        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHero(seriesDetail)),
              SliverToBoxAdapter(child: _buildInfo(seriesDetail)),
              SliverToBoxAdapter(child: _buildActions(seriesDetail)),
              SliverToBoxAdapter(child: _buildSeasonTabs(seriesDetail)),
              SliverToBoxAdapter(child: _buildEpisodeList(seriesDetail)),
              SliverToBoxAdapter(child: _buildExploreMore()),
              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHero(Series series) {
    final bannerImg = formatMediaUrl(
      series.banner.isNotEmpty ? series.banner : series.poster,
    );
    return Stack(
      children: [
        SizedBox(
          height: 240,
          width: double.infinity,
          child: bannerImg.isNotEmpty
              ? Image.network(
                  bannerImg,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 240,
                    color: AppColors.cardColor,
                    child: const Icon(
                      Icons.tv_rounded,
                      color: AppColors.hintTextColor,
                      size: 48,
                    ),
                  ),
                )
              : Container(
                  height: 240,
                  color: AppColors.cardColor,
                  child: const Icon(
                    Icons.tv_rounded,
                    color: AppColors.hintTextColor,
                    size: 48,
                  ),
                ),
        ),
        Container(
          height: 240,
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
                        series.banner.isNotEmpty ? series.banner : series.poster,
                      );
                      final response = await http.get(Uri.parse(imageUrl));

                      if (response.statusCode != 200) {
                        debugPrint("⚠️ Failed to download poster for sharing");
                        return;
                      }

                      final tempDir = await getTemporaryDirectory();
                      final file = File(
                        '${tempDir.path}/goliDoli_poster_${series.id}.jpg',
                      );
                      await file.writeAsBytes(response.bodyBytes);

                      final shareText = series.title.isNotEmpty
                          ? 'Check out "${series.title}" on Masti Adda!'
                          : 'Check out this show on Masti Adda!';

                      await SharePlus.instance.share(
                        ShareParams(
                          files: [XFile(file.path)],
                          text: shareText,
                          subject: series.title.isNotEmpty
                              ? series.title
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

        // Coming soon badge on hero banner
        if (series.isComingSoon)
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          ),
        // Premium badge (Uncomment if needed in future):
        /*
        if (series.isPremium)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          ),
        */
      ],
    );
  }

  // ── Info row (poster + title/rating/tags/description) ─────────────────────
  Widget _buildInfo(Series series) {
    final posterImg = formatMediaUrl(
      series.poster.isNotEmpty ? series.poster : series.banner,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: posterImg.isNotEmpty
                ? Image.network(
                    posterImg,
                    width: 90,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 90,
                      height: 120,
                      color: AppColors.cardColor,
                      child: const Icon(
                        Icons.tv_rounded,
                        color: AppColors.hintTextColor,
                      ),
                    ),
                  )
                : Container(
                    width: 90,
                    height: 120,
                    color: AppColors.cardColor,
                    child: const Icon(
                      Icons.tv_rounded,
                      color: AppColors.hintTextColor,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  series.title,
                  style: text18(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                // Rating
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.ratingColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${series.rating}',
                      style: text13(
                        color: AppColors.ratingColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'totalReviews',
                      style: text11(color: AppColors.hintTextColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: series.genre
                      .map((genre) => _buildTag(genre))
                      .toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  series.description,
                  style: text12(color: AppColors.secondaryTextColor),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String genre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
      ),
      child: Text(genre, style: text10(color: AppColors.secondaryTextColor)),
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────
  Widget _buildActions(Series series) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          // Primary "Watch Now" Button
          GestureDetector(
            onTap: () {
              final episodes = _episodeController.allEpisode.value?.episodes;
              if (episodes != null && episodes.isNotEmpty) {
                final sorted = List<Episode>.from(episodes)
                  ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
                final firstEp = sorted.first;
                final isPremium = series.isPremium;
                final title = series.title;
                if (checkPlayable(
                  context,
                  isPremium: isPremium,
                  title: title,
                )) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MoviePlayerScreen(
                        episodeId: firstEp.id,
                        title: "${series.title} - EP ${firstEp.episodeNumber}",
                        contentId: widget.id,
                        contentType: 'series',
                      ),
                    ),
                  );
                }
              } else {
                Get.snackbar(
                  'Notice',
                  'No episodes available yet',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.black87,
                  colorText: Colors.white,
                );
              }
            },
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.25),
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
                    color: AppColors.black,
                    size: 24,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Watch Now',
                    style: text15(
                      color: AppColors.black,
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
                    widget.id.isNotEmpty &&
                    _watchlistController.isItemInWatchlist(widget.id);
                final bool isLoading =
                    widget.id.isNotEmpty &&
                    _watchlistController.isItemLoading(widget.id);

                return _buildQuickActionItem(
                  icon: isInWatchlist
                      ? Icons.bookmark_added_rounded
                      : Icons.bookmark_add_outlined,
                  label: isInWatchlist ? 'Saved' : 'Watchlist',
                  isSelected: isInWatchlist,
                  isLoading: isLoading,
                  onTap: () {
                    if (widget.id.isNotEmpty && !isLoading) {
                      _watchlistController.toggleWatchlist(widget.id);
                    }
                  },
                );
              }),
              // 2. Like
              Obx(() {
                final interactionCtrl = InteractionController.to;
                final likes = interactionCtrl.getLikes(series.id, series.likes);
                final isLiked = interactionCtrl.isLiked(series.id);
                final isLoading = interactionCtrl.isLikeLoading(series.id);

                return _buildQuickActionItem(
                  icon: isLiked
                      ? Icons.thumb_up_alt_rounded
                      : Icons.thumb_up_alt_outlined,
                  label: likes > 0 ? '$likes' : 'Like',
                  isSelected: isLiked,
                  isLoading: isLoading,
                  onTap: () {
                    interactionCtrl.toggleLike(series.id, showToast: true);
                  },
                );
              }),
              // 3. Dislike
              Obx(() {
                final interactionCtrl = InteractionController.to;
                final dislikes = interactionCtrl.getDislikes(
                  series.id,
                  series.dislikes,
                );
                final isDisliked = interactionCtrl.isDisliked(series.id);
                final isLoading = interactionCtrl.isDislikeLoading(series.id);

                return _buildQuickActionItem(
                  icon: isDisliked
                      ? Icons.thumb_down_alt_rounded
                      : Icons.thumb_down_alt_outlined,
                  label: dislikes > 0 ? '$dislikes' : 'Dislike',
                  isSelected: isDisliked,
                  activeColor: AppColors.errorColor,
                  isLoading: isLoading,
                  onTap: () {
                    interactionCtrl.toggleDislike(series.id, showToast: true);
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

  // ── Season tabs ────────────────────────────────────────────────────────────
  Widget _buildSeasonTabs(Series series) {
    if (series.seasons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(series.seasons.length, (index) {
            final season = series.seasons[index];
            String seasonName;

            if (season is Map<String, dynamic>) {
              seasonName = season['name'] ?? 'Season ${index + 1}';
            } else {
              seasonName = (season as dynamic).name ?? 'Season ${index + 1}';
            }

            return Padding(
              padding: EdgeInsets.only(
                right: index < series.seasons.length - 1 ? 16 : 0,
              ),
              child: _seasonTab(seasonName, index),
            );
          }),
        ),
      ),
    );
  }

  Widget _seasonTab(String label, int index) {
    final isSelected = _selectedSeasonIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSeasonIndex = index;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text14(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? AppColors.textColor
                  : AppColors.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: isSelected ? 60 : 0,
            color: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  // ── Episode list with GetX ──────────────────────────────────────────────
  Widget _buildEpisodeList(Series series) {
    final seasonNumber = _selectedSeasonIndex + 1;
    final status = _episodeController.allEpisodeStatus.value;

    if (status == Status.loading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accentColor),
        ),
      );
    }

    if (status == Status.error) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Center(
          child: Text(
            'Failed to load episodes',
            style: text14(color: AppColors.errorColor),
          ),
        ),
      );
    }

    final allEpisodes = _episodeController.allEpisode.value;

    if (allEpisodes == null || allEpisodes.episodes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Center(
          child: Text(
            'No episodes available',
            style: text14(color: AppColors.secondaryTextColor),
          ),
        ),
      );
    }

    final filteredEpisodes = allEpisodes.episodes
        .where((ep) => ep.seasonNumber == seasonNumber)
        .toList();

    if (filteredEpisodes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Center(
          child: Text(
            'No episodes available for Season $seasonNumber',
            style: text14(color: AppColors.secondaryTextColor),
          ),
        ),
      );
    }

    filteredEpisodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: filteredEpisodes.map((ep) => _buildEpisodeTile(ep)).toList(),
      ),
    );
  }

  Widget _buildEpisodeTile(Episode ep) {
    final series = _seriesController.seriesDetail.value;
    final epThumb = formatMediaUrl(
      ep.thumbnail.isNotEmpty
          ? ep.thumbnail
          : (series?.poster.isNotEmpty == true
              ? series!.poster
              : (series?.banner ?? '')),
    );
    return GestureDetector(
      onTap: () {
        final isPremium = series?.isPremium ?? false;
        final title = series?.title;
        final localPath = AppDownloadService.to.getLocalFilePath(ep.id);

        if (localPath != null && localPath.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MoviePlayerScreen(
                videoUrl: localPath,
                title: ep.title,
                contentId: widget.id,
                contentType: 'series',
                episodeId: ep.id,
              ),
            ),
          );
          return;
        }

        if (checkPlayable(context, isPremium: isPremium, title: title)) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MoviePlayerScreen(
                episodeId: ep.id,
                contentId: widget.id,
                contentType: 'series',
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: epThumb.isNotEmpty
                  ? Image.network(
                      epThumb,
                      width: 70,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 70,
                        height: 46,
                        color: AppColors.cardColor,
                        child: const Icon(
                          Icons.play_circle,
                          color: AppColors.hintTextColor,
                        ),
                      ),
                    )
                  : Container(
                      width: 70,
                      height: 46,
                      color: AppColors.cardColor,
                      child: const Icon(
                        Icons.play_circle,
                        color: AppColors.hintTextColor,
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
                    style: text13(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        'S${ep.seasonNumber.toString().padLeft(2, '0')}:E${ep.episodeNumber.toString().padLeft(2, '0')}',
                        style: text11(color: AppColors.hintTextColor),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ep.duration,
                        style: text11(color: AppColors.hintTextColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Download Action
            Obx(() {
              final downloadService = AppDownloadService.to;
              final isDownloaded = downloadService.isDownloaded(ep.id);
              final isDownloading = downloadService.isDownloading(ep.id);
              final progress = downloadService.getProgress(ep.id);
              final series = _seriesController.seriesDetail.value;

              if (isDownloading) {
                return Container(
                  width: 30,
                  height: 30,
                  padding: const EdgeInsets.all(6),
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
                  onPressed: () {
                    _showEpisodeDownloadOptions(context, ep, downloadService);
                  },
                );
              }

              return IconButton(
                icon: const Icon(
                  Icons.download_outlined,
                  color: AppColors.hintTextColor,
                  size: 22,
                ),
                onPressed: () {
                  final isEpPremium = ep.isPremium || (series?.isPremium ?? false);
                  if (!checkDownloadable(
                    context,
                    isPremium: isEpPremium,
                    title: ep.title.isNotEmpty ? ep.title : series?.title,
                  )) {
                    return;
                  }
                  downloadService.downloadMedia(
                    id: ep.id,
                    title: ep.title,
                    parentTitle: series?.title ?? 'Web Series',
                    coverImage: epThumb,
                    remoteUrl: ep.videoUrl,
                    mediaType: DownloadMediaType.webSeries,
                    episodeNumber: ep.episodeNumber,
                    extra: {
                      'seriesId': widget.id,
                      'seasonNumber': ep.seasonNumber,
                    },
                    isPremium: isEpPremium,
                  );
                },
              );
            }),
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.black,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEpisodeDownloadOptions(
    BuildContext context,
    Episode ep,
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
                      builder: (context) => MoviePlayerScreen(
                        videoUrl: localPath,
                        title: ep.title,
                        contentId: widget.id,
                        contentType: 'series',
                        episodeId: ep.id,
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

  Widget _buildExploreMore() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: () {
          Get.toNamed(AppRoutes.webSeries);
        },
        child: Center(
          child: Text(
            'Explore More Series',
            style: text13(
              color: AppColors.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

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
}
