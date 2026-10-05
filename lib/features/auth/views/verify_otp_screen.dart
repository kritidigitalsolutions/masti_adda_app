import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/auth/controllers/auth_controller.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  late final AuthController controllers;

  @override
  void initState() {
    super.initState();
    controllers = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

    final args = Get.arguments;
    if (args is Map && args['mobile'] != null) {
      controllers.mobileNumber.value = args['mobile'].toString();
    }

    // Clear previous OTP text and errors
    for (final c in controllers.otpControllers) {
      c.clear();
    }
    controllers.otp.value = '';
    controllers.otpError.value = '';
    controllers.isOtpValid.value = false;

    // Start timer on entry
    controllers.startTimer();
  }

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
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'Verify Your',
                          style: text24(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Mobile Number',
                          style: text24(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Subtitle
                        Text(
                          "We've sent a 4-digit verification code to",
                          style: text13(color: AppColors.secondaryTextColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),

                        // Mobile number row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Obx(
                              () => Text(
                                '+91 ${controllers.mobileNumber.value}',
                                style: text14(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => Get.back(),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: AppColors.accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),

                        // OTP boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            4,
                            (i) => _OtpBox(
                              index: i,
                              controller: controllers.otpControllers[i],
                              focusNode: controllers.otpFocusNodes[i],
                              onChanged: (v) => controllers.onOtpChanged(v, i),
                            ),
                          ),
                        ),
                        Obx(() {
                          if (controllers.otpError.value.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                controllers.otpError.value,
                                style: text12(color: AppColors.errorColor),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        const SizedBox(height: 28),

                        // Resend timer
                        Obx(() {
                          if (controllers.resendOtpStatus.value) {
                            return const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryColor,
                              ),
                            );
                          }

                          if (controllers.canResend.value) {
                            return GestureDetector(
                              onTap: controllers.resendOtp,
                              child: Text(
                                'Resend OTP',
                                style: text14(
                                  color: AppColors.accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }

                          return RichText(
                            text: TextSpan(
                              text: 'Resend OTP in ',
                              style: text13(
                                color: AppColors.secondaryTextColor,
                              ),
                              children: [
                                TextSpan(
                                  text: controllers.formattedTimer,
                                  style: text13(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                _SecurityBadge(),
              ],
            ),
          ),

          // Loading overlay
          Obx(
            () => controllers.verifyOtpStatus.value
                ? Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Single OTP input box ─────────────────────────────
class _OtpBox extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasFocus = focusNode.hasFocus;
    final hasText = controller.text.isNotEmpty;

    return Container(
      width: 58,
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFocus
              ? AppColors.primaryColor
              : hasText
                  ? AppColors.primaryColor.withValues(alpha: 0.5)
                  : AppColors.borderColor.withValues(alpha: 0.6),
          width: hasFocus ? 1.8 : 1.0,
        ),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Center(
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: appTextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textColor,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Security badge at bottom ─────────────────────────
class _SecurityBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 14,
            color: AppColors.hintTextColor,
          ),
          const SizedBox(width: 6),
          Text(
            'Your data is secured with end-to-end encryption',
            style: text11(color: AppColors.hintTextColor),
          ),
        ],
      ),
    );
  }
}
