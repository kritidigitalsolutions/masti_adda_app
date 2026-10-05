import 'package:flutter/material.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/shared/widgets/app_back_button.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class ProfilePageScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  const ProfilePageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
      physics: onRefresh != null
          ? const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics())
          : const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );

    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        color: AppColors.primaryColor,
        backgroundColor: AppColors.surfaceColor,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const AppBackButton(),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: text18(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

class ProfileSurfaceTile extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ProfileSurfaceTile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor.withOpacity(0.45)),
      ),
      child: child,
    );
  }
}

class ProfilePrimaryButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const ProfilePrimaryButton({
    super.key,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: text15(color: AppColors.black, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
