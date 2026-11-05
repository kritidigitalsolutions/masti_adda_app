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
  final bool? isHide;
  final HomeBannerContent? content;
  final String? createdAt;

  HomeBannerItem({
    this.id,
    this.title,
    this.banner,
    this.contentType,
    this.order,
    this.isActive,
    this.isHide,
    this.content,
    this.createdAt,
  });

  bool get isVisible {
    if (isActive == false) return false;
    if (isHide == true) return false;
    if (content != null && !content!.isVisible) return false;
    return true;
  }

  factory HomeBannerItem.fromJson(Map<String, dynamic> json) {
    final dynamic active = json['isActive'] ?? json['is_active'] ?? json['active'];
    final bool? isActiveParsed = active == null
        ? null
        : (active == true || active == 1 || active.toString().toLowerCase() == 'true');

    final dynamic hide = json['isHide'] ?? json['is_hide'] ?? json['hide'];
    final bool? isHideParsed = hide == null
        ? null
        : (hide == true || hide == 1 || hide.toString().toLowerCase() == 'true');

    final contentJson = json['contentId'] ?? json['content'];

    return HomeBannerItem(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      banner: json['banner'],
      contentType: json['contentType'],
      order: json['order'],
      isActive: isActiveParsed,
      isHide: isHideParsed,
      content: contentJson is Map<String, dynamic>
          ? HomeBannerContent.fromJson(contentJson)
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
      'isHide': isHide,
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
  final String? trailerUrl;
  final String? type;
  final String? modelName;
  final bool? isHide;

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
    this.trailerUrl,
    this.type,
    this.modelName,
    this.isHide,
  });

  bool get isVisible => !(isHide ?? false);

  factory HomeBannerContent.fromJson(Map<String, dynamic> json) {
    final dynamic hide = json['isHide'] ?? json['is_hide'] ?? json['hide'];
    final bool? isHideParsed = hide == null
        ? null
        : (hide == true || hide == 1 || hide.toString().toLowerCase() == 'true');

    return HomeBannerContent(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      storyline: json['storyline'],
      poster: json['poster'],
      banner: json['banner'],
      releaseYear: json['releaseYear'],
      genre: json['genre'] != null ? List<String>.from(json['genre']) : [],
      rating: json['rating']?.toString(),
      duration: json['duration'],
      videoUrl: json['videoUrl'],
      trailerUrl: json['trailerUrl']?.toString() ?? json['trailer']?.toString(),
      type: json['type'],
      modelName: json['modelName'],
      isHide: isHideParsed,
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
      'trailerUrl': trailerUrl,
      'type': type,
      'modelName': modelName,
      'isHide': isHide,
    };
  }
}
