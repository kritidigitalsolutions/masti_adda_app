import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/auth/controllers/auth_controller.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/shared/widgets/custom_button.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class EnterMobileScreen extends StatelessWidget {
  EnterMobileScreen({super.key});

  final AuthController controllers = Get.put(AuthController());
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
                  Color(0xFF1A0520),
                  Color(0xFF0D0614),
                  Color(0xFF0A0A18),
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
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Phone illustration
                        _PhoneIllustration(),
                        const SizedBox(height: 36),

                        // Title
                        Text(
                          'Enter Mobile Number',
                          style: text20(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textColor,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Phone input field
                        _MobileInputField(controller: controllers),

                        Obx(() {
                          if (controllers.mobileError.value.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                controllers.mobileError.value,
                                style: text12(color: AppColors.errorColor),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        const SizedBox(height: 12),

                        // Hint
                        Text(
                          "We'll send a verification code\nto continue",
                          style: text13(color: AppColors.secondaryTextColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 36),

                        // Send OTP button
                        Obx(
                          () => AppButton(
                            title: "Send OTP",
                            onTap: controllers.isMobileValid.value
                                ? controllers.sendOTP
                                : null,
                            isLoading: controllers.sendOtpStatus.value,
                          ),
                        ),
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

// ─── Phone illustration ───────────────────────────────
class _PhoneIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer dashed ring
          DottedBorder(
            options: CircularDottedBorderOptions(
              color: AppColors.otherColor,
              strokeWidth: 1,
              dashPattern: [8, 4],
            ),
            child: const SizedBox(width: 150, height: 150),
          ),

          // Lock badge
          Positioned(
            bottom: 15,
            right: 15,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: AppColors.black,
                size: 16,
              ),
            ),
          ),
          // Phone icon
          Icon(
            Icons.smartphone_rounded,
            size: 56,
            color: AppColors.accentColor,
          ),
        ],
      ),
    );
  }
}

// ─── Mobile input field ───────────────────────────────
class _MobileInputField extends StatelessWidget {
  final AuthController controller;
  const _MobileInputField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Row(
        children: [
          // Country code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: AppColors.borderColor, width: 1),
              ),
            ),
            child: Text(
              '+91',
              style: text15(
                color: AppColors.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Number input
          Expanded(
            child: TextField(
              controller: controller.mobileController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              cursorColor: AppColors.white,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: text15(color: AppColors.textColor),
              onChanged: controller.validateMobile, // <-- add this line
              decoration: InputDecoration(
                hintText: '0000000000',
                hintStyle: text15(color: AppColors.hintTextColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
