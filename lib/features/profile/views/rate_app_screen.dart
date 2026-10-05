import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/utils/text_style.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:masti_adda_app/features/profile/repositories/rating_repository.dart';

class RateAppScreen extends StatefulWidget {
  const RateAppScreen({super.key});

  @override
  State<RateAppScreen> createState() => _RateAppScreenState();
}

class _RateAppScreenState extends State<RateAppScreen> {
  int _rating = 5;
  bool _isSubmitting = false;
  final TextEditingController _feedbackController = TextEditingController();
  // final Set<String> _selectedTags = {'🎬 Movies & Series', '⚡ Fast Video Streaming'};
  final RatingRepository _ratingRepo = RatingRepository();

  // final List<String> _feedbackTags = [
  //   '🎬 Movies & Series',
  //   '🎭 Micro Dramas',
  //   '🔊 Audio Stories',
  //   '⚡ Fast Video Streaming',
  //   '📱 Sleek UI & Experience',
  //   '💎 Great Value Plans',
  //   '📥 Offline Downloads',
  //   '🎧 Regional Content',
  // ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    switch (_rating) {
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

    final customFeedback = _feedbackController.text.trim();
    final List<String> reviewParts = [];
    // if (_selectedTags.isNotEmpty) {
    //   reviewParts.add('Likes: ${_selectedTags.join(', ')}');
    // }
    if (customFeedback.isNotEmpty) {
      reviewParts.add(customFeedback);
    }
    final fullReview = reviewParts.isNotEmpty
        ? reviewParts.join('\n')
        : 'Rating: $_rating/5';

    setState(() => _isSubmitting = true);

    try {
      await _ratingRepo.submitRating(rating: _rating, review: fullReview);

      if (!mounted) return;

      if (_rating >= 4) {
        final storeUrl = Uri.parse(
          "https://play.google.com/store/apps/details?id=com.kritidigitalsolutions.golidoli",
        );
        try {
          if (await canLaunchUrl(storeUrl)) {
            await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}
      }

      Get.back();
      Get.snackbar(
        'Thank You!',
        'Thank you for rating Masti Adda $_rating stars! ⭐',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryColor,
        colorText: AppColors.black,
      );
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Submission Failed',
        'Could not submit your review. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorColor,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    _buildHeroHeader(),
                    const SizedBox(height: 24),
                    _buildStarRatingCard(),
                    //const SizedBox(height: 20),
                    // _buildFeedbackTagsSection(),
                    const SizedBox(height: 20),
                    _buildCommentBox(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const AppBackButton(),
          const SizedBox(width: 12),
          Text('Rate App', style: text18(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryColor.withValues(alpha: 0.15),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.star_rounded,
              color: AppColors.primaryColor,
              size: 46,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'How was your experience?',
          style: text20(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Your feedback helps us bring you more movies, series, and vertical dramas you love.',
            style: text12(color: AppColors.secondaryTextColor),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildStarRatingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isFilled = starIndex <= _rating;
              return GestureDetector(
                onTap: () {
                  setState(() => _rating = starIndex);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedScale(
                    scale: isFilled ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isFilled
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: isFilled
                          ? AppColors.ratingColor
                          : AppColors.hintTextColor,
                      size: 42,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _ratingLabel,
              key: ValueKey<int>(_rating),
              style: text13(
                fontWeight: FontWeight.bold,
                color: _rating >= 4
                    ? AppColors.primaryColor
                    : AppColors.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildFeedbackTagsSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'What did you like the most?',
  //         style: text14(fontWeight: FontWeight.bold, color: AppColors.white),
  //       ),
  //       const SizedBox(height: 10),
  //       Wrap(
  //         spacing: 8,
  //         runSpacing: 8,
  //         children: _feedbackTags.map((tag) {
  //           final isSelected = _selectedTags.contains(tag);
  //           return GestureDetector(
  //             onTap: () {
  //               setState(() {
  //                 if (isSelected) {
  //                   _selectedTags.remove(tag);
  //                 } else {
  //                   _selectedTags.add(tag);
  //                 }
  //               });
  //             },
  //             child: AnimatedContainer(
  //               duration: const Duration(milliseconds: 180),
  //               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  //               decoration: BoxDecoration(
  //                 color: isSelected
  //                     ? AppColors.primaryColor.withValues(alpha: 0.2)
  //                     : AppColors.surfaceColor,
  //                 borderRadius: BorderRadius.circular(20),
  //                 border: Border.all(
  //                   color: isSelected
  //                       ? AppColors.primaryColor
  //                       : AppColors.borderColor.withValues(alpha: 0.35),
  //                 ),
  //               ),
  //               child: Text(
  //                 tag,
  //                 style: text12(
  //                   fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
  //                   color: isSelected
  //                       ? AppColors.primaryColor
  //                       : AppColors.secondaryTextColor,
  //                 ),
  //               ),
  //             ),
  //           );
  //         }).toList(),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildCommentBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Feedback (Optional)',
          style: text14(fontWeight: FontWeight.bold, color: AppColors.white),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.borderColor.withValues(alpha: 0.4),
            ),
          ),
          child: TextField(
            controller: _feedbackController,
            maxLines: 4,
            style: text13(color: AppColors.textColor),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(14),
              hintText:
                  'Tell us how we can make Masti Adda even better for you...',
              hintStyle: text12(color: AppColors.hintTextColor),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    final isHighRating = _rating >= 4;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        border: Border(
          top: BorderSide(color: AppColors.borderColor.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _isSubmitting ? null : _submitReview,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: _isSubmitting
                    ? AppColors.primaryColor.withValues(alpha: 0.6)
                    : AppColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.black,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isHighRating
                                ? Icons.open_in_new_rounded
                                : Icons.send_rounded,
                            color: AppColors.black,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isHighRating
                                ? 'Submit & Rate on Play Store'
                                : 'Submit Feedback',
                            style: text14(
                              color: AppColors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
