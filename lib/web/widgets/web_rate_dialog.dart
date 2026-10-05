import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/profile/repositories/rating_repository.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:url_launcher/url_launcher.dart';

class WebRateDialog extends StatefulWidget {
  const WebRateDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => const WebRateDialog(),
    );
  }

  @override
  State<WebRateDialog> createState() => _WebRateDialogState();
}

class _WebRateDialogState extends State<WebRateDialog> {
  int _selectedRating = 5;
  int? _hoveredRating;
  bool _isSubmitting = false;
  String? _errorMessage;

  final TextEditingController _feedbackController = TextEditingController();
  final RatingRepository _ratingRepo = RatingRepository();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  int get _currentRating => _hoveredRating ?? _selectedRating;

  String get _ratingLabel {
    switch (_currentRating) {
      case 5:
        return 'Loved it! Absolutely Fantastic 😍';
      case 4:
        return 'Great! Really enjoying it 😊';
      case 3:
        return 'Good, but could be better 🙂';
      case 2:
        return 'Below Average, needs work 🙁';
      case 1:
        return 'Poor Experience 😞';
      default:
        return 'Tap a star to rate';
    }
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final List<String> reviewParts = [];

    final customFeedback = _feedbackController.text.trim();
    if (customFeedback.isNotEmpty) {
      reviewParts.add(customFeedback);
    }
    final fullReview = reviewParts.isNotEmpty
        ? reviewParts.join('\n')
        : 'Rating: $_selectedRating/5';

    try {
      await _ratingRepo.submitRating(
        rating: _selectedRating,
        review: fullReview,
      );

      if (!mounted) return;

      // For 4 or 5 stars, also offer opening Play Store link if desired
      if (_selectedRating >= 4) {
        final storeUrl = Uri.parse(
          "https://play.google.com/store/apps/details?id=com.kritidigitalsolutions.golidoli",
        );
        try {
          if (await canLaunchUrl(storeUrl)) {
            await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }

      Get.snackbar(
        'Thank You!',
        'Thank you for rating Masti Adda $_selectedRating stars! ⭐',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryPink,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not submit review. Please try again.';
      });
      Get.snackbar(
        'Submission Failed',
        'Could not submit your review. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorColor,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isHighRating = _selectedRating >= 4;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF16181F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.borderColor.withValues(alpha: 0.45),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header: Icon badge, Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFFB800,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(
                              0xFFFFB800,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB800),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rate Masti Adda',
                            style: text18(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Tell us what you think',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.secondaryTextColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Interactive Stars Card
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E212B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        final isFilled = star <= _currentRating;

                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          onEnter: (_) => setState(() => _hoveredRating = star),
                          onExit: (_) => setState(() => _hoveredRating = null),
                          child: GestureDetector(
                            onTap: _isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _selectedRating = star;
                                    });
                                  },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: AnimatedScale(
                                scale: isFilled ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                child: Icon(
                                  isFilled
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: isFilled
                                      ? const Color(0xFFFFB800)
                                      : AppColors.secondaryTextColor.withValues(
                                          alpha: 0.4,
                                        ),
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _ratingLabel,
                        key: ValueKey<int>(_currentRating),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _currentRating >= 4
                              ? const Color(0xFFFFB800)
                              : AppColors.secondaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. Feedback Comment Box
              const Text(
                'Additional Comments (Optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E212B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: TextField(
                  controller: _feedbackController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(12),
                    hintText:
                        'Tell us how we can make your streaming experience even better...',
                    hintStyle: TextStyle(
                      color: AppColors.secondaryTextColor.withValues(
                        alpha: 0.6,
                      ),
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.errorColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 22),

              // 5. Submit Action Button
              MouseRegion(
                cursor: _isSubmitting
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _isSubmitting ? null : _submitReview,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF0564), Color(0xFFFF2E88)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPink.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isHighRating
                                      ? Icons.star_rounded
                                      : Icons.send_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isHighRating
                                      ? 'Submit Rating'
                                      : 'Submit Feedback',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
