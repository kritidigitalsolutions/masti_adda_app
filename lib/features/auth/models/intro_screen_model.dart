class IntroScreenResponse {
  final bool? success;
  final int? count;
  final List<IntroScreenItem>? data;

  IntroScreenResponse({this.success, this.count, this.data});

  factory IntroScreenResponse.fromJson(Map<String, dynamic> json) {
    return IntroScreenResponse(
      success: json['success'],
      count: json['count'],
      data: json['data'] != null
          ? (json['data'] as List).map((i) => IntroScreenItem.fromJson(i)).toList()
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

class IntroScreenItem {
  final String? id;
  final String? title;
  final String? image;
  final int? order;

  IntroScreenItem({
    this.id,
    this.title,
    this.image,
    this.order,
  });

  factory IntroScreenItem.fromJson(Map<String, dynamic> json) {
    return IntroScreenItem(
      id: json['_id'],
      title: json['title'],
      image: json['image'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'image': image,
      'order': order,
    };
  }
}
