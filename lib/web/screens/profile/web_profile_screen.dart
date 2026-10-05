import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/app_images.dart';
import 'package:masti_adda_app/constants/app_url.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/core/data/exception/app_exception.dart';
import 'package:masti_adda_app/core/data/network/network_api_service.dart';
import 'package:masti_adda_app/core/services/storage_service.dart';
import 'package:masti_adda_app/features/home/controllers/ai_reels_controller.dart';
import 'package:masti_adda_app/features/profile/controllers/help_controller.dart';
import 'package:masti_adda_app/features/profile/controllers/profile_controller.dart';
import 'package:masti_adda_app/features/profile/controllers/subscription_status_controller.dart';
import 'package:masti_adda_app/shared/widgets/custom_button.dart';
import 'package:masti_adda_app/shared/widgets/shimmer/shimmer.dart';
import 'package:masti_adda_app/utils/date_utils.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:masti_adda_app/web/layouts/web_main_layout.dart';
import 'package:masti_adda_app/web/routes/web_routes.dart';
import 'package:masti_adda_app/web/screens/auth/web_login_dialog.dart';
import 'package:masti_adda_app/web/utils/web_responsive.dart';
import 'package:masti_adda_app/web/widgets/web_rate_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class WebProfileScreen extends StatefulWidget {
  const WebProfileScreen({super.key});

  @override
  State<WebProfileScreen> createState() => _WebProfileScreenState();
}

class _WebProfileScreenState extends State<WebProfileScreen> {
  late final ProfileController _profileController;
  late final SubscriptionStatusController _subController;
  bool _isLoggedIn = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    _subController = Get.isRegistered<SubscriptionStatusController>()
        ? Get.find<SubscriptionStatusController>()
        : Get.put(SubscriptionStatusController());

    _checkLoginAndLoad();
  }

  Future<void> _checkLoginAndLoad() async {
    setState(() => _isCheckingAuth = true);
    final token = await StorageService.getToken();
    final hasToken = token != null && token.isNotEmpty;

    if (mounted) {
      setState(() {
        _isLoggedIn = hasToken;
        _isCheckingAuth = false;
      });
    }

    if (hasToken) {
      await Future.wait([
        _profileController.fetchProfile(),
        _subController.checkStatus(),
      ]);
    }
  }

  void _openLogin() {
    showDialog<bool>(
      context: context,
      builder: (_) => const WebLoginDialog(),
    ).then((result) {
      if (result == true) {
        _checkLoginAndLoad();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = WebResponsive.contentHorizontalPadding(context);

    return WebMainLayout(
      activeRoute: WebRoutes.profile,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 24,
            ),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 700),
                child: _isCheckingAuth
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryPink,
                          ),
                        ),
                      )
                    : _isLoggedIn
                    ? _buildProfileContent()
                    : _buildLoggedOutView(),
              ),
            ),
          ),
          // WhatsApp Floating Action Button
          Positioned(
            right: 24,
            bottom: 24,
            child: _buildWhatsAppFloatingButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedOutView() {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primaryPink,
              size: 44,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sign In to Your Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sign in to manage your profile, view subscription status, unlock premium dramas and movies, and save your watch history.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.secondaryTextColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _openLogin,
            icon: const Icon(Icons.login_rounded, color: Colors.white),
            label: const Text(
              'Sign In / Create Account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAppBar(),
        _buildUserHeader(_profileController),
        _buildSubscriptionCard(),
        const SizedBox(height: 10),
        _buildMenuList(context, _profileController),
        const SizedBox(height: 16),
        _buildLogOutButton(_profileController),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 22,
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
          const SizedBox(width: 4),
          Text(
            'Profile',
            style: text18(fontWeight: FontWeight.w600, color: AppColors.white),
          ),
        ],
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
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "No user profile found",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        );
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

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: text16(
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('🔥', style: TextStyle(fontSize: 14)),
                    ],
                  ),

                  const SizedBox(height: 4),

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
                      const SizedBox(width: 6),
                      Text(
                        user.role.isNotEmpty ? user.role : 'Member',
                        style: text11(color: AppColors.primaryColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _avatarInitial(String initial) {
    return Container(
      color: AppColors.primaryColor.withOpacity(0.15),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Obx(() {
      if (_subController.isLoading.value) {
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

      final isPremium = _subController.isPremiumUser.value;
      final status = _subController.subscriptionStatus.value;

      if (isPremium && status != null && status.subscription != null) {
        final sub = status.subscription!;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.6),
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
                      color: AppColors.primaryColor.withOpacity(0.2),
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
              Divider(color: AppColors.white.withOpacity(0.1), height: 1),
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primaryPink,
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
              style: text12(color: AppColors.secondaryTextColor),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Get.toNamed(WebRoutes.subscription),
              child: Container(
                height: 40,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentColor, Color(0xFFFF5E97)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Upgrade to Premium',
                    style: text13(
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

  Widget _buildMenuList(BuildContext context, ProfileController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          _ProfileListTile(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            onTap: _openEditProfileModal,
          ),
          _ProfileListTile(
            icon: Icons.card_membership_outlined,
            title: 'Subscription',
            onTap: () => Get.toNamed(WebRoutes.subscription),
          ),
          Obx(
            () => _ProfileListTile(
              icon: Icons.language_outlined,
              title: 'Language',
              trailingText: controller.selectedLanguage.value,
              onTap: _openLanguageModal,
            ),
          ),
          // _ProfileListTile(
          //   icon: Icons.download_outlined,
          //   title: 'Downloads',
          //   onTap: _openDownloadsModal,
          // ),
          // _ProfileListTile(
          //   icon: Icons.tune_outlined,
          //   title: 'Content Preference',
          //   onTap: _openContentPreferenceModal,
          // ),
          // _ProfileListTile(
          //   icon: Icons.settings_outlined,
          //   title: 'Notifications Settings',
          //   onTap: _openNotificationSettingsModal,
          // ),
          _ProfileListTile(
            icon: Icons.star_rate_outlined,
            title: 'Rate App',
            onTap: _openRateModal,
          ),
          _ProfileListTile(
            icon: Icons.share_outlined,
            title: 'Share App',
            onTap: _shareApp,
          ),
          _ProfileListTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _openLegalModal('privacy-policy', 'Privacy Policy'),
          ),
          _ProfileListTile(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () =>
                _openLegalModal('terms-and-conditions', 'Terms & Conditions'),
          ),
          _ProfileListTile(
            icon: Icons.question_answer_outlined,
            title: "FAQ's",
            onTap: _openFaqModal,
          ),
          _ProfileListTile(
            icon: Icons.money_off_outlined,
            title: 'Refund Policy',
            showDivider: false,
            onTap: () => _openLegalModal('refund-policy', 'Refund Policy'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogOutButton(ProfileController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: AppButton(
        onTap: () => _showLogoutDialog(controller),
        title: 'Log Out',
      ),
    );
  }

  void _showLogoutDialog(ProfileController controller) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: AppColors.accentColor,
                size: 44,
              ),
              const SizedBox(height: 16),
              Text(
                'Log Out',
                style: text18(
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to log out from Masti Adda?',
                style: text13(color: AppColors.secondaryTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.borderColor.withOpacity(0.5),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: text13(
                              color: AppColors.secondaryTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await StorageService.logout();
                        if (Get.isRegistered<AiReelsController>()) {
                          Get.find<AiReelsController>().resetState();
                          Get.delete<AiReelsController>(force: true);
                        }
                        if (mounted) {
                          setState(() {
                            _isLoggedIn = false;
                          });
                          Get.toNamed(WebRoutes.home);
                        }
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'Log Out',
                            style: text13(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsAppFloatingButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25D366).withOpacity(0.45),
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
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppImages.whtsapp,
                  height: 22,
                  width: 22,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
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
    _openShareModal();
  }

  void _openShareModal() {
    const String shareText =
        '🎬 Watch the best movies, web series, audio stories, and exclusive micro dramas on Masti Adda OTT!\n\n✨ Visit: https://mastiadda.com\n📲 Download App: https://play.google.com/store/apps/details?id=com.kritidigitalsolutions.golidoli';
    const String shareUrl = 'https://mastiadda.com';
    bool isCopied = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPink.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.share_rounded,
                            color: AppColors.primaryPink,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Share Masti Adda',
                          style: text18(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.secondaryTextColor,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Share Masti Adda OTT with your friends and family so they can stream unlimited entertainment!',
                  style: appTextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryTextColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildShareSocialButton(
                      label: 'WhatsApp',
                      icon: Icons.chat_bubble_outline_rounded,
                      color: const Color(0xFF25D366),
                      onTap: () {
                        _launchShareUrl(
                          'https://api.whatsapp.com/send?text=${Uri.encodeComponent(shareText)}',
                        );
                      },
                    ),
                    _buildShareSocialButton(
                      label: 'Twitter / X',
                      icon: Icons.alternate_email_rounded,
                      color: const Color(0xFF1DA1F2),
                      onTap: () {
                        _launchShareUrl(
                          'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(shareText)}',
                        );
                      },
                    ),
                    _buildShareSocialButton(
                      label: 'Facebook',
                      icon: Icons.facebook_rounded,
                      color: const Color(0xFF1877F2),
                      onTap: () {
                        _launchShareUrl(
                          'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareUrl)}',
                        );
                      },
                    ),
                    _buildShareSocialButton(
                      label: 'Telegram',
                      icon: Icons.send_rounded,
                      color: const Color(0xFF0088CC),
                      onTap: () {
                        _launchShareUrl(
                          'https://t.me/share/url?url=${Uri.encodeComponent(shareUrl)}&text=${Uri.encodeComponent('Watch movies, web series and micro dramas on Masti Adda OTT!')}',
                        );
                      },
                    ),
                    _buildShareSocialButton(
                      label: 'Email',
                      icon: Icons.mail_outline_rounded,
                      color: const Color(0xFFEA4335),
                      onTap: () {
                        _launchShareUrl(
                          'mailto:?subject=${Uri.encodeComponent('Watch Unlimited Entertainment on Masti Adda OTT')}&body=${Uri.encodeComponent(shareText)}',
                        );
                      },
                    ),
                    _buildShareSocialButton(
                      label: 'System Share',
                      icon: Icons.more_horiz_rounded,
                      color: AppColors.primaryPink,
                      onTap: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text: shareText,
                            subject: 'Experience unlimited entertainment on Masti Adda!',
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Or copy link',
                  style: text12(
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        color: AppColors.hintTextColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          shareUrl,
                          style: text13(color: AppColors.textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            const ClipboardData(text: shareText),
                          );
                          setModalState(() => isCopied = true);
                          Get.snackbar(
                            'Link Copied',
                            'Masti Adda share message copied to clipboard!',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppColors.primaryPink.withValues(
                              alpha: 0.85,
                            ),
                            colorText: Colors.white,
                            duration: const Duration(seconds: 2),
                          );
                          Future.delayed(const Duration(seconds: 3), () {
                            if (mounted) {
                              setModalState(() => isCopied = false);
                            }
                          });
                        },
                        icon: Icon(
                          isCopied
                              ? Icons.check_circle_rounded
                              : Icons.copy_rounded,
                          color: isCopied ? Colors.greenAccent : Colors.white,
                          size: 16,
                        ),
                        label: Text(
                          isCopied ? 'Copied' : 'Copy',
                          style: TextStyle(
                            color: isCopied ? Colors.greenAccent : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: isCopied
                              ? Colors.green.withValues(alpha: 0.2)
                              : AppColors.primaryPink,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareSocialButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchShareUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening share URL: $e');
    }
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
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    final message = Uri.encodeComponent(
      'Hello Masti Adda Support, I need assistance with the website.',
    );
    final whatsappUrl = Uri.parse('https://wa.me/$finalPhone?text=$message');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
      } else {
        Get.snackbar(
          'WhatsApp Support',
          'Could not open WhatsApp support.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'WhatsApp Support',
        'Unable to open WhatsApp: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorColor.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // ─── Modal Dialogs for Web ────────────────────────────────────────────────

  void _openEditProfileModal() {
    final user = _profileController.user.value;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final bool isPhoneAuth = user?.isPhoneAuth ?? true;
    bool isSaving = false;
    String modalError = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.borderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Profile',
                      style: text18(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.secondaryTextColor,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Inline error display inside modal
                if (modalError.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.errorColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.errorColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.errorColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            modalError,
                            style: text12(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                _buildModalTextField('Full Name', nameCtrl),
                const SizedBox(height: 14),
                _buildModalTextField(
                  'Mobile Number',
                  phoneCtrl,
                  enabled: !isPhoneAuth,
                  keyboardType: TextInputType.phone,
                  helperText: isPhoneAuth
                      ? 'Mobile number cannot be changed for phone login accounts'
                      : null,
                ),
                const SizedBox(height: 14),
                _buildModalTextField(
                  'Email Address',
                  emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            setDialogState(() {
                              isSaving = true;
                              modalError = '';
                            });
                            try {
                              final api = NetworkApiService();
                              final body = <String, dynamic>{
                                if (nameCtrl.text.trim().isNotEmpty &&
                                    nameCtrl.text.trim() != user?.name)
                                  "name": nameCtrl.text.trim(),
                                if (emailCtrl.text.trim().isNotEmpty &&
                                    emailCtrl.text.trim() != user?.email)
                                  "email": emailCtrl.text.trim(),
                                if (!isPhoneAuth &&
                                    phoneCtrl.text.trim().isNotEmpty &&
                                    phoneCtrl.text.trim() != user?.phone)
                                  "phone": phoneCtrl.text.trim(),
                              };

                              if (body.isEmpty) {
                                Navigator.of(ctx).pop();
                                return;
                              }

                              await api.pacthApi(AppUrl.updateProfile, body);
                              await _profileController.fetchProfile();
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                              }
                              if (mounted) {
                                Get.snackbar(
                                  'Profile Updated',
                                  'Your profile has been saved successfully.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.primaryPink
                                      .withValues(alpha: 0.85),
                                  colorText: Colors.white,
                                );
                              }
                            } catch (e) {
                              String cleanError = "Failed to update profile";
                              if (e is AppException) {
                                cleanError = e.message;
                              } else {
                                final errStr = e.toString();
                                final stripped = errStr
                                    .replaceFirst(
                                      RegExp(r'^[a-zA-Z]+Exception:\s*'),
                                      '',
                                    )
                                    .trim();
                                cleanError = stripped.isNotEmpty
                                    ? stripped
                                    : "Failed to update profile";
                              }

                              if (mounted) {
                                setDialogState(() {
                                  isSaving = false;
                                  modalError = cleanError;
                                });
                                Get.snackbar(
                                  'Update Failed',
                                  cleanError,
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.errorColor
                                      .withValues(alpha: 0.9),
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 4),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalTextField(
    String label,
    TextEditingController ctrl, {
    bool enabled = true,
    String? helperText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: text12(color: AppColors.secondaryTextColor)),
            if (!enabled) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: AppColors.hintTextColor,
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(
            color: enabled
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled
                ? AppColors.surfaceColor
                : AppColors.surfaceColor.withValues(alpha: 0.4),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.borderColor.withValues(alpha: 0.5),
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.borderColor.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primaryPink),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: text11(color: AppColors.hintTextColor),
          ),
        ],
      ],
    );
  }

  void _openLanguageModal() {
    final languages = const ['English', 'Hindi', 'Tamil', 'Telugu', 'Bengali'];
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Language',
                    style: text16(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.secondaryTextColor,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...languages.map((lang) {
                return Obx(() {
                  final isSelected =
                      _profileController.selectedLanguage.value == lang;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      lang,
                      style: text14(
                        color: isSelected
                            ? AppColors.primaryPink
                            : AppColors.textColor,
                      ),
                    ),
                    trailing: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: isSelected
                          ? AppColors.primaryPink
                          : AppColors.hintTextColor,
                      size: 20,
                    ),
                    onTap: () {
                      _profileController.selectedLanguage.value = lang;
                      Navigator.of(ctx).pop();
                    },
                  );
                });
              }),
            ],
          ),
        ),
      ),
    );
  }

  // void _openDownloadsModal() {
  //   showDialog(
  //     context: context,
  //     builder: (ctx) => Dialog(
  //       backgroundColor: Colors.transparent,
  //       child: Container(
  //         constraints: const BoxConstraints(maxWidth: 460),
  //         padding: const EdgeInsets.all(28),
  //         decoration: BoxDecoration(
  //           color: AppColors.backgroundColor,
  //           borderRadius: BorderRadius.circular(20),
  //           border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
  //         ),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Container(
  //               width: 64,
  //               height: 64,
  //               decoration: BoxDecoration(
  //                 color: AppColors.primaryPink.withOpacity(0.15),
  //                 shape: BoxShape.circle,
  //               ),
  //               child: const Icon(
  //                 Icons.download_rounded,
  //                 color: AppColors.primaryPink,
  //                 size: 36,
  //               ),
  //             ),
  //             const SizedBox(height: 20),
  //             Text(
  //               'Offline Downloads',
  //               style: text18(fontWeight: FontWeight.bold),
  //             ),
  //             const SizedBox(height: 10),
  //             Text(
  //               'Offline downloading is supported on the Masti Adda mobile apps for Android and iOS. Download the app to watch without internet!',
  //               textAlign: TextAlign.center,
  //               style: appTextStyle(
  //                 fontSize: 13,
  //                 color: AppColors.secondaryTextColor,
  //                 height: 1.5,
  //               ),
  //             ),
  //             const SizedBox(height: 24),
  //             SizedBox(
  //               width: double.infinity,
  //               child: ElevatedButton(
  //                 onPressed: () => Navigator.of(ctx).pop(),
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: AppColors.primaryPink,
  //                   padding: const EdgeInsets.symmetric(vertical: 13),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                 ),
  //                 child: const Text(
  //                   'Got It',
  //                   style: TextStyle(
  //                     color: Colors.white,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // void _openContentPreferenceModal() {
  //   final genres = [
  //     'Romance',
  //     'Thriller',
  //     'Drama',
  //     'Action',
  //     'Comedy',
  //     'Movies',
  //     'Web Series',
  //     'Micro Dramas',
  //   ];
  //   final selected = <String>{'Romance', 'Drama', 'Movies'};

  //   showDialog(
  //     context: context,
  //     builder: (ctx) => StatefulBuilder(
  //       builder: (context, setModalState) => Dialog(
  //         backgroundColor: Colors.transparent,
  //         child: Container(
  //           constraints: const BoxConstraints(maxWidth: 480),
  //           padding: const EdgeInsets.all(24),
  //           decoration: BoxDecoration(
  //             color: AppColors.backgroundColor,
  //             borderRadius: BorderRadius.circular(16),
  //             border: Border.all(color: AppColors.borderColor.withOpacity(0.4)),
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Text(
  //                     'Content Preferences',
  //                     style: text16(fontWeight: FontWeight.bold),
  //                   ),
  //                   IconButton(
  //                     icon: const Icon(
  //                       Icons.close,
  //                       color: AppColors.secondaryTextColor,
  //                     ),
  //                     onPressed: () => Navigator.of(ctx).pop(),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 12),
  //               Text(
  //                 'Choose your favorite genres to personalize your feed.',
  //                 style: text12(color: AppColors.secondaryTextColor),
  //               ),
  //               const SizedBox(height: 16),
  //               Wrap(
  //                 spacing: 8,
  //                 runSpacing: 8,
  //                 children: genres.map((g) {
  //                   final isSel = selected.contains(g);
  //                   return ChoiceChip(
  //                     label: Text(g),
  //                     selected: isSel,
  //                     selectedColor: AppColors.primaryPink,
  //                     backgroundColor: AppColors.surfaceColor,
  //                     labelStyle: TextStyle(
  //                       color: isSel
  //                           ? Colors.white
  //                           : AppColors.secondaryTextColor,
  //                       fontSize: 13,
  //                       fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
  //                     ),
  //                     onSelected: (val) {
  //                       setModalState(() {
  //                         if (val) {
  //                           selected.add(g);
  //                         } else {
  //                           selected.remove(g);
  //                         }
  //                       });
  //                     },
  //                   );
  //                 }).toList(),
  //               ),
  //               const SizedBox(height: 24),
  //               SizedBox(
  //                 width: double.infinity,
  //                 child: ElevatedButton(
  //                   onPressed: () {
  //                     Navigator.of(ctx).pop();
  //                     Get.snackbar(
  //                       'Preferences Saved',
  //                       'Your content preferences have been updated.',
  //                       snackPosition: SnackPosition.BOTTOM,
  //                       backgroundColor: AppColors.primaryPink.withOpacity(
  //                         0.85,
  //                       ),
  //                       colorText: Colors.white,
  //                     );
  //                   },
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: AppColors.primaryPink,
  //                     padding: const EdgeInsets.symmetric(vertical: 13),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                   ),
  //                   child: const Text(
  //                     'Save Preferences',
  //                     style: TextStyle(
  //                       color: Colors.white,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // void _openNotificationSettingsModal() {
  //   bool pushEnabled = true;
  //   bool newReleases = true;
  //   bool subAlerts = true;

  //   showDialog(
  //     context: context,
  //     builder: (ctx) => StatefulBuilder(
  //       builder: (context, setModalState) => Dialog(
  //         backgroundColor: Colors.transparent,
  //         child: Container(
  //           constraints: const BoxConstraints(maxWidth: 440),
  //           padding: const EdgeInsets.all(24),
  //           decoration: BoxDecoration(
  //             color: AppColors.backgroundColor,
  //             borderRadius: BorderRadius.circular(16),
  //             border: Border.all(color: AppColors.borderColor.withOpacity(0.4)),
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Text(
  //                     'Notification Settings',
  //                     style: text16(fontWeight: FontWeight.bold),
  //                   ),
  //                   IconButton(
  //                     icon: const Icon(
  //                       Icons.close,
  //                       color: AppColors.secondaryTextColor,
  //                     ),
  //                     onPressed: () => Navigator.of(ctx).pop(),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 12),
  //               SwitchListTile(
  //                 contentPadding: EdgeInsets.zero,
  //                 title: const Text(
  //                   'Push Notifications',
  //                   style: TextStyle(color: Colors.white, fontSize: 14),
  //                 ),
  //                 subtitle: const Text(
  //                   'Receive notifications on browser',
  //                   style: TextStyle(
  //                     color: AppColors.secondaryTextColor,
  //                     fontSize: 12,
  //                   ),
  //                 ),
  //                 value: pushEnabled,
  //                 activeColor: AppColors.primaryPink,
  //                 onChanged: (v) => setModalState(() => pushEnabled = v),
  //               ),
  //               SwitchListTile(
  //                 contentPadding: EdgeInsets.zero,
  //                 title: const Text(
  //                   'New Drama & Movie Releases',
  //                   style: TextStyle(color: Colors.white, fontSize: 14),
  //                 ),
  //                 subtitle: const Text(
  //                   'Get notified when new episodes drop',
  //                   style: TextStyle(
  //                     color: AppColors.secondaryTextColor,
  //                     fontSize: 12,
  //                   ),
  //                 ),
  //                 value: newReleases,
  //                 activeColor: AppColors.primaryPink,
  //                 onChanged: (v) => setModalState(() => newReleases = v),
  //               ),
  //               SwitchListTile(
  //                 contentPadding: EdgeInsets.zero,
  //                 title: const Text(
  //                   'Subscription Reminders',
  //                   style: TextStyle(color: Colors.white, fontSize: 14),
  //                 ),
  //                 subtitle: const Text(
  //                   'Expiry and renewal alerts',
  //                   style: TextStyle(
  //                     color: AppColors.secondaryTextColor,
  //                     fontSize: 12,
  //                   ),
  //                 ),
  //                 value: subAlerts,
  //                 activeColor: AppColors.primaryPink,
  //                 onChanged: (v) => setModalState(() => subAlerts = v),
  //               ),
  //               const SizedBox(height: 18),
  //               SizedBox(
  //                 width: double.infinity,
  //                 child: ElevatedButton(
  //                   onPressed: () {
  //                     Navigator.of(ctx).pop();
  //                     Get.snackbar(
  //                       'Settings Saved',
  //                       'Notification preferences saved.',
  //                       snackPosition: SnackPosition.BOTTOM,
  //                       backgroundColor: AppColors.primaryPink.withOpacity(
  //                         0.85,
  //                       ),
  //                       colorText: Colors.white,
  //                     );
  //                   },
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: AppColors.primaryPink,
  //                     padding: const EdgeInsets.symmetric(vertical: 13),
  //                     shape: RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                   ),
  //                   child: const Text(
  //                     'Done',
  //                     style: TextStyle(
  //                       color: Colors.white,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  void _openRateModal() {
    WebRateDialog.show(context);
  }

  void _openLegalModal(String docId, String title) {
    final helpCtrl = Get.isRegistered<HelpController>()
        ? Get.find<HelpController>()
        : Get.put(HelpController());

    helpCtrl.fetchSingleDocument(id: docId);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 650, maxHeight: 600),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text18(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.secondaryTextColor,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  final doc = helpCtrl.singleDocument.value;
                  if (helpCtrl.singleDocumentStatus.value == Status.loading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPink,
                      ),
                    );
                  }
                  if (doc == null || doc.content.isEmpty) {
                    return Center(
                      child: Text(
                        'No content available for $title.',
                        style: text13(color: AppColors.secondaryTextColor),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...[
                          Text(
                            'Last updated: ${formatDateMedium(doc.updatedAt)}',
                            style: text11(color: AppColors.secondaryTextColor),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          doc.content,
                          style: appTextStyle(
                            fontSize: 13,
                            color: AppColors.textColor,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFaqModal() {
    final helpCtrl = Get.isRegistered<HelpController>()
        ? Get.find<HelpController>()
        : Get.put(HelpController());

    helpCtrl.fetchAllHelp();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 650, maxHeight: 600),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Frequently Asked Questions",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text18(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.secondaryTextColor,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  final helps = helpCtrl.helps.value;
                  if (helpCtrl.helpStatus.value == Status.loading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPink,
                      ),
                    );
                  }
                  final faqItems =
                      helps?.helpData
                          .where((e) => e.category == 'faq')
                          .toList() ??
                      [];
                  if (faqItems.isEmpty) {
                    return Center(
                      child: Text(
                        'No FAQs available right now.',
                        style: text13(color: AppColors.secondaryTextColor),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: faqItems.length,
                    itemBuilder: (context, index) {
                      final item = faqItems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.borderColor.withOpacity(0.3),
                          ),
                        ),
                        child: ExpansionTile(
                          title: Text(
                            item.question,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),
                          iconColor: AppColors.primaryPink,
                          collapsedIconColor: AppColors.secondaryTextColor,
                          children: [
                            Text(
                              item.answer,
                              style: const TextStyle(
                                color: AppColors.secondaryTextColor,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
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
            horizontal: 16,
            vertical: 2,
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
            color: AppColors.secondaryTextColor.withOpacity(0.12),
          ),
      ],
    );
  }
}
