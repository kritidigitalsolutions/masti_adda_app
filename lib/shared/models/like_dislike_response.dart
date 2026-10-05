class LikeDislikeResponse {
  final bool success;
  final String message;
  final int totalLikes;
  final int totalDislikes;
  final String contentType;
  final bool? isLiked;
  final bool? isDisliked;

  const LikeDislikeResponse({
    required this.success,
    required this.message,
    required this.totalLikes,
    required this.totalDislikes,
    this.contentType = '',
    this.isLiked,
    this.isDisliked,
  });

  factory LikeDislikeResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : null;

    int parseNum(dynamic val, [int fallback = 0]) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    bool? parseBool(dynamic val) {
      if (val == null) return null;
      if (val is bool) return val;
      if (val is num) return val == 1;
      if (val is String) {
        final s = val.trim().toLowerCase();
        if (s == 'true' || s == '1' || s == 'yes') return true;
        if (s == 'false' || s == '0' || s == 'no') return false;
      }
      return null;
    }

    final totalLikesVal = json['totalLikes'] ??
        json['likes'] ??
        json['like'] ??
        json['likeCount'] ??
        data?['totalLikes'] ??
        data?['likes'] ??
        data?['like'] ??
        data?['likeCount'];

    final totalDislikesVal = json['totalDislikes'] ??
        json['dislikes'] ??
        json['dislike'] ??
        json['dislikeCount'] ??
        data?['totalDislikes'] ??
        data?['dislikes'] ??
        data?['dislike'] ??
        data?['dislikeCount'];

    final isLikedVal = json['isLiked'] ??
        json['is_liked'] ??
        json['liked'] ??
        json['isLike'] ??
        data?['isLiked'] ??
        data?['is_liked'] ??
        data?['liked'] ??
        data?['isLike'];

    final isDislikedVal = json['isDisliked'] ??
        json['is_disliked'] ??
        json['disliked'] ??
        json['isDislike'] ??
        data?['isDisliked'] ??
        data?['is_disliked'] ??
        data?['disliked'] ??
        data?['isDislike'];

    return LikeDislikeResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      totalLikes: parseNum(totalLikesVal, 0),
      totalDislikes: parseNum(totalDislikesVal, 0),
      contentType: (json['contentType'] ?? data?['contentType'] ?? '').toString(),
      isLiked: parseBool(isLikedVal),
      isDisliked: parseBool(isDislikedVal),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'totalLikes': totalLikes,
    'totalDislikes': totalDislikes,
    'contentType': contentType,
    if (isLiked != null) 'isLiked': isLiked,
    if (isDisliked != null) 'isDisliked': isDisliked,
  };
}
