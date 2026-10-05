import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/micro_drama/datasource/micro_drama_datasource.dart';
import 'package:masti_adda_app/features/micro_drama/models/episode_detail_response.dart';
import 'package:masti_adda_app/features/micro_drama/models/micro_drama_detail_response.dart';
import 'package:masti_adda_app/features/movie/models/MovieModel.dart';
import 'package:masti_adda_app/features/movie/repositories/movie_datasource.dart';
import 'package:masti_adda_app/features/web_series/datasource/series_datasource.dart';
import 'package:masti_adda_app/features/web_series/model/SeriesModel.dart';
import 'package:masti_adda_app/features/web_series/model/episode_response.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/web/layouts/web_main_layout.dart';
import 'package:masti_adda_app/web/routes/web_routes.dart';
import 'package:masti_adda_app/web/utils/web_auth_guard.dart';
import 'package:masti_adda_app/web/utils/web_responsive.dart';
import 'package:masti_adda_app/web/widgets/web_content_card.dart';

class WebDetailsScreen extends StatefulWidget {
  const WebDetailsScreen({super.key});

  @override
  State<WebDetailsScreen> createState() => _WebDetailsScreenState();
}

class _WebDetailsScreenState extends State<WebDetailsScreen> {
  final MicroDramaDatasource _dramaDatasource = MicroDramaDatasource();
  final MovieDatasource _movieDatasource = MovieDatasource();
  final SeriesDatasource _seriesDatasource = SeriesDatasource();

  String _id = '';
  String _type = 'movie'; // 'drama', 'movie', 'series'

  bool _isLoading = true;
  String _errorMessage = '';

  // Data
  MovieModel? _movie;
  Microdrama? _drama;
  Series? _series;
  List<Episode> _seriesEpisodes = [];
  List<MicroDramaEpisode> _dramaEpisodes = [];

  // Related content
  List<dynamic> _relatedItems = [];

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
  }

  Future<void> _checkAuthAndLoad() async {
    final loggedIn = await WebAuthGuard.isAuthenticated();
    if (!loggedIn) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await WebAuthGuard.requireAuth(
          context: context,
          message: 'Please sign in to view details and watch on Masti Adda.',
          onSuccess: () {
            if (mounted) {
              _extractParamsAndFetch();
            }
          },
        );

        // If user dismissed dialog without logging in, redirect to home
        final stillLoggedIn = await WebAuthGuard.isAuthenticated();
        if (!stillLoggedIn && mounted) {
          Get.offAllNamed(WebRoutes.home);
        }
      });
      return;
    }

    _extractParamsAndFetch();
  }

  void _extractParamsAndFetch() {
    final queryId = Get.parameters['id'];
    final queryType = Get.parameters['type'];

    final args = Get.arguments as Map<String, dynamic>?;
    _id = queryId ?? args?['id']?.toString() ?? '';
    _type = queryType ?? args?['type']?.toString().toLowerCase() ?? 'movie';

    if (_id.isNotEmpty) {
      _fetchDetails();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid content ID';
      });
    }
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_type.contains('drama')) {
        final dramaRes = await _dramaDatasource.dramaDetail(id: _id);
        if (dramaRes != null) {
          _drama = dramaRes.microdrama;
          final epRes = await _dramaDatasource.episodeDetail(id: _id);
          _dramaEpisodes = epRes?.episodes ?? [];

          // Fetch related dramas
          final allDramas = await _dramaDatasource.allMicroDrama(limit: 10);
          _relatedItems = allDramas?.microdramas
                  .where((d) => d.id != _id)
                  .take(6)
                  .toList() ??
              [];
        } else {
          _errorMessage = 'Drama not found';
        }
      } else if (_type.contains('series')) {
        final seriesRes = await _seriesDatasource.seriesDetail(id: _id);
        if (seriesRes != null) {
          _series = seriesRes;
          final epRes = await _seriesDatasource.allEpisode(id: _id);
          _seriesEpisodes = epRes?.episodes ?? [];

          // Fetch related series
          final allSeries = await _seriesDatasource.allSeries(limit: 10);
          _relatedItems = allSeries?.series
                  .where((s) => s.id != _id)
                  .take(6)
                  .toList() ??
              [];
        } else {
          _errorMessage = 'Series not found';
        }
      } else {
        // Movie
        final movieRes = await _movieDatasource.movieDetail(id: _id);
        if (movieRes != null) {
          _movie = movieRes;
          // Fetch related movies
          final allMovies = await _movieDatasource.allMovie(limit: 10);
          _relatedItems =
              allMovies.where((m) => m.id != _id).take(6).toList();
        } else {
          _errorMessage = 'Movie not found';
        }
      }
    } catch (e) {
      _errorMessage = 'Error loading content: $e';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onPlayClicked({
    String? episodeId,
    String? episodeTitle,
    String? videoUrl,
  }) {
    bool isPremiumContent = false;
    String title = '';
    if (_movie != null) {
      isPremiumContent = _movie!.isPremium;
      title = _movie!.title;
    } else if (_series != null) {
      isPremiumContent = _series!.isPremium;
      title = episodeTitle ?? _series!.title;
    } else if (_drama != null) {
      isPremiumContent = _drama!.isPremium;
      title = episodeTitle ?? _drama!.title;
    }

    WebAuthGuard.requireAuthAndSubscription(
      context: context,
      isPremium: isPremiumContent,
      contentTitle: title,
      onSuccess: () {
        String targetVideo = videoUrl ?? '';
        String contentId = _id;
        String epId = episodeId ?? '';

        if (_type.contains('movie') && _movie != null) {
          targetVideo = _movie!.videoUrl;
          title = _movie!.title;
        } else if (_type.contains('series') && _series != null) {
          title = episodeTitle ?? _series!.title;
          if (targetVideo.isEmpty && _seriesEpisodes.isNotEmpty) {
            final firstEp = _seriesEpisodes.first;
            epId = firstEp.id;
            targetVideo = firstEp.videoUrl;
            title = firstEp.title;
          }
        } else if (_type.contains('drama') && _drama != null) {
          title = episodeTitle ?? _drama!.title;
          if (targetVideo.isEmpty && _dramaEpisodes.isNotEmpty) {
            final firstEp = _dramaEpisodes.first;
            epId = firstEp.id;
            targetVideo = firstEp.videoUrl;
            title = firstEp.title;
          }
        }

        int initialIdx = 0;
        if (_type.contains('drama') && _dramaEpisodes.isNotEmpty) {
          final idx = _dramaEpisodes.indexWhere((e) => e.id == epId);
          initialIdx = idx >= 0 ? idx : 0;
        } else if (_type.contains('series') && _seriesEpisodes.isNotEmpty) {
          final idx = _seriesEpisodes.indexWhere((e) => e.id == epId);
          initialIdx = idx >= 0 ? idx : 0;
        }

        Get.toNamed(
          WebRoutes.player,
          arguments: {
            'contentId': contentId,
            'episodeId': epId,
            'title': title,
            'dramaTitle': _drama?.title ?? (_series?.title ?? _movie?.title ?? title),
            'poster': _drama?.poster.isNotEmpty == true
                ? _drama!.poster
                : (_drama?.banner.isNotEmpty == true
                    ? _drama!.banner
                    : (_series?.poster.isNotEmpty == true
                        ? _series!.poster
                        : (_movie?.poster ?? ''))),
            'videoUrl': targetVideo,
            'type': _type,
            'isPremium': isPremiumContent,
            'dramaEpisodes': _type.contains('drama') ? _dramaEpisodes : null,
            'seriesEpisodes': _type.contains('series') ? _seriesEpisodes : null,
            'initialEpisodeIndex': initialIdx,
          },
        );
      },
    );
  }

  Widget _buildDetailsMeta({
    required bool isMobile,
    required bool isTablet,
    required String type,
    required String title,
    required double? rating,
    required int? releaseYear,
    required String? duration,
    required List<dynamic> genres,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Type Tag
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryPink,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                type.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Title
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 26 : (isTablet ? 34 : 44),
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),

        // Metadata Badges (Rating, Year, Duration, Episodes)
        Wrap(
          spacing: 14,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (rating != null && rating > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFFC107), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            if (releaseYear != null)
              Text(
                releaseYear.toString(),
                style: const TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontSize: 14,
                ),
              ),
            if (duration != null && duration.isNotEmpty)
              Text(
                duration,
                style: const TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontSize: 14,
                ),
              ),
            if (_type.contains('series') && _seriesEpisodes.isNotEmpty)
              Text(
                '${_seriesEpisodes.length} Episodes',
                style: const TextStyle(
                  color: AppColors.primaryPink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (_type.contains('drama') && _dramaEpisodes.isNotEmpty)
              Text(
                '${_dramaEpisodes.length} Episodes',
                style: const TextStyle(
                  color: AppColors.primaryPink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Genre Tags
        if (genres.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: genres.map((g) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
                child: Text(
                  g.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 18),

        // Watch Now Button
        ElevatedButton.icon(
          onPressed: () => _onPlayClicked(),
          icon: const Icon(Icons.play_arrow_rounded,
              size: 26, color: Colors.white),
          label: const Text(
            'Watch Now',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPink,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 32,
              vertical: isMobile ? 12 : 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 8,
            shadowColor: AppColors.primaryPink.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const WebMainLayout(
        activeRoute: WebRoutes.details,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 120.0),
            child: CircularProgressIndicator(color: AppColors.primaryPink),
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return WebMainLayout(
        activeRoute: WebRoutes.details,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 100.0),
            child: Column(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.primaryPink, size: 60),
                const SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                  ),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isMobile = WebResponsive.isMobile(context);
    final isTablet = WebResponsive.isTablet(context);
    final horizontalPadding = WebResponsive.contentHorizontalPadding(context);

    // Common properties
    String title = '';
    String description = '';
    String posterUrl = '';
    String bannerUrl = '';
    List<dynamic> genres = [];
    double? rating;
    String? duration;
    int? releaseYear;

    if (_movie != null) {
      title = _movie!.title;
      description = _movie!.description;
      posterUrl = _movie!.poster;
      bannerUrl = _movie!.banner;
      genres = _movie!.genre;
      rating = _movie!.rating;
      duration = _movie!.duration;
      releaseYear = _movie!.releaseYear;
    } else if (_series != null) {
      title = _series!.title;
      description = _series!.description;
      posterUrl = _series!.poster;
      bannerUrl = _series!.banner;
      genres = _series!.genre;
      rating = _series!.rating;
      duration = _series!.duration;
      releaseYear = _series!.releaseYear;
    } else if (_drama != null) {
      title = _drama!.title;
      description = _drama!.description;
      posterUrl = _drama!.poster;
      bannerUrl = _drama!.banner;
      genres = _drama!.genre;
      rating = _drama!.rating.toDouble();
      duration = _drama!.duration;
      releaseYear = _drama!.releaseYear;
    }

    final backdropImage = bannerUrl.isNotEmpty ? bannerUrl : posterUrl;

    return WebMainLayout(
      activeRoute: WebRoutes.details,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Backdrop & Content Header
          Stack(
            children: [
              // Backdrop Image (.fill as requested, clear)
              if (backdropImage.isNotEmpty)
                SizedBox(
                  height: isMobile ? 480 : 520,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: formatMediaUrl(backdropImage),
                    fit: BoxFit.fill,
                    alignment: Alignment.topCenter,
                    placeholder: (_, __) => Container(color: AppColors.surfaceColor),
                    errorWidget: (_, __, ___) => Container(color: AppColors.surfaceColor),
                  ),
                )
              else
                Container(height: isMobile ? 480 : 520, color: AppColors.surfaceColor),

              // Gradient Overlay into page background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        AppColors.backgroundColor.withOpacity(0.85),
                        AppColors.backgroundColor,
                      ],
                      stops: const [0.0, 0.75, 1.0],
                    ),
                  ),
                ),
              ),

              // Floating Back Button at top-left
              Positioned(
                top: 16,
                left: horizontalPadding,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Get.back();
                      } else {
                        Get.toNamed(WebRoutes.home);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content Details Header (Floating Poster shown on Desktop/Laptop only, Meta & Watch Now on both)
              Positioned(
                bottom: 20,
                left: horizontalPadding,
                right: horizontalPadding,
                child: isMobile
                    ? _buildDetailsMeta(
                        isMobile: true,
                        isTablet: false,
                        type: _type,
                        title: title,
                        rating: rating,
                        releaseYear: releaseYear,
                        duration: duration,
                        genres: genres,
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (posterUrl.isNotEmpty) ...[
                            Container(
                              width: isTablet ? 160 : 220,
                              height: isTablet ? 240 : 330,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.8),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: CachedNetworkImage(
                                  imageUrl: formatMediaUrl(posterUrl),
                                  fit: BoxFit.contain,
                                  alignment: Alignment.center,
                                ),
                              ),
                            ),
                            const SizedBox(width: 32),
                          ],
                          Expanded(
                            child: _buildDetailsMeta(
                              isMobile: false,
                              isTablet: isTablet,
                              type: _type,
                              title: title,
                              rating: rating,
                              releaseYear: releaseYear,
                              duration: duration,
                              genres: genres,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. Main Content Body
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Synopsis Section
                if (description.isNotEmpty) ...[
                  const Text(
                    'Storyline',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 36),
                ],

                // 3. Episodes Section (for Series)
                if (_type.contains('series') && _seriesEpisodes.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Episodes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_seriesEpisodes.length} Episodes Available',
                        style: const TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _seriesEpisodes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ep = _seriesEpisodes[index];
                      final epThumb = ep.thumbnail.isNotEmpty ? ep.thumbnail : posterUrl;

                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _onPlayClicked(
                            episodeId: ep.id,
                            episodeTitle: ep.title,
                            videoUrl: ep.videoUrl,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.borderColor.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Thumbnail
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 120,
                                        height: 70,
                                        child: CachedNetworkImage(
                                          imageUrl: formatMediaUrl(epThumb),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),

                                // Episode Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Episode ${ep.episodeNumber}: ${ep.title}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (ep.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          ep.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppColors.secondaryTextColor,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                      if (ep.duration.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          ep.duration,
                                          style: const TextStyle(
                                            color: AppColors.secondaryTextColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],

                // 4. Drama Episodes List (for Micro Dramas)
                if (_type.contains('drama') && _dramaEpisodes.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Drama Episodes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_dramaEpisodes.length} Episodes Available',
                        style: const TextStyle(
                          color: AppColors.secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _dramaEpisodes.map((ep) {
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _onPlayClicked(
                            episodeId: ep.id,
                            episodeTitle: ep.title,
                            videoUrl: ep.videoUrl,
                          ),
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.borderColor.withOpacity(0.5),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.play_circle_outline_rounded,
                                    color: AppColors.primaryPink, size: 28),
                                const SizedBox(height: 8),
                                Text(
                                  'Ep. ${ep.episodeNumber}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                ],

                // 5. Recommended / More Like This
                if (_relatedItems.isNotEmpty) ...[
                  const Text(
                    'More Like This',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 280,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _relatedItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final item = _relatedItems[index];
                        final relId = (item.id ?? '').toString();
                        final relTitle = (item.title ?? '').toString();
                        final relPoster = (item.poster ?? item.banner ?? '').toString();
                        final relRating = (item.rating is num) ? (item.rating as num).toDouble() : null;

                        return WebContentCard(
                          id: relId,
                          title: relTitle,
                          posterUrl: relPoster,
                          type: _type,
                          rating: relRating,
                          onTap: () {
                            Get.toNamed(
                              '${WebRoutes.details}?id=$relId&type=$_type',
                              arguments: {'id': relId, 'type': _type},
                              preventDuplicates: false,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
