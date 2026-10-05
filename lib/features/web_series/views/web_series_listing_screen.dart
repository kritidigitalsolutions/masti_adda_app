import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/features/web_series/controllers/series_controller.dart';
import 'package:masti_adda_app/features/web_series/model/SeriesModel.dart';
import 'package:masti_adda_app/features/web_series/views/web_series_detail_screen.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/shared/widgets/shimmer/shimmer.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class WebSeriesListingScreen extends StatefulWidget {
  const WebSeriesListingScreen({super.key});

  @override
  State<WebSeriesListingScreen> createState() => _WebSeriesListingScreenState();
}

class _WebSeriesListingScreenState extends State<WebSeriesListingScreen> {
  late final SeriesController _controller;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = Get.find<SeriesController>();
    final args = Get.arguments;
    if (args is Map) {
      final initialCategory = args['category']?.toString() ??
          args['categoryName']?.toString() ??
          args['title']?.toString();
      final initialSlug =
          args['categorySlug']?.toString() ?? args['slug']?.toString();
      if (initialCategory != null && initialCategory.isNotEmpty) {
        _controller.selectCategoryByName(initialCategory, slug: initialSlug);
      } else if (initialSlug != null && initialSlug.isNotEmpty) {
        _controller.selectCategoryByName(initialSlug, slug: initialSlug);
      }
    } else if (args is String && args.isNotEmpty) {
      _controller.selectCategoryByName(args);
    }
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      _controller.searchSeries(_searchController.text);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchAllSeries();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_controller.currentSearchQuery.value.isEmpty) {
        _controller.fetchMoreSeries();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
            const SizedBox(height: 12),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Obx(() {
      final isSearchOpen = _controller.isSearchOpen.value;
      final query = _controller.currentSearchQuery.value;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: isSearchOpen
            ? Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.borderColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.hintTextColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: text13(color: AppColors.white),
                        decoration: InputDecoration(
                          hintText: 'Search series by title, genre, cast...',
                          hintStyle: text13(color: AppColors.hintTextColor),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    if (query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          _controller.clearSearch();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.hintTextColor,
                            size: 18,
                          ),
                        ),
                      ),
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _controller.closeSearch();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, right: 12),
                        child: Text(
                          'Cancel',
                          style: text13(
                            color: AppColors.accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Text(
                    _controller.currentCategoryName == 'All'
                        ? 'Web Series'
                        : _controller.currentCategoryName,
                    style: text18(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _controller.openSearch();
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _searchFocusNode.requestFocus();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.borderColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
      );
    });
  }

  Widget _buildCategoryTabs() {
    return Obx(() {
      final selectedIndex = _controller.selectedCategoryIndex.value;
      final categories = _controller.categories;

      return SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, index) {
            final isSelected = selectedIndex == index;
            return GestureDetector(
              onTap: () {
                _controller.selectCategory(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                    categories[index],
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

  Widget _buildGrid() {
    return Obx(() {
      final status = _controller.allSeriesStatus.value;
      final query = _controller.currentSearchQuery.value;
      final isSearchLoading =
          query.isNotEmpty && _controller.searchStatus.value == Status.loading;
      final seriesList = _controller.filteredSeries;

      // Handle loading state
      if (status == Status.loading &&
          _controller.allSeries.value == null &&
          seriesList.isEmpty) {
        return const ShimmerGrid(itemCount: 12);
      }

      // Handle error state
      if (status == Status.error &&
          _controller.allSeries.value == null &&
          seriesList.isEmpty) {
        return Center(
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
                'Failed to load series',
                style: text14(color: AppColors.secondaryTextColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _controller.fetchAllSeries();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                  foregroundColor: AppColors.black,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      // Handle empty state
      if (seriesList.isEmpty) {
        if (isSearchLoading) {
          return const ShimmerGrid(itemCount: 9);
        }

        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  query.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.tv_outlined,
                  color: AppColors.hintTextColor,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  query.isNotEmpty
                      ? "No web series found matching \"$query\""
                      : 'No web series found',
                  style: text16(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  query.isNotEmpty
                      ? 'Try searching with another title, genre, or keyword'
                      : 'Check back later for new releases',
                  style: text12(color: AppColors.secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
                if (query.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _searchController.clear();
                      _controller.clearSearch();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      foregroundColor: AppColors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      'Clear Search',
                      style: text13(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await _controller.fetchAllSeries();
        },
        color: AppColors.primaryColor,
        backgroundColor: AppColors.surfaceColor,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.62,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, index) => _buildCard(seriesList[index]),
                childCount: seriesList.length,
              ),
            ),
          ),
          if (query.isEmpty)
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
                return const SizedBox(height: 16);
              }),
            ),
        ],
      ),
    );
  });
}

  Widget _buildCard(Series item) {
    final img = formatMediaUrl(
      item.poster.isNotEmpty ? item.poster : item.banner,
    );
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => WebSeriesDetailScreen(id: item.id),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            img.isNotEmpty
                ? Image.network(
                    img,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.cardColor,
                      child: const Center(
                        child: Icon(
                          Icons.tv_rounded,
                          color: AppColors.hintTextColor,
                          size: 32,
                        ),
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.cardColor,
                    child: const Center(
                      child: Icon(
                        Icons.tv_rounded,
                        color: AppColors.hintTextColor,
                        size: 32,
                      ),
                    ),
                  ),
            // Coming soon badge
            if (item.isComingSoon)
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
            if (item.isPremium)
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
            // Bottom Title overlay
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
                      AppColors.backgroundColor.withValues(alpha: 0.9),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: text10(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper text style for badges
TextStyle text8({Color? color, FontWeight? fontWeight}) {
  return TextStyle(
    fontSize: 8,
    color: color ?? AppColors.white,
    fontWeight: fontWeight ?? FontWeight.normal,
  );
}
