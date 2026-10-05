import 'package:get/get.dart';
import 'package:masti_adda_app/routes/app_routes.dart';

// ── Web Series Model ───────────────────────────────────────────────────────
class WebSeriesModel {
  final String id;
  final String title;
  final String imageUrl;
  final double rating;
  final int totalReviews;
  final List<String> tags;
  final String description;
  final String genre;
  final List<WebSeriesEpisode> season1;
  final List<WebSeriesEpisode> season2;

  const WebSeriesModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.totalReviews,
    required this.tags,
    required this.description,
    required this.genre,
    required this.season1,
    required this.season2,
  });
}

class WebSeriesEpisode {
  final int number;
  final String title;
  final String duration;
  final String thumbnailUrl;

  const WebSeriesEpisode({
    required this.number,
    required this.title,
    required this.duration,
    required this.thumbnailUrl,
  });
}

// ── Listing Controller ─────────────────────────────────────────────────────
class WebSeriesListingController extends GetxController {
  final RxInt selectedCategoryIndex = 0.obs;

  final List<String> categories = [
    'All',
    'Action',
    'Romance',
    'Thriller',
    'Horror',
    'Comedy',
  ];

  final List<Map<String, String>> allSeries = List.generate(
    12,
    (i) => {
      'title': i % 3 == 0
          ? 'Me Before You'
          : i % 3 == 1
              ? 'Squid Game'
              : 'Connect',
      'genre': i % 3 == 0
          ? 'Romance'
          : i % 3 == 1
              ? 'Thriller'
              : 'Romance',
      'image': 'https://picsum.photos/seed/ser${i + 1}/200/300',
    },
  );

  List<Map<String, String>> get filteredSeries {
    if (selectedCategoryIndex.value == 0) return allSeries;
    final genre = categories[selectedCategoryIndex.value];
    return allSeries.where((s) => s['genre'] == genre).toList();
  }

  void onCategorySelected(int index) => selectedCategoryIndex.value = index;

  void onSeriesTap(Map<String, String> series) {
    final model = _buildSeriesModel(series);
    Get.toNamed(AppRoutes.webSeriesDetail, arguments: model);
  }

  WebSeriesModel _buildSeriesModel(Map<String, String> s) {
    final eps1 = List.generate(
      5,
      (i) => WebSeriesEpisode(
        number: i + 1,
        title: 'Episode ${i + 1}',
        duration: '56 min',
        thumbnailUrl: 'https://picsum.photos/seed/ep1${i + 1}/200/120',
      ),
    );
    final eps2 = List.generate(
      5,
      (i) => WebSeriesEpisode(
        number: i + 1,
        title: 'Episode ${i + 1}',
        duration: '52 min',
        thumbnailUrl: 'https://picsum.photos/seed/ep2${i + 1}/200/120',
      ),
    );
    return WebSeriesModel(
      id: s['title'] ?? '',
      title: s['title'] ?? 'Squid Game',
      imageUrl: s['image'] ?? 'https://picsum.photos/seed/squid/700/400',
      rating: 4.6,
      totalReviews: 13500,
      tags: ['18+', 'Drama', 'Thriller', '2024'],
      description:
          'A gripping story of power, betrayal and survival. Watch how one man rises from the ashes of his past to reclaim his destiny.',
      genre: s['genre'] ?? 'Thriller',
      season1: eps1,
      season2: eps2,
    );
  }
}

// ── Detail Controller ──────────────────────────────────────────────────────
class WebSeriesDetailController extends GetxController {
  late WebSeriesModel series;
  final RxBool isInWatchlist = false.obs;
  final RxInt selectedSeason = 0.obs; // 0 = S1, 1 = S2

  List<WebSeriesEpisode> get currentEpisodes =>
      selectedSeason.value == 0 ? series.season1 : series.season2;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is WebSeriesModel) {
      series = Get.arguments as WebSeriesModel;
    } else {
      series = _fallbackSeries();
    }
  }

  void toggleWatchlist() => isInWatchlist.value = !isInWatchlist.value;
  void selectSeason(int index) => selectedSeason.value = index;

  void onEpisodeTap(WebSeriesEpisode ep) {
    Get.toNamed(AppRoutes.videoPlayer, arguments: {'title': ep.title});
  }

  void onWatchNow() {
    Get.toNamed(AppRoutes.videoPlayer, arguments: {'title': series.title});
  }
}

WebSeriesModel _fallbackSeries() {
  final eps = List.generate(
    5,
    (i) => WebSeriesEpisode(
      number: i + 1,
      title: 'Episode ${i + 1}',
      duration: '56 min',
      thumbnailUrl: 'https://picsum.photos/seed/squid${i + 1}/200/120',
    ),
  );
  return WebSeriesModel(
    id: 'squid',
    title: 'Squid Game',
    imageUrl: 'https://picsum.photos/seed/squidhero/700/400',
    rating: 4.6,
    totalReviews: 13500,
    tags: ['18+', 'Drama', 'Thriller', '2024'],
    description:
        'A gripping story of power, betrayal and survival. Watch how one man rises from the ashes of his past to reclaim his destiny.',
    genre: 'Thriller',
    season1: eps,
    season2: eps,
  );
}
