import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/web/controllers/web_search_controller.dart';
import 'package:masti_adda_app/web/layouts/web_main_layout.dart';
import 'package:masti_adda_app/web/routes/web_routes.dart';
import 'package:masti_adda_app/web/utils/web_responsive.dart';
import 'package:masti_adda_app/web/widgets/web_content_card.dart';
import 'package:masti_adda_app/web/widgets/web_responsive_grid.dart';
import 'package:masti_adda_app/web/widgets/web_shimmer.dart';

class WebSearchScreen extends StatelessWidget {
  const WebSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WebSearchController());
    final horizontalPadding = WebResponsive.contentHorizontalPadding(context);

    return WebMainLayout(
      activeRoute: WebRoutes.search,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar Header with Back Button
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
                const SizedBox(width: 8),
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 700),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181C26),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.borderColor.withOpacity(0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(Icons.search_rounded,
                                color: AppColors.primaryPink, size: 24),
                          ),
                          Expanded(
                            child: TextField(
                              controller: controller.searchInputController,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: 'Search for dramas, movies, series, genres...',
                                hintStyle: TextStyle(
                                  color: AppColors.secondaryTextColor,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              onChanged: controller.onQueryChanged,
                            ),
                          ),
                          Obx(() {
                            if (controller.query.value.isNotEmpty) {
                              return IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    color: AppColors.secondaryTextColor, size: 20),
                                onPressed: () {
                                  controller.searchInputController.clear();
                                  controller.onQueryChanged('');
                                },
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Type Filter Chips (All, Dramas, Movies, Series)
            Obx(() {
              if (controller.allResults.isEmpty) return const SizedBox.shrink();

              final filters = ['All', 'Dramas', 'Movies', 'Series'];
              return Center(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: filters.map((filter) {
                    final isSelected = controller.selectedTypeFilter.value == filter;
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => controller.selectedTypeFilter.value = filter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryPink
                                : AppColors.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryPink
                                  : AppColors.borderColor.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.white.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),

            const SizedBox(height: 32),

            // Search Results Display
            Obx(() {
              if (controller.isLoading.value) {
                return WebResponsiveGrid(
                  children: List.generate(12, (_) => const WebShimmerCard()),
                );
              }

              if (controller.query.value.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 80.0),
                    child: Column(
                      children: [
                        Icon(Icons.search_rounded,
                            color: AppColors.secondaryTextColor, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'Find Your Next Favorite Story',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Type a title, actor, or genre to search across Dramas, Movies, and Series.',
                          style: TextStyle(
                            color: AppColors.secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final results = controller.filteredResults;
              if (results.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80.0),
                    child: Column(
                      children: [
                        const Icon(Icons.sentiment_dissatisfied_rounded,
                            color: AppColors.secondaryTextColor, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          'No results found for "${controller.query.value}"',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try searching with a different keyword or browsing our categories.',
                          style: TextStyle(
                            color: AppColors.secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Found ${results.length} results for "${controller.query.value}"',
                    style: const TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  WebResponsiveGrid(
                    children: results.map((item) {
                      return WebContentCard(
                        id: item.id,
                        title: item.title,
                        posterUrl: item.poster,
                        category: item.genre,
                        type: item.type,
                        rating: item.rating,
                        duration: item.duration,
                        releaseYear: item.releaseYear,
                        isPremium: item.isPremium,
                        onTap: () => Get.toNamed(
                          '${WebRoutes.details}?id=${item.id}&type=${item.type}',
                          arguments: {'id': item.id, 'type': item.type},
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
