import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/audio_play/controllers/audio_stories_controller.dart';
import 'package:masti_adda_app/features/audio_play/models/audio_story_model.dart';
import 'package:masti_adda_app/features/audio_play/widgets/audio_mini_player.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/shared/widgets/shimmer/shimmer.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class AudioStoriesScreen extends StatefulWidget {
  const AudioStoriesScreen({super.key});

  @override
  State<AudioStoriesScreen> createState() => _AudioStoriesScreenState();
}

class _AudioStoriesScreenState extends State<AudioStoriesScreen> {
  late final AudioStoriesController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AudioStoriesController>()
        ? Get.find<AudioStoriesController>()
        : Get.put(AudioStoriesController());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      controller.fetchMoreStories();
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
      bottomNavigationBar: const AudioMiniPlayer(withSystemPadding: true),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(controller),
            _buildSearchBar(controller),
            Obx(() {
              if (controller.searchQuery.value.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _buildCategoryTabs(controller),
                );
              }
              return const SizedBox.shrink();
            }),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryColor,
                backgroundColor: AppColors.surfaceColor,
                onRefresh: controller.loadInitialData,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildBody(controller)),
                    SliverToBoxAdapter(
                      child: Obx(() {
                        if (controller.isLoadingMore.value) {
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
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AudioStoriesController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: 12),
          Text('Audio Stories', style: text18(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AudioStoriesController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.5)),
        ),
        child: TextField(
          controller: controller.searchController,
          onChanged: controller.onSearchChanged,
          style: text13(color: AppColors.textColor),
          cursorColor: AppColors.primaryColor,
          decoration: InputDecoration(
            hintText: 'Search audio stories by title...',
            hintStyle: text13(color: AppColors.hintTextColor),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.hintTextColor,
              size: 20,
            ),
            suffixIcon: Obx(() {
              if (controller.searchQuery.value.isNotEmpty) {
                return IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.hintTextColor,
                    size: 18,
                  ),
                  onPressed: controller.clearSearch,
                );
              }
              return const SizedBox.shrink();
            }),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AudioStoriesController controller) {
    return Obx(() {
      // 1. Search Mode
      if (controller.searchQuery.value.isNotEmpty) {
        if (controller.searchResults.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.music_off_rounded,
                    size: 48,
                    color: AppColors.hintTextColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No audio stories found for "${controller.searchQuery.value}"',
                    style: text14(color: AppColors.secondaryTextColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return _buildSearchResultsGrid(controller);
      }

      // 2. Loading State
      if (controller.isLoading.value && controller.allStories.isEmpty) {
        return const AudioStoriesFeedShimmer();
      }

      // 3. Normal Feed
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.selectedCategoryIndex.value == 0) ...[
            if (controller.continueListeningList.isNotEmpty)
              _buildContinueListening(controller),
            if (controller.heroBanner != null)
              _buildHeroBanner(controller),
            if (controller.topAudioStories.isNotEmpty)
              _buildSection(
                'Top Audio Stories',
                controller.topAudioStories,
                controller,
              ),
            if (controller.recentlyAdded.isNotEmpty)
              _buildSection(
                'Recently Added',
                controller.recentlyAdded,
                controller,
              ),
          ] else ...[
            _buildCategoryFilteredList(controller),
          ],
        ],
      );
    });
  }

  Widget _buildCategoryTabs(AudioStoriesController controller) {
    return SizedBox(
      height: 38,
      child: Obx(() {
        final selected = controller.selectedCategoryIndex.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final isSelected = selected == i;
            final cat = controller.categories[i];
            return GestureDetector(
              onTap: () => controller.onCategorySelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.borderColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    cat.name,
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
        );
      }),
    );
  }

  Widget _buildContinueListening(AudioStoriesController controller) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, color: AppColors.accentColor, size: 18),
                const SizedBox(width: 6),
                Text('Continue Listening', style: text15(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: controller.continueListeningList.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final item = controller.continueListeningList[i];
                final ep = item.episode;
                final story = controller.getStoryById(
                  item.storyId.isNotEmpty ? item.storyId : (ep?.storyId ?? ''),
                );

                final displayImageUrl = item.imageUrl.isNotEmpty
                    ? item.imageUrl
                    : (ep?.imageUrl.isNotEmpty == true
                        ? ep!.imageUrl
                        : (story?.imageUrl ?? ''));

                final displayStoryTitle = (ep?.storyTitle.isNotEmpty == true)
                    ? ep!.storyTitle
                    : (item.storyTitle.isNotEmpty
                        ? item.storyTitle
                        : (story?.title ?? 'Audio Story'));

                return GestureDetector(
                  onTap: () => controller.onContinueListeningTap(item),
                  child: Container(
                    width: 240,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: displayImageUrl.isNotEmpty
                              ? Image.network(
                                  displayImageUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _fallbackPlaceholder(70, 70),
                                )
                              : _fallbackPlaceholder(70, 70),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                displayStoryTitle,
                                style: text12(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ep?.title ?? 'Episode',
                                style: text10(color: AppColors.secondaryTextColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: item.progressPercentage,
                                backgroundColor: AppColors.cardColor,
                                color: AppColors.primaryColor,
                                minHeight: 3,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(AudioStoriesController controller) {
    final story = controller.heroBanner;
    if (story == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: GestureDetector(
        onTap: () => controller.onStoryTap(story),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.network(
                story.imageUrl,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallbackPlaceholder(double.infinity, 190),
              ),
              Container(
                height: 190,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.backgroundColor.withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),
              // Premium badge (Uncomment if needed in future):
              /*
              if (story.isPremium)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: text8(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              */
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      style: text18(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      story.subtitle,
                      style: text12(color: AppColors.secondaryTextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => controller.onStoryTap(story),
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
                              'Play Now',
                              style: text11(
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
  }

  Widget _buildSection(
    String title,
    List<AudioStoryModel> stories,
    AudioStoriesController controller,
  ) {
    if (stories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: text16(fontWeight: FontWeight.bold)),
                Text(
                  '${stories.length} Stories',
                  style: text11(color: AppColors.hintTextColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: stories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                return _buildStoryCard(stories[i], controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(
    AudioStoryModel story,
    AudioStoriesController controller,
  ) {
    return GestureDetector(
      onTap: () => controller.onStoryTap(story),
      child: SizedBox(
        width: 100,
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
                      story.imageUrl,
                      width: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          _fallbackPlaceholder(100, 110),
                    ),
                    // Premium badge (Uncomment if needed in future):
                    /*
                    if (story.isPremium)
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              story.title,
              style: text11(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              story.subtitle,
              style: text10(color: AppColors.hintTextColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilteredList(AudioStoriesController controller) {
    if (controller.isCategoryLoading.value && controller.filteredCategoryStories.isEmpty) {
      return const AudioStoryGridShimmer(itemCount: 6);
    }

    final stories = controller.filteredCategoryStories;
    if (stories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.library_music_outlined,
                size: 44,
                color: AppColors.hintTextColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No stories found in this category.',
                style: text13(color: AppColors.secondaryTextColor),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 16,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (_, i) => _buildStoryCard(stories[i], controller),
      ),
    );
  }

  Widget _buildSearchResultsGrid(AudioStoriesController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search Results',
                style: text15(fontWeight: FontWeight.bold),
              ),
              Text(
                '${controller.searchResults.length} Found',
                style: text11(color: AppColors.hintTextColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.searchResults.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 16,
              childAspectRatio: 0.62,
            ),
            itemBuilder: (_, i) => _buildStoryCard(controller.searchResults[i], controller),
          ),
        ],
      ),
    );
  }

  Widget _fallbackPlaceholder(double w, double h) {
    return Container(
      width: w,
      height: h,
      color: AppColors.cardColor,
      child: Center(
        child: Icon(
          Icons.headphones_rounded,
          color: AppColors.hintTextColor,
          size: 32,
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
