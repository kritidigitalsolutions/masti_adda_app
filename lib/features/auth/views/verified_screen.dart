import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/auth/controllers/auth_controller.dart';
import 'package:masti_adda_app/shared/widgets/custom_button.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:google_fonts/google_fonts.dart';

class VerifiedScreen extends StatelessWidget {
  VerifiedScreen({super.key});

  final AuthController controller = Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A0520),
                  Color(0xFF0D0614),
                  Color(0xFF0A0A18),
                ],
              ),
            ),
          ),

          // Decorative star dots scattered around
          const _StarDecorations(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Checkmark circle
                  _VerifiedCheckmark(),
                  const SizedBox(height: 36),

                  // Verified text
                  Text(
                    'Verified',
                    style: text30(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Successfully!',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Welcome message
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'Welcome to ',
                      style: text15(color: AppColors.secondaryTextColor),
                      children: [
                        TextSpan(
                          text: 'Goli',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        TextSpan(
                          text: 'Doli',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Continue button
                  AppButton(
                    title: "Continue",
                    onTap: controller.continueToHome,
                  ),
                  // SizedBox(
                  //   width: double.infinity,
                  //   height: 52,
                  //   child: ElevatedButton(
                  //     onPressed: controller.continueToHome,
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: AppColors.primaryColor,
                  //       foregroundColor: AppColors.black,
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(10),
                  //       ),
                  //       elevation: 0,
                  //     ),
                  //     child: Text(
                  //       'Continue',
                  //       style: text16(
                  //         fontWeight: FontWeight.w700,
                  //         color: AppColors.black,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Checkmark circle with ring ──────────────────────
class _VerifiedCheckmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.25),
                width: 1.5,
              ),
            ),
          ),
          // Inner ring
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.5),
                width: 2,
              ),
            ),
          ),
          // Filled circle with checkmark
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryColor, width: 2.5),
            ),
            child: Icon(
              Icons.check_rounded,
              color: AppColors.primaryColor,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Decorative star / dot decorations ───────────────
class _StarDecorations extends StatelessWidget {
  const _StarDecorations();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-left stars
        _Star(top: 120, left: 30, color: AppColors.accentColor, size: 16),
        _Star(top: 160, left: 70, color: AppColors.primaryColor, size: 10),
        _Star(top: 100, left: 90, color: const Color(0xFF00BFFF), size: 8),

        // Top-right stars
        _Star(top: 110, right: 40, color: AppColors.primaryColor, size: 14),
        _Star(top: 155, right: 75, color: AppColors.accentColor, size: 10),
        _Star(top: 85, right: 100, color: const Color(0xFF00BFFF), size: 8),

        // Mid-left dots
        _Star(top: 280, left: 20, color: AppColors.accentColor, size: 8),
        _Star(top: 320, left: 50, color: AppColors.primaryColor, size: 6),

        // Mid-right dots
        _Star(top: 270, right: 25, color: const Color(0xFF00BFFF), size: 8),
        _Star(top: 315, right: 55, color: AppColors.primaryColor, size: 6),
      ],
    );
  }
}

class _Star extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final Color color;
  final double size;

  const _Star({
    this.top,
    this.left,
    this.right,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Icon(
        Icons.star_rounded,
        color: color.withOpacity(0.75),
        size: size,
      ),
    );
  }
}
