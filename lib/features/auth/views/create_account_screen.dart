import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/auth/controllers/register_controller.dart';
import 'package:masti_adda_app/routes/app_routes.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/shared/widgets/custom_button.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RegistrationController controller =
        Get.isRegistered<RegistrationController>()
            ? Get.find<RegistrationController>()
            : Get.put(RegistrationController());
    controller.loadArguments();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dark background
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
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        // ── Title ──
                        Center(
                          child: Column(
                            children: [
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Create Your\n',
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textColor,
                                        height: 1.25,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Account',
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.accentColor,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Let's personalize your\nentertainment",
                                style: text14(
                                  color: AppColors.secondaryTextColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ── Full Name ──
                        _InputField(
                          controller: controller.nameController,
                          hintText: 'Full Name',
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                        ),
                        Obx(() {
                          if (controller.nameError.value.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 6.0,
                                left: 4.0,
                              ),
                              child: Text(
                                controller.nameError.value,
                                style: text12(color: AppColors.errorColor),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        const SizedBox(height: 14),

                        // ── Email ──
                        _InputField(
                          controller: controller.emailController,
                          hintText: 'Email Address (Optional)',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        Obx(() {
                          if (controller.emailError.value.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 6.0,
                                left: 4.0,
                              ),
                              child: Text(
                                controller.emailError.value,
                                style: text12(color: AppColors.errorColor),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),

                        const SizedBox(height: 20),

                        // ── Terms checkbox ──
                        Obx(
                          () => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: controller.isTermsAccepted.value,
                                  onChanged: controller.toggleTerms,
                                  activeColor: AppColors.accentColor,
                                  side: const BorderSide(
                                    color: AppColors.borderColor,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    text: 'I agree to the ',
                                    style: text12(
                                      color: AppColors.secondaryTextColor,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: text12(
                                          color: AppColors.accentColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Get.toNamed(
                                              AppRoutes.termsConditions,
                                            );
                                          },
                                      ),
                                      TextSpan(
                                        text: ' and\n',
                                        style: text12(
                                          color: AppColors.secondaryTextColor,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: text12(
                                          color: AppColors.accentColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Get.toNamed(
                                              AppRoutes.privacyPolicy,
                                            );
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ── Next button ──
                        Obx(
                          () => AppButton(
                            title: "Next",
                            onTap: controller.isFormValid
                                ? controller.nextFromCreateAccount
                                : null,
                            isLoading: controller.isLoading.value,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Already have account ──
                        // Center(
                        //   child: RichText(
                        //     text: TextSpan(
                        //       text: 'Already have an account? ',
                        //       style: text13(
                        //         color: AppColors.secondaryTextColor,
                        //       ),
                        //       children: [
                        //         WidgetSpan(
                        //           child: GestureDetector(
                        //             onTap: () =>
                        //                 Get.offAllNamed(AppRoutes.login),
                        //             child: Text(
                        //               'Log In',
                        //               style: text13(
                        //                 color: AppColors.accentColor,
                        //                 fontWeight: FontWeight.w600,
                        //               ),
                        //             ),
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 32),
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

// ─── Reusable input field ──────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;

  const _InputField({
    required this.controller,
    required this.hintText,

    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: TextField(
        controller: controller,
        cursorColor: AppColors.white,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: text14(color: AppColors.textColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: text14(color: AppColors.hintTextColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),

          suffixIconConstraints: const BoxConstraints(minWidth: 40),
        ),
      ),
    );
  }
}
