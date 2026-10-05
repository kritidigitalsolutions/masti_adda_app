import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/core/services/firebase_service.dart';
import 'package:masti_adda_app/features/profile/controllers/notifications_controller.dart';
import 'package:masti_adda_app/features/profile/widgets/profile_page_scaffold.dart';
import 'package:masti_adda_app/shared/widgets/shimmer/shimmer.dart';
import 'package:masti_adda_app/utils/date_utils.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class NotificationScreen extends StatelessWidget {
  NotificationScreen({super.key});

  final NotificationsController controller = Get.put(NotificationsController());

  @override
  Widget build(BuildContext context) {
    return ProfilePageScaffold(
      title: 'Notifications',
      children: [
        Obx(() {
          if (controller.notifications.isEmpty) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: controller.clearAll,
                  icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.accentColor),
                  label: Text(
                    'Mark All Read',
                    style: text12(color: AppColors.accentColor, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Get.defaultDialog(
                      title: 'Delete All Notifications',
                      titleStyle: text16(fontWeight: FontWeight.bold, color: AppColors.textColor),
                      middleText: 'Are you sure you want to delete all notifications?',
                      middleTextStyle: text13(color: AppColors.secondaryTextColor),
                      backgroundColor: AppColors.surfaceColor,
                      textConfirm: 'Delete',
                      textCancel: 'Cancel',
                      confirmTextColor: Colors.white,
                      cancelTextColor: AppColors.secondaryTextColor,
                      buttonColor: Colors.red,
                      onConfirm: () {
                        Get.back();
                        controller.deleteAll();
                      },
                    );
                  },
                  icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.redAccent),
                  label: Text(
                    'Delete All',
                    style: text12(color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }),
        Obx(() {
          if (controller.isLoading.value && controller.notifications.isEmpty) {
            return const ShimmerList(itemCount: 6);
          }

          if (controller.notifications.isEmpty) {
            return _EmptyState();
          }

          return RefreshIndicator(
            color: AppColors.accentColor,
            backgroundColor: AppColors.cardColor,
            onRefresh: () async {
              await Get.find<NotificationService>().fetchNotifications();
            },
            child: Column(
              children: List.generate(controller.notifications.length, (index) {
                final item = controller.notifications[index];
                return _NotificationTile(
                  item: item,
                  index: index,
                  onTap: () {
                    controller.markRead(index);
                    Get.find<NotificationService>().handleNotificationClick(item);
                  },
                  onDismissed: () {
                    controller.deleteNotification(index);
                    Get.snackbar(
                      "Notification Removed",
                      "Notification deleted",
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.red.withValues(alpha: 0.8),
                      colorText: Colors.white,
                    );
                  },
                );
              }),
            ),
          );
        }),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationTile({
    required this.item,
    required this.index,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRead = item['isRead'] == true;
    final String rawImage = (item['imageUrl'] ?? item['image'] ?? '').toString().trim();
    final String imageUrl = rawImage.isNotEmpty ? formatMediaUrl(rawImage) : '';
    final String title = item['title']?.toString() ?? '';
    final String message = (item['message'] ?? item['subtitle'] ?? item['body'] ?? '').toString();
    final String category = (item['category'] ?? item['type'] ?? '').toString();
    final String formattedTime = formatTimeAgo(item['time']);

    return Dismissible(
      key: ValueKey("${item['id']}_${item['title']}_$index"),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Delete",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
          ],
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isRead
                ? AppColors.cardColor.withValues(alpha: 0.5)
                : AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRead
                  ? AppColors.borderColor.withValues(alpha: 0.25)
                  : AppColors.accentColor.withValues(alpha: 0.35),
              width: isRead ? 1.0 : 1.2,
            ),
            boxShadow: isRead
                ? []
                : [
                    BoxShadow(
                      color: AppColors.accentColor.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image thumbnail or category icon
              _buildLeadingMedia(imageUrl, category, isRead),
              const SizedBox(width: 12),

              // Notification text details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chip & time row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (category.isNotEmpty)
                          _buildCategoryBadge(category)
                        else
                          const SizedBox.shrink(),
                        Row(
                          children: [
                            Text(
                              formattedTime,
                              style: text10(
                                color: isRead ? AppColors.hintTextColor : AppColors.secondaryTextColor,
                              ),
                            ),
                            if (!isRead) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      title,
                      style: text14(
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                        color: isRead ? AppColors.secondaryTextColor : AppColors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: text12(
                          color: isRead ? AppColors.hintTextColor : AppColors.secondaryTextColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(top: 18),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: AppColors.hintTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingMedia(String imageUrl, String category, bool isRead) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildCategoryIconFallback(category, isRead),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 54,
              height: 54,
              color: AppColors.cardColor,
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentColor),
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildCategoryIconFallback(category, isRead);
  }

  Widget _buildCategoryIconFallback(String category, bool isRead) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    final cat = category.toLowerCase();
    if (cat.contains('subscription') || cat.contains('plan')) {
      icon = Icons.workspace_premium_rounded;
      iconColor = const Color(0xFFFFB800);
      bgColor = const Color(0xFFFFB800).withValues(alpha: 0.15);
    } else if (cat.contains('movie')) {
      icon = Icons.movie_outlined;
      iconColor = AppColors.primaryColor;
      bgColor = AppColors.primaryColor.withValues(alpha: 0.15);
    } else if (cat.contains('episode') || cat.contains('series')) {
      icon = Icons.tv_rounded;
      iconColor = const Color(0xFF00D2FF);
      bgColor = const Color(0xFF00D2FF).withValues(alpha: 0.15);
    } else if (cat.contains('microdrama') || cat.contains('drama')) {
      icon = Icons.video_collection_outlined;
      iconColor = const Color(0xFFFF2E93);
      bgColor = const Color(0xFFFF2E93).withValues(alpha: 0.15);
    } else {
      icon = isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded;
      iconColor = isRead ? AppColors.hintTextColor : AppColors.accentColor;
      bgColor = AppColors.cardColor;
    }

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    String label = category;
    Color color = AppColors.accentColor;

    final cat = category.toLowerCase();
    if (cat.contains('subscription') || cat.contains('plan')) {
      label = 'Subscription';
      color = const Color(0xFFFFB800);
    } else if (cat.contains('newmovies') || cat == 'movie') {
      label = 'New Movie';
      color = AppColors.primaryColor;
    } else if (cat.contains('newepisodes') || cat == 'series') {
      label = 'New Episode';
      color = const Color(0xFF00D2FF);
    } else if (cat.contains('microdrama')) {
      label = 'Micro Drama';
      color = const Color(0xFFFF2E93);
    } else if (cat == 'general') {
      label = 'Alert';
      color = AppColors.secondaryTextColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: AppColors.hintTextColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: text16(fontWeight: FontWeight.w700, color: AppColors.textColor),
          ),
          const SizedBox(height: 6),
          Text(
            'Stay tuned! We\'ll let you know when new movies, series, or updates arrive.',
            style: text12(color: AppColors.secondaryTextColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
