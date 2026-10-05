import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/core/services/app_download_service.dart';
import 'package:masti_adda_app/features/profile/controllers/profile_controller.dart';
import 'package:masti_adda_app/features/profile/widgets/profile_page_scaffold.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/shared/widgets/shimmer/shimmer.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class DownloadsScreen extends StatelessWidget {
  DownloadsScreen({super.key});

  final DownloadsController controller = Get.put(DownloadsController());

  @override
  Widget build(BuildContext context) {
    return ProfilePageScaffold(
      title: 'Downloads',
      onRefresh: () async {
        controller.appDownload.reloadDownloads();
      },
      children: [
        // Category Pills Filter
        Obx(() {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: controller.categories.map((cat) {
                final isSelected = controller.selectedCategory.value == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      cat,
                      style: text12(
                        color: isSelected
                            ? AppColors.black
                            : AppColors.secondaryTextColor,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => controller.selectCategory(cat),
                    backgroundColor: AppColors.surfaceColor,
                    selectedColor: AppColors.primaryColor,
                    checkmarkColor: AppColors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.borderColor.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),
        const SizedBox(height: 16),

        // Downloads List
        Obx(() {
          final items = controller.filteredDownloads;

          if (items.isEmpty) {
            return _buildEmptyState(controller.selectedCategory.value);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${controller.selectedCategory.value} (${items.length})',
                      style: text14(
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                    Text(
                      'Available Offline',
                      style: text11(color: AppColors.primaryColor),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.62,
                ),
                itemBuilder: (_, index) {
                  final item = items[index];
                  return _DownloadedMediaGridCard(
                    item: item,
                    onPlay: () => controller.playDownloadedItem(context, item),
                    onDelete: () => _confirmDelete(context, item),
                  );
                },
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState(String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.download_for_offline_rounded,
              size: 40,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Downloads in $category',
            style: text18(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Download movies, series, micro dramas, or audio stories to watch and listen offline without internet.',
            style: text13(color: AppColors.secondaryTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (category == 'Audio') {
                Get.toNamed(AppRoutes.audioStories);
              } else {
                Get.toNamed(AppRoutes.home);
              }
            },
            icon: const Icon(
              Icons.explore_rounded,
              color: AppColors.black,
              size: 18,
            ),
            label: Text(
              'Explore Content',
              style: text13(
                color: AppColors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, DownloadedMediaItem item) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete Download?',
                style: text16(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Are you sure you want to delete "${item.title}" from your device storage?',
                style: text13(color: AppColors.secondaryTextColor),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: text13(color: AppColors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        controller.removeDownload(item.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: text13(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadedMediaGridCard extends StatelessWidget {
  final DownloadedMediaItem item;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const _DownloadedMediaGridCard({
    required this.item,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = _getMediaTypeLabel(item.mediaType);
    final typeColor = _getMediaTypeColor(item.mediaType);

    return GestureDetector(
      onTap: onPlay,
      onLongPress: onDelete,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover / Poster Image
              _buildCoverImage(),

              // Center play icon overlay
              Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),

              // Top row: Type badge & Delete button
              Positioned(
                top: 5,
                left: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    typeLabel,
                    style: appTextStyle(
                      fontSize: 7.5,
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white70,
                      size: 13,
                    ),
                  ),
                ),
              ),

              // Bottom gradient overlay with title & file info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 16, 6, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.parentTitle.isNotEmpty)
                        Text(
                          item.parentTitle,
                          style: appTextStyle(
                            fontSize: 8,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        item.title,
                        style: text11(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.offline_pin_rounded,
                            color: AppColors.primaryColor,
                            size: 10,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.fileSize.isNotEmpty
                                  ? item.fileSize
                                  : 'Offline',
                              style: appTextStyle(
                                fontSize: 8.5,
                                color: AppColors.hintTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.episodeNumber > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceColor.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'EP ${item.episodeNumber}',
                                style: appTextStyle(
                                  fontSize: 7.5,
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage() {
    final raw = item.coverImage.trim();
    if (raw.isEmpty) {
      return _fallbackPlaceholder(item.mediaType);
    }

    if (isLocalFilePath(raw)) {
      final cleanPath = raw.startsWith('file://')
          ? raw.replaceFirst('file://', '')
          : raw;
      return Image.file(
        File(cleanPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _fallbackPlaceholder(item.mediaType),
      );
    }

    final formatted = formatMediaUrl(raw);
    if (isLocalFilePath(formatted)) {
      final cleanPath = formatted.startsWith('file://')
          ? formatted.replaceFirst('file://', '')
          : formatted;
      return Image.file(
        File(cleanPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _fallbackPlaceholder(item.mediaType),
      );
    }

    return CachedNetworkImage(
      imageUrl: formatted,
      fit: BoxFit.cover,
      placeholder: (context, url) => const ShimmerEffect(
        child: ShimmerBox(borderRadius: 10),
      ),
      errorWidget: (context, url, error) =>
          _fallbackPlaceholder(item.mediaType),
    );
  }

  String _getMediaTypeLabel(DownloadMediaType type) {
    switch (type) {
      case DownloadMediaType.audio:
        return 'AUDIO';
      case DownloadMediaType.movie:
        return 'MOVIE';
      case DownloadMediaType.webSeries:
        return 'SERIES';
      case DownloadMediaType.microDrama:
        return 'DRAMA';
    }
  }

  Color _getMediaTypeColor(DownloadMediaType type) {
    switch (type) {
      case DownloadMediaType.audio:
        return AppColors.primaryColor;
      case DownloadMediaType.movie:
        return Colors.redAccent;
      case DownloadMediaType.webSeries:
        return Colors.blueAccent;
      case DownloadMediaType.microDrama:
        return Colors.purpleAccent;
    }
  }

  Widget _fallbackPlaceholder(DownloadMediaType type) {
    IconData iconData = Icons.headphones_rounded;
    if (type == DownloadMediaType.movie) iconData = Icons.movie_rounded;
    if (type == DownloadMediaType.webSeries) iconData = Icons.tv_rounded;
    if (type == DownloadMediaType.microDrama) {
      iconData = Icons.play_lesson_rounded;
    }

    return Container(
      color: AppColors.surfaceColor,
      child: Center(
        child: Icon(iconData, color: AppColors.hintTextColor, size: 24),
      ),
    );
  }
}
