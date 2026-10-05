class HomeBannerResponse {
  final bool? success;
  final int? count;
  final List<HomeBannerItem>? data;

  HomeBannerResponse({this.success, this.count, this.data});

  factory HomeBannerResponse.fromJson(Map<String, dynamic> json) {
    return HomeBannerResponse(
      success: json['success'],
      count: json['count'],
      data: json['data'] != null
          ? (json['data'] as List).map((i) => HomeBannerItem.fromJson(i)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'count': count,
      'data': data?.map((v) => v.toJson()).toList(),
    };
  }
}

class HomeBannerItem {
  final String? id;
  final String? title;
  final String? banner;
  final String? contentType;
  final int? order;
  final bool? isActive;
  final HomeBannerContent? content;
  final String? createdAt;

  HomeBannerItem({
    this.id,
    this.title,
    this.banner,
    this.contentType,
    this.order,
    this.isActive,
    this.content,
    this.createdAt,
  });

  factory HomeBannerItem.fromJson(Map<String, dynamic> json) {
    return HomeBannerItem(
      id: json['_id'],
      title: json['title'],
      banner: json['banner'],
      contentType: json['contentType'],
      order: json['order'],
      isActive: json['isActive'],
      content: json['contentId'] is Map<String, dynamic>
          ? HomeBannerContent.fromJson(json['contentId'])
          : null,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'banner': banner,
      'contentType': contentType,
      'order': order,
      'isActive': isActive,
      'contentId': content?.toJson(),
      'createdAt': createdAt,
    };
  }
}

class HomeBannerContent {
  final String? id;
  final String? title;
  final String? storyline;
  final String? poster;
  final String? banner;
  final int? releaseYear;
  final List<String>? genre;
  final String? rating;
  final String? duration;
  final String? videoUrl;
  final String? type;
  final String? modelName;

  HomeBannerContent({
    this.id,
    this.title,
    this.storyline,
    this.poster,
    this.banner,
    this.releaseYear,
    this.genre,
    this.rating,
    this.duration,
    this.videoUrl,
    this.type,
    this.modelName,
  });

  factory HomeBannerContent.fromJson(Map<String, dynamic> json) {
    return HomeBannerContent(
      id: json['_id'],
      title: json['title'],
      storyline: json['storyline'],
      poster: json['poster'],
      banner: json['banner'],
      releaseYear: json['releaseYear'],
      genre: json['genre'] != null ? List<String>.from(json['genre']) : [],
      rating: json['rating']?.toString(),
      duration: json['duration'],
      videoUrl: json['videoUrl'],
      type: json['type'],
      modelName: json['modelName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'storyline': storyline,
      'poster': poster,
      'banner': banner,
      'releaseYear': releaseYear,
      'genre': genre,
      'rating': rating,
      'duration': duration,
      'videoUrl': videoUrl,
      'type': type,
      'modelName': modelName,
    };
  }
}
