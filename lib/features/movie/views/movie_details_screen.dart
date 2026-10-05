import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/core/services/app_download_service.dart';
import 'package:masti_adda_app/features/movie/controllers/movie_controller.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/enums.dart';
import '../models/MovieModel.dart';
import 'package:masti_adda_app/features/movie/views/movie_player_screen.dart';
import 'package:masti_adda_app/features/profile/controllers/watchlist_controller.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/shared/controllers/interaction_controller.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/shared/widgets/shimmer/shimmer.dart';

class MovieDetailsScreen extends StatefulWidget {
  const MovieDetailsScreen({super.key, this.id});
  final String? id;

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  final WatchlistController _watchlistController = Get.put(
    WatchlistController(),
  );
  late final MovieController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<MovieController>();
    if (widget.id != null) {
      _controller.fetchMovieDetail(widget.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Handle loading state
      if (_controller.movieDetailStatus.value == Status.loading) {
        return const Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: DetailScreenShimmer(),
        );
      }

      // Handle error state
      if (_controller.movieDetailStatus.value == Status.error) {
        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.errorColor,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load movie details',
                  style: text14(color: AppColors.secondaryTextColor),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (widget.id != null) {
                      _controller.fetchMovieDetail(widget.id!);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentColor,
                    foregroundColor: AppColors.black,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      final movie = _controller.movieDetail.value;
      if (movie == null) {
        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: const Center(child: Text('No movie found')),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHero(movie)),
            SliverToBoxAdapter(child: _buildMovieInfo(movie)),
            SliverToBoxAdapter(child: _buildActions(movie)),
            SliverToBoxAdapter(child: _buildMoreLikeThis()),
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      );
    });
  }

  Widget _buildHero(MovieModel movie) {
    final heroImg = formatMediaUrl(
      movie.banner.isNotEmpty ? movie.banner : movie.poster,
    );
    return Stack(
      children: [
        // Backdrop image
        SizedBox(
          height: 240,
          width: double.infinity,
          child: heroImg.isNotEmpty
              ? Image.network(
                  heroImg,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.cardColor,
                    child: const Icon(
                      Icons.movie_outlined,
                      color: AppColors.hintTextColor,
                      size: 48,
                    ),
                  ),
                )
              : Container(
                  color: AppColors.cardColor,
                  child: const Icon(
                    Icons.movie_outlined,
                    color: AppColors.hintTextColor,
                    size: 48,
                  ),
                ),
        ),
        // Gradient overlay
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
                  GestureDetector(
                    onTap: () async {
                      try {
                        final imageUrl = formatMediaUrl(
                          movie.banner.isNotEmpty ? movie.banner : movie.poster,
                        );
                        final response = await http.get(Uri.parse(imageUrl));

                        if (response.statusCode != 200) {
                          debugPrint(
                            "⚠️ Failed to download poster for sharing",
                          );
                          return;
                        }

                        final tempDir = await getTemporaryDirectory();
                        final file = File(
                          '${tempDir.path}/goliDoli_poster_${movie.id}.jpg',
                        );
                        await file.writeAsBytes(response.bodyBytes);

                        final shareText = movie.title.isNotEmpty
                            ? 'Check out "${movie.title}" on Masti Adda!'
                            : 'Check out this show on Masti Adda!';

                        await SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(file.path)],
                            text: shareText,
                            subject: movie.title.isNotEmpty
                                ? movie.title
                                : 'Movie',
                          ),
                        );
                      } catch (e) {
                        debugPrint("⚠️ Error sharing poster: $e");
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.overlayColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.share_outlined,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Coming soon badge if applicable
        if (movie.isComingSoon)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
        if (movie.isPremium)
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

  Widget _buildMovieInfo(MovieModel movie) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Movie poster
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: () {
              final posterImg = formatMediaUrl(
                movie.poster.isNotEmpty ? movie.poster : movie.banner,
              );
              return posterImg.isNotEmpty
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
                          Icons.movie_outlined,
                          color: AppColors.hintTextColor,
                        ),
                      ),
                    )
                  : Container(
                      width: 90,
                      height: 120,
                      color: AppColors.cardColor,
                      child: const Icon(
                        Icons.movie_outlined,
                        color: AppColors.hintTextColor,
                      ),
                    );
            }(),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movie.title, style: text20(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                // Rating and year
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.ratingColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      movie.rating.toString(),
                      style: text13(
                        color: AppColors.ratingColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 12,
                      color: AppColors.hintTextColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      movie.releaseYear.toString(),
                      style: text12(color: AppColors.hintTextColor),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 12,
                      color: AppColors.hintTextColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      movie.duration,
                      style: text12(color: AppColors.hintTextColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Genre tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: movie.genre
                      .map((genre) => _buildTag(genre))
                      .toList(),
                ),
                const SizedBox(height: 10),
                Text(
                  movie.description,
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

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
      ),
      child: Text(label, style: text10(color: AppColors.secondaryTextColor)),
    );
  }

  Widget _buildActions(MovieModel movie) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Primary "Watch Now" Button
          GestureDetector(
            onTap: () {
              if (movie.videoUrl.isNotEmpty) {
                if (checkPlayable(
                  context,
                  isPremium: movie.isPremium,
                  title: movie.title,
                )) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MoviePlayerScreen(
                        videoUrl: movie.videoUrl,
                        title: movie.title,
                        contentId: movie.id,
                        contentType: 'movie',
                      ),
                    ),
                  );
                }
              } else {
                Get.snackbar(
                  'Notice',
                  'Video is not available yet',
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
          // Modern Quick Actions Row (Watchlist, Like, Dislike, Download, Share)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Watchlist
              Obx(() {
                final bool isInWatchlist =
                    widget.id != null &&
                    _watchlistController.isItemInWatchlist(widget.id!);
                final bool isLoading =
                    widget.id != null &&
                    _watchlistController.isItemLoading(widget.id!);

                return _buildQuickActionItem(
                  icon: isInWatchlist
                      ? Icons.bookmark_added_rounded
                      : Icons.bookmark_add_outlined,
                  label: isInWatchlist ? 'Saved' : 'Watchlist',
                  isSelected: isInWatchlist,
                  isLoading: isLoading,
                  onTap: () {
                    if (widget.id != null && !isLoading) {
                      _watchlistController.toggleWatchlist(widget.id!);
                    }
                  },
                );
              }),
              // 2. Like
              Obx(() {
                final interactionCtrl = InteractionController.to;
                final likes = interactionCtrl.getLikes(movie.id, movie.likes);
                final isLiked = interactionCtrl.isLiked(movie.id);
                final isLoading = interactionCtrl.isLikeLoading(movie.id);

                return _buildQuickActionItem(
                  icon: isLiked
                      ? Icons.thumb_up_alt_rounded
                      : Icons.thumb_up_alt_outlined,
                  label: likes > 0 ? '$likes' : 'Like',
                  isSelected: isLiked,
                  isLoading: isLoading,
                  onTap: () {
                    interactionCtrl.toggleLike(movie.id, showToast: true);
                  },
                );
              }),
              // 3. Dislike
              Obx(() {
                final interactionCtrl = InteractionController.to;
                final dislikes = interactionCtrl.getDislikes(
                  movie.id,
                  movie.dislikes,
                );
                final isDisliked = interactionCtrl.isDisliked(movie.id);
                final isLoading = interactionCtrl.isDislikeLoading(movie.id);

                return _buildQuickActionItem(
                  icon: isDisliked
                      ? Icons.thumb_down_alt_rounded
                      : Icons.thumb_down_alt_outlined,
                  label: dislikes > 0 ? '$dislikes' : 'Dislike',
                  isSelected: isDisliked,
                  activeColor: AppColors.errorColor,
                  isLoading: isLoading,
                  onTap: () {
                    interactionCtrl.toggleDislike(movie.id, showToast: true);
                  },
                );
              }),
              // 4. Download
              Obx(() {
                final downloadService = AppDownloadService.to;
                final isDownloaded = downloadService.isDownloaded(movie.id);
                final isDownloading = downloadService.isDownloading(movie.id);
                final progress = downloadService.getProgress(movie.id);

                return _buildQuickActionItem(
                  icon: isDownloading
                      ? Icons.hourglass_top_rounded
                      : (isDownloaded
                            ? Icons.download_done_rounded
                            : Icons.download_rounded),
                  label: isDownloading
                      ? '${(progress * 100).toInt()}%'
                      : (isDownloaded ? 'Downloaded' : 'Download'),
                  isSelected: isDownloaded || isDownloading,
                  isLoading: false,
                  onTap: () {
                    if (isDownloading) return;
                    if (isDownloaded) {
                      _showDownloadOptions(context, movie, downloadService);
                    } else {
                      if (!checkDownloadable(
                        context,
                        isPremium: movie.isPremium,
                        title: movie.title,
                      )) {
                        return;
                      }
                      downloadService.downloadMedia(
                        id: movie.id,
                        title: movie.title,
                        parentTitle: movie.genre.join(', '),
                        coverImage: formatMediaUrl(
                          movie.poster.isNotEmpty
                              ? movie.poster
                              : movie.banner,
                        ),
                        remoteUrl: movie.videoUrl,
                        mediaType: DownloadMediaType.movie,
                        isPremium: movie.isPremium,
                      );
                    }
                  },
                );
              }),
              // 5. Share
              // _buildQuickActionItem(
              //   icon: Icons.share_outlined,
              //   label: 'Share',
              //   onTap: () {
              //     Get.snackbar(
              //       'Share',
              //       'Sharing ${movie.title}...',
              //       snackPosition: SnackPosition.BOTTOM,
              //       backgroundColor: Colors.black87,
              //       colorText: Colors.white,
              //       duration: const Duration(seconds: 2),
              //     );
              //   },
              // ),
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

  void _showDownloadOptions(
    BuildContext context,
    MovieModel movie,
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
            Text(movie.title, style: text16(fontWeight: FontWeight.bold)),
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
                final localPath = downloadService.getLocalFilePath(movie.id);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MoviePlayerScreen(
                      videoUrl: localPath ?? movie.videoUrl,
                      title: movie.title,
                      contentId: movie.id,
                      contentType: 'movie',
                    ),
                  ),
                );
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
                downloadService.removeDownload(movie.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreLikeThis() {
    final movies = _controller.allMovies;
    // Filter out current movie and get random 6 movies
    final moreLikeThis = movies
        .where((m) => m.id != widget.id)
        .take(6)
        .toList();

    if (moreLikeThis.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('More Like This', style: text16(fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: moreLikeThis.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (_, index) {
              final movie = moreLikeThis[index];
              return GestureDetector(
                onTap: () {
                  // Navigate to movie detail
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovieDetailsScreen(id: movie.id),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: () {
                    final mPoster = formatMediaUrl(
                      movie.poster.isNotEmpty ? movie.poster : movie.banner,
                    );
                    return mPoster.isNotEmpty
                        ? Image.network(
                            mPoster,
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
                          );
                  }(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Get.toNamed(AppRoutes.movieListing);
            },
            child: Center(
              child: Text(
                'Explore More Movies',
                style: text13(
                  color: AppColors.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
