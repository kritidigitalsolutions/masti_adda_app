import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/core/services/storage_service.dart';
import 'package:masti_adda_app/features/auth/models/response/user_model.dart';
import 'package:masti_adda_app/features/home/controllers/ai_reels_controller.dart';
import 'package:masti_adda_app/features/home/models/ai_reel_comment_model.dart';
import 'package:masti_adda_app/features/home/repositories/ai_reels_datasource.dart';
import 'package:masti_adda_app/routes/app_routes.dart';

class AiReelCommentsController extends GetxController {
  final String contentId;
  final String? episodeId;

  AiReelCommentsController({
    required this.contentId,
    this.episodeId,
  });

  final AiReelsDatasource _datasource = AiReelsDatasource();

  // Observable State
  final RxList<AiReelCommentModel> comments = <AiReelCommentModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isPosting = false.obs;
  final RxBool isFetchingMore = false.obs;
  final RxInt totalComments = 0.obs;
  final RxInt currentPage = 1.obs;
  final RxBool hasMore = false.obs;
  final RxString errorMessage = ''.obs;

  // Current logged in user
  final Rxn<UserModel> currentUser = Rxn<UserModel>();

  // Text & Scroll controllers
  late TextEditingController textController;
  late ScrollController scrollController;
  late FocusNode focusNode;

  @override
  void onInit() {
    super.onInit();
    textController = TextEditingController();
    scrollController = ScrollController();
    focusNode = FocusNode();

    _loadCurrentUser();
    fetchComments();

    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    textController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 150) {
      if (!isFetchingMore.value && hasMore.value && !isLoading.value) {
        loadMoreComments();
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await StorageService.getUser();
      currentUser.value = user;
    } catch (e) {
      debugPrint("⚠️ Error loading current user for comments: $e");
    }
  }

  /// Check if the comment belongs to the currently logged in user
  bool isMyComment(AiReelCommentModel comment) {
    final user = currentUser.value;
    if (user == null) return false;

    // Check by user ID if available
    if (comment.userId.isNotEmpty && user.id.isNotEmpty) {
      return comment.userId == user.id;
    }

    // Fallback: check by username
    if (comment.userName.isNotEmpty && user.name.isNotEmpty) {
      return comment.userName.trim().toLowerCase() ==
          user.name.trim().toLowerCase();
    }

    return false;
  }

  /// Fetch initial batch of comments
  Future<void> fetchComments({bool isRefresh = false}) async {
    if (contentId.isEmpty) return;

    try {
      if (!isRefresh) {
        isLoading.value = true;
      }
      errorMessage.value = '';
      currentPage.value = 1;

      final response = await _datasource.fetchComments(
        contentId,
        page: 1,
        limit: 20,
        episodeId: episodeId,
      );

      comments.assignAll(response.comments);
      totalComments.value = response.totalComments;
      hasMore.value = response.pagination.page < response.pagination.pages;

      // Sync with parent AiReelsController
      if (Get.isRegistered<AiReelsController>()) {
        AiReelsController.to.updateCommentsCount(contentId, response.totalComments);
      }
    } catch (e) {
      debugPrint("❌ Error fetching comments: $e");
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more comments (pagination)
  Future<void> loadMoreComments() async {
    if (isFetchingMore.value || !hasMore.value || isLoading.value) return;

    try {
      isFetchingMore.value = true;
      final nextPage = currentPage.value + 1;

      final response = await _datasource.fetchComments(
        contentId,
        page: nextPage,
        limit: 20,
        episodeId: episodeId,
      );

      currentPage.value = nextPage;
      hasMore.value = response.pagination.page < response.pagination.pages;

      // Avoid duplicates
      final existingIds = comments.map((c) => c.id).toSet();
      final newItems = response.comments
          .where((c) => !existingIds.contains(c.id))
          .toList();

      comments.addAll(newItems);
      if (response.totalComments > 0) {
        totalComments.value = response.totalComments;
        if (Get.isRegistered<AiReelsController>()) {
          AiReelsController.to.updateCommentsCount(contentId, response.totalComments);
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading more comments: $e");
    } finally {
      isFetchingMore.value = false;
    }
  }

  /// Post a new comment
  Future<void> postComment() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    // Check authentication
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      Get.snackbar(
        'Login Required',
        'Please log in to share your comment.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        mainButton: TextButton(
          onPressed: () {
            Get.back(); // close bottom sheet
            Get.toNamed(AppRoutes.login);
          },
          child: const Text(
            'Log In',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    try {
      isPosting.value = true;
      focusNode.unfocus();

      final response = await _datasource.postComment(
        contentId: contentId,
        episodeId: episodeId,
        text: text,
      );

      if (response.success) {
        textController.clear();

        if (response.comment != null) {
          comments.insert(0, response.comment!);
        } else {
          // Fallback comment object
          final fallbackComment = AiReelCommentModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            contentId: contentId,
            episodeId: episodeId ?? '',
            userId: currentUser.value?.id ?? '',
            userName: currentUser.value?.name.isNotEmpty == true
                ? currentUser.value!.name
                : 'You',
            userAvatar: currentUser.value?.profileImage ?? '',
            text: text,
            createdAt: DateTime.now().toIso8601String(),
          );
          comments.insert(0, fallbackComment);
        }

        if (response.totalComments > 0) {
          totalComments.value = response.totalComments;
        } else {
          totalComments.value += 1;
        }

        // Sync with parent AiReelsController
        if (Get.isRegistered<AiReelsController>()) {
          AiReelsController.to.updateCommentsCount(contentId, totalComments.value);
        }

        // Smoothly scroll to the top to see the new comment
        if (scrollController.hasClients) {
          scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Failed to post comment.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
        );
      }
    } catch (e) {
      debugPrint("❌ Error posting comment: $e");
      Get.snackbar(
        'Error',
        'Could not post your comment. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isPosting.value = false;
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    if (commentId.isEmpty) return;

    final index = comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final removedItem = comments[index];
    final prevTotal = totalComments.value;

    // Optimistic removal
    comments.removeAt(index);
    totalComments.value = (prevTotal - 1).clamp(0, 99999999);
    if (Get.isRegistered<AiReelsController>()) {
      AiReelsController.to.updateCommentsCount(contentId, totalComments.value);
    }

    try {
      final response = await _datasource.deleteComment(commentId);
      if (response.success) {
        if (response.totalComments >= 0) {
          totalComments.value = response.totalComments;
          if (Get.isRegistered<AiReelsController>()) {
            AiReelsController.to.updateCommentsCount(contentId, response.totalComments);
          }
        }
      } else {
        // Rollback on non-success
        comments.insert(index, removedItem);
        totalComments.value = prevTotal;
        if (Get.isRegistered<AiReelsController>()) {
          AiReelsController.to.updateCommentsCount(contentId, prevTotal);
        }
        Get.snackbar(
          'Error',
          response.message.isNotEmpty
              ? response.message
              : 'Failed to delete comment.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(12),
        );
      }
    } catch (e) {
      debugPrint("❌ Error deleting comment: $e");
      // Rollback on error
      comments.insert(index, removedItem);
      totalComments.value = prevTotal;
      if (Get.isRegistered<AiReelsController>()) {
        AiReelsController.to.updateCommentsCount(contentId, prevTotal);
      }
      Get.snackbar(
        'Error',
        'Could not delete comment. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
      );
    }
  }
}
