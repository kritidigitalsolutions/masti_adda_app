import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/auth/controllers/register_controller.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/shared/widgets/custom_button.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:google_fonts/google_fonts.dart';

class SelectInterestsScreen extends StatelessWidget {
  SelectInterestsScreen({super.key});

  final RegistrationController controller =
      Get.find<RegistrationController>(); // was Get.put(...)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF141420),
                  Color(0xFF0E0E18),
                  Color(0xFF0A0A14),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back button
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AppBackButton(),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // ── Title ──
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Create Your\n',
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textColor,
                                  height: 1.3,
                                ),
                              ),
                              TextSpan(
                                text: 'Interests',
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryColor,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select what you love to watch!',
                          style: text13(color: AppColors.secondaryTextColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        // ── Interest grid ──
                        Obx(() {
                          final selectedList = controller.selectedInterests
                              .toList();

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.interests.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.0,
                                ),
                            itemBuilder: (_, i) {
                              final item = controller.interests[i];
                              final isSelected = selectedList.contains(i);

                              return _InterestTile(
                                item: item,
                                isSelected: isSelected,
                                onTap: () => controller.toggleInterest(i),
                              );
                            },
                          );
                        }),
                        const SizedBox(height: 32),

                        Obx(() {
                          final hasSelected =
                              controller.selectedInterests.isNotEmpty;
                          final isLoading = controller
                              .isCompleteProfileLoading
                              .value; // was isLoading
                          return AppButton(
                            title: "Next",
                            onTap: hasSelected
                                ? controller.continueFromInterests
                                : null,
                            isLoading: isLoading,
                          );
                        }),

                        const SizedBox(height: 16),

                        Obx(
                          () => GestureDetector(
                            onTap: controller.isCompleteProfileLoading.value
                                ? null
                                : controller.skipInterests,
                            child: Text(
                              'Skip For Now',
                              style: text14(
                                color: AppColors.secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Single interest tile ─────────────────────────────
class _InterestTile extends StatelessWidget {
  final dynamic item; // InterestItem
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentColor.withOpacity(0.15)
              : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentColor : AppColors.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Checkmark badge top-right
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),

            // Icon + label
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(item.image, height: 40, width: 40),

                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    style: text11(
                      color: isSelected
                          ? AppColors.textColor
                          : AppColors.secondaryTextColor,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
