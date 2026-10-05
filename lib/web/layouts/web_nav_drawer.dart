import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/app_images.dart';
import 'package:masti_adda_app/core/services/storage_service.dart';
import 'package:masti_adda_app/features/home/controllers/ai_reels_controller.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/web/routes/web_routes.dart';
import 'package:masti_adda_app/web/screens/auth/web_login_dialog.dart';

class WebNavDrawer extends StatefulWidget {
  final String activeRoute;

  const WebNavDrawer({
    super.key,
    required this.activeRoute,
  });

  @override
  State<WebNavDrawer> createState() => _WebNavDrawerState();
}

class _WebNavDrawerState extends State<WebNavDrawer> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await StorageService.getToken();
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
      });
    }
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required String route,
  }) {
    final bool isActive = widget.activeRoute == route ||
        (route == WebRoutes.home && widget.activeRoute == WebRoutes.root);

    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppColors.primaryPink : AppColors.secondaryTextColor,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? AppColors.primaryPink : Colors.white,
          fontSize: 15,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      selected: isActive,
      selectedTileColor: AppColors.primaryPink.withOpacity(0.12),
      onTap: () {
        Navigator.pop(context);
        if (Get.currentRoute != route) {
          Get.toNamed(route);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Image.asset(
                    AppImages.logo,
                    height: 38,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.play_circle_fill_rounded,
                      color: AppColors.primaryPink,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Masti Adda',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.borderColor, height: 1),
            const SizedBox(height: 12),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    route: WebRoutes.home,
                  ),
                  _buildDrawerItem(
                    icon: Icons.video_collection_rounded,
                    label: 'Dramas',
                    route: WebRoutes.dramas,
                  ),
                  _buildDrawerItem(
                    icon: Icons.movie_rounded,
                    label: 'Movies',
                    route: WebRoutes.movies,
                  ),
                  _buildDrawerItem(
                    icon: Icons.live_tv_rounded,
                    label: 'Web Series',
                    route: WebRoutes.series,
                  ),
                  _buildDrawerItem(
                    icon: Icons.search_rounded,
                    label: 'Search',
                    route: WebRoutes.search,
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderColor, height: 1),
                  const SizedBox(height: 16),
                  _buildDrawerItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    route: WebRoutes.profile,
                  ),
                  _buildDrawerItem(
                    icon: Icons.workspace_premium_rounded,
                    label: 'VIP Subscription',
                    route: WebRoutes.subscription,
                  ),
                  _buildDrawerItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    route: AppRoutes.privacyPolicy,
                  ),
                  _buildDrawerItem(
                    icon: Icons.description_outlined,
                    label: 'Terms & Conditions',
                    route: AppRoutes.termsConditions,
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline_rounded,
                    label: 'FAQ',
                    route: AppRoutes.faq,
                  ),
                ],
              ),
            ),

            // Login / Logout Bottom Action
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoggedIn
                  ? OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await StorageService.logout();
                        if (Get.isRegistered<AiReelsController>()) {
                          Get.find<AiReelsController>().resetState();
                          Get.delete<AiReelsController>(force: true);
                        }
                        if (mounted) {
                          setState(() => _isLoggedIn = false);
                          Get.toNamed(WebRoutes.home);
                        }
                      },
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.primaryPink, size: 20),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(
                          color: AppColors.primaryPink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: AppColors.primaryPink),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (_) => const WebLoginDialog(),
                        ).then((_) => _checkAuth());
                      },
                      icon: const Icon(Icons.login_rounded,
                          color: Colors.white, size: 20),
                      label: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
