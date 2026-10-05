import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/web/controllers/web_home_controller.dart';
import 'package:masti_adda_app/web/layouts/web_main_layout.dart';
import 'package:masti_adda_app/web/routes/web_routes.dart';
import 'package:masti_adda_app/web/utils/web_category_helper.dart';
import 'package:masti_adda_app/web/utils/web_responsive.dart';
import 'package:masti_adda_app/web/widgets/web_content_card.dart';
import 'package:masti_adda_app/web/widgets/web_content_section.dart';
import 'package:masti_adda_app/web/widgets/web_hero_carousel.dart';

class WebHomeScreen extends StatelessWidget {
  const WebHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WebHomeController(), permanent: true);
    final horizontalPadding = WebResponsive.contentHorizontalPadding(context);

    return WebMainLayout(
      activeRoute: WebRoutes.home,
      body: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Spotlight Carousel
            WebHeroCarousel(
              banners: controller.banners,
              isLoading: controller.isBannersLoading.value,
            ),

            const SizedBox(height: 10),

            // Content Sections Container
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 5. Dynamic Category Rows from API (sorted by priority)
                  ...controller.categories.map((category) {
                    final apiItems =
                        controller.categoryContents[category.id] ?? [];
                    final matchedMovies = controller.movies
                        .where(
                          (m) => WebCategoryHelper.matchesMovie(m, category),
                        )
                        .toList();
                    final matchedSeries = controller.series
                        .where(
                          (s) => WebCategoryHelper.matchesSeries(s, category),
                        )
                        .toList();
                    final matchedDramas = controller.dramas
                        .where(
                          (d) => WebCategoryHelper.matchesDrama(d, category),
                        )
                        .toList();

                    final List<Map<String, dynamic>> combined = [];
                    final Set<String> seenIds = {};

                    for (final c in apiItems) {
                      if (c.id.isNotEmpty && !seenIds.contains(c.id)) {
                        seenIds.add(c.id);
                        final t = c.type.toLowerCase();
                        combined.add({
                          'id': c.id,
                          'title': c.title,
                          'poster': c.poster.isNotEmpty ? c.poster : c.banner,
                          'type': t.contains('drama')
                              ? 'drama'
                              : (t.contains('series') ? 'series' : 'movie'),
                          'rating': c.rating.toDouble(),
                          'priority': c.priority,
                          'isPremium': c.isPremium,
                          'duration': c.duration,
                          'releaseYear': c.releaseYear,
                          'category': c.genre.isNotEmpty
                              ? c.genre.first
                              : category.name,
                        });
                      }
                    }

                    for (final m in matchedMovies) {
                      if (m.id.isNotEmpty && !seenIds.contains(m.id)) {
                        seenIds.add(m.id);
                        combined.add({
                          'id': m.id,
                          'title': m.title,
                          'poster': m.poster.isNotEmpty ? m.poster : m.banner,
                          'type': 'movie',
                          'rating': m.rating,
                          'priority': m.priority,
                          'isPremium': m.isPremium,
                          'duration': m.duration,
                          'releaseYear': m.releaseYear,
                          'category': m.genre.isNotEmpty
                              ? m.genre.first
                              : category.name,
                        });
                      }
                    }

                    for (final s in matchedSeries) {
                      if (s.id.isNotEmpty && !seenIds.contains(s.id)) {
                        seenIds.add(s.id);
                        combined.add({
                          'id': s.id,
                          'title': s.title,
                          'poster': s.poster.isNotEmpty ? s.poster : s.banner,
                          'type': 'series',
                          'rating': s.rating,
                          'priority': s.priority,
                          'isPremium': s.isPremium,
                          'duration': s.duration,
                          'releaseYear': s.releaseYear,
                          'category': s.genre.isNotEmpty
                              ? s.genre.first
                              : category.name,
                        });
                      }
                    }

                    for (final d in matchedDramas) {
                      if (d.id.isNotEmpty && !seenIds.contains(d.id)) {
                        seenIds.add(d.id);
                        combined.add({
                          'id': d.id,
                          'title': d.title,
                          'poster': d.poster.isNotEmpty ? d.poster : d.banner,
                          'type': 'drama',
                          'rating': d.rating.toDouble(),
                          'priority': d.priority,
                          'isPremium': d.isPremium,
                          'duration': d.duration,
                          'releaseYear': d.releaseYear,
                          'category': d.genre.isNotEmpty
                              ? d.genre.first.toString()
                              : category.name,
                        });
                      }
                    }

                    if (combined.isEmpty) return const SizedBox.shrink();

                    // Sort items by priority ascending (1, 2, 3...), then rating descending
                    combined.sort((a, b) {
                      final pA = a['priority'] as int? ?? 0;
                      final pB = b['priority'] as int? ?? 0;
                      if (pA != pB) return pA.compareTo(pB);
                      final rA = (a['rating'] as num?)?.toDouble() ?? 0.0;
                      final rB = (b['rating'] as num?)?.toDouble() ?? 0.0;
                      return rB.compareTo(rA);
                    });

                    return WebContentSection(
                      title: category.name,
                      items: combined.map((item) {
                        final id = item['id'] as String;
                        final title = item['title'] as String;
                        final poster = item['poster'] as String;
                        final type = item['type'] as String;
                        final rating = (item['rating'] as num).toDouble();
                        final isPremium = item['isPremium'] as bool;
                        final duration = item['duration'] as String?;
                        final releaseYear = item['releaseYear'] as int?;
                        final catName = item['category'] as String?;

                        return WebContentCard(
                          id: id,
                          title: title,
                          posterUrl: poster,
                          type: type,
                          category: catName ?? category.name,
                          rating: rating,
                          duration: duration,
                          releaseYear: releaseYear,
                          isPremium: isPremium,
                          onTap: () => Get.toNamed(
                            '${WebRoutes.details}?id=$id&type=$type',
                            arguments: {'id': id, 'type': type},
                          ),
                        );
                      }).toList(),
                    );
                  }),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
