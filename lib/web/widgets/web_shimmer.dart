import 'package:flutter/material.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class WebShimmerCard extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const WebShimmerCard({
    super.key,
    this.width = 180,
    this.height = 260,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceColor.withOpacity(0.6),
      highlightColor: AppColors.borderColor.withOpacity(0.4),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class WebShimmerBanner extends StatelessWidget {
  final double height;

  const WebShimmerBanner({super.key, this.height = 450});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceColor.withOpacity(0.6),
      highlightColor: AppColors.borderColor.withOpacity(0.4),
      child: Container(
        width: double.infinity,
        height: height,
        color: AppColors.surfaceColor,
      ),
    );
  }
}

class WebShimmerSection extends StatelessWidget {
  const WebShimmerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: AppColors.surfaceColor.withOpacity(0.6),
          highlightColor: AppColors.borderColor.withOpacity(0.4),
          child: Container(
            width: 180,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, __) => const WebShimmerCard(),
          ),
        ),
      ],
    );
  }
}
