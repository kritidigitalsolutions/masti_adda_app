import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/app_images.dart' show AppImages;
import 'package:masti_adda_app/features/profile/controllers/help_controller.dart';
import 'package:masti_adda_app/features/profile/controllers/profile_controller.dart';
import 'package:masti_adda_app/features/profile/controllers/subscription_status_controller.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/shared/widgets/custom_button.dart';
import 'package:masti_adda_app/shared/widgets/shimmer/shimmer.dart';
import 'package:masti_adda_app/utils/date_utils.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      floatingActionButton: _buildWhatsAppFloatingButton(),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    controller.fetchProfile(),
                    if (Get.isRegistered<SubscriptionStatusController>())
                      Get.find<SubscriptionStatusController>().checkStatus(),
                  ]);
                },
                color: AppColors.primaryColor,
                backgroundColor: AppColors.surfaceColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    children: [
                      _buildUserHeader(controller),
                      _buildSubscriptionCard(),
                      const SizedBox(height: 10),
                      _buildMenuList(context, controller),
                      const SizedBox(height: 16),
                      _buildLogOutButton(controller),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [Text('Profile', style: text16(fontWeight: FontWeight.w600))],
      ),
    );
  }

  Widget _buildUserHeader(ProfileController controller) {
    return Obx(() {
      final user = controller.user.value;

      if (controller.isLoading.value && user == null) {
        return const ShimmerEffect(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                ShimmerBox(width: 60, height: 60, borderRadius: 30),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 140, height: 18, borderRadius: 4),
                      SizedBox(height: 8),
                      ShimmerBox(width: 100, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (user == null) {
        return const Center(child: Text("No user found"));
      }
      final userImg = formatMediaUrl(user.profileImage);
      final hasImage = user.profileImage.isNotEmpty;
      final initial = user.name.trim().isNotEmpty
          ? user.name.trim()[0].toUpperCase()
          : '?';

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Row(
          children: [
            Stack(
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: hasImage
                        ? Image.network(
                            userImg,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: AppColors.cardColor,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, _, _) => _avatarInitial(initial),
                          )
                        : _avatarInitial(initial),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.backgroundColor,
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        '✦',
                        style: TextStyle(fontSize: 8, color: AppColors.black),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user.name, style: text16(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                  ],
                ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      user.role,
                      style: text11(color: AppColors.primaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _avatarInitial(String initial) {
    return Container(
      color: AppColors.primaryColor.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildMenuList(BuildContext context, ProfileController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _ProfileListTile(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            onTap: () => Get.toNamed(AppRoutes.editProfile),
          ),
          _ProfileListTile(
            icon: Icons.card_membership_outlined,
            title: 'Subscription',
            onTap: () => Get.toNamed(AppRoutes.subscription),
          ),
          Obx(
            () => _ProfileListTile(
              icon: Icons.language_outlined,
              title: 'Language',
              trailingText: controller.selectedLanguage.value,
              onTap: () => Get.toNamed(AppRoutes.language),
            ),
          ),
          _ProfileListTile(
            icon: Icons.download_outlined,
            title: 'Downloads',
            onTap: () => Get.toNamed(AppRoutes.downloads),
          ),
          // _ProfileListTile(
          //   icon: Icons.tune_outlined,
          //   title: 'Content Preference',
          //   onTap: () => Get.toNamed(AppRoutes.contentPreference),
          // ),
          _ProfileListTile(
            icon: Icons.settings_outlined,
            title: 'Notifications Settings',
            onTap: () => Get.toNamed(AppRoutes.notificationSettings),
          ),
          _ProfileListTile(
            icon: Icons.star_rate_outlined,
            title: 'Rate App',
            onTap: () => Get.toNamed(AppRoutes.rateApp),
          ),
          _ProfileListTile(
            icon: Icons.share_outlined,
            title: 'Share App',
            onTap: _shareApp,
          ),
          _ProfileListTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
          ),
          _ProfileListTile(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () => Get.toNamed(AppRoutes.termsConditions),
          ),
          _ProfileListTile(
            icon: Icons.question_answer_outlined,
            title: "FAQ's",
            onTap: () => Get.toNamed(AppRoutes.faq),
          ),
          _ProfileListTile(
            icon: Icons.money_off_outlined,
            title: 'Refund Policy',
            showDivider: false,
            onTap: () => Get.toNamed(AppRoutes.refundPolicy),
          ),
        ],
      ),
    );
  }

  Widget _buildLogOutButton(ProfileController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: AppButton(onTap: controller.onLogOut, title: 'Log Out'),
    );
  }

  Widget _buildSubscriptionCard() {
    final subController = Get.isRegistered<SubscriptionStatusController>()
        ? Get.find<SubscriptionStatusController>()
        : Get.put(SubscriptionStatusController(), permanent: true);
    return Obx(() {
      if (subController.isLoading.value) {
        return const ShimmerEffect(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ShimmerBox(
              width: double.infinity,
              height: 80,
              borderRadius: 12,
            ),
          ),
        );
      }

      final isPremium = subController.isPremiumUser.value;
      final status = subController.subscriptionStatus.value;

      if (isPremium && status != null && status.subscription != null) {
        final sub = status.subscription!;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accentColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: AppColors.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sub.plan.name,
                        style: text15(
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: text10(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.white.withValues(alpha: 0.1), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remaining Days',
                        style: text10(color: AppColors.hintTextColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${status.remainingDays} Days',
                        style: text16(
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Renews On',
                        style: text10(color: AppColors.hintTextColor),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatDate(sub.endDate),
                        style: text12(
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }

      // Unsubscribed user promo card
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'No Active Subscription',
                  style: text14(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock all premium widescreen movies, web series, and vertical dramas with zero ads.',
              style: text11(color: AppColors.secondaryTextColor),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.subscription),
              child: Container(
                height: 36,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentColor, Color(0xFFFF5E97)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Upgrade to Premium',
                    style: text12(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildWhatsAppFloatingButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25D366).withValues(alpha: 0.45),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openWhatsApp,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF25D366), Color(0xFF1EBE5D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(AppImages.whtsapp, height: 24, width: 24),
                const SizedBox(width: 8),
                Text(
                  'Support',
                  style: text13(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareApp() {
    SharePlus.instance.share(
      ShareParams(
        text:
            'Watch the best movies, web series, audio stories, and exclusive micro dramas on Masti Adda OTT!\n\nDownload now: https://play.google.com/store/apps/details?id=com.kritidigitalsolutions.golidoli',
        subject: 'Experience unlimited entertainment on Masti Adda!',
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final helpCtrl = HelpController.to;

    String rawNumber = helpCtrl.supportNumber;
    if (rawNumber.isEmpty) {
      await helpCtrl.fetchAllHelp();
      rawNumber = helpCtrl.supportNumber;
    }

    final cleanDigits = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
    String finalPhone = cleanDigits;
    if (cleanDigits.length == 10) {
      finalPhone = '91$cleanDigits';
    } else if (cleanDigits.length == 11 && cleanDigits.startsWith('0')) {
      finalPhone = '91${cleanDigits.substring(1)}';
    }

    if (finalPhone.isEmpty) {
      Get.snackbar(
        'WhatsApp Support',
        'Support number is currently not available. Please check the FAQ section.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    final message = Uri.encodeComponent(
      'Hello Masti Adda Support, I need assistance with the app.',
    );
    final whatsappUrl = Uri.parse('https://wa.me/$finalPhone?text=$message');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'WhatsApp Support',
          'Could not open WhatsApp. Please ensure WhatsApp is installed.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'WhatsApp Support',
        'Unable to open WhatsApp: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorColor.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }
}

class _ProfileListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;
  final bool showDivider;

  const _ProfileListTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 0,
          ),
          leading: Icon(icon, color: AppColors.secondaryTextColor, size: 22),
          title: Text(title, style: text14(color: AppColors.textColor)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null) ...[
                Text(
                  trailingText!,
                  style: text13(color: AppColors.secondaryTextColor),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.hintTextColor,
                size: 13,
              ),
            ],
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.6,
            color: AppColors.secondaryTextColor.withValues(alpha: 0.15),
          ),
      ],
    );
  }
}
