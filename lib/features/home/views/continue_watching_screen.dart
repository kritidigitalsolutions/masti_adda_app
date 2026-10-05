import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/features/home/widgets/continue_watching_helper.dart';
import 'package:masti_adda_app/features/micro_drama/controllers/continue_watching_controller.dart';
import 'package:masti_adda_app/features/micro_drama/models/continue_watching_model.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class ContinueWatchingScreen extends StatefulWidget {
  final String? initialFilter; // 'movie', 'series'

  const ContinueWatchingScreen({super.key, this.initialFilter});

  @override
  State<ContinueWatchingScreen> createState() => _ContinueWatchingScreenState();
}

class _ContinueWatchingScreenState extends State<ContinueWatchingScreen> {
  late final ContinueWatchingController _cwController;
  final RxInt _selectedFilterIndex = 0.obs;

  // Only Movies and Web Series for this screen
  final List<String> _filters = ['All', 'Movies', 'Web Series'];
  final List<String?> _filterKeys = [null, 'movie', 'series'];

  @override
  void initState() {
    super.initState();
    _cwController = Get.isRegistered<ContinueWatchingController>()
        ? Get.find<ContinueWatchingController>()
        : Get.put(ContinueWatchingController());

    if (widget.initialFilter != null) {
      final idx = _filterKeys.indexOf(widget.initialFilter);
      if (idx != -1) {
        _selectedFilterIndex.value = idx;
      }
    }

    // Call fetch asynchronously after first frame to avoid setState/markNeedsBuild during build error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cwController.fetchForHome();
    });
  }

  List<ContinueWatchingItem> _filterItems(List<ContinueWatchingItem> items) {
    final key = _filterKeys[_selectedFilterIndex.value];
    if (key == null) return items;
    if (key == 'movie') {
      return items.where((item) => item.isMovie).toList();
    } else if (key == 'series') {
      return items.where((item) => item.isSeries).toList();
    }
    return items;
  }

  void _showClearAllDialog() {
    final key = _filterKeys[_selectedFilterIndex.value];
    final filterName = _filters[_selectedFilterIndex.value];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Clear Continue Watching',
            style: text16(fontWeight: FontWeight.bold),
          ),
          content: Text(
            key == null
                ? 'Are you sure you want to remove all continue watching items?'
                : 'Are you sure you want to remove all $filterName from continue watching?',
            style: text13(color: AppColors.secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: text13(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _cwController.clearAll(contentType: key);
              },
              child: Text(
                'Clear All',
                style: text13(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: const Center(
          child: AppBackButton(),
        ),
        title: Text(
          'Continue Watching',
          style: text18(fontWeight: FontWeight.bold),
        ),
        actions: [
          Obx(() {
            final items = _filterItems(_cwController.homeList);
            if (items.isEmpty) return const SizedBox.shrink();
            return TextButton(
              onPressed: _showClearAllDialog,
              child: Text(
                'Clear All',
                style: text13(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter tabs
            _buildFilterTabs(),
            const SizedBox(height: 12),

            // Content List
            Expanded(
              child: Obx(() {
                if (_cwController.homeFetchStatus.value == Status.loading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentColor,
                    ),
                  );
                }

                final items = _filterItems(_cwController.homeList);

                if (items.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildListItem(item);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          return Obx(() {
            final isSelected = _selectedFilterIndex.value == i;
            return GestureDetector(
              onTap: () => _selectedFilterIndex.value = i,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentColor
                      : AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentColor
                        : AppColors.borderColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    _filters[i],
                    style: text12(
                      color: isSelected
                          ? Colors.black
                          : AppColors.secondaryTextColor,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildListItem(ContinueWatchingItem item) {
    final posterUrl = formatMediaUrl(item.displayPoster);
    final title = item.displayTitle;
    final epNum = item.displayEpisodeNumber;
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
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Poster thumbnail with progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 90,
                height: 70,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    posterUrl.isNotEmpty
                        ? Image.network(
                            posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _fallbackThumb(),
                          )
                        : _fallbackThumb(),

                    // Dark overlay
                    Container(color: Colors.black.withValues(alpha: 0.25)),

                    // Center play icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(5),
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

                    // Progress bar at bottom
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
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content details (Left side)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
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
                      if (epNum != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Episode $epNum',
                          style: text11(color: AppColors.secondaryTextColor),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: text13(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$percentage% watched',
                    style: text11(
                      color: AppColors.accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // 3-dots icon on the Right side
            IconButton(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: () {
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackThumb() {
    return Container(
      color: AppColors.cardColor,
      child: const Center(
        child: Icon(
          Icons.movie_outlined,
          color: AppColors.hintTextColor,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline_rounded,
            size: 64,
            color: AppColors.hintTextColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Continue Watching',
            style: text16(fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            'Movies and Web Series you watch will appear here.',
            style: text12(color: AppColors.secondaryTextColor),
            textAlign: TextAlign.center,
          ),
        ],
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
}
