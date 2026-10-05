import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/profile/controllers/notification_settings_controller.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NotificationSettingsController.to;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchSettings(silent: controller.isLoaded.value);
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && !controller.isLoaded.value) {
                  return _buildShimmerLoading();
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Push Notifications',
                        style: text14(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _buildToggleTile('New Episodes', controller.newEpisodes),
                      _buildToggleTile('New Movies', controller.newMovies),
                      _buildToggleTile(
                        'Recommendations',
                        controller.recommendations,
                      ),
                      _buildToggleTile('Downloads', controller.downloads),
                      _buildToggleTile(
                        'Continue Watching Reminder',
                        controller.continueWatchingReminder,
                      ),
                      _buildToggleTile(
                        'Subscription Alerts',
                        controller.subscriptionAlerts,
                      ),
                      _buildToggleTile(
                        'Promotional Offers',
                        controller.promotionalOffers,
                      ),
                      const SizedBox(height: 24),
                      _buildSaveButton(controller),
                      const SizedBox(height: 30),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 140,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            7,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderColor.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: 12),
          Text(
            'Notifications Settings',
            style: text18(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(String title, RxBool observable) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: text14(fontWeight: FontWeight.w500)),
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: observable.value,
                onChanged: (val) => observable.value = val,
                activeThumbColor: AppColors.white,
                activeTrackColor: AppColors.accentColor,
                inactiveThumbColor: AppColors.secondaryTextColor,
                inactiveTrackColor: AppColors.dividerColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(NotificationSettingsController controller) {
    return GestureDetector(
      onTap: () {
        if (!controller.isSaving.value) {
          controller.saveChanges();
        }
      },
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Obx(() {
            if (controller.isSaving.value) {
              return const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: AppColors.black,
                  strokeWidth: 2.5,
                ),
              );
            }
            return Text(
              'Save Changes',
              style: text16(color: AppColors.black, fontWeight: FontWeight.bold),
            );
          }),
        ),
      ),
    );
  }
}
