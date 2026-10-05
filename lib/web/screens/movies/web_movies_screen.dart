import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/web/controllers/web_content_controller.dart';
import 'package:masti_adda_app/web/layouts/web_main_layout.dart';
import 'package:masti_adda_app/web/routes/web_routes.dart';
import 'package:masti_adda_app/web/utils/web_responsive.dart';
import 'package:masti_adda_app/web/widgets/web_content_card.dart';
import 'package:masti_adda_app/web/widgets/web_responsive_grid.dart';
import 'package:masti_adda_app/web/widgets/web_shimmer.dart';

class WebMoviesScreen extends StatelessWidget {
  const WebMoviesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WebContentController(), permanent: true);
    final horizontalPadding = WebResponsive.contentHorizontalPadding(context);

    return WebMainLayout(
      activeRoute: WebRoutes.movies,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title with Back Button
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'Back',
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Get.back();
                    } else {
                      Get.toNamed(WebRoutes.home);
                    }
                  },
                ),
                const SizedBox(width: 6),
                Container(
                  width: 5,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Blockbuster Movies',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore top-rated movies, new releases, and all-time favorites.',
              style: TextStyle(
                color: AppColors.secondaryTextColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Genre Filter Chips
            Obx(() {
              final genres = controller.movieGenres;
              final selected = controller.selectedMovieGenre.value;
              if (genres.length <= 1) return const SizedBox.shrink();

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: genres.map((genre) {
                    final isSelected = selected.toLowerCase() == genre.toLowerCase();

                    return Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            controller.selectedMovieGenre.value = genre;
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryPink
                                  : AppColors.surfaceColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryPink
                                    : AppColors.borderColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              genre,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),

            const SizedBox(height: 28),

            // Content Grid
            Obx(() {
              if (controller.isMoviesLoading.value) {
                return WebResponsiveGrid(
                  children: List.generate(12, (_) => const WebShimmerCard()),
                );
              }

              final movies = controller.filteredMovies;
              if (movies.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60.0),
                    child: Column(
                      children: [
                        Icon(Icons.movie_outlined,
                            color: AppColors.secondaryTextColor, size: 56),
                        SizedBox(height: 16),
                        Text(
                          'No movies found in this category',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return WebResponsiveGrid(
                children: movies.map((movie) {
                  return WebContentCard(
                    id: movie.id,
                    title: movie.title,
                    posterUrl: movie.poster.isNotEmpty ? movie.poster : movie.banner,
                    category: movie.genre.isNotEmpty ? movie.genre.first : 'Movie',
                    type: 'movie',
                    rating: movie.rating,
                    duration: movie.duration,
                    releaseYear: movie.releaseYear,
                    isPremium: movie.isPremium,
                    onTap: () => Get.toNamed(
                      '${WebRoutes.details}?id=${movie.id}&type=movie',
                      arguments: {'id': movie.id, 'type': 'movie'},
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}
