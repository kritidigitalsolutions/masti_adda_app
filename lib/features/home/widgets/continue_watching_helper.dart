import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/micro_drama/models/continue_watching_model.dart';
import 'package:masti_adda_app/features/micro_drama/views/micro_drama_detail_screen.dart';
import 'package:masti_adda_app/features/micro_drama/views/micro_drama_player_screen.dart';
import 'package:masti_adda_app/features/movie/views/movie_details_screen.dart';
import 'package:masti_adda_app/features/movie/views/movie_player_screen.dart';
import 'package:masti_adda_app/features/web_series/views/web_series_detail_screen.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class ContinueWatchingHelper {
  /// Plays content directly and resumes from the exact saved progressSeconds.
  static void playDirectly(
    BuildContext context,
    ContinueWatchingItem item, {
    VoidCallback? onFinished,
  }) {
    final bool isItemPremium =
        item.content?.isPremium ?? item.episode?.isPremium ?? false;
    if (isItemPremium) {
      if (!checkPlayable(context, isPremium: true, title: item.displayTitle)) {
        return;
      }
    }

    final type = item.contentType.toLowerCase();
    final contentId = item.contentId;
    final progressSeconds = item.progressSeconds;

    if (type == 'movie') {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => MoviePlayerScreen(
                contentId: contentId,
                videoUrl: item.directVideoUrl.isNotEmpty
                    ? item.directVideoUrl
                    : null,
                title: item.displayTitle,
                initialPositionSeconds: progressSeconds,
                contentType: 'movie',
              ),
            ),
          )
          .then((_) => onFinished?.call());
    } else if (type == 'series' ||
        type == 'web_series' ||
        type == 'webseries') {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (_) => MoviePlayerScreen(
                contentId: contentId,
                episodeId: item.episodeId,
                title:
                    '${item.displayTitle}${item.displayEpisodeNumber != null ? ' - Ep ${item.displayEpisodeNumber}' : ''}',
                initialPositionSeconds: progressSeconds,
                contentType: 'series',
              ),
            ),
          )
          .then((_) => onFinished?.call());
    } else if (type == 'microdrama' ||
        type == 'micro_drama' ||
        type == 'micro-drama') {
      final epNum = item.displayEpisodeNumber;
      final episodeIndex = epNum != null ? (epNum - 1).clamp(0, 999) : 0;
      Get.to(
        () => MicroDramaPlayerScreen(
          dramaId: contentId,
          initialIndex: episodeIndex,
          initialPositionSeconds: progressSeconds,
        ),
      )?.then((_) => onFinished?.call());
    }
  }

  /// Navigates to the respective content detail screen.
  static void viewDetails(BuildContext context, ContinueWatchingItem item) {
    final type = item.contentType.toLowerCase();
    final contentId = item.contentId;

    if (type == 'movie') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MovieDetailsScreen(id: contentId)),
      );
    } else if (type == 'series' ||
        type == 'web_series' ||
        type == 'webseries') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WebSeriesDetailScreen(id: contentId)),
      );
    } else if (type == 'microdrama' ||
        type == 'micro_drama' ||
        type == 'micro-drama') {
      Get.to(() => MicroDramaDetailScreen(id: contentId));
    }
  }

  /// Shows the 3-dots bottom sheet with options to Resume, View Details, or Remove.
  static void showOptionsBottomSheet(
    BuildContext context,
    ContinueWatchingItem item, {
    required VoidCallback onDelete,
    VoidCallback? onPlay,
  }) {
    final posterUrl = formatMediaUrl(item.displayPoster);
    final title = item.displayTitle;
    final epNum = item.displayEpisodeNumber;
    final percentage = item.progressPercentage;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Content Header Info
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: posterUrl.isNotEmpty
                        ? Image.network(
                            posterUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 60,
                              height: 60,
                              color: AppColors.cardColor,
                              child: const Icon(
                                Icons.movie,
                                color: Colors.white38,
                              ),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: AppColors.cardColor,
                            child: const Icon(
                              Icons.movie,
                              color: Colors.white38,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: text14(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (epNum != null) ...[
                              Text(
                                'Episode $epNum',
                                style: text12(
                                  color: AppColors.secondaryTextColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '•',
                                style: TextStyle(color: Colors.white38),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              '$percentage% watched',
                              style: text12(color: AppColors.accentColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 8),

              // Option 1: Resume Playing
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.accentColor,
                    size: 22,
                  ),
                ),
                title: Text(
                  'Resume Playing',
                  style: text14(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Continue from $percentage%',
                  style: text12(color: AppColors.secondaryTextColor),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (onPlay != null) {
                    onPlay();
                  } else {
                    playDirectly(context, item);
                  }
                },
              ),

              // Option 2: View Details
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
                title: Text(
                  'View Details',
                  style: text14(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  viewDetails(context, item);
                },
              ),

              // Option 3: Remove from Continue Watching
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Remove from Continue Watching',
                  style: text14(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
