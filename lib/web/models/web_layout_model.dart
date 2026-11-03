import 'package:masti_adda_app/features/home/models/home_banner_model.dart';

class WebLayoutBannersResponse {
  final bool success;
  final int count;
  final List<HomeBannerItem> heroBanners;

  WebLayoutBannersResponse({
    required this.success,
    required this.count,
    required this.heroBanners,
  });

  factory WebLayoutBannersResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['heroBanners'] ?? json['banners'] ?? json['data'];
    final List<HomeBannerItem> items = [];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          items.add(parseBannerItem(item));
        }
      }
    }
    return WebLayoutBannersResponse(
      success: json['success'] ?? true,
      count: json['count'] ?? items.length,
      heroBanners: items,
    );
  }

  static HomeBannerItem parseBannerItem(Map<String, dynamic> json) {
    final contentMap = json['contentId'] is Map<String, dynamic>
        ? json['contentId'] as Map<String, dynamic>
        : (json['content'] is Map<String, dynamic>
            ? json['content'] as Map<String, dynamic>
            : null);

    final String? id = json['_id']?.toString() ??
        json['id']?.toString() ??
        contentMap?['_id']?.toString() ??
        contentMap?['id']?.toString();
    final String? title = json['title']?.toString() ??
        json['name']?.toString() ??
        contentMap?['title']?.toString() ??
        contentMap?['name']?.toString();
    final String? banner = json['banner']?.toString() ??
        json['image']?.toString() ??
        json['imageUrl']?.toString() ??
        json['backdrop']?.toString() ??
        contentMap?['banner']?.toString() ??
        contentMap?['backdrop']?.toString();
    final String? contentType = json['contentType']?.toString() ??
        json['type']?.toString() ??
        json['modelName']?.toString() ??
        contentMap?['type']?.toString() ??
        contentMap?['contentType']?.toString() ??
        contentMap?['modelName']?.toString();
    final int? order = (json['order'] is num)
        ? (json['order'] as num).toInt()
        : (json['priority'] is num
            ? (json['priority'] as num).toInt()
            : null);
    final bool? isActive = json['isActive'] ?? true;

    HomeBannerContent? bannerContent;
    if (contentMap != null) {
      bannerContent = HomeBannerContent.fromJson(contentMap);
    } else {
      bannerContent = HomeBannerContent(
        id: id,
        title: title,
        storyline: json['storyline']?.toString() ??
            json['description']?.toString() ??
            json['overview']?.toString(),
        poster: json['poster']?.toString() ?? banner,
        banner: banner,
        releaseYear: (json['releaseYear'] is num)
            ? (json['releaseYear'] as num).toInt()
            : int.tryParse(json['releaseYear']?.toString() ?? ''),
        genre: (json['genre'] is List)
            ? (json['genre'] as List).map((e) => e.toString()).toList()
            : (json['genres'] is List
                ? (json['genres'] as List).map((e) => e.toString()).toList()
                : (json['category'] != null
                    ? [json['category'].toString()]
                    : null)),
        rating: json['rating']?.toString(),
        duration: json['duration']?.toString(),
        videoUrl: json['videoUrl']?.toString(),
        type: contentType,
        modelName: contentType,
      );
    }

    return HomeBannerItem(
      id: id,
      title: title,
      banner: banner,
      contentType: contentType,
      order: order,
      isActive: isActive,
      content: bannerContent,
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class WebLayoutSectionsResponse {
  final bool success;
  final int count;
  final List<WebLayoutSection> sections;

  WebLayoutSectionsResponse({
    required this.success,
    required this.count,
    required this.sections,
  });

  factory WebLayoutSectionsResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['sections'] ?? json['data'] ?? json['rows'];
    final List<WebLayoutSection> list = [];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          list.add(WebLayoutSection.fromJson(item));
        }
      }
    }
    return WebLayoutSectionsResponse(
      success: json['success'] ?? true,
      count: json['count'] ?? list.length,
      sections: list,
    );
  }
}

class WebLayoutSection {
  final String id;
  final String title;
  final String slug;
  final String? subtitle;
  final int order;
  final bool isActive;
  final String? sectionType;
  final List<WebLayoutItem> items;

  WebLayoutSection({
    required this.id,
    required this.title,
    required this.slug,
    this.subtitle,
    required this.order,
    this.isActive = true,
    this.sectionType,
    required this.items,
  });

  factory WebLayoutSection.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ??
        json['contents'] ??
        json['content'] ??
        json['data'] ??
        json['movies'] ??
        json['series'] ??
        json['microdramas'] ??
        [];

    final List<WebLayoutItem> parsedItems = [];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map<String, dynamic>) {
          parsedItems.add(WebLayoutItem.fromJson(raw));
        }
      }
    }

    return WebLayoutSection(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      subtitle:
          json['subtitle']?.toString() ?? json['description']?.toString(),
      order: (json['order'] is num)
          ? (json['order'] as num).toInt()
          : (json['priority'] is num
              ? (json['priority'] as num).toInt()
              : 0),
      isActive: json['isActive'] != false,
      sectionType: json['sectionType']?.toString() ?? json['type']?.toString(),
      items: parsedItems,
    );
  }
}

class WebLayoutItem {
  final String id;
  final String title;
  final String poster;
  final String banner;
  final String type; // 'movie', 'series', 'drama'
  final double rating;
  final bool isPremium;
  final String? duration;
  final int? releaseYear;
  final String? category;
  final String? trailerUrl;
  final int priority;

  WebLayoutItem({
    required this.id,
    required this.title,
    required this.poster,
    required this.banner,
    required this.type,
    required this.rating,
    required this.isPremium,
    this.duration,
    this.releaseYear,
    this.category,
    this.trailerUrl,
    required this.priority,
  });

  factory WebLayoutItem.fromJson(Map<String, dynamic> json) {
    final contentMap = json['contentId'] is Map<String, dynamic>
        ? json['contentId'] as Map<String, dynamic>
        : (json['content'] is Map<String, dynamic>
            ? json['content'] as Map<String, dynamic>
            : null);

    final raw = contentMap ?? json;

    final id = (raw['_id'] ??
            raw['id'] ??
            json['_id'] ??
            json['id'] ??
            '')
        .toString();
    final title = (raw['title'] ??
            raw['name'] ??
            json['title'] ??
            json['name'] ??
            '')
        .toString();

    final poster = (raw['poster'] ??
            raw['image'] ??
            raw['thumbnail'] ??
            raw['imageUrl'] ??
            json['poster'] ??
            json['image'] ??
            raw['banner'] ??
            '')
        .toString();

    final banner = (raw['banner'] ??
            raw['backdrop'] ??
            json['banner'] ??
            poster)
        .toString();

    final rawType = (raw['contentType'] ??
            raw['type'] ??
            raw['modelName'] ??
            json['contentType'] ??
            json['type'] ??
            'movie')
        .toString()
        .toLowerCase();

    String parsedType = 'movie';
    if (rawType.contains('drama') ||
        rawType.contains('microdrama') ||
        rawType.contains('micro_drama')) {
      parsedType = 'drama';
    } else if (rawType.contains('series') || rawType.contains('webseries')) {
      parsedType = 'series';
    } else {
      parsedType = 'movie';
    }

    final double rating = (raw['rating'] is num)
        ? (raw['rating'] as num).toDouble()
        : double.tryParse(raw['rating']?.toString() ?? '0') ?? 0.0;

    final bool isPremium = raw['isPremium'] == true ||
        raw['is_premium'] == true ||
        raw['premium'] == true ||
        json['isPremium'] == true;

    final String? duration =
        (raw['duration'] ?? json['duration'])?.toString();

    int? releaseYear;
    if (raw['releaseYear'] is num) {
      releaseYear = (raw['releaseYear'] as num).toInt();
    } else if (raw['releaseYear'] != null) {
      releaseYear = int.tryParse(raw['releaseYear'].toString());
    }

    String? category;
    if (raw['genre'] is List && (raw['genre'] as List).isNotEmpty) {
      category = (raw['genre'] as List).first.toString();
    } else if (raw['category'] != null) {
      if (raw['category'] is Map) {
        category = raw['category']['name']?.toString();
      } else {
        category = raw['category']?.toString();
      }
    }

    final String? trailerUrl = (raw['trailerUrl'] ??
            raw['trailer'] ??
            json['trailerUrl'] ??
            json['trailer'])
        ?.toString();

    final int priority = (json['priority'] is num)
        ? (json['priority'] as num).toInt()
        : ((raw['priority'] is num)
            ? (raw['priority'] as num).toInt()
            : ((json['order'] is num)
                ? (json['order'] as num).toInt()
                : 0));

    return WebLayoutItem(
      id: id,
      title: title,
      poster: poster,
      banner: banner,
      type: parsedType,
      rating: rating,
      isPremium: isPremium,
      duration: duration,
      releaseYear: releaseYear,
      category: category,
      trailerUrl: trailerUrl,
      priority: priority,
    );
  }
}

