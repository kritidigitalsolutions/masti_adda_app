import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DiscoverController extends GetxController {
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  final List<String> trendingSearches = [
    'Romance Drama',
    'Billionaire Series',
    'Thriller',
    'CEO Love Story',
  ];

  final List<Map<String, dynamic>> categories = [
    {'label': 'Movies', 'icon': Icons.movie_outlined},
    {'label': 'Web Series', 'icon': Icons.live_tv_outlined},
    {'label': 'Micro Dramas', 'icon': Icons.video_library_outlined},
    {'label': 'Action', 'icon': Icons.local_fire_department_outlined},
    {'label': 'Romance', 'icon': Icons.favorite_outline},
    {'label': 'Thriller', 'icon': Icons.theater_comedy_outlined},
    {'label': 'Comedy', 'icon': Icons.sentiment_very_satisfied_outlined},
    {'label': 'Bold Content', 'icon': Icons.eighteen_up_rating_outlined},
    {'label': 'Suspense', 'icon': Icons.remove_red_eye_outlined},
  ];

  void onSearchChanged(String val) => searchQuery.value = val;

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
