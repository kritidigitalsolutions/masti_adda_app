import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/core/services/firebase_service.dart';
import 'package:masti_adda_app/features/home/controllers/home_controller.dart';
import 'package:masti_adda_app/features/home/models/category_detail_model.dart';
import 'package:masti_adda_app/features/home/models/category_model.dart';
import 'package:masti_adda_app/features/home/models/home_banner_model.dart';
import 'package:masti_adda_app/features/home/views/continue_watching_screen.dart';
import 'package:masti_adda_app/features/home/widgets/continue_watching_helper.dart';
import 'package:masti_adda_app/shared/widgets/shimmer/shimmer.dart';
import 'package:masti_adda_app/features/micro_drama/controllers/continue_watching_controller.dart';
import 'package:masti_adda_app/features/micro_drama/controllers/micro_drama_controller.dart';
import 'package:masti_adda_app/features/micro_drama/models/continue_watching_model.dart';
import 'package:masti_adda_app/features/micro_drama/models/micro_drama_model.dart';
import 'package:masti_adda_app/features/micro_drama/views/micro_drama_detail_screen.dart';
import 'package:masti_adda_app/features/movie/controllers/movie_controller.dart';
import 'package:masti_adda_app/features/movie/models/MovieModel.dart';
import 'package:masti_adda_app/features/movie/views/movie_details_screen.dart';
import 'package:masti_adda_app/features/profile/controllers/profile_controller.dart';
import 'package:masti_adda_app/features/profile/controllers/watchlist_controller.dart';
import 'package:masti_adda_app/features/web_series/controllers/series_controller.dart';
import 'package:masti_adda_app/features/web_series/model/SeriesModel.dart';
import 'package:masti_adda_app/features/web_series/views/web_series_detail_screen.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _currentBannerIndex = 0;
  int _selectedTabIndex =
      0; // 0 = For you, 1 = Movies, 2 = Web series, 3 = Micro dramas

  final List<String> _tabLabels = [
    'For you',
    'Movies',
    'Web series',
    'Micro dramas',
  ];

  // ─── GetX Controllers ────────────────────────────────────────────────────
  final HomeController _homeController = Get.find();
  final MovieController _movieController = Get.put(MovieController());
  final SeriesController _seriesController = Get.put(SeriesController());
  final MicroDramaController _microDramaController =
      Get.isRegistered<MicroDramaController>()
      ? Get.find<MicroDramaController>()
      : Get.put(MicroDramaController());
  final ProfileController _fetchProfileController = Get.put(
    ProfileController(),
  );
  final WatchlistController _watchlistController =
      Get.isRegistered<WatchlistController>()
      ? Get.find<WatchlistController>()
      : Get.put(WatchlistController());
  late final ContinueWatchingController _cwController;

  @override
  void initState() {
    super.initState();
    _movieController.fetchAllMovies();
    _seriesController.fetchAllSeries();
    _microDramaController.fetchAllMicroDrama();
    _homeController.fetchHomeBanners();
    _homeController.fetchCategories();
    _cwController = Get.isRegistered<ContinueWatchingController>()
        ? Get.find<ContinueWatchingController>()
        : Get.put(ContinueWatchingController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cwController.fetchForHome();
      _watchlistController.fetchWatchlist();
    });
  }

  void _onTabTapped(int index) {
    setState(() => _selectedTabIndex = index);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'Good evening';
    } else {
      return 'Good night';
    }
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return '☀️';
    } else if (hour >= 12 && hour < 18) {
      return '🌤️';
    } else if (hour >= 18 && hour < 22) {
      return '🌆';
    } else {
      return '🌙';
    }
  }

  // String _getGreetingTitle() {
  //   final hour = DateTime.now().hour;
  //   if (hour >= 4 && hour < 12) {
  //     return "What's the plan today?";
  //   } else if (hour >= 12 && hour < 17) {
  //     return "Ready for a break?";
  //   } else if (hour >= 17 && hour < 22) {
  //     return "What's the plan tonight?";
  //   } else {
  //     return "Late night entertainment?";
  //   }
  // }

  // ─── Navigation helper ──────────────────────────────────────────────────
  void _navigateToDetail(String id, {String type = 'movie'}) {
    if (type == 'movie') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => MovieDetailsScreen(id: id)));
    } else if (type == 'series' ||
        type == 'web_series' ||
        type == 'webseries') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => WebSeriesDetailScreen(id: id)));
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => MicroDramaDetailScreen(id: id)));
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _movieController.fetchAllMovies(),
      _seriesController.fetchAllSeries(),
      _microDramaController.fetchAllMicroDrama(),
      _homeController.fetchHomeBanners(),
      _homeController.fetchCategories(),
      _cwController.fetchForHome(),
      _watchlistController.fetchWatchlist(),
      _fetchProfileController.fetchProfile(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 1. Fixed Header (Greeting + Notification & Profile)
          _buildHeader(_fetchProfileController),

          // Scrollable Feed with Pull-To-Refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primaryColor,
              backgroundColor: AppColors.surfaceColor,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // 2. Fixed Search Bar (Always visible on scroll)
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  // 3. Quick Access Cards (Audio Stories & Micro Dramas)
                  SliverToBoxAdapter(child: _buildQuickCards()),

                  // 4. Category Filter Chips (For you, Movies, Web series, Micro dramas)
                  SliverToBoxAdapter(child: _buildTabRow()),

                  // 5. Trending / Featured Hero Banner
                  SliverToBoxAdapter(child: _buildHeroBanner()),

                  // 6. Tab-Selected Content
                  SliverToBoxAdapter(child: _buildContentForSelectedTab()),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader(ProfileController ctr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Dynamic Greeting and question
          Expanded(
            child: Obx(() {
              final user = ctr.user.value;
              final firstName = (user != null && user.name.trim().isNotEmpty)
                  ? ' ${user.name.trim().split(' ').first}'
                  : '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getGreeting(),
                        style: text13(color: AppColors.secondaryTextColor),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$firstName, ${_getGreetingEmoji()}',
                    style: text15(
                      color: AppColors.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }),
          ),

          // Right: Notification Bell & Profile Avatar
          Row(
            children: [
              // Notification button
              Obx(() {
                final unreadCount = Get.isRegistered<NotificationService>()
                    ? Get.find<NotificationService>().unreadCount.value
                    : 0;

                return GestureDetector(
                  onTap: () {
                    Get.toNamed(AppRoutes.notifications);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.accentColor,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),

              const SizedBox(width: 10),

              // User profile avatar
              Obx(() {
                final user = ctr.user.value;
                final initial = (user != null && user.name.trim().isNotEmpty)
                    ? user.name.trim()[0].toUpperCase()
                    : 'U';
                final hasImage =
                    user != null && user.profileImage.trim().isNotEmpty;
                final userImg = hasImage
                    ? formatMediaUrl(user.profileImage)
                    : '';

                return GestureDetector(
                  onTap: () {
                    Get.toNamed(AppRoutes.editProfile);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasImage
                        ? Image.network(
                            userImg,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _avatarInitial(initial),
                          )
                        : _avatarInitial(initial),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarInitial(String initial) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  // ─── Search Bar ─────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () {
          _homeController.changeTab(3); // Switches to search tab
        },
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.borderColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search,
                color: AppColors.hintTextColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search movies, series and dramas',
                  style: text13(color: AppColors.hintTextColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tab Row ──────────────────────────────────────────────────────────
  Widget _buildTabRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _tabLabels.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final label = _tabLabels[i];
            final selected = _selectedTabIndex == i;
            return GestureDetector(
              onTap: () => _onTabTapped(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.accentColor
                      : AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.accentColor
                        : AppColors.borderColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: text12(
                      color: selected
                          ? AppColors.white
                          : AppColors.secondaryTextColor,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Hero Banner / Trending Card ─────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Obx(() {
      final List<dynamic> banners = _homeController.banners.isNotEmpty
          ? _homeController.banners
          : [];

      if (_homeController.isBannersLoading.value && banners.isEmpty) {
        return const HomeBannerShimmer();
      }

      if (banners.isEmpty) return const SizedBox.shrink();

      final int activeIndex = _currentBannerIndex >= banners.length
          ? 0
          : _currentBannerIndex;

      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Column(
          children: [
            CarouselSlider.builder(
              itemCount: banners.length,
              itemBuilder: (context, index, realIndex) {
                final bannerItem = banners[index];
                String title = '';
                String imageUrl = '';
                String contentId = '';
                String contentType = 'movie';

                if (bannerItem is HomeBannerItem) {
                  title = bannerItem.title ?? bannerItem.content?.title ?? '';
                  imageUrl = formatMediaUrl(
                    bannerItem.banner ??
                        bannerItem.content?.banner ??
                        bannerItem.content?.poster ??
                        '',
                  );
                  contentId = bannerItem.content?.id ?? '';
                  contentType =
                      (bannerItem.contentType ??
                              bannerItem.content?.type ??
                              'movie')
                          .toLowerCase();
                } else if (bannerItem is Map<String, dynamic>) {
                  title = bannerItem['title'] ?? '';
                  imageUrl = formatMediaUrl(bannerItem['image'] ?? '');
                  contentId = bannerItem['id'] ?? '';
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image
                        if (imageUrl.isNotEmpty)
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: AppColors.cardColor,
                              child: const Center(
                                child: Icon(
                                  Icons.movie_outlined,
                                  color: AppColors.hintTextColor,
                                  size: 40,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            color: AppColors.cardColor,
                            child: const Center(
                              child: Icon(
                                Icons.movie_outlined,
                                color: AppColors.hintTextColor,
                                size: 40,
                              ),
                            ),
                          ),

                        // Gradient shadow
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.2),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.9),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),

                        // "Trending now" Top-Left Badge
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Trending now',
                              style: TextStyle(
                                color: AppColors.accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // Title & Action buttons at bottom
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: text20(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // "Watch now" Button
                                  GestureDetector(
                                    onTap: () {
                                      if (contentId.isNotEmpty) {
                                        _navigateToDetail(
                                          contentId,
                                          type: contentType,
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.play_arrow_rounded,
                                            color: AppColors.black,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Watch now',
                                            style: text13(
                                              color: AppColors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  // Add to Watchlist Button (+)
                                  // Obx(() {
                                  //   final isSaved = contentId.isNotEmpty &&
                                  //       _watchlistController.isItemInWatchlist(
                                  //         contentId,
                                  //       );

                                  //   return GestureDetector(
                                  //     onTap: () {
                                  //       if (contentId.isNotEmpty) {
                                  //         _watchlistController.toggleWatchlist(
                                  //           contentId,
                                  //         );
                                  //       }
                                  //     },
                                  //     child: Container(
                                  //       width: 38,
                                  //       height: 38,
                                  //       decoration: BoxDecoration(
                                  //         color: Colors.white.withValues(
                                  //           alpha: 0.22,
                                  //         ),
                                  //         shape: BoxShape.circle,
                                  //       ),
                                  //       child: Icon(
                                  //         isSaved
                                  //             ? Icons.check_rounded
                                  //             : Icons.add_rounded,
                                  //         color: Colors.white,
                                  //         size: 20,
                                  //       ),
                                  //     ),
                                  //   );
                                  // }),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              options: CarouselOptions(
                height: 200,
                viewportFraction: 0.93,
                enlargeCenterPage: true,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayCurve: Curves.easeInOut,
                autoPlayAnimationDuration: const Duration(milliseconds: 600),
                onPageChanged: (index, reason) {
                  setState(() => _currentBannerIndex = index);
                },
              ),
            ),

            const SizedBox(height: 10),

            // Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (index) {
                final isActive = activeIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: isActive ? 20 : 5,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.accentColor : Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  // ─── 2 Quick Access Feature Cards (Audio Stories & Micro Dramas) ─────────
  Widget _buildQuickCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Row(
        children: [
          // Audio Stories Card
          Expanded(
            child: GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.audioStories),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2E1022), Color(0xFF191024)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFF2A7A).withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2A7A).withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF0564), Color(0xFFFF528E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFF0564,
                            ).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.headphones_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Audio Stories',
                            style: text12(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.graphic_eq_rounded,
                                size: 10,
                                color: Color(0xFFFF528E),
                              ),
                              const SizedBox(width: 3),
                              const Flexible(
                                child: Text(
                                  'Listen audio',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFF75A5),
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
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: Color(0xFFFF528E),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Micro Dramas Card
          Expanded(
            child: GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.microDrama),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF22113D), Color(0xFF14132B)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF8C52FF).withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8C52FF).withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C4DFF), Color(0xFFA57DFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF7C4DFF,
                            ).withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.smartphone_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Micro Dramas',
                            style: text12(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.flash_on_rounded,
                                size: 10,
                                color: Color(0xFFA57DFF),
                              ),
                              const SizedBox(width: 2),
                              const Flexible(
                                child: Text(
                                  'Vertical shorts',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFC0A6FF),
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
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: Color(0xFFA57DFF),
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

  // ─── Content selection ──────────────────────────────────────────────────
  Widget _buildContentForSelectedTab() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildForYouContent();
      case 1:
        return _buildMoviesContent();
      case 2:
        return _buildSeriesContent();
      case 3:
        return _buildMicroDramasContent();
      default:
        return _buildForYouContent();
    }
  }

  // ─── 1. "For You" Tab Content ───────────────────────────────────────────
  Widget _buildForYouContent() {
    return Obx(() {
      final isMoviesLoading =
          _movieController.allMoviesStatus.value == Status.loading &&
          _movieController.allMovies.isEmpty;
      final isSeriesLoading =
          _seriesController.allSeriesStatus.value == Status.loading &&
          (_seriesController.allSeries.value?.series.isEmpty ?? true);

      if (isMoviesLoading && isSeriesLoading) {
        return const HomeFeedShimmer(sectionCount: 3);
      }

      // Popular Movies
      List<MovieModel> popularMovies = _movieController.allMovies
          .where((m) => m.isPopular)
          .toList();
      if (popularMovies.isEmpty) {
        popularMovies = List<MovieModel>.from(_movieController.allMovies)
          ..sort((a, b) => b.rating.compareTo(a.rating));
      }

      // Top Web Series
      final allSeries = _seriesController.allSeries.value?.series ?? [];
      List<Series> topSeries = allSeries.where((s) => s.isPopular).toList();
      if (topSeries.isEmpty) {
        topSeries = List<Series>.from(allSeries)
          ..sort((a, b) => b.rating.compareTo(a.rating));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Continue Watching
          _buildContinueWatchingSection(),

          // Popular Movies
          if (popularMovies.isNotEmpty)
            _buildMediaSection(
              title: 'Popular Movies',
              items: popularMovies.map((m) => _toMap(m, 'movie')).toList(),
              onViewAll: () => Get.toNamed(
                AppRoutes.movieListing,
                arguments: {'title': 'Popular Movies', 'category': 'All'},
              ),
            ),

          // Top Web Series
          if (topSeries.isNotEmpty)
            _buildMediaSection(
              title: 'Top Web Series',
              items: topSeries.map((s) => _toMap(s, 'series')).toList(),
              onViewAll: () => Get.toNamed(
                AppRoutes.webSeries,
                arguments: {'title': 'Top Web Series', 'category': 'All'},
              ),
            ),

          // Trending Micro Dramas
          _buildMicroDramaHorizontalSection(),
        ],
      );
    });
  }

  // ─── 2. "Movies" Tab Content ────────────────────────────────────────────
  Widget _buildMoviesContent() {
    return Obx(() {
      final isMoviesLoading =
          _movieController.allMoviesStatus.value == Status.loading &&
          _movieController.allMovies.isEmpty;
      final isCatsLoading =
          _homeController.isCategoriesLoading.value &&
          _homeController.categories.isEmpty;

      if (isMoviesLoading && isCatsLoading) {
        return const HomeFeedShimmer(
          showContinueWatching: true,
          sectionCount: 2,
        );
      }

      final allMovies = _movieController.allMovies;
      // Sort categories by priority ascending (priority 1, 2, 3...)
      final sortedCategories = List<CategoryModel>.from(_homeController.categories)
        ..sort((a, b) => a.priority.compareTo(b.priority));

      final List<Widget> categorySections = [];
      for (final cat in sortedCategories) {
        // 1. From categoryContents API
        final apiContent = _homeController.categoryContents[cat.id] ?? [];
        final apiMovies = apiContent
            .where((c) => _isMovieContent(c, allMovies))
            .toList();

        // 2. From allMovies (local match)
        final matchedMovies = allMovies
            .where((m) => _matchesMovieCategory(m, cat))
            .toList();

        final List<Map<String, dynamic>> items = [];
        final Set<String> seenIds = {};

        for (final c in apiMovies) {
          if (c.id.isNotEmpty && !seenIds.contains(c.id)) {
            seenIds.add(c.id);
            items.add({
              'id': c.id,
              'title': c.title,
              'image': c.poster.isNotEmpty ? c.poster : c.banner,
              'type': 'movie',
              'isPremium': c.isPremium,
              'priority': c.priority,
              'rating': c.rating.toDouble(),
            });
          }
        }

        for (final m in matchedMovies) {
          if (m.id.isNotEmpty && !seenIds.contains(m.id)) {
            seenIds.add(m.id);
            items.add({
              'id': m.id,
              'title': m.title,
              'image': m.poster.isNotEmpty ? m.poster : m.banner,
              'type': 'movie',
              'isPremium': m.isPremium,
              'priority': m.priority,
              'rating': m.rating,
            });
          }
        }

        if (items.isNotEmpty) {
          // Sort movies by priority, then rating
          items.sort((a, b) {
            final pA = a['priority'] as int? ?? 0;
            final pB = b['priority'] as int? ?? 0;
            if (pA != pB) return pA.compareTo(pB);
            final rA = (a['rating'] as num?)?.toDouble() ?? 0.0;
            final rB = (b['rating'] as num?)?.toDouble() ?? 0.0;
            return rB.compareTo(rA);
          });

          categorySections.add(
            _buildMediaSection(
              title: cat.name,
              items: items,
              onViewAll: () => Get.toNamed(
                AppRoutes.movieListing,
                arguments: {
                  'category': cat.name,
                  'categoryId': cat.id,
                  'categorySlug': cat.slug,
                },
              ),
            ),
          );
        }
      }

      if (categorySections.isEmpty && allMovies.isNotEmpty) {
        final sortedAllMovies = List<MovieModel>.from(allMovies)
          ..sort((a, b) {
            if (a.priority != b.priority) {
              return a.priority.compareTo(b.priority);
            }
            return b.rating.compareTo(a.rating);
          });

        categorySections.add(
          _buildMediaSection(
            title: 'All Movies',
            items: sortedAllMovies.map((m) => _toMap(m, 'movie')).toList(),
            onViewAll: () => Get.toNamed(
              AppRoutes.movieListing,
              arguments: {'category': 'All'},
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContinueWatchingSection(filterType: 'movie'),
          ...categorySections,
        ],
      );
    });
  }

  // ─── 3. "Web Series" Tab Content ────────────────────────────────────────
  Widget _buildSeriesContent() {
    return Obx(() {
      final isSeriesLoading =
          _seriesController.allSeriesStatus.value == Status.loading &&
          (_seriesController.allSeries.value?.series.isEmpty ?? true);
      final isCatsLoading =
          _homeController.isCategoriesLoading.value &&
          _homeController.categories.isEmpty;

      if (isSeriesLoading && isCatsLoading) {
        return const HomeFeedShimmer(
          showContinueWatching: true,
          sectionCount: 2,
        );
      }

      final allSeries = _seriesController.allSeries.value?.series ?? [];
      // Sort categories by priority ascending (priority 1, 2, 3...)
      final sortedCategories = List<CategoryModel>.from(_homeController.categories)
        ..sort((a, b) => a.priority.compareTo(b.priority));

      final List<Widget> categorySections = [];
      for (final cat in sortedCategories) {
        // 1. From categoryContents API
        final apiContent = _homeController.categoryContents[cat.id] ?? [];
        final apiSeries = apiContent
            .where((c) => _isSeriesContent(c, allSeries))
            .toList();

        // 2. From allSeries (local match)
        final matchedSeries = allSeries
            .where((s) => _matchesSeriesCategory(s, cat))
            .toList();

        final List<Map<String, dynamic>> items = [];
        final Set<String> seenIds = {};

        for (final c in apiSeries) {
          if (c.id.isNotEmpty && !seenIds.contains(c.id)) {
            seenIds.add(c.id);
            items.add({
              'id': c.id,
              'title': c.title,
              'image': c.poster.isNotEmpty ? c.poster : c.banner,
              'type': 'series',
              'isPremium': c.isPremium,
              'priority': c.priority,
              'rating': c.rating.toDouble(),
            });
          }
        }

        for (final s in matchedSeries) {
          if (s.id.isNotEmpty && !seenIds.contains(s.id)) {
            seenIds.add(s.id);
            items.add({
              'id': s.id,
              'title': s.title,
              'image': s.poster.isNotEmpty ? s.poster : s.banner,
              'type': 'series',
              'isPremium': s.isPremium,
              'priority': s.priority,
              'rating': s.rating,
            });
          }
        }

        if (items.isNotEmpty) {
          // Sort series by priority, then rating
          items.sort((a, b) {
            final pA = a['priority'] as int? ?? 0;
            final pB = b['priority'] as int? ?? 0;
            if (pA != pB) return pA.compareTo(pB);
            final rA = (a['rating'] as num?)?.toDouble() ?? 0.0;
            final rB = (b['rating'] as num?)?.toDouble() ?? 0.0;
            return rB.compareTo(rA);
          });

          categorySections.add(
            _buildMediaSection(
              title: cat.name,
              items: items,
              onViewAll: () => Get.toNamed(
                AppRoutes.webSeries,
                arguments: {
                  'category': cat.name,
                  'categoryId': cat.id,
                  'categorySlug': cat.slug,
                },
              ),
            ),
          );
        }
      }

      if (categorySections.isEmpty && allSeries.isNotEmpty) {
        final sortedAllSeries = List<Series>.from(allSeries)
          ..sort((a, b) {
            if (a.priority != b.priority) {
              return a.priority.compareTo(b.priority);
            }
            return b.rating.compareTo(a.rating);
          });

        categorySections.add(
          _buildMediaSection(
            title: 'All Web Series',
            items: sortedAllSeries.map((s) => _toMap(s, 'series')).toList(),
            onViewAll: () => Get.toNamed(
              AppRoutes.webSeries,
              arguments: {'category': 'All'},
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContinueWatchingSection(filterType: 'series'),
          ...categorySections,
        ],
      );
    });
  }

  // ─── 4. "Micro Dramas" Tab Content ──────────────────────────────────────
  Widget _buildMicroDramasContent() {
    return Obx(() {
      final isDramaLoading =
          _microDramaController.allMicroDramaStatus.value == Status.loading &&
          (_microDramaController.allMicroDrama.value?.microdramas.isEmpty ??
              true);
      final isCatsLoading =
          _homeController.isCategoriesLoading.value &&
          _homeController.categories.isEmpty;

      if (isDramaLoading && isCatsLoading) {
        return const HomeFeedShimmer(
          showContinueWatching: true,
          sectionCount: 1,
        );
      }

      final dramas =
          _microDramaController.allMicroDrama.value?.microdramas ?? [];
      // Sort categories by priority ascending (priority 1, 2, 3...)
      final sortedCategories = List<CategoryModel>.from(_homeController.categories)
        ..sort((a, b) => a.priority.compareTo(b.priority));

      final List<Widget> categorySections = [];
      for (final cat in sortedCategories) {
        // 1. From categoryContents API
        final apiContent = _homeController.categoryContents[cat.id] ?? [];
        final apiDramas = apiContent
            .where((c) => _isDramaContent(c, dramas))
            .toList();

        // 2. From allMicroDrama (local match)
        final matchedDramas = dramas
            .where((d) => _matchesDramaCategory(d, cat))
            .toList();

        final List<Map<String, dynamic>> items = [];
        final Set<String> seenIds = {};

        for (final c in apiDramas) {
          if (c.id.isNotEmpty && !seenIds.contains(c.id)) {
            seenIds.add(c.id);
            items.add({
              'id': c.id,
              'title': c.title,
              'image': c.poster.isNotEmpty ? c.poster : c.banner,
              'type': 'microdrama',
              'isPremium': c.isPremium,
              'priority': c.priority,
              'rating': c.rating.toDouble(),
            });
          }
        }

        for (final d in matchedDramas) {
          if (d.id.isNotEmpty && !seenIds.contains(d.id)) {
            seenIds.add(d.id);
            items.add({
              'id': d.id,
              'title': d.title,
              'image': d.poster.isNotEmpty ? d.poster : d.banner,
              'type': 'microdrama',
              'isPremium': d.isPremium,
              'priority': d.priority,
              'rating': d.rating.toDouble(),
            });
          }
        }

        if (items.isNotEmpty) {
          // Sort dramas by priority, then rating
          items.sort((a, b) {
            final pA = a['priority'] as int? ?? 0;
            final pB = b['priority'] as int? ?? 0;
            if (pA != pB) return pA.compareTo(pB);
            final rA = (a['rating'] as num?)?.toDouble() ?? 0.0;
            final rB = (b['rating'] as num?)?.toDouble() ?? 0.0;
            return rB.compareTo(rA);
          });

          categorySections.add(
            _buildMediaSection(
              title: cat.name,
              items: items,
              onViewAll: () => Get.toNamed(
                AppRoutes.microDrama,
                arguments: {
                  'category': cat.name,
                  'categoryId': cat.id,
                  'categorySlug': cat.slug,
                },
              ),
            ),
          );
        }
      }

      if (categorySections.isEmpty && dramas.isNotEmpty) {
        final sortedDramas = List<Microdrama>.from(dramas)
          ..sort((a, b) {
            if (a.priority != b.priority) {
              return a.priority.compareTo(b.priority);
            }
            return b.rating.compareTo(a.rating);
          });

        categorySections.add(
          _buildMediaSection(
            title: 'All Micro Dramas',
            items: sortedDramas
                .map(
                  (d) => {
                    'id': d.id,
                    'title': d.title,
                    'image': d.poster.isNotEmpty ? d.poster : d.banner,
                    'type': 'microdrama',
                    'isPremium': d.isPremium,
                  },
                )
                .toList(),
            onViewAll: () => Get.toNamed(
              AppRoutes.microDrama,
              arguments: {'category': 'All'},
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContinueWatchingSection(filterType: 'microdrama'),
          ...categorySections,
        ],
      );
    });
  }

  // ─── Content Type Helpers ────────────────────────────────────────────────
  bool _isMovieContent(ContentModel c, List<MovieModel> allMovies) {
    final t = c.type.toLowerCase().trim();
    if (t == 'movie') return true;
    if (t.contains('series') || t.contains('drama') || t.contains('short')) {
      return false;
    }
    return allMovies.any((m) => m.id == c.id) || t.isEmpty;
  }

  bool _isSeriesContent(ContentModel c, List<Series> allSeries) {
    final t = c.type.toLowerCase().trim();
    if (t.contains('series') || t == 'webseries' || t == 'web_series') {
      return true;
    }
    if (t == 'movie' || t.contains('drama') || t.contains('short')) {
      return false;
    }
    return allSeries.any((s) => s.id == c.id);
  }

  bool _isDramaContent(ContentModel c, List<Microdrama> dramas) {
    final t = c.type.toLowerCase().trim();
    if (t.contains('drama') || t.contains('micro') || t.contains('short')) {
      return true;
    }
    if (t == 'movie' || t.contains('series')) {
      return false;
    }
    return dramas.any((d) => d.id == c.id);
  }

  // ─── Micro Drama Section in For You Feed ────────────────────────────────
  Widget _buildMicroDramaHorizontalSection() {
    return Obx(() {
      final dramas =
          _microDramaController.allMicroDrama.value?.microdramas ?? [];
      if (dramas.isEmpty) return const SizedBox.shrink();

      return _buildMediaSection(
        title: 'Trending Micro Dramas',
        items: dramas
            .take(10)
            .map(
              (d) => {
                'id': d.id,
                'title': d.title,
                'image': d.poster.isNotEmpty ? d.poster : d.banner,
                'type': 'microdrama',
                'isPremium': d.isPremium,
              },
            )
            .toList(),
        onViewAll: () => Get.toNamed(
          AppRoutes.microDrama,
          arguments: {'title': 'Trending Micro Dramas', 'category': 'All'},
        ),
      );
    });
  }

  // ─── Category Match Helpers ─────────────────────────────────────────────
  bool _slugOrNameMatches(dynamic itemValue, CategoryModel cat) {
    if (itemValue == null) return false;

    final catSlug = cat.slug.trim().toLowerCase();
    final catName = cat.name.trim().toLowerCase();
    final catId = cat.id.trim();

    String clean(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final cleanSlug = clean(catSlug);
    final cleanName = clean(catName);

    if (itemValue is String) {
      final v = itemValue.trim();
      if (v.isEmpty) return false;
      final vLower = v.toLowerCase();
      final vClean = clean(v);

      if (v == catId ||
          vLower == catSlug ||
          vLower == catName ||
          (cleanSlug.isNotEmpty && vClean == cleanSlug) ||
          (cleanName.isNotEmpty && vClean == cleanName)) {
        return true;
      }
    } else if (itemValue is Map) {
      final id = (itemValue['_id'] ?? itemValue['id'] ?? '').toString().trim();
      final slug = (itemValue['slug'] ?? '').toString().trim();
      final name = (itemValue['name'] ?? '').toString().trim();

      if (id.isNotEmpty && id == catId) return true;
      if (slug.isNotEmpty && _slugOrNameMatches(slug, cat)) return true;
      if (name.isNotEmpty && _slugOrNameMatches(name, cat)) return true;
    } else if (itemValue is List) {
      for (final sub in itemValue) {
        if (_slugOrNameMatches(sub, cat)) return true;
      }
    }
    return false;
  }

  bool _matchesMovieCategory(MovieModel movie, CategoryModel category) {
    for (final c in movie.category) {
      if (_slugOrNameMatches(c, category)) return true;
    }
    for (final g in movie.genre) {
      if (_slugOrNameMatches(g, category)) return true;
    }
    if (movie.slug.isNotEmpty && _slugOrNameMatches(movie.slug, category)) {
      return true;
    }
    return false;
  }

  bool _matchesSeriesCategory(Series series, CategoryModel category) {
    for (final c in series.category) {
      if (_slugOrNameMatches(c, category)) return true;
    }
    for (final g in series.genre) {
      if (_slugOrNameMatches(g, category)) return true;
    }
    if (series.slug.isNotEmpty && _slugOrNameMatches(series.slug, category)) {
      return true;
    }
    return false;
  }

  bool _matchesDramaCategory(Microdrama drama, CategoryModel category) {
    for (final c in drama.category) {
      if (_slugOrNameMatches(c, category)) return true;
    }
    for (final g in drama.genre) {
      if (_slugOrNameMatches(g, category)) return true;
    }
    if (drama.slug.isNotEmpty && _slugOrNameMatches(drama.slug, category)) {
      return true;
    }
    return false;
  }

  // ─── Continue Watching Section ──────────────────────────────────────────
  Widget _buildContinueWatchingSection({String? filterType}) {
    return Obx(() {
      List<ContinueWatchingItem> list = _cwController.homeList.toList();
      final isLoading =
          _cwController.homeFetchStatus.value == Status.loading && list.isEmpty;

      if (isLoading) {
        return const ContinueWatchingShimmer();
      }

      if (filterType != null) {
        list = list.where((item) {
          final t = item.contentType.toLowerCase().replaceAll('-', '_');
          if (filterType == 'movie') return t == 'movie';
          if (filterType == 'series') {
            return t == 'series' || t == 'web_series' || t == 'webseries';
          }
          if (filterType == 'microdrama') {
            return t == 'microdrama' || t == 'micro_drama';
          }
          return true;
        }).toList();
      }

      if (list.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Continue watching',
                  style: text18(fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    Get.to(
                      () => const ContinueWatchingScreen(),
                    )?.then((_) => _cwController.fetchForHome());
                  },
                  child: const Text(
                    'View All >',
                    style: TextStyle(
                      color: AppColors.accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = list[index];
                  return _buildCwCard(item);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCwCard(ContinueWatchingItem item) {
    final imageUrl = formatMediaUrl(item.displayPoster);
    final title = item.displayTitle;
    final epNum = item.displayEpisodeNumber;
    final epLabel = epNum != null ? 'EP $epNum' : null;
    final progress = item.progressRatio;
    final percentage = item.progressPercentage;
    final type = item.contentType;

    return GestureDetector(
      onTap: () {
        ContinueWatchingHelper.playDirectly(
          context,
          item,
          onFinished: () => _cwController.fetchForHome(),
        );
      },
      child: SizedBox(
        width: 165,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 165,
                          height: 98,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _cwFallback(),
                        )
                      : _cwFallback(),

                  // Dark subtle gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Progress bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentColor,
                      ),
                      minHeight: 3.5,
                    ),
                  ),

                  // Type badge (top-left)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _typeColor(type),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _typeLabel(type),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Percentage badge (bottom-right)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Text(
                      '$percentage%',
                      style: text10(
                        color: AppColors.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Card Bottom: Title & 3-dots
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: text12(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (epLabel != null)
                        Text(
                          epLabel,
                          style: text10(color: AppColors.hintTextColor),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ContinueWatchingHelper.showOptionsBottomSheet(
                      context,
                      item,
                      onDelete: () => _cwController.deleteItem(item),
                      onPlay: () => ContinueWatchingHelper.playDirectly(
                        context,
                        item,
                        onFinished: () => _cwController.fetchForHome(),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cwFallback() {
    return Container(
      width: 165,
      height: 98,
      color: AppColors.surfaceColor,
      child: const Center(
        child: Icon(Icons.play_circle_outline, color: AppColors.hintTextColor),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'movie':
        return const Color(0xFFE53935);
      case 'series':
      case 'web_series':
      case 'webseries':
        return const Color(0xFF29B6F6);
      case 'microdrama':
      case 'micro_drama':
        return const Color(0xFF8E24AA);
      default:
        return AppColors.borderColor;
    }
  }

  String _typeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'movie':
        return 'Movie';
      case 'series':
      case 'web_series':
      case 'webseries':
        return 'Series';
      case 'microdrama':
      case 'micro_drama':
        return 'Drama';
      default:
        return type.toUpperCase();
    }
  }

  // ─── Helper to convert MovieModel / Series to Map with type ──────────
  Map<String, dynamic> _toMap(dynamic item, String type) {
    if (item is MovieModel) {
      return {
        'id': item.id,
        'title': item.title,
        'image': item.poster,
        'type': type,
        'isPremium': item.isPremium,
      };
    } else if (item is Series) {
      return {
        'id': item.id,
        'title': item.title,
        'image': item.poster,
        'type': type,
        'isPremium': item.isPremium,
      };
    }
    return {};
  }

  // ─── Generic Media Section (Movies / Series / Dramas) ─────────────────
  Widget _buildMediaSection({
    required String title,
    required List<Map<String, dynamic>> items,
    VoidCallback? onViewAll,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: text16(fontWeight: FontWeight.bold)),
                if (onViewAll != null)
                  GestureDetector(
                    onTap: onViewAll,
                    child: const Text(
                      'View All >',
                      style: TextStyle(
                        color: AppColors.accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildMediaCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(Map<String, dynamic> item) {
    final rawUrl = item['image'] ?? '';
    final processedUrl = formatMediaUrl(rawUrl);
    final title = item['title'] ?? '';
    final type = item['type'] ?? 'movie';
    final id = item['id'] ?? '';

    return GestureDetector(
      onTap: () {
        if (id.isNotEmpty) {
          _navigateToDetail(id, type: type);
        }
      },
      child: SizedBox(
        width: 115,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      processedUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.surfaceColor,
                        child: const Center(
                          child: Icon(
                            Icons.movie_outlined,
                            color: AppColors.hintTextColor,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    if (type == 'microdrama' || type == 'micro_drama')
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C4DFF), Color(0xFF9E77FF)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF7C4DFF,
                                ).withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.smartphone_rounded,
                                color: Colors.white,
                                size: 8,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'SHORTS',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Premium badge (Uncomment if needed in future):
                    /*
                    if (item['isPremium'] == true)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PREMIUM',
                            style: TextStyle(
                              fontSize: 7.5,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    */
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: text11(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/*
// =============================================================================
// PREVIOUS HOME TAB DESIGN BACKUP (OLD LAYOUT)
// =============================================================================
// To switch back to this previous design in the future:
// 1. Rename the class above or comment out `class HomeTab` above.
// 2. Uncomment the code below and rename `HomeTabPreviousDesign` to `HomeTab`.
// =============================================================================

class HomeTabPreviousDesign extends StatefulWidget {
  const HomeTabPreviousDesign({super.key});

  @override
  State<HomeTabPreviousDesign> createState() => _HomeTabPreviousDesignState();
}

class _HomeTabPreviousDesignState extends State<HomeTabPreviousDesign> {
  int _currentBannerIndex = 0;
  int _selectedTabIndex = 0; // 0 = For You, 1 = Movies, 2 = Web Series

  final List<String> _tabLabels = ['For You', 'Movies', 'Web Series'];

  // ─── GetX Controllers ────────────────────────────────────────────────────
  final HomeController _homeController = Get.find();
  final MovieController _movieController = Get.put(MovieController());
  final SeriesController _seriesController = Get.put(SeriesController());
  final ProfileController _fetchProfileController = Get.put(ProfileController());
  late final ContinueWatchingController _cwController;

  @override
  void initState() {
    super.initState();
    _movieController.fetchAllMovies();
    _seriesController.fetchAllSeries();
    _homeController.fetchHomeBanners();
    _homeController.fetchCategories();
    _cwController = Get.isRegistered<ContinueWatchingController>()
        ? Get.find<ContinueWatchingController>()
        : Get.put(ContinueWatchingController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cwController.fetchForHome();
    });
  }

  void _onTabTapped(int index) {
    setState(() => _selectedTabIndex = index);
  }

  void _navigateToDetail(String id, {String type = 'movie'}) {
    if (type == 'movie') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MovieDetailsScreen(id: id)),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WebSeriesDetailScreen(id: id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(_fetchProfileController)),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildHeroBanner()),
          SliverToBoxAdapter(child: _buildAudioStoriesBanner()),
          SliverToBoxAdapter(child: _buildTabRow()),
          SliverToBoxAdapter(child: _buildContentForSelectedTab()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildContentForSelectedTab() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildForYouContent();
      case 1:
        return _buildMoviesContent();
      case 2:
        return _buildSeriesContent();
      default:
        return _buildForYouContent();
    }
  }

  Widget _buildForYouContent() {
    return Obx(() {
      final isMoviesLoading =
          _movieController.allMoviesStatus.value == Status.loading;
      final isSeriesLoading =
          _seriesController.allSeriesStatus.value == Status.loading;

      if (isMoviesLoading && isSeriesLoading) {
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      List<MovieModel> popularMovies = _movieController.allMovies
          .where((m) => m.isPopular)
          .toList();
      if (popularMovies.isEmpty) {
        popularMovies = List<MovieModel>.from(_movieController.allMovies)
          ..sort((a, b) => b.rating.compareTo(a.rating));
      }

      final allSeries = _seriesController.allSeries.value?.series ?? [];
      List<Series> topSeries = allSeries.where((s) => s.isPopular).toList();
      if (topSeries.isEmpty) {
        topSeries = List<Series>.from(allSeries)
          ..sort((a, b) => b.rating.compareTo(a.rating));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContinueWatchingSection(),
          if (popularMovies.isNotEmpty)
            _buildMediaSection(
              title: 'Popular Movies',
              items: popularMovies.map((m) => _toMap(m, 'movie')).toList(),
              onViewAll: () => Get.toNamed(AppRoutes.movieListing),
            ),
          if (topSeries.isNotEmpty)
            _buildMediaSection(
              title: 'Top Web Series',
              items: topSeries.map((s) => _toMap(s, 'series')).toList(),
              onViewAll: () => Get.toNamed(AppRoutes.webSeries),
            ),
        ],
      );
    });
  }

  Widget _buildMoviesContent() {
    return Obx(() {
      final isMoviesLoading =
          _movieController.allMoviesStatus.value == Status.loading;
      final isCatsLoading = _homeController.isCategoriesLoading.value;

      if (isMoviesLoading && isCatsLoading) {
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final allMovies = _movieController.allMovies;
      final topCategories = _homeController.categories;

      final List<Widget> categorySections = [];
      for (final cat in topCategories) {
        final matchedMovies = allMovies
            .where((m) => _matchesMovieCategory(m, cat))
            .toList();

        if (matchedMovies.isNotEmpty) {
          categorySections.add(
            _buildMediaSection(
              title: cat.name,
              items: matchedMovies.map((m) => _toMap(m, 'movie')).toList(),
              onViewAll: () => Get.toNamed(AppRoutes.movieListing),
            ),
          );
        }
      }

      if (categorySections.isEmpty && allMovies.isNotEmpty) {
        categorySections.add(
          _buildMediaSection(
            title: 'All Movies',
            items: allMovies.map((m) => _toMap(m, 'movie')).toList(),
            onViewAll: () => Get.toNamed(AppRoutes.movieListing),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildContinueWatchingSection(), ...categorySections],
      );
    });
  }

  Widget _buildSeriesContent() {
    return Obx(() {
      final isSeriesLoading =
          _seriesController.allSeriesStatus.value == Status.loading;
      final isCatsLoading = _homeController.isCategoriesLoading.value;

      if (isSeriesLoading && isCatsLoading) {
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final allSeries = _seriesController.allSeries.value?.series ?? [];
      final topCategories = _homeController.categories;

      final List<Widget> categorySections = [];
      for (final cat in topCategories) {
        final matchedSeries = allSeries
            .where((s) => _matchesSeriesCategory(s, cat))
            .toList();

        if (matchedSeries.isNotEmpty) {
          categorySections.add(
            _buildMediaSection(
              title: cat.name,
              items: matchedSeries.map((s) => _toMap(s, 'series')).toList(),
              onViewAll: () => Get.toNamed(AppRoutes.webSeries),
            ),
          );
        }
      }

      if (categorySections.isEmpty && allSeries.isNotEmpty) {
        categorySections.add(
          _buildMediaSection(
            title: 'All Web Series',
            items: allSeries.map((s) => _toMap(s, 'series')).toList(),
            onViewAll: () => Get.toNamed(AppRoutes.webSeries),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildContinueWatchingSection(), ...categorySections],
      );
    });
  }

  bool _slugOrNameMatchesBackup(dynamic itemValue, CategoryModel cat) {
    if (itemValue == null) return false;

    final catSlug = cat.slug.trim().toLowerCase();
    final catName = cat.name.trim().toLowerCase();
    final catId = cat.id.trim();

    String clean(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final cleanSlug = clean(catSlug);
    final cleanName = clean(catName);

    if (itemValue is String) {
      final v = itemValue.trim();
      if (v.isEmpty) return false;
      final vLower = v.toLowerCase();
      final vClean = clean(v);

      if (v == catId ||
          vLower == catSlug ||
          vLower == catName ||
          (cleanSlug.isNotEmpty && vClean == cleanSlug) ||
          (cleanName.isNotEmpty && vClean == cleanName)) {
        return true;
      }
    } else if (itemValue is Map) {
      final id = (itemValue['_id'] ?? itemValue['id'] ?? '').toString().trim();
      final slug = (itemValue['slug'] ?? '').toString().trim();
      final name = (itemValue['name'] ?? '').toString().trim();

      if (id.isNotEmpty && id == catId) return true;
      if (slug.isNotEmpty && _slugOrNameMatchesBackup(slug, cat)) return true;
      if (name.isNotEmpty && _slugOrNameMatchesBackup(name, cat)) return true;
    } else if (itemValue is List) {
      for (final sub in itemValue) {
        if (_slugOrNameMatchesBackup(sub, cat)) return true;
      }
    }
    return false;
  }

  bool _matchesMovieCategory(MovieModel movie, CategoryModel category) {
    for (final c in movie.category) {
      if (_slugOrNameMatchesBackup(c, category)) return true;
    }
    for (final g in movie.genre) {
      if (_slugOrNameMatchesBackup(g, category)) return true;
    }
    if (movie.slug.isNotEmpty && _slugOrNameMatchesBackup(movie.slug, category)) {
      return true;
    }
    return false;
  }

  bool _matchesSeriesCategory(Series series, CategoryModel category) {
    for (final c in series.category) {
      if (_slugOrNameMatchesBackup(c, category)) return true;
    }
    for (final g in series.genre) {
      if (_slugOrNameMatchesBackup(g, category)) return true;
    }
    if (series.slug.isNotEmpty && _slugOrNameMatchesBackup(series.slug, category)) {
      return true;
    }
    return false;
  }

  Widget _buildContinueWatchingSection() {
    return Obx(() {
      final list = _cwController.homeList;
      final isLoading = _cwController.homeFetchStatus.value == Status.loading;

      if (isLoading) {
        return const SizedBox(
          height: 170,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.accentColor),
          ),
        );
      }

      if (list.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Continue Watching',
                  style: text16(fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    Get.to(
                      () => const ContinueWatchingScreen(),
                    )?.then((_) => _cwController.fetchForHome());
                  },
                  child: const Text(
                    'View All >',
                    style: TextStyle(
                      color: AppColors.accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = list[index];
                  return _buildCwCard(item);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCwCard(ContinueWatchingItem item) {
    final imageUrl = formatMediaUrl(item.displayPoster);
    final title = item.displayTitle;
    final epNum = item.displayEpisodeNumber;
    final epLabel = epNum != null
        ? 'EP $epNum'
        : (item.contentType == 'movie' ? null : null);
    final progress = item.progressRatio;
    final percentage = item.progressPercentage;
    final type = item.contentType;

    return GestureDetector(
      onTap: () {
        ContinueWatchingHelper.playDirectly(
          context,
          item,
          onFinished: () => _cwController.fetchForHome(),
        );
      },
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 180,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _cwFallback(),
                        )
                      : _cwFallback(),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accentColor,
                      ),
                      minHeight: 3,
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _typeColor(type),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _typeLabel(type),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Text(
                      '$percentage%',
                      style: text10(
                        color: AppColors.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: text12(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (epLabel != null)
                        Text(
                          epLabel,
                          style: text10(color: AppColors.hintTextColor),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ContinueWatchingHelper.showOptionsBottomSheet(
                      context,
                      item,
                      onDelete: () => _cwController.deleteItem(item),
                      onPlay: () => ContinueWatchingHelper.playDirectly(
                        context,
                        item,
                        onFinished: () => _cwController.fetchForHome(),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cwFallback() {
    return Container(
      width: 180,
      height: 100,
      color: AppColors.cardColor,
      child: const Center(
        child: Icon(Icons.play_circle_outline, color: AppColors.hintTextColor),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'movie':
        return const Color(0xFFE53935);
      case 'series':
        return const Color(0xFF1E88E5);
      case 'microdrama':
        return AppColors.accentColor;
      default:
        return AppColors.borderColor;
    }
  }

  String _typeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'movie':
        return 'MOVIE';
      case 'series':
        return 'SERIES';
      case 'microdrama':
        return 'DRAMA';
      default:
        return type.toUpperCase();
    }
  }

  Map<String, dynamic> _toMap(dynamic item, String type) {
    if (item is MovieModel) {
      return {
        'id': item.id,
        'title': item.title,
        'image': item.poster,
        'type': type,
      };
    } else if (item is Series) {
      return {
        'id': item.id,
        'title': item.title,
        'image': item.poster,
        'type': type,
      };
    }
    return {};
  }

  Widget _buildMediaSection({
    required String title,
    required List<Map<String, dynamic>> items,
    VoidCallback? onViewAll,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: text16(fontWeight: FontWeight.bold)),
                if (onViewAll != null)
                  GestureDetector(
                    onTap: onViewAll,
                    child: const Text(
                      'View All >',
                      style: TextStyle(
                        color: AppColors.accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildMediaCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(Map<String, dynamic> item) {
    final rawUrl = item['image'] ?? '';
    final processedUrl = formatMediaUrl(rawUrl);
    final title = item['title'] ?? '';
    final type = item['type'] ?? 'movie';
    final id = item['id'] ?? '';

    return GestureDetector(
      onTap: () {
        if (id.isNotEmpty) {
          _navigateToDetail(id, type: type);
        }
      },
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  processedUrl,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.cardColor,
                    child: const Center(
                      child: Icon(
                        Icons.movie,
                        color: AppColors.hintTextColor,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: text10(fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabRow() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabLabels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = _tabLabels[i];
          final selected = _selectedTabIndex == i;
          return GestureDetector(
            onTap: () => _onTabTapped(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accentColor
                    : AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected
                      ? AppColors.accentColor
                      : AppColors.borderColor.withValues(alpha: 0.4),
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: text12(
                    color: selected
                        ? AppColors.black
                        : AppColors.secondaryTextColor,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ProfileController ctr) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Good Evening',
                          style: text14(color: AppColors.secondaryTextColor),
                        ),
                        const SizedBox(width: 4),
                        const Text('👋', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Get.toNamed(AppRoutes.microDrama);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accentColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🎬', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        'Enjoy Micro Dramas',
                        style: text10(
                          color: AppColors.accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'What do you want\nto watch today?',
                  style: text18(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Row(
                children: [
                  Obx(() {
                    final unreadCount = Get.isRegistered<NotificationService>()
                        ? Get.find<NotificationService>().unreadCount.value
                        : 0;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.borderColor,
                          child: IconButton(
                            color: AppColors.white,
                            icon: const Icon(Icons.notifications_none_rounded),
                            onPressed: () {
                              Get.toNamed(AppRoutes.notifications);
                            },
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.accentColor,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                  const SizedBox(width: 8),
                  Obx(() {
                    final user = ctr.user.value;

                    if (ctr.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (user == null) {
                      return const Center(child: Text("No user found"));
                    }
                    final userImg = formatMediaUrl(user.profileImage);
                    final hasImage = user.profileImage.isNotEmpty;
                    final initial = user.name.trim().isNotEmpty
                        ? user.name.trim()[0].toUpperCase()
                        : '?';

                    return ClipOval(
                      child: GestureDetector(
                        onTap: () {
                          Get.toNamed(AppRoutes.editProfile);
                        },
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: hasImage
                              ? Image.network(
                                  userImg,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _avatarInitial(initial),
                                )
                              : _avatarInitial(initial),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarInitial(String initial) {
    return Container(
      color: AppColors.primaryColor.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        _homeController.changeTab(3);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderColor.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(
                Icons.search,
                color: AppColors.hintTextColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AbsorbPointer(
                  child: TextField(
                    style: text13(color: AppColors.textColor),
                    decoration: InputDecoration(
                      hintText: 'Search movies, series & dramas',
                      hintStyle: text13(color: AppColors.hintTextColor),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Obx(() {
      final List<dynamic> banners = _homeController.banners.isNotEmpty
          ? _homeController.banners
          : [];

      if (banners.isEmpty) return const SizedBox.shrink();

      final int activeIndex = _currentBannerIndex >= banners.length
          ? 0
          : _currentBannerIndex;

      return Column(
        children: [
          CarouselSlider.builder(
            itemCount: banners.length,
            itemBuilder: (context, index, realIndex) {
              final bannerItem = banners[index];
              String title = '';
              String imageUrl = '';
              VoidCallback? onBannerTap;

              if (bannerItem is HomeBannerItem) {
                title = bannerItem.title ?? bannerItem.content?.title ?? '';
                imageUrl = formatMediaUrl(
                  bannerItem.banner ??
                      bannerItem.content?.banner ??
                      bannerItem.content?.poster ??
                      '',
                );
                final contentId = bannerItem.content?.id ?? '';
                final type = (bannerItem.contentType ??
                        bannerItem.content?.type ??
                        '')
                    .toLowerCase();

                onBannerTap = () {
                  if (contentId.isEmpty) return;
                  if (type == 'movie') {
                    Get.to(() => MovieDetailsScreen(id: contentId));
                  } else if (type == 'series' ||
                      type == 'web_series' ||
                      type == 'webseries') {
                    Get.to(() => WebSeriesDetailScreen(id: contentId));
                  } else if (type == 'microdrama' ||
                      type == 'micro_drama' ||
                      type == 'micro-drama') {
                    Get.to(() => MicroDramaDetailScreen(id: contentId));
                  }
                };
              } else if (bannerItem is Map<String, dynamic>) {
                title = bannerItem['title'] ?? '';
                imageUrl = formatMediaUrl(bannerItem['image'] ?? '');
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: onBannerTap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        if (imageUrl.isNotEmpty)
                          Image.network(
                            imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: 180,
                              color: AppColors.cardColor,
                              child: const Center(
                                child: Icon(
                                  Icons.movie,
                                  color: AppColors.hintTextColor,
                                  size: 40,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 180,
                            color: AppColors.cardColor,
                            child: const Center(
                              child: Icon(
                                Icons.movie,
                                color: AppColors.hintTextColor,
                                size: 40,
                              ),
                            ),
                          ),
                        Container(
                          height: 180,
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
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: text16(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: onBannerTap,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.play_arrow_rounded,
                                        color: AppColors.black,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Watch Now',
                                        style: text12(
                                          color: AppColors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: 180,
              viewportFraction: 0.92,
              enlargeCenterPage: true,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayCurve: Curves.easeInOut,
              autoPlayAnimationDuration: const Duration(milliseconds: 700),
              onPageChanged: (index, reason) {
                setState(() => _currentBannerIndex = index);
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (index) {
              final isActive = activeIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.accentColor
                      : AppColors.borderColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      );
    });
  }

  Widget _buildAudioStoriesBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.audioStories),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF0564),
                Color(0xFFFF6B35),
                AppColors.buttonColor,
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Text('🎧', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Enjoy Audio Stories',
                style: text13(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Center(
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.black,
                  size: 14,
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    );
  }
}
*/
