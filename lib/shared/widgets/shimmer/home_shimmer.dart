import 'package:flutter/material.dart';
import 'app_shimmer.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// 1. Hero Banner Shimmer Skeleton
/// ─────────────────────────────────────────────────────────────────────────────
class HomeBannerShimmer extends StatelessWidget {
  const HomeBannerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: ShimmerEffect(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppShimmerConfig.baseColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    // Top-Left Trending Badge placeholder
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        width: 90,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppShimmerConfig.highlightColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    // Bottom title & button placeholders
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 180,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppShimmerConfig.highlightColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 110,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppShimmerConfig.highlightColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: AppShimmerConfig.highlightColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Dots placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: index == 0 ? 20 : 5,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppShimmerConfig.highlightColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 2. Continue Watching Shimmer Skeleton
/// ─────────────────────────────────────────────────────────────────────────────
class ContinueWatchingShimmer extends StatelessWidget {
  const ContinueWatchingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: ShimmerEffect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 140,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppShimmerConfig.baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 50,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppShimmerConfig.baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Horizontal Card List
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, _) => const _CwCardShimmer(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CwCardShimmer extends StatelessWidget {
  const _CwCardShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 165,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 165,
            height: 98,
            decoration: BoxDecoration(
              color: AppShimmerConfig.baseColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 120,
            height: 12,
            decoration: BoxDecoration(
              color: AppShimmerConfig.baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 10,
            decoration: BoxDecoration(
              color: AppShimmerConfig.baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 3. Media Section Shimmer Skeleton (Movies / Series / Dramas Row)
/// ─────────────────────────────────────────────────────────────────────────────
class MediaSectionShimmer extends StatelessWidget {
  final String? title;

  const MediaSectionShimmer({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: ShimmerEffect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 130,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppShimmerConfig.baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppShimmerConfig.baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Horizontal Card List
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, _) => const _MediaCardShimmer(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaCardShimmer extends StatelessWidget {
  const _MediaCardShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 115,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppShimmerConfig.baseColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 85,
            height: 12,
            decoration: BoxDecoration(
              color: AppShimmerConfig.baseColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 4. Full Feed Shimmer Skeleton (For Tab Loading)
/// ─────────────────────────────────────────────────────────────────────────────
class HomeFeedShimmer extends StatelessWidget {
  final bool showContinueWatching;
  final int sectionCount;

  const HomeFeedShimmer({
    super.key,
    this.showContinueWatching = true,
    this.sectionCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showContinueWatching) const ContinueWatchingShimmer(),
        ...List.generate(sectionCount, (index) => const MediaSectionShimmer()),
      ],
    );
  }
}
