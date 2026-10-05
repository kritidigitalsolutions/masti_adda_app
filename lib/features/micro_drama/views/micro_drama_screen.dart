import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/features/home/controllers/home_controller.dart';
import 'package:masti_adda_app/features/home/widgets/continue_watching_helper.dart';
import 'package:masti_adda_app/features/micro_drama/controllers/continue_watching_controller.dart';
import 'package:masti_adda_app/features/micro_drama/controllers/micro_drama_controller.dart';
import 'package:masti_adda_app/features/micro_drama/models/continue_watching_model.dart';
import 'package:masti_adda_app/features/micro_drama/models/micro_drama_model.dart';
import 'package:masti_adda_app/features/micro_drama/views/micro_drama_detail_screen.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/shared/widgets/shimmer/shimmer.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class MicroDramaScreen extends StatefulWidget {
  const MicroDramaScreen({super.key});

  @override
  State<MicroDramaScreen> createState() => _MicroDramaScreenState();
}

class _MicroDramaScreenState extends State<MicroDramaScreen> {
  final RxInt selectedCategoryIndex = 0.obs;
  late final MicroDramaController _controller;
  late final ContinueWatchingController _cwController;
  final ScrollController _scrollController = ScrollController();

  List<String> get categories {
    final list = <String>['All'];
    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      for (final cat in homeController.categories) {
        if (!list.contains(cat.name)) list.add(cat.name);
      }
    }
    final all = _controller.allMicroDrama.value?.microdramas ?? [];
    for (final d in all) {
      for (final g in d.genre) {
        final str = g.toString().trim();
        if (str.isNotEmpty && !list.contains(str)) {
          list.add(str);
        }
      }
    }
    return list;
  }

  String get currentCategoryName {
    final cats = categories;
    if (selectedCategoryIndex.value >= 0 &&
        selectedCategoryIndex.value < cats.length) {
      return cats[selectedCategoryIndex.value];
    }
    return 'All';
  }

  void _selectCategoryByName(String name, {String? slug}) {
    if (name.isEmpty && (slug == null || slug.isEmpty)) return;
    final cats = categories;
    String clean(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final targetName = clean(name);
    final targetSlug = slug != null ? clean(slug) : '';

    final index = cats.indexWhere((c) {
      final cLower = c.toLowerCase();
      final cClean = clean(c);
      return (name.isNotEmpty &&
              (cLower == name.toLowerCase() ||
                  (targetName.isNotEmpty && cClean == targetName))) ||
          (slug != null &&
              slug.isNotEmpty &&
              (cLower == slug.toLowerCase() ||
                  (targetSlug.isNotEmpty && cClean == targetSlug)));
    });
    if (index != -1) {
      selectedCategoryIndex.value = index;
    }
  }

  bool _matchesDramaCategoryName(Microdrama drama, String catName) {
    String clean(String s) =>
        s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final target = clean(catName);

    for (final c in drama.category) {
      if (c == null) continue;
      if (c is String) {
        if (c.toLowerCase() == catName.toLowerCase() ||
            (target.isNotEmpty && clean(c) == target)) {
          return true;
        }
      } else if (c is Map) {
        final name = (c['name'] ?? '').toString();
        final slug = (c['slug'] ?? '').toString();
        if (name.toLowerCase() == catName.toLowerCase() ||
            slug.toLowerCase() == catName.toLowerCase() ||
            (target.isNotEmpty && clean(name) == target) ||
            (target.isNotEmpty && clean(slug) == target)) {
          return true;
        }
      }
    }
    for (final g in drama.genre) {
      final gStr = g.toString();
      if (gStr.toLowerCase() == catName.toLowerCase() ||
          (target.isNotEmpty && clean(gStr) == target)) {
        return true;
      }
    }
    if (drama.slug.isNotEmpty &&
        (drama.slug.toLowerCase() == catName.toLowerCase() ||
            (target.isNotEmpty && clean(drama.slug) == target))) {
      return true;
    }
    return false;
  }

  List<Microdrama> _filteredDramas(List<Microdrama> allDramas) {
    final catName = currentCategoryName;
    final matched = allDramas.where((d) {
      if (catName == 'All') return true;
      return _matchesDramaCategoryName(d, catName);
    }).toList();

    matched.sort((a, b) {
      if (a.priority != b.priority) return a.priority.compareTo(b.priority);
      return b.rating.compareTo(a.rating);
    });

    return matched;
  }

  void _onCategorySelected(int index) {
    selectedCategoryIndex.value = index;
  }

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<MicroDramaController>()
        ? Get.find<MicroDramaController>()
        : Get.put(MicroDramaController());
    _cwController = Get.isRegistered<ContinueWatchingController>()
        ? Get.find<ContinueWatchingController>()
        : Get.put(ContinueWatchingController());

    final args = Get.arguments;
    if (args is Map) {
      final initialCategory = args['category']?.toString() ??
          args['categoryName']?.toString() ??
          args['title']?.toString();
      final initialSlug =
          args['categorySlug']?.toString() ?? args['slug']?.toString();
      if (initialCategory != null && initialCategory.isNotEmpty) {
        _selectCategoryByName(initialCategory, slug: initialSlug);
      } else if (initialSlug != null && initialSlug.isNotEmpty) {
        _selectCategoryByName(initialSlug, slug: initialSlug);
      }
    } else if (args is String && args.isNotEmpty) {
      _selectCategoryByName(args);
    }

    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchAllMicroDrama();
      _cwController.fetchContinueWatching();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.fetchMoreMicroDrama();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildCategoryTabs(),
            const SizedBox(height: 6),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    _controller.fetchAllMicroDrama(),
                    _cwController.fetchContinueWatching(),
                  ]);
                },
                color: AppColors.primaryColor,
                backgroundColor: AppColors.surfaceColor,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(child: _buildContinueWatchingSection()),
                    SliverToBoxAdapter(child: _buildDramaGridSection()),
                    SliverToBoxAdapter(
                      child: Obx(() {
                        if (_controller.isLoadingMore.value) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 30)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final canPop = Navigator.canPop(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          if (canPop) ...[
            const AppBackButton(),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Obx(() {
              final name = currentCategoryName;
              return Text(
                name == 'All' ? 'Micro Dramas' : name,
                style: text18(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Category chips ─────────────────────────────────────────────────────────
  Widget _buildCategoryTabs() {
    return Obx(() {
      final cats = categories;
      final selectedIndex = selectedCategoryIndex.value;

      return SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: cats.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final isSelected = selectedIndex == i;

            return GestureDetector(
              onTap: () => _onCategorySelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentColor
                      : AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentColor
                        : AppColors.borderColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    cats[i],
                    style: text12(
                      color: isSelected
                          ? AppColors.black
                          : AppColors.secondaryTextColor,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // // ── Hero banner section ────────────────────────────────────────────────────
  // Widget _buildHeroBannerSection() {
  //   return Obx(() {
  //     final allDramas = _controller.allMicroDrama.value?.microdramas ?? [];
  //     if (allDramas.isEmpty) return const SizedBox.shrink();
  //     final heroDrama = allDramas.first;
  //     return _buildHeroBanner(heroDrama);
  //   });
  // }

  // Widget _buildHeroBanner(Microdrama drama) {
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
  //     child: GestureDetector(
  //       onTap: () => _onDramaTap(drama),
  //       child: ClipRRect(
  //         borderRadius: BorderRadius.circular(16),
  //         child: Stack(
  //           children: [
  //             Image.network(
  //               "${AppUrl.baseUrl}${drama.banner}",
  //               height: 200,
  //               width: double.infinity,
  //               fit: BoxFit.cover,
  //               errorBuilder: (_, _, _) => Container(
  //                 height: 200,
  //                 color: AppColors.cardColor,
  //                 child: const Center(
  //                   child: Icon(
  //                     Icons.movie_outlined,
  //                     color: AppColors.hintTextColor,
  //                     size: 40,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //             // Gradient overlay
  //             Container(
  //               height: 200,
  //               decoration: BoxDecoration(
  //                 gradient: LinearGradient(
  //                   begin: Alignment.topCenter,
  //                   end: Alignment.bottomCenter,
  //                   colors: [
  //                     Colors.transparent,
  //                     AppColors.backgroundColor.withValues(alpha: 0.92),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //             // Title at bottom
  //             Positioned(
  //               bottom: 14,
  //               left: 14,
  //               right: 14,
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     drama.title,
  //                     style: text20(fontWeight: FontWeight.bold),
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     '${drama.totalEpisodes} Episodes',
  //                     style: text12(color: AppColors.secondaryTextColor),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // ── Continue Watching section ──────────────────────────────────────────────
  Widget _buildContinueWatchingSection() {
    return Obx(() {
      final list = _cwController.continueWatchingList;
      if (list.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Continue Watching',
                  style: text15(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${list.length} ${list.length == 1 ? 'Drama' : 'Dramas'}',
                  style: text12(color: AppColors.secondaryTextColor),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 175,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _buildContinueWatchingCard(list[i]),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildContinueWatchingCard(ContinueWatchingItem item) {
    final posterUrl = formatMediaUrl(item.displayPoster);
    final title = item.displayTitle;
    final epNum = item.displayEpisodeNumber;
    final epTitle = item.displayEpisodeTitle;
    final progress = item.progressRatio;
    final percentage = item.progressPercentage;

    return GestureDetector(
      onTap: () {
        ContinueWatchingHelper.playDirectly(
          context,
          item,
          onFinished: () => _cwController.fetchContinueWatching(),
        );
      },
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with progress bar & play icon
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  posterUrl.isNotEmpty
                      ? Image.network(
                          posterUrl,
                          height: 105,
                          width: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _fallbackThumbnail(),
                        )
                      : _fallbackThumbnail(),

                  // Dark gradient at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Center Play Icon
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                  // Episode badge (bottom left)
                  if (epNum != null)
                    Positioned(
                      left: 7,
                      bottom: 8,
                      child: Text(
                        'Ep $epNum',
                        style: text10(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // Percentage badge (bottom right)
                  Positioned(
                    right: 7,
                    bottom: 8,
                    child: Text(
                      '$percentage%',
                      style: text10(
                        color: AppColors.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Progress bar at very bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.accentColor,
                      ),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Card Bottom Row: Left has Title & Subtitle, Right has 3-dots icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: text11(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (epTitle.isNotEmpty)
                        Text(
                          epTitle,
                          style: text10(color: AppColors.secondaryTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                        onFinished: () => _cwController.fetchContinueWatching(),
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

  Widget _fallbackThumbnail() {
    return Container(
      height: 105,
      width: 140,
      color: AppColors.cardColor,
      child: const Center(
        child: Icon(
          Icons.movie_outlined,
          color: AppColors.hintTextColor,
          size: 28,
        ),
      ),
    );
  }

  // ── Drama grid section ─────────────────────────────────────────────────────
  Widget _buildDramaGridSection() {
    return Obx(() {
      if (_controller.allMicroDramaStatus.value == Status.loading) {
        return const MicroDramaGridShimmer(
          itemCount: 6,
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        );
      }

      final allDramas = _controller.allMicroDrama.value?.microdramas ?? [];
      if (allDramas.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No micro dramas found',
              style: text13(color: AppColors.secondaryTextColor),
            ),
          ),
        );
      }

      final dramas = _filteredDramas(allDramas);
      return _buildDramaGrid(dramas);
    });
  }

  Widget _buildDramaGrid(List<Microdrama> dramas) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: dramas.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (_, i) => _buildDramaCard(dramas[i]),
      ),
    );
  }

  Widget _buildDramaCard(Microdrama drama) {
    final bannerUrl = formatMediaUrl(drama.banner);
    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => MicroDramaDetailScreen(id: drama.id),
              ),
            )
            .then((_) => _cwController.fetchContinueWatching());
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              bannerUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.cardColor,
                child: const Center(
                  child: Icon(
                    Icons.movie_outlined,
                    color: AppColors.hintTextColor,
                    size: 32,
                  ),
                ),
              ),
            ),
            // Coming soon badge
            if (drama.isComingSoon)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: text8(
                      color: AppColors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Premium badge (Uncomment if needed in future):
            /*
            if (drama.isPremium)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PREMIUM',
                    style: text8(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            */
            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.backgroundColor.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),
            // Title
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Text(
                drama.title.toUpperCase(),
                style: text10(fontWeight: FontWeight.bold),
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle text8({Color? color, FontWeight? fontWeight}) {
  return TextStyle(
    fontSize: 8,
    color: color ?? AppColors.white,
    fontWeight: fontWeight ?? FontWeight.normal,
  );
}
