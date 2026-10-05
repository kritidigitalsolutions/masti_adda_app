import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/app_images.dart';
import 'package:masti_adda_app/features/home/models/home_banner_model.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/web/controllers/web_home_controller.dart';
import 'package:masti_adda_app/web/routes/web_routes.dart';
import 'package:masti_adda_app/web/utils/web_auth_guard.dart';
import 'package:masti_adda_app/web/utils/web_responsive.dart';
import 'package:masti_adda_app/web/widgets/web_shimmer.dart';

class WebHeroCarousel extends StatefulWidget {
  final List<HomeBannerItem> banners;
  final bool isLoading;

  const WebHeroCarousel({
    super.key,
    required this.banners,
    this.isLoading = false,
  });

  @override
  State<WebHeroCarousel> createState() => _WebHeroCarouselState();
}

class _WebHeroCarouselState extends State<WebHeroCarousel> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onWatchNow(HomeBannerItem banner) {
    final targetId = banner.content?.id ?? banner.id;
    final targetType = (banner.contentType ?? 'movie').toLowerCase();

    if (targetId != null && targetId.isNotEmpty) {
      WebAuthGuard.requireAuth(
        context: context,
        message: 'Please sign in to view details and watch on Masti Adda.',
        onSuccess: () {
          Get.toNamed(
            '${WebRoutes.details}?id=$targetId&type=$targetType',
            arguments: {'id': targetId, 'type': targetType},
          );
        },
      );
    }
  }

  DateTime? _lastKeyEventTime;
  LogicalKeyboardKey? _lastKeyEventKey;

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final now = DateTime.now();
    // Throttle carousel slide switching to 350ms so long press advances smoothly without spastic skipping
    if (_lastKeyEventKey == event.logicalKey &&
        _lastKeyEventTime != null &&
        now.difference(_lastKeyEventTime!).inMilliseconds < 350) {
      return;
    }

    _lastKeyEventTime = now;
    _lastKeyEventKey = event.logicalKey;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _carouselController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _carouselController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = WebResponsive.isMobile(context);
    final isTablet = WebResponsive.isTablet(context);
    final double bannerHeight = isMobile
        ? 340.0
        : (isTablet ? 460.0 : 560.0);

    if (widget.isLoading) {
      return WebShimmerBanner(height: bannerHeight);
    }

    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      onEnter: (_) {
        if (_focusNode.canRequestFocus) {
          _focusNode.requestFocus();
        }
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: widget.banners.length,
              options: CarouselOptions(
                height: bannerHeight,
                viewportFraction: 1.0,
                autoPlay: widget.banners.length > 1,
                autoPlayInterval: const Duration(seconds: 6),
                autoPlayAnimationDuration: const Duration(milliseconds: 900),
                autoPlayCurve: Curves.easeInOutCubic,
                onPageChanged: (index, reason) {
                  setState(() => _currentIndex = index);
                },
              ),
              itemBuilder: (context, index, realIndex) {
                final banner = widget.banners[index];
                final description = banner.content?.storyline ?? '';

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Background Backdrop Image with Multi-Tier Fallback
                    _HeroBannerImage(banner: banner),

                    // 2. Cinematic Gradients
                    // // Left-to-Right dark vignette for text readability
                    // Positioned.fill(
                    //   child: Container(
                    //     decoration: BoxDecoration(
                    //       gradient: LinearGradient(
                    //         begin: Alignment.centerLeft,
                    //         end: Alignment.centerRight,
                    //         colors: [
                    //           AppColors.backgroundColor,
                    //           AppColors.backgroundColor.withOpacity(0.9),
                    //           AppColors.backgroundColor.withOpacity(0.5),
                    //           Colors.transparent,
                    //         ],
                    //         stops: const [0.0, 0.35, 0.65, 1.0],
                    //       ),
                    //     ),
                    //   ),
                    // ),

                    // Bottom-to-Top fade into page background
                    // Positioned.fill(
                    //   child: Container(
                    //     decoration: BoxDecoration(
                    //       gradient: LinearGradient(
                    //         begin: Alignment.bottomCenter,
                    //         end: Alignment.topCenter,
                    //         colors: [
                    //           AppColors.backgroundColor,
                    //           AppColors.backgroundColor.withOpacity(0.7),
                    //           Colors.transparent,
                    //         ],
                    //         stops: const [0.0, 0.25, 0.6],
                    //       ),
                    //     ),
                    //   ),
                    // ),

                    // 3. Hero Content Information
                    Positioned(
                      left: WebResponsive.contentHorizontalPadding(context),
                      right: isMobile
                          ? 20
                          : (MediaQuery.sizeOf(context).width * 0.4),
                      bottom: isMobile ? 36 : 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Featured Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPink.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primaryPink.withOpacity(0.6),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  color: AppColors.primaryPink,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (banner.contentType ?? 'FEATURED')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primaryPink,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Title
                          Text(
                            banner.title ??
                                banner.content?.title ??
                                'Experience Great Cinema',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: isMobile ? 24 : (isTablet ? 32 : 42),
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Description
                          if (description.isNotEmpty && !isMobile)
                            Text(
                              description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.white.withOpacity(0.85),
                                fontSize: isTablet ? 13 : 15,
                                height: 1.4,
                              ),
                            ),
                          const SizedBox(height: 20),

                          // Action Buttons
                          Wrap(
                            spacing: 14,
                            runSpacing: 10,
                            children: [
                              // Watch Now Button
                              ElevatedButton.icon(
                                onPressed: () => _onWatchNow(banner),
                                icon: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 24,
                                  color: Colors.white,
                                ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 6,
                                  shadowColor: AppColors.primaryPink
                                      .withOpacity(0.5),
                                ),
                              ),

                              // Details Button
                              OutlinedButton.icon(
                                onPressed: () => _onWatchNow(banner),
                                icon: const Icon(
                                  Icons.info_outline_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'More Details',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(
                                    0.12,
                                  ),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            // Carousel Indicator Dots
            if (widget.banners.length > 1)
              Positioned(
                bottom: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widget.banners.asMap().entries.map((entry) {
                    final isSelected = _currentIndex == entry.key;
                    return GestureDetector(
                      onTap: () => _carouselController.animateToPage(entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isSelected ? 24.0 : 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryPink
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroBannerImage extends StatefulWidget {
  final HomeBannerItem banner;

  const _HeroBannerImage({required this.banner});

  @override
  State<_HeroBannerImage> createState() => _HeroBannerImageState();
}

class _HeroBannerImageState extends State<_HeroBannerImage> {
  int _candidateIndex = 0;
  List<String> _candidates = [];

  @override
  void initState() {
    super.initState();
    _buildCandidates();
  }

  @override
  void didUpdateWidget(covariant _HeroBannerImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banner.id != widget.banner.id ||
        oldWidget.banner.banner != widget.banner.banner ||
        oldWidget.banner.content?.banner != widget.banner.content?.banner ||
        oldWidget.banner.content?.poster != widget.banner.content?.poster) {
      _candidateIndex = 0;
      _buildCandidates();
    }
  }

  void _buildCandidates() {
    final banner = widget.banner;
    final rawList = <String?>[
      banner.banner,
      banner.content?.banner,
      banner.content?.poster,
    ];

    final uniqueFormatted = <String>[];
    for (final raw in rawList) {
      if (raw != null && raw.trim().isNotEmpty) {
        final formatted = formatMediaUrl(raw);
        if (formatted.isNotEmpty && !uniqueFormatted.contains(formatted)) {
          uniqueFormatted.add(formatted);
        }
      }
    }

    _candidates = uniqueFormatted;
  }

  void _onError() {
    if (_candidateIndex + 1 < _candidates.length) {
      if (mounted) {
        setState(() {
          _candidateIndex++;
        });
      }
    } else {
      // If all candidates failed, trigger silent background re-fetch in case URLs expired
      if (Get.isRegistered<WebHomeController>()) {
        Get.find<WebHomeController>().fetchBanners(isSilent: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_candidates.isEmpty) {
      return _buildPlaceholder();
    }

    final currentUrl = _candidates[_candidateIndex];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Primary Banner Image (Cover to prevent stretching, with increased height for complete view)
        Image.network(
          currentUrl,
          fit: BoxFit.fill,
          alignment: Alignment.center,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              return child;
            }
            return Container(color: AppColors.surfaceColor);
          },
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _onError());
            return _candidateIndex + 1 < _candidates.length
                ? Container(color: AppColors.surfaceColor)
                : _buildPlaceholder();
          },
        ),

        // Dark gradient overlay for text readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B1E29),
            Color(0xFF13151D),
            Color(0xFF0E0F15),
          ],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.25,
          child: Image.asset(
            AppImages.logo,
            height: 64,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.movie_creation_outlined,
              color: AppColors.secondaryTextColor,
              size: 56,
            ),
          ),
        ),
      ),
    );
  }
}
