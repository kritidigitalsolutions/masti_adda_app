import 'package:get/get.dart';
import 'package:masti_adda_app/routes/app_routes.dart';

class MovieListingController extends GetxController {
  final RxInt selectedCategoryIndex = 0.obs;

  final List<String> categories = [
    'All',
    'Action',
    'Romance',
    'Thriller',
    'Horror',
    'Comedy',
  ];

  final List<Map<String, String>> allMovies = List.generate(
    12,
    (i) => {
      'title': i % 3 == 0
          ? 'Me Before You'
          : i % 3 == 1
              ? 'Connect'
              : 'Squid Game',
      'genre': i % 3 == 0
          ? 'Romance'
          : i % 3 == 1
              ? 'Romance'
              : 'Thriller',
      'image': 'https://picsum.photos/seed/mov${i + 1}/200/300',
    },
  );

  List<Map<String, String>> get filteredMovies {
    if (selectedCategoryIndex.value == 0) return allMovies;
    final genre = categories[selectedCategoryIndex.value];
    return allMovies.where((m) => m['genre'] == genre).toList();
  }

  void onCategorySelected(int index) => selectedCategoryIndex.value = index;

  void onMovieTap(Map<String, String> movie) {
    Get.toNamed(AppRoutes.movieDetails);
  }
}
