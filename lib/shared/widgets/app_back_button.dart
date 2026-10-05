import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';

/// A standardized, premium back button used throughout the Masti Adda app.
///
/// Features two visual variants:
/// - [isOverlay] == false (default): Surface circular container with subtle border.
///   Ideal for standard screens, app bars, and profile/settings headers.
/// - [isOverlay] == true: Translucent dark circular container.
///   Ideal for media banners, posters, and video players.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isOverlay;
  final Color? color;
  final double size;
  final EdgeInsetsGeometry? padding;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.isOverlay = false,
    this.color,
    this.size = 16.0,
    this.padding,
  });

  void _handleBack(BuildContext context) {
    if (onPressed != null) {
      onPressed!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = isOverlay ? AppColors.overlayColor : AppColors.surfaceColor;
    final border = isOverlay
        ? Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1)
        : Border.all(color: AppColors.borderColor.withValues(alpha: 0.4), width: 1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleBack(context),
        customBorder: const CircleBorder(),
        child: Container(
          padding: padding ?? const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: border,
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: color ?? AppColors.white,
            size: size,
          ),
        ),
      ),
    );
  }
}
