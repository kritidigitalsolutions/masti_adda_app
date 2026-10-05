import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/constants/enums.dart';
import 'package:masti_adda_app/features/profile/controllers/help_controller.dart';
import 'package:masti_adda_app/features/profile/widgets/profile_page_scaffold.dart';
import 'package:masti_adda_app/shared/widgets/shimmer/shimmer.dart';
import 'package:masti_adda_app/utils/date_utils.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class RefundPolicy extends StatefulWidget {
  const RefundPolicy({super.key});

  @override
  State<RefundPolicy> createState() => _RefundPolicyState();
}

class _RefundPolicyState extends State<RefundPolicy> {
  final HelpController _controller = Get.put(HelpController());

  @override
  void initState() {
    super.initState();

    _controller.fetchSingleDocument(id: "refund-policy");
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = _controller.singleDocumentStatus.value;

      // Loading State
      if (status == Status.loading) {
        return const ProfilePageScaffold(
          title: 'Refund Policy',
          children: [
            TextContentShimmer(paragraphCount: 3),
          ],
        );
      }

      // Error State
      if (status == Status.error) {
        return ProfilePageScaffold(
          title: 'Refund Policy',
          children: [
            const SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: Colors.grey[400], size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load refund policy',
                    style: text13(color: AppColors.secondaryTextColor),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _controller.fetchSingleDocument(id: "refund-policy");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      // Success State
      if (status == Status.success &&
          _controller.singleDocument.value != null) {
        final document = _controller.singleDocument.value!;

        // If document has no content
        if (document.content.isEmpty) {
          return ProfilePageScaffold(
            title: 'Refund Policy',
            children: [
              const SizedBox(height: 100),
              Center(
                child: Text(
                  'No refund policy available',
                  style: text13(color: AppColors.secondaryTextColor),
                ),
              ),
            ],
          );
        }

        return ProfilePageScaffold(
          title: 'Refund Policy',
          children: [
            Text(
              'Please read our refund policy carefully.',
              style: text13(color: AppColors.secondaryTextColor),
            ),
            const SizedBox(height: 14),

            // Display the document content
            ProfileSurfaceTile(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: text15(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    document.content,
                    style: text13(color: AppColors.secondaryTextColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Last updated: ${formatDateMedium(document.updatedAt)}',
                    style: text11(color: AppColors.secondaryTextColor),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      // Default/Initial state
      return ProfilePageScaffold(
        title: 'Refund Policy',
        children: [
          const SizedBox(height: 100),
          Center(
            child: Text(
              'Loading refund policy...',
              style: text13(color: AppColors.secondaryTextColor),
            ),
          ),
        ],
      );
    });
  }
}
