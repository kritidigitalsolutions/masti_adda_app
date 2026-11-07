import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/core/services/storage_service.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:masti_adda_app/web/layouts/web_main_layout.dart';
import 'package:masti_adda_app/web/routes/web_routes.dart';
import 'package:masti_adda_app/web/utils/web_responsive.dart';

class WebDeleteAccountScreen extends StatefulWidget {
  const WebDeleteAccountScreen({super.key});

  @override
  State<WebDeleteAccountScreen> createState() => _WebDeleteAccountScreenState();
}

class _WebDeleteAccountScreenState extends State<WebDeleteAccountScreen> {
  String? _selectedReason = 'Privacy Concerns';
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  bool _isConfirmed = false;

  final List<String> _reasons = [
    'Privacy Concerns',
    'No Longer Using',
    'Too Expensive',
    'Found Alternative',
    'Security Concerns',
    'Accidental Submission',
    'App Performance',
    'Billing Dispute',
    'Other',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_phoneController.text.trim().isEmpty) {
      Get.snackbar(
        'Phone Number Required',
        'Please enter your registered phone number to identify your account.',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(20),
        maxWidth: 500,
      );
      return;
    }

    if (!_isConfirmed) {
      Get.snackbar(
        'Confirmation Required',
        'Please check the box confirming you understand that your account and data will be permanently deleted.',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(20),
        maxWidth: 500,
      );
      return;
    }

    // Show "Do you really want to delete?" popup
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderColor.withOpacity(0.4)),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 12),
            Text(
              'Confirm Deletion',
              style: text18(fontWeight: FontWeight.bold, color: AppColors.white),
            ),
          ],
        ),
        content: Text(
          'Do you really want to delete your account associated with ${_phoneController.text.trim()}?',
          style: text14(color: AppColors.secondaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: text14(color: AppColors.secondaryTextColor, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showSuccessDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Yes, Delete',
              style: text14(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.borderColor.withOpacity(0.4)),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 28),
            const SizedBox(width: 12),
            Text(
              'Request Submitted',
              style: text18(fontWeight: FontWeight.bold, color: AppColors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your account will be deleted in 24 - 48 hours. Thank you for consideration. After this you will not be able to use this app. Thanks.',
              style: appTextStyle(fontSize: 14, color: AppColors.secondaryTextColor, height: 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await StorageService.logout();
              Get.offAllNamed(WebRoutes.home);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'OK / Logout',
              style: text14(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = WebResponsive.contentHorizontalPadding(context);

    return WebMainLayout(
      activeRoute: WebRoutes.profile,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 32,
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 640),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderColor.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with back button and title
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                      tooltip: 'Back to Profile',
                      onPressed: () => Get.back(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_remove_rounded,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delete Account',
                            style: text20(fontWeight: FontWeight.bold, color: AppColors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Submit an account deletion request using your authenticated session.',
                            style: text12(color: AppColors.secondaryTextColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: AppColors.borderColor.withOpacity(0.3), height: 1),
                const SizedBox(height: 24),

                // Registered Phone Number Input
                Text(
                  'Registered Phone Number',
                  style: text14(fontWeight: FontWeight.bold, color: AppColors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: text13(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter your registered phone number (e.g. +91 9876543210)',
                    hintStyle: text13(color: AppColors.hintTextColor),
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.secondaryTextColor, size: 20),
                    filled: true,
                    fillColor: AppColors.backgroundColor.withOpacity(0.6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Select Reason Category
                Text(
                  'Select Reason Category',
                  style: text14(fontWeight: FontWeight.bold, color: AppColors.white),
                ),
                const SizedBox(height: 12),

                ..._reasons.map((reason) {
                  final isSelected = _selectedReason == reason;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.redAccent.withOpacity(0.6) : AppColors.borderColor.withOpacity(0.2),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: RadioListTile<String>(
                      title: Text(
                        reason,
                        style: text13(
                          color: isSelected ? Colors.white : AppColors.secondaryTextColor,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      value: reason,
                      groupValue: _selectedReason,
                      activeColor: Colors.redAccent,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      onChanged: (val) {
                        setState(() {
                          _selectedReason = val;
                        });
                      },
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // Reason Details / Feedback (Optional)
                Text(
                  'Reason Details / Feedback (Optional)',
                  style: text14(fontWeight: FontWeight.bold, color: AppColors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  style: text13(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: 'Please provide additional details or feedback...',
                    hintStyle: text13(color: AppColors.hintTextColor),
                    filled: true,
                    fillColor: AppColors.backgroundColor.withOpacity(0.6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderColor.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Permanent Action Warning Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_rounded,
                        color: Colors.redAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Permanent Action Warning',
                              style: text13(fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Identity is extracted securely on the server from your token. After deletion, you won\'t be able to use this account or access your subscription.',
                              style: appTextStyle(fontSize: 12, color: AppColors.secondaryTextColor, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Checkbox confirmation
                CheckboxListTile(
                  value: _isConfirmed,
                  onChanged: (val) {
                    setState(() {
                      _isConfirmed = val ?? false;
                    });
                  },
                  activeColor: Colors.redAccent,
                  checkColor: Colors.white,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'I understand that my account and data will be permanently deleted and cannot be recovered.',
                    style: text12(color: AppColors.secondaryTextColor),
                  ),
                ),

                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton.icon(
                  onPressed: _handleSubmit,
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                  label: Text(
                    'Submit',
                    style: text15(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
}
