import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/profile/controllers/profile_controller.dart';
import 'package:masti_adda_app/features/profile/widgets/profile_page_scaffold.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class ContentPreferenceScreen extends StatelessWidget {
  ContentPreferenceScreen({super.key});

  final ContentPreferenceController controller = Get.put(
    ContentPreferenceController(),
  );

  @override
  Widget build(BuildContext context) {
    return ProfilePageScaffold(
      title: 'Content Preference',

      children: [
        _ChipSection(
          title: 'Genres',
          values: controller.genres,
          controller: controller,
        ),
        const SizedBox(height: 18),
        _ChipSection(
          title: 'Content Type',
          values: controller.contentTypes,
          controller: controller,
        ),
        const SizedBox(height: 18),
        ProfilePrimaryButton(
          title: 'Update Preference',
          onTap: controller.savePreference,
        ),
      ],
    );
  }
}

class _ChipSection extends StatelessWidget {
  final String title;
  final List<String> values;
  final ContentPreferenceController controller;

  const _ChipSection({
    required this.title,
    required this.values,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text15(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) {
              final active = controller.selectedPreferences.contains(value);
              return GestureDetector(
                onTap: () => controller.togglePreference(value),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.accentColor
                        : AppColors.surfaceColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active
                          ? AppColors.accentColor
                          : AppColors.borderColor,
                    ),
                  ),
                  child: Text(
                    value,
                    style: text12(
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
