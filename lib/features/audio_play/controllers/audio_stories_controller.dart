import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/features/audio_play/models/audio_story_model.dart';
import 'package:masti_adda_app/features/audio_play/repositories/audio_repository.dart';
import 'package:masti_adda_app/routes/app_routes.dart';

class AudioStoriesController extends GetxController {
  final AudioRepository _repository = AudioRepository();

  // Categories
  final RxList<AudioCategoryModel> categories = <AudioCategoryModel>[].obs;
  final RxInt selectedCategoryIndex = 0.obs;
  final RxBool isCategoriesLoading = false.obs;

  // Home Feed
  final RxBool isLoading = false.obs;
  final RxList<AudioStoryModel> featuredStories = <AudioStoryModel>[].obs;
  final RxList<AudioStoryModel> recentlyAddedStories = <AudioStoryModel>[].obs;
  final RxList<AudioStoryModel> topRatedStories = <AudioStoryModel>[].obs;
  final RxList<AudioStoryModel> allStories = <AudioStoryModel>[].obs;
  final RxList<AudioStoryModel> categoryStories = <AudioStoryModel>[].obs;
  final RxList<AudioProgressModel> continueListeningList =
      <AudioProgressModel>[].obs;

  // Search
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxList<AudioStoryModel> searchResults = <AudioStoryModel>[].obs;
  final RxBool isSearching = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    await Future.wait([
      fetchCategories(),
      fetchHomeFeed(),
      fetchContinueListening(),
      fetchAllStories(),
    ]);
    isLoading.value = false;
  }

  /// 1. Fetch Categories
  Future<void> fetchCategories() async {
    try {
      isCategoriesLoading.value = true;
      final result = await _repository.getAudioCategories();

      final activeSorted = result.where((c) => c.isActive).toList()
        ..sort((a, b) => a.priority.compareTo(b.priority));

      _populateCategories(activeSorted);
    } catch (e) {
      debugPrint("fetchCategories error: $e");
    } finally {
      isCategoriesLoading.value = false;
    }
  }

  void _populateCategories(List<AudioCategoryModel> apiCats) {
    final Map<String, AudioCategoryModel> catMap = {};
    for (var c in apiCats) {
      if (c.name.trim().isNotEmpty && !catMap.containsKey(c.name.trim().toLowerCase())) {
        catMap[c.name.trim().toLowerCase()] = c;
      }
    }

    // Also collect categories from allStories
    for (var story in allStories) {
      for (var c in story.categories) {
        if (c.name.trim().isNotEmpty && !catMap.containsKey(c.name.trim().toLowerCase())) {
          catMap[c.name.trim().toLowerCase()] = c;
        }
      }
      if (story.genre.trim().isNotEmpty && story.genre != 'Audio Story' && !catMap.containsKey(story.genre.trim().toLowerCase())) {
        catMap[story.genre.trim().toLowerCase()] = AudioCategoryModel(
          id: story.categoryId,
          name: story.genre,
        );
      }
    }

    final list = <AudioCategoryModel>[
      const AudioCategoryModel(
        id: 'all',
        name: 'All',
        description: 'All Audio Stories',
      ),
      ...catMap.values,
    ];
    categories.assignAll(list);
  }

  /// 2. Fetch Home Feed (Featured, Recently Added, Top Rated)
  Future<void> fetchHomeFeed() async {
    try {
      final feed = await _repository.getAudioStoriesHome();
      if (feed != null) {
        featuredStories.assignAll(feed.featured);
        recentlyAddedStories.assignAll(feed.recentlyAdded);
        topRatedStories.assignAll(feed.topRated);
      }
    } catch (e) {
      debugPrint("fetchHomeFeed error: $e");
    }
  }

  /// 3. Fetch Continue Listening Feed
  Future<void> fetchContinueListening() async {
    try {
      final list = await _repository.getContinueListening();
      continueListeningList.assignAll(list);
    } catch (e) {
      debugPrint("fetchContinueListening error: $e");
    }
  }

  /// 4. Fetch All Stories
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  int currentPage = 1;
  static const int pageSize = 12;

  Future<void> fetchAllStories() async {
    currentPage = 1;
    hasMore.value = true;
    try {
      final stories = await _repository.getAudioStories(page: 1, limit: pageSize);
      allStories.assignAll(stories);
      if (stories.length < pageSize) {
        hasMore.value = false;
      }
      _populateCategories(categories.where((c) => c.id != 'all').toList());
      _updateCategoryStories();
    } catch (e) {
      debugPrint("fetchAllStories error: $e");
    }
  }

  Future<void> fetchMoreStories() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final nextPage = currentPage + 1;
      final selectedCat = (selectedCategoryIndex.value < categories.length &&
              categories[selectedCategoryIndex.value].id != 'all')
          ? categories[selectedCategoryIndex.value].id
          : null;

      final newStories = await _repository.getAudioStories(
        categoryId: selectedCat,
        page: nextPage,
        limit: pageSize,
      );

      if (newStories.isNotEmpty) {
        final existingIds = allStories.map((s) => s.id).toSet();
        final filtered = newStories.where((s) => !existingIds.contains(s.id)).toList();
        if (filtered.isNotEmpty) {
          allStories.addAll(filtered);
          currentPage = nextPage;
          _updateCategoryStories();
        } else {
          hasMore.value = false;
        }
        if (newStories.length < pageSize) {
          hasMore.value = false;
        }
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      debugPrint("fetchMoreStories error: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }

  final RxBool isCategoryLoading = false.obs;

  /// Helper to check if a story belongs to a given category
  bool _storyMatchesCategory(AudioStoryModel story, AudioCategoryModel cat) {
    if (cat.id == 'all') return true;

    final targetName = cat.name.trim().toLowerCase();
    final targetId = cat.id.trim();
    final targetSlug = cat.slug.trim().toLowerCase();

    // Check category id
    if (targetId.isNotEmpty) {
      if (story.categoryId.trim() == targetId) return true;
      if (story.categories.any((c) => c.id.trim() == targetId)) return true;
    }

    // Check slug
    if (targetSlug.isNotEmpty) {
      if (story.categories.any((c) => c.slug.trim().toLowerCase() == targetSlug)) {
        return true;
      }
    }

    // Check name / genre
    if (targetName.isNotEmpty) {
      final genre = story.genre.trim().toLowerCase();
      if (genre == targetName || genre.contains(targetName) || targetName.contains(genre)) {
        return true;
      }
      if (story.categories.any((c) {
        final cName = c.name.trim().toLowerCase();
        return cName == targetName || cName.contains(targetName) || targetName.contains(cName);
      })) {
        return true;
      }
    }

    return false;
  }

  /// 5. Category Selection
  Future<void> onCategorySelected(int index) async {
    selectedCategoryIndex.value = index;
    _updateCategoryStories();

    if (index > 0 && index < categories.length) {
      final selectedCat = categories[index];
      if (selectedCat.id != 'all' && selectedCat.id.isNotEmpty) {
        try {
          isCategoryLoading.value = true;
          final catStories = await _repository.getAudioStories(
            categoryId: selectedCat.id,
            limit: 30,
          );
          if (catStories.isNotEmpty) {
            final existingIds = allStories.map((s) => s.id).toSet();
            final newItems = catStories.where((s) => !existingIds.contains(s.id)).toList();
            if (newItems.isNotEmpty) {
              allStories.addAll(newItems);
            }
            _updateCategoryStories();
          }
        } catch (e) {
          debugPrint("onCategorySelected fetch error: $e");
        } finally {
          isCategoryLoading.value = false;
        }
      }
    }
  }

  void _updateCategoryStories() {
    final index = selectedCategoryIndex.value;
    if (index <= 0 || index >= categories.length) {
      categoryStories.assignAll(allStories);
      return;
    }

    final selectedCat = categories[index];
    final allKnown = <AudioStoryModel>{
      ...allStories,
      ...featuredStories,
      ...recentlyAddedStories,
      ...topRatedStories,
    };
    final filtered = allKnown.where((s) => _storyMatchesCategory(s, selectedCat)).toList();
    categoryStories.assignAll(filtered);
  }

  List<AudioStoryModel> get filteredCategoryStories {
    final index = selectedCategoryIndex.value;
    if (index <= 0 || index >= categories.length) return allStories;

    final selectedCat = categories[index];
    final allKnown = <AudioStoryModel>{
      ...allStories,
      ...featuredStories,
      ...recentlyAddedStories,
      ...topRatedStories,
    };
    final filtered = allKnown.where((s) => _storyMatchesCategory(s, selectedCat)).toList();
    return filtered.isNotEmpty ? filtered : categoryStories;
  }

  /// 6. Search Stories (Instant local filter on all loaded content)
  void onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    searchQuery.value = query.trim();
    if (q.isEmpty) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }

    final allKnown = <AudioStoryModel>{
      ...allStories,
      ...featuredStories,
      ...recentlyAddedStories,
      ...topRatedStories,
    };

    final matches = allKnown.where((story) {
      final titleMatch = story.title.toLowerCase().contains(q);
      final subtitleMatch = story.subtitle.toLowerCase().contains(q);
      final authorMatch = story.author.toLowerCase().contains(q);
      final narratorMatch = story.narrator.toLowerCase().contains(q);
      final genreMatch = story.genre.toLowerCase().contains(q);
      final descMatch = story.description.toLowerCase().contains(q);
      final catMatch = story.categories.any((c) => c.name.toLowerCase().contains(q));

      return titleMatch ||
          subtitleMatch ||
          authorMatch ||
          narratorMatch ||
          genreMatch ||
          descMatch ||
          catMatch;
    }).toList();

    searchResults.assignAll(matches);
    isSearching.value = false;
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    searchResults.clear();
    isSearching.value = false;
  }

  // Getters for display
  AudioStoryModel? get heroBanner {
    if (featuredStories.isNotEmpty) return featuredStories.first;
    if (allStories.isNotEmpty) return allStories.first;
    return null;
  }

  List<AudioStoryModel> get topAudioStories => topRatedStories.isNotEmpty
      ? topRatedStories
      : allStories.take(5).toList();

  List<AudioStoryModel> get recentlyAdded => recentlyAddedStories.isNotEmpty
      ? recentlyAddedStories
      : allStories.skip(2).take(5).toList();

  AudioStoryModel? getStoryById(String storyId) {
    if (storyId.isEmpty) return null;
    return allStories.firstWhereOrNull((s) => s.id == storyId) ??
        featuredStories.firstWhereOrNull((s) => s.id == storyId) ??
        recentlyAddedStories.firstWhereOrNull((s) => s.id == storyId) ??
        topRatedStories.firstWhereOrNull((s) => s.id == storyId);
  }

  void onStoryTap(AudioStoryModel story) {
    Get.toNamed(
      AppRoutes.audioDetail,
      arguments: story.id.isNotEmpty ? story.id : story,
    );
  }

  void onContinueListeningTap(AudioProgressModel item) {
    final ep = item.episode;
    final storyId = item.storyId.isNotEmpty
        ? item.storyId
        : (ep?.storyId ?? '');

    final cachedStory = getStoryById(storyId);

    final Map<String, dynamic> args = {
      'storyId': storyId,
      'episodeId': item.episodeId.isNotEmpty ? item.episodeId : (ep?.id ?? ''),
      'progressSeconds': item.progressSeconds,
    };
    if (ep != null) args['episode'] = ep;
    if (cachedStory != null) args['story'] = cachedStory;

    Get.toNamed(
      AppRoutes.audioPlayer,
      arguments: args,
    );
  }
}
