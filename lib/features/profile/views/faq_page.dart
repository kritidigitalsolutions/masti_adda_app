import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/profile/controllers/help_controller.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/enums.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/shared/widgets/shimmer/shimmer.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final HelpController _controller = Get.put(HelpController());

  @override
  void initState() {
    super.initState();
    _controller.fetchAllHelp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'FAQ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: const Center(
          child: AppBackButton(),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Obx(() {
            final status = _controller.helpStatus.value;

            if (status == Status.loading) {
              return const TextContentShimmer(paragraphCount: 5);
            }

            if (status == Status.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.grey[400], size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _controller.fetchAllHelp();
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
              );
            }

            final helps = _controller.helps.value;
            if (helps == null || helps.helpData.isEmpty) {
              return Center(
                child: Text(
                  'No content available',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
              );
            }

            // 🔹 Split data by category
            final faqItems = helps.helpData
                .where((e) => e.category == 'faq')
                .toList();
            final contactItems = helps.helpData
                .where((e) => e.category == 'contact-support')
                .toList();
            final otherItems = helps.helpData
                .where(
                  (e) => e.category != 'faq' && e.category != 'contact-support',
                )
                .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 🔹 1. Contact support -> special card (icon + tap to call/email)
                if (contactItems.isNotEmpty) ...[
                  _sectionTitle('Contact Us'),
                  const SizedBox(height: 8),
                  ...contactItems.map((item) => _buildContactTile(item)),
                  const SizedBox(height: 20),
                ],

                // 🔹 2. Other categories (e.g. cancel-subscription) -> highlighted info card
                if (otherItems.isNotEmpty) ...[
                  _sectionTitle('Important Info'),
                  const SizedBox(height: 8),
                  ...otherItems.map((item) => _buildInfoCard(item)),
                  const SizedBox(height: 20),
                ],

                // 🔹 3. FAQ category -> expandable tiles
                if (faqItems.isNotEmpty) ...[
                  _sectionTitle('Frequently Asked Questions'),
                  const SizedBox(height: 8),
                  ...faqItems.map((faq) => _buildFaqTile(faq)),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 450;
        return Text(
          title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmall ? 15 : 18,
            fontWeight: FontWeight.w700,
            height: 1.3,
            letterSpacing: 0.2,
          ),
        );
      },
    );
  }

  // Expandable FAQ tile (only for category == 'faq')
  Widget _buildFaqTile(faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          faq.question,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconColor: Colors.grey[400],
        collapsedIconColor: Colors.grey[400],
        trailing: const Icon(Icons.keyboard_arrow_down),
        children: [
          Text(
            faq.answer,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // Contact support -> tappable card with icon (call / email)
  Widget _buildContactTile(item) {
    final isEmail = item.question.toLowerCase().contains('email');
    final icon = isEmail ? Icons.email_outlined : Icons.phone_outlined;
    final value = isEmail ? item.supportEmail : item.supportNumber;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: () async {
          final uri = isEmail
              ? Uri(scheme: 'mailto', path: value)
              : Uri(scheme: 'tel', path: value);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.question,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.answer,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  // Other categories (e.g. cancel-subscription) -> simple highlighted card
  Widget _buildInfoCard(item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primaryColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.answer,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
