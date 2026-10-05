import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/app_images.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/web/controllers/company_info_controller.dart';
import 'package:masti_adda_app/web/utils/web_responsive.dart';
import 'package:url_launcher/url_launcher.dart';

class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  Future<void> _launchUrlString(String urlString) async {
    if (urlString.trim().isEmpty) return;
    try {
      final uri = Uri.parse(urlString.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint("WebFooter: Could not launch $urlString: $e");
    }
  }

  Widget _buildRedLink(String label, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primaryPink,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon({
    required IconData icon,
    required String url,
    required String tooltip,
  }) {
    if (url.trim().isEmpty) return const SizedBox.shrink();

    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _launchUrlString(url),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = WebResponsive.isMobile(context);
    final horizontalPadding = WebResponsive.contentHorizontalPadding(context);
    final controller = CompanyInfoController.to;

    return Obx(() {
      final info = controller.companyInfo.value;

      // Powered By Parsing
      final poweredByText = info.poweredBy.trim().isNotEmpty
          ? info.poweredBy.trim()
          : 'POWERED BY KRITI DIGITAL SOLUTIONS';
      String prefixText = 'POWERED BY ';
      String brandText = poweredByText;
      if (poweredByText.toUpperCase().startsWith('POWERED BY ')) {
        prefixText = 'POWERED BY ';
        brandText = poweredByText.substring(11).trim();
      }

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          border: Border(
            top: BorderSide(
              color: AppColors.borderColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: isMobile ? 40 : 54,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. App Logo
                Image.asset(
                  AppImages.logo,
                  height: isMobile ? 44 : 60,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppColors.primaryPink,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Brand Title
                Text(
                  info.companyName.trim().isNotEmpty
                      ? info.companyName.trim().toUpperCase()
                      : 'Masti Adda OTT',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Tagline / Description
                if (info.tagline.trim().isNotEmpty) ...[
                  Text(
                    info.tagline.trim(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 13.5,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 4. Support Contacts (Email & Phone)
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    if (info.supportEmail.trim().isNotEmpty)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _launchUrlString(
                            'mailto:${info.supportEmail.trim()}',
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.email_outlined,
                                size: 16,
                                color: AppColors.primaryPink,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Email: ${info.supportEmail.trim()}',
                                style: const TextStyle(
                                  color: AppColors.primaryPink,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (info.supportPhone.trim().isNotEmpty)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _launchUrlString(
                            'tel:${info.supportPhone.trim()}',
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 16,
                                color: AppColors.primaryPink,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Phone: ${info.supportPhone.trim()}',
                                style: const TextStyle(
                                  color: AppColors.primaryPink,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // 5. Social Media Links (if present)
                if (info.socialLinks.hasAnyLink) ...[
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildSocialIcon(
                        icon: Icons.facebook,
                        url: info.socialLinks.facebook,
                        tooltip: 'Facebook',
                      ),
                      _buildSocialIcon(
                        icon: Icons.camera_alt_outlined,
                        url: info.socialLinks.instagram,
                        tooltip: 'Instagram',
                      ),
                      _buildSocialIcon(
                        icon: Icons.tag,
                        url: info.socialLinks.twitter,
                        tooltip: 'Twitter / X',
                      ),
                      _buildSocialIcon(
                        icon: Icons.smart_display_rounded,
                        url: info.socialLinks.youtube,
                        tooltip: 'YouTube',
                      ),
                      _buildSocialIcon(
                        icon: Icons.business_rounded,
                        url: info.socialLinks.linkedin,
                        tooltip: 'LinkedIn',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // 6. Red Legal / Navigation Links
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: isMobile ? 16 : 28,
                  runSpacing: 12,
                  children: [
                    _buildRedLink(
                      'Privacy Policy',
                      () => Get.toNamed(AppRoutes.privacyPolicy),
                    ),
                    _buildRedLink(
                      'Terms & Conditions',
                      () => Get.toNamed(AppRoutes.termsConditions),
                    ),
                    _buildRedLink(
                      'Refund Policy',
                      () => Get.toNamed(AppRoutes.refundPolicy),
                    ),
                    _buildRedLink(
                      'Help & Support',
                      () => Get.toNamed(AppRoutes.faq),
                    ),
                  ],
                ),
                const SizedBox(height: 38),

                // 7. Copyright Text
                Text(
                  info.copyrightText.trim().isNotEmpty
                      ? info.copyrightText.trim()
                      : '© ${DateTime.now().year} ${info.companyName} All Rights Reserved',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),

                // 8. Powered By
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                    children: [
                      TextSpan(
                        text: prefixText,
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: brandText,
                        style: const TextStyle(
                          color: AppColors.primaryPink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 9. Registered Address & Company Info
                if (info.displayAddress.isNotEmpty)
                  MouseRegion(
                    cursor: info.googleMapUrl.isNotEmpty
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: GestureDetector(
                      onTap: info.googleMapUrl.isNotEmpty
                          ? () => _launchUrlString(info.googleMapUrl)
                          : null,
                      child: Text(
                        info.displayAddress,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF616161),
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
