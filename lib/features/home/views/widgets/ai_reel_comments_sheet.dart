import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/home/controllers/ai_reel_comments_controller.dart';
import 'package:masti_adda_app/features/home/models/ai_reel_comment_model.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class AiReelCommentsSheet extends StatelessWidget {
  final String contentId;
  final String? episodeId;

  const AiReelCommentsSheet({
    super.key,
    required this.contentId,
    this.episodeId,
  });

  /// Static helper to show the comments bottom sheet
  static void show(
    BuildContext context, {
    required String contentId,
    String? episodeId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => AiReelCommentsSheet(
        contentId: contentId,
        episodeId: episodeId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Unique tag per contentId so separate reel modals don't collide
    final tag = 'comments_$contentId';
    final controller = Get.put(
      AiReelCommentsController(
        contentId: contentId,
        episodeId: episodeId,
      ),
      tag: tag,
    );

    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          Get.delete<AiReelCommentsController>(tag: tag);
        }
      },
      child: Container(
        height: screenHeight * 0.72 + (bottomInset > 0 ? bottomInset * 0.4 : 0),
        decoration: BoxDecoration(
          color: const Color(0xFF141418),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // 1. Top Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // 2. Sheet Header (Title + Count + Close)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Comments',
                              style: text16(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Obx(() {
                              final count = controller.totalComments.value;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$count',
                                  style: text12(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white12, height: 1),

                  // 3. Comments List Body
                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value &&
                          controller.comments.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentColor,
                            strokeWidth: 2.5,
                          ),
                        );
                      }

                      if (controller.errorMessage.value.isNotEmpty &&
                          controller.comments.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.white38,
                                  size: 44,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Couldn't load comments",
                                  style: text14(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () =>
                                      controller.fetchComments(isRefresh: true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accentColor,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text('Retry', style: text12(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (controller.comments.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.05),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 28,
                                  color: Colors.white38,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No comments yet',
                                style: text14(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Be the first to share your thoughts!',
                                style: text12(color: Colors.white54),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () =>
                            controller.fetchComments(isRefresh: true),
                        color: AppColors.accentColor,
                        backgroundColor: const Color(0xFF1E1E24),
                        child: ListView.separated(
                          controller: controller.scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount:
                              controller.comments.length +
                              (controller.isFetchingMore.value ? 1 : 0),
                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index == controller.comments.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: AppColors.accentColor,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final comment = controller.comments[index];
                            final isMine = controller.isMyComment(comment);

                            return _CommentRow(
                              comment: comment,
                              isMine: isMine,
                              onDelete: () => _showDeleteDialog(
                                context,
                                controller,
                                comment.id,
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ),

                  // 4. Bottom Input Bar
                  Container(
                    padding: EdgeInsets.only(
                      left: 14,
                      right: 14,
                      top: 10,
                      bottom: bottomInset > 0 ? bottomInset + 10 : 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A22),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Current User Avatar
                        Obx(() {
                          final user = controller.currentUser.value;
                          final avatarUrl = user?.profileImage ?? '';
                          return CircleAvatar(
                            radius: 17,
                            backgroundColor: AppColors.surfaceColor,
                            backgroundImage: avatarUrl.isNotEmpty
                                ? NetworkImage(formatMediaUrl(avatarUrl))
                                : null,
                            child: avatarUrl.isEmpty
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 18,
                                    color: Colors.white70,
                                  )
                                : null,
                          );
                        }),
                        const SizedBox(width: 10),

                        // Input TextField Container
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: controller.textController,
                                    focusNode: controller.focusNode,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    style: text13(color: Colors.white),
                                    cursorColor: AppColors.accentColor,
                                    maxLines: 4,
                                    minLines: 1,
                                    decoration: InputDecoration(
                                      hintText: 'Add a comment...',
                                      hintStyle: text13(color: Colors.white38),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                ),
                                Obx(() {
                                  if (controller.isPosting.value) {
                                    return const Padding(
                                      padding: EdgeInsets.all(6.0),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: AppColors.accentColor,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  }

                                  return GestureDetector(
                                    onTap: controller.postComment,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.accentColor,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_upward_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }),
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
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    AiReelCommentsController controller,
    String commentId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Comment',
          style: text16(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this comment?',
          style: text13(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: text13(color: Colors.white54, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.deleteComment(commentId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Delete',
              style: text13(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final AiReelCommentModel comment;
  final bool isMine;
  final VoidCallback onDelete;

  const _CommentRow({
    required this.comment,
    required this.isMine,
    required this.onDelete,
  });

  String _formatTimeAgo(String dateStr) {
    if (dateStr.isEmpty) return 'now';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inSeconds < 60) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
      return '${(diff.inDays / 30).floor()}mo';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = comment.userAvatar;
    final timeAgo = _formatTimeAgo(comment.createdAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 17,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          backgroundImage: avatarUrl.isNotEmpty
              ? NetworkImage(formatMediaUrl(avatarUrl))
              : null,
          child: avatarUrl.isEmpty
              ? Text(
                  comment.userName.isNotEmpty
                      ? comment.userName[0].toUpperCase()
                      : 'U',
                  style: text12(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),

        // Comment content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username + Time Ago + Delete
              Row(
                children: [
                  Text(
                    comment.userName.isNotEmpty ? comment.userName : 'User',
                    style: text12(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (timeAgo.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: text11(color: Colors.white38),
                    ),
                  ],
                  const Spacer(),
                  if (isMine)
                    GestureDetector(
                      onTap: onDelete,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),

              // Comment text
              Text(
                comment.text,
                style: text13(
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                ).copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
