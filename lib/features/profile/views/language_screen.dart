import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/profile/controllers/profile_controller.dart';
import 'package:masti_adda_app/features/profile/widgets/profile_page_scaffold.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class LanguageScreen extends StatelessWidget {
  LanguageScreen({super.key});

  final LanguageController controller = Get.put(LanguageController());

  @override
  Widget build(BuildContext context) {
    return ProfilePageScaffold(
      title: 'Language',

      children: [
        Obx(
          () => Column(
            children: controller.languages.map((language) {
              final selected = controller.selectedLanguage.value == language;
              return GestureDetector(
                onTap: () => controller.selectLanguage(language),
                child: ProfileSurfaceTile(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          language,
                          style: text14(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected
                            ? AppColors.primaryColor
                            : AppColors.hintTextColor,
                        size: 20,
                      ),
                    ],
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
