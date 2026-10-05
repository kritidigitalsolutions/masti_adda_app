import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/auth/controllers/auth_controller.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/shared/widgets/custom_button.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatelessWidget {
  OnboardingScreen({super.key});

  final OnboardingController controller = Get.put(OnboardingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Page view
          Obx(
            () => PageView.builder(
              controller: controller.pageController,
              itemCount: controller.totalPages,
              onPageChanged: controller.onPageChanged,
              itemBuilder: (_, i) =>
                  _OnboardingPageView(page: controller.pages[i]),
            ),
          ),

          Positioned(
            right: 20,
            top: 20,
            child: CustomTextButton(
              title: "Skip",
              onTap: () {
                Get.toNamed(AppRoutes.login);
              },
            ),
          ),

          // Bottom controls overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Obx(
              () => _BottomControls(
                totalPages: controller.totalPages,
                currentPage: controller.currentPage.value,
                isLastPage: controller.isLastPage,
                onNext: controller.nextPage,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Single Onboarding Page
// ─────────────────────────────────────────────────────
class _OnboardingPageView extends StatelessWidget {
  final dynamic page; // OnboardingPage
  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        if (page.imageUrl != null && page.imageUrl.toString().isNotEmpty)
          Image.network(
            formatMediaUrl(page.imageUrl.toString()),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => page.imagePath != null
                ? Image.asset(page.imagePath, fit: BoxFit.cover)
                : Container(color: Colors.black),
          )
        else if (page.imagePath != null)
          Image.asset(page.imagePath, fit: BoxFit.cover)
        else
          Container(color: Colors.black),

        // Bottom gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.35),
                Colors.black.withOpacity(0.75),
                Colors.black.withOpacity(0.97),
              ],
              stops: const [0.0, 0.45, 0.7, 1.0],
            ),
          ),
        ),

        // Text content
        Positioned(
          left: 28,
          right: 28,
          bottom: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                page.title,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: page.accentColor,
                  height: 1.15,
                ),
                textAlign: TextAlign.center,
              ),
              // Text(
              //   page.titleHighlight,
              //   style: GoogleFonts.poppins(
              //     fontSize: 26,
              //     fontWeight: FontWeight.w800,
              //     color: page.accentColor,
              //     height: 1.15,
              //   ),
              //   textAlign: TextAlign.center,
              // ),
              // const SizedBox(height: 12),
              // Text(
              //   page.subtitle,
              //   style: text14(color: AppColors.secondaryTextColor),
              //   textAlign: TextAlign.center,
              // ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
// Bottom Controls
// ─────────────────────────────────────────────────────
class _BottomControls extends StatelessWidget {
  final int totalPages;
  final int currentPage;
  final bool isLastPage;
  final VoidCallback onNext;

  const _BottomControls({
    required this.totalPages,
    required this.currentPage,
    required this.isLastPage,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (i) {
              final isActive = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryColor
                      : AppColors.dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Next / Get Started button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                isLastPage ? 'Get Started' : 'Next',
                style: text16(
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
