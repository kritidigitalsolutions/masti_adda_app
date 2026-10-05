import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/app_images.dart';
import 'package:masti_adda_app/features/auth/controllers/auth_controller.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.put(AuthController());
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background gradient (dark purple-black) ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A0A2E),
                  Color(0xFF0D0614),
                  Color(0xFF0A0A14),
                ],
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),

                  // Welcome to
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 1,
                        width: 40,
                        color: AppColors.secondaryTextColor.withOpacity(0.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Welcome to',
                        style: text20(color: AppColors.secondaryTextColor),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 1,
                        width: 40,
                        color: AppColors.secondaryTextColor.withOpacity(0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Masti Adda logo text
                  _MastiAddaText(),
                  const SizedBox(height: 24),

                  // Tagline
                  Text(
                    'unlock unlimited\nentertainment!',
                    style: text15(color: AppColors.textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Continue with Mobile Number
                  _PrimaryButton(
                    icon: Icons.phone_android_rounded,
                    label: 'Continue with Mobile Number',
                    onTap: () => Get.toNamed(AppRoutes.enterMobile),
                  ),
                  const SizedBox(height: 20),

                  // Or divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.dividerColor,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Or',
                          style: text13(color: AppColors.hintTextColor),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColors.dividerColor,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Google
                  Obx(
                    () => _SocialButton(
                      image: AppImages.google,
                      label: 'Continue with Google',
                      isLoading: authController.isGoogleLoading.value,
                      onTap: () => authController.loginWithGoogle(),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Already have an account
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'Already have an account?\n',
                      style: text13(color: AppColors.secondaryTextColor),
                      children: [
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () {
                              Get.toNamed(AppRoutes.enterMobile);
                            },
                            child: Text(
                              'Log In',
                              style: text13(
                                color: AppColors.accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Masti Adda styled logo text ───────────────────────
class _MastiAddaText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Goli',
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryColor,
            ),
          ),
          TextSpan(
            text: 'Doli',
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppColors.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Yellow primary button ────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: AppColors.black),
        label: Text(
          label,
          style: text14(fontWeight: FontWeight.w700, color: AppColors.black),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

// ─── Social auth button ───────────────────────────────
class _SocialButton extends StatelessWidget {
  final String image;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _SocialButton({
    required this.image,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.borderColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(image, width: 22, height: 22),
                  const SizedBox(width: 12),
                  Text(label, style: text14(color: AppColors.textColor)),
                ],
              ),
      ),
    );
  }
}
