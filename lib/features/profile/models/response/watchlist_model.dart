class WatchlistResponse {
  final bool? success;
  final int? count;
  final String? message;
  final List<WatchlistItem>? data;

  WatchlistResponse({this.success, this.count, this.message, this.data});

  factory WatchlistResponse.fromJson(Map<String, dynamic> json) {
    return WatchlistResponse(
      success: json['success'],
      count: json['count'],
      message: json['message'],
      data: json['data'] != null
          ? (json['data'] as List).map((i) => WatchlistItem.fromJson(i)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'count': count,
      'message': message,
      'data': data?.map((v) => v.toJson()).toList(),
    };
  }
}

class WatchlistItem {
  final String? id;
  final String? user;
  final WatchlistMediaItem? item;
  final String? itemModel;
  final String? createdAt;
  final String? updatedAt;

  WatchlistItem({
    this.id,
    this.user,
    this.item,
    this.itemModel,
    this.createdAt,
    this.updatedAt,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    WatchlistMediaItem? mediaItem;
    if (json['item'] is Map<String, dynamic>) {
      mediaItem = WatchlistMediaItem.fromJson(json['item']);
    } else if (json['itemId'] is Map<String, dynamic>) {
      mediaItem = WatchlistMediaItem.fromJson(json['itemId']);
    } else if (json['item'] is String) {
      mediaItem = WatchlistMediaItem(id: json['item']);
    } else if (json['itemId'] is String) {
      mediaItem = WatchlistMediaItem(id: json['itemId']);
    }

    return WatchlistItem(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      user: json['user']?.toString(),
      item: mediaItem,
      itemModel: json['itemModel']?.toString() ?? json['model']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user,
      'item': item?.toJson(),
      'itemModel': itemModel,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class WatchlistMediaItem {
  final String? id;
  final String? title;
  final String? poster;
  final String? banner;
  final int? releaseYear;
  final List<String>? genre;
  final String? rating;
  final String? duration;

  WatchlistMediaItem({
    this.id,
    this.title,
    this.poster,
    this.banner,
    this.releaseYear,
    this.genre,
    this.rating,
    this.duration,
  });

  factory WatchlistMediaItem.fromJson(Map<String, dynamic> json) {
    return WatchlistMediaItem(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      title: json['title'] ?? json['name'],
      poster: json['poster'] ?? json['coverImage'] ?? json['thumbnail'],
      banner: json['banner'],
      releaseYear: json['releaseYear'] is int
          ? json['releaseYear']
          : int.tryParse(json['releaseYear']?.toString() ?? ''),
      genre: json['genre'] != null
          ? List<String>.from(json['genre'].map((e) => e.toString()))
          : [],
      rating: json['rating']?.toString(),
      duration: json['duration']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'poster': poster,
      'banner': banner,
      'releaseYear': releaseYear,
      'genre': genre,
      'rating': rating,
      'duration': duration,
    };
  }
}
