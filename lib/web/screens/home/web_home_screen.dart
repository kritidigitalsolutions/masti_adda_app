import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/web/controllers/web_home_controller.dart';
import 'package:masti_adda_app/web/layouts/web_main_layout.dart';
import 'package:masti_adda_app/web/routes/web_routes.dart';
import 'package:masti_adda_app/web/utils/web_responsive.dart';
import 'package:masti_adda_app/web/widgets/web_content_card.dart';
import 'package:masti_adda_app/web/widgets/web_content_section.dart';
import 'package:masti_adda_app/web/widgets/web_hero_carousel.dart';

class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  late final WebHomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<WebHomeController>()
        ? Get.find<WebHomeController>()
        : Get.put(WebHomeController(), permanent: true);

    // Refresh home data silently upon entering to guarantee fresh image URLs and VIP status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchAllHomeData(isSilent: _controller.sections.isNotEmpty);
    });
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = WebResponsive.contentHorizontalPadding(context);

    return WebMainLayout(
      activeRoute: WebRoutes.home,
      body: Obx(() {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Spotlight Carousel (GET /api/webpage-layout/banners)
            WebHeroCarousel(
              banners: _controller.banners,
              isLoading: _controller.isBannersLoading.value,
            ),

            const SizedBox(height: 10),

            // 2. Dynamic Carousel Rows / Sections (GET /api/webpage-layout/sections)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_controller.isSectionsLoading.value &&
                      _controller.sections.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),

                  ..._controller.sections.map((section) {
                    if (section.items.isEmpty) return const SizedBox.shrink();

                    return WebContentSection(
                      title: section.title,
                      subtitle: section.subtitle,
                      items: section.items.map((item) {
                        return WebContentCard(
                          id: item.id,
                          title: item.title,
                          posterUrl: item.poster,
                          bannerUrl: item.banner,
                          type: item.type,
                          category: item.category ?? section.title,
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
