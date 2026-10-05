class AiReelCommentModel {
  final String id;
  final String contentId;
  final String episodeId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String text;
  final int likesCount;
  final bool isLiked;
  final String createdAt;
  final String updatedAt;

  AiReelCommentModel({
    required this.id,
    required this.contentId,
    this.episodeId = '',
    this.userId = '',
    this.userName = '',
    this.userAvatar = '',
    required this.text,
    this.likesCount = 0,
    this.isLiked = false,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory AiReelCommentModel.fromJson(Map<String, dynamic> json) {
    int parsedLikes = 0;
    final dynamic likesRaw = json['likesCount'] ??
        json['likes'] ??
        json['totalLikes'] ??
        json['likeCount'];
    if (likesRaw != null) {
      if (likesRaw is num) {
        parsedLikes = likesRaw.toInt();
      } else if (likesRaw is List) {
        parsedLikes = likesRaw.length;
      } else if (likesRaw is String) {
        parsedLikes = int.tryParse(likesRaw) ?? 0;
      }
    }

    bool parsedIsLiked = false;
    final dynamic isLikedRaw = json['isLiked'] ??
        json['is_liked'] ??
        json['liked'] ??
        json['isLike'] ??
        json['is_like'] ??
        json['userLiked'];
    if (isLikedRaw != null) {
      if (isLikedRaw is bool) {
        parsedIsLiked = isLikedRaw;
      } else if (isLikedRaw is num) {
        parsedIsLiked = isLikedRaw == 1;
      } else if (isLikedRaw is String) {
        final s = isLikedRaw.trim().toLowerCase();
        parsedIsLiked = s == 'true' || s == '1' || s == 'yes';
      }
    }

    // Extract User Id if present
    String extractedUserId = '';
    if (json['userId'] != null) {
      extractedUserId = json['userId'].toString();
    } else if (json['user'] != null) {
      if (json['user'] is Map) {
        extractedUserId = (json['user']['_id'] ?? json['user']['id'] ?? '').toString();
      } else if (json['user'] is String) {
        extractedUserId = json['user'].toString();
      }
    }

    // Extract User Name
    String extractedUserName = '';
    if (json['userName'] != null && json['userName'].toString().trim().isNotEmpty) {
      extractedUserName = json['userName'].toString();
    } else if (json['username'] != null && json['username'].toString().trim().isNotEmpty) {
      extractedUserName = json['username'].toString();
    } else if (json['name'] != null && json['name'].toString().trim().isNotEmpty) {
      extractedUserName = json['name'].toString();
    } else if (json['user'] != null && json['user'] is Map) {
      final u = json['user'] as Map;
      extractedUserName = (u['name'] ?? u['userName'] ?? u['username'] ?? 'User').toString();
    } else {
      extractedUserName = 'User';
    }

    // Extract User Avatar
    String extractedAvatar = '';
    if (json['userAvatar'] != null && json['userAvatar'].toString().trim().isNotEmpty) {
      extractedAvatar = json['userAvatar'].toString();
    } else if (json['avatar'] != null && json['avatar'].toString().trim().isNotEmpty) {
      extractedAvatar = json['avatar'].toString();
    } else if (json['profileImage'] != null && json['profileImage'].toString().trim().isNotEmpty) {
      extractedAvatar = json['profileImage'].toString();
    } else if (json['photoUrl'] != null && json['photoUrl'].toString().trim().isNotEmpty) {
      extractedAvatar = json['photoUrl'].toString();
    } else if (json['user'] != null && json['user'] is Map) {
      final u = json['user'] as Map;
      extractedAvatar = (u['avatar'] ?? u['userAvatar'] ?? u['profileImage'] ?? u['photoUrl'] ?? '').toString();
    }

    return AiReelCommentModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      contentId: (json['contentId'] ?? json['content'] ?? '').toString(),
      episodeId: (json['episodeId'] ?? json['episode'] ?? '').toString(),
      userId: extractedUserId,
      userName: extractedUserName,
      userAvatar: extractedAvatar,
      text: (json['text'] ?? json['comment'] ?? json['message'] ?? '').toString(),
      likesCount: parsedLikes,
      isLiked: parsedIsLiked,
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'contentId': contentId,
      'episodeId': episodeId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'likesCount': likesCount,
      'isLiked': isLiked,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  AiReelCommentModel copyWith({
    String? id,
    String? contentId,
    String? episodeId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? text,
    int? likesCount,
    bool? isLiked,
    String? createdAt,
    String? updatedAt,
  }) {
    return AiReelCommentModel(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      episodeId: episodeId ?? this.episodeId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      text: text ?? this.text,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CommentPagination {
  final int totalItems;
  final int page;
  final int limit;
  final int pages;

  CommentPagination({
    this.totalItems = 0,
    this.page = 1,
    this.limit = 20,
    this.pages = 1,
  });

  factory CommentPagination.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CommentPagination();
    return CommentPagination(
      totalItems: (json['totalItems'] is num)
          ? (json['totalItems'] as num).toInt()
          : (json['total'] is num ? (json['total'] as num).toInt() : 0),
      page: (json['page'] is num) ? (json['page'] as num).toInt() : 1,
      limit: (json['limit'] is num) ? (json['limit'] as num).toInt() : 20,
      pages: (json['pages'] is num)
          ? (json['pages'] as num).toInt()
          : (json['totalPages'] is num ? (json['totalPages'] as num).toInt() : 1),
    );
  }
}

class AiReelCommentsResponse {
  final bool success;
  final String message;
  final int totalComments;
  final CommentPagination pagination;
  final List<AiReelCommentModel> comments;

  AiReelCommentsResponse({
    required this.success,
    required this.message,
    this.totalComments = 0,
    required this.pagination,
    required this.comments,
  });

  factory AiReelCommentsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final List<AiReelCommentModel> parsedList = [];
    int total = 0;
    CommentPagination pagination = CommentPagination();

    if (data != null) {
      if (data['totalComments'] != null && data['totalComments'] is num) {
        total = (data['totalComments'] as num).toInt();
      } else if (data['total'] != null && data['total'] is num) {
        total = (data['total'] as num).toInt();
      }

      pagination = CommentPagination.fromJson(
        data['pagination'] as Map<String, dynamic>?,
      );

      final rawComments = data['comments'] ?? data['items'] ?? data['list'];
      if (rawComments is List) {
        for (final item in rawComments) {
          if (item is Map<String, dynamic>) {
            parsedList.add(AiReelCommentModel.fromJson(item));
          }
        }
      }
    } else if (json['comments'] is List) {
      for (final item in json['comments']) {
        if (item is Map<String, dynamic>) {
          parsedList.add(AiReelCommentModel.fromJson(item));
        }
      }
    }

    // Fallback total if 0
    if (total == 0 && parsedList.isNotEmpty) {
      total = pagination.totalItems > 0 ? pagination.totalItems : parsedList.length;
    }

    return AiReelCommentsResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      totalComments: total,
      pagination: pagination,
      comments: parsedList,
    );
  }
}

class PostCommentResponse {
  final bool success;
  final String message;
  final int totalComments;
  final AiReelCommentModel? comment;

  PostCommentResponse({
    required this.success,
    required this.message,
    this.totalComments = 0,
    this.comment,
  });

  factory PostCommentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    int total = 0;
    AiReelCommentModel? comment;

    if (data != null) {
      if (data['totalComments'] != null && data['totalComments'] is num) {
        total = (data['totalComments'] as num).toInt();
      } else if (data['total'] != null && data['total'] is num) {
        total = (data['total'] as num).toInt();
      }

      if (data['comment'] is Map<String, dynamic>) {
        comment = AiReelCommentModel.fromJson(data['comment'] as Map<String, dynamic>);
      } else if (data['item'] is Map<String, dynamic>) {
        comment = AiReelCommentModel.fromJson(data['item'] as Map<String, dynamic>);
      } else {
        // If data itself is the comment object
        if (data.containsKey('_id') || data.containsKey('text') || data.containsKey('contentId')) {
          comment = AiReelCommentModel.fromJson(data);
        }
      }
    }

    return PostCommentResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      totalComments: total,
      comment: comment,
    );
  }
}

class DeleteCommentResponse {
  final bool success;
  final String message;
  final String commentId;
  final int totalComments;

  DeleteCommentResponse({
    required this.success,
    required this.message,
    required this.commentId,
    this.totalComments = 0,
  });

  factory DeleteCommentResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    String commentId = '';
    int total = 0;

    if (data != null) {
      commentId = (data['commentId'] ?? data['_id'] ?? data['id'] ?? '').toString();
      if (data['totalComments'] != null && data['totalComments'] is num) {
        total = (data['totalComments'] as num).toInt();
      } else if (data['total'] != null && data['total'] is num) {
        total = (data['total'] as num).toInt();
      }
    }

    return DeleteCommentResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      commentId: commentId,
      totalComments: total,
    );
  }
}
