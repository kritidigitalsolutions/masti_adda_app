import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Global Shimmer Theme & Config for Masti Adda Dark OTT Theme
/// ─────────────────────────────────────────────────────────────────────────────
class AppShimmerConfig {
  static const Color baseColor = Color(0xFF1E1E28);
  static const Color highlightColor = Color(0xFF2E2E3E);
}

/// Global Base Shimmer Wrapper Widget
class ShimmerEffect extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? AppShimmerConfig.baseColor,
      highlightColor: highlightColor ?? AppShimmerConfig.highlightColor,
      child: child,
    );
  }
}

/// Reusable Shimmer Skeleton Box
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final ShapeBorder? shape;
  final Color? color;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.margin,
    this.shape,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (shape != null) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        decoration: ShapeDecoration(
          color: color ?? AppShimmerConfig.baseColor,
          shape: shape!,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppShimmerConfig.baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 1. Generic Card Grid Shimmer Skeleton (Movies / Series / Listing Grid)
/// ─────────────────────────────────────────────────────────────────────────────
class ShimmerGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  const ShimmerGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 3,
    this.childAspectRatio = 0.62,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (_, _) => const ShimmerBox(borderRadius: 10),
      ),
    );
  }
}

/// Sliver version of ShimmerGrid for CustomScrollView
class SliverShimmerGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  const SliverShimmerGrid({
    super.key,
    this.itemCount = 9,
    this.crossAxisCount = 3,
    this.childAspectRatio = 0.62,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, _) => const ShimmerEffect(child: ShimmerBox(borderRadius: 10)),
          childCount: itemCount,
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 2. Generic List Tile Shimmer Skeleton (Notifications, Watchlist, Episodes)
/// ─────────────────────────────────────────────────────────────────────────────
class ShimmerListTile extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const ShimmerListTile({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            const ShimmerBox(width: 50, height: 50, borderRadius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(
                    width: double.infinity,
                    height: 14,
                    borderRadius: 4,
                  ),
                  SizedBox(height: 6),
                  ShimmerBox(width: 120, height: 10, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multiple List Tiles Shimmer
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (_, _) => const ShimmerListTile(),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 3. Media Details Screen Shimmer Skeleton (Movie / Web Series)
/// ─────────────────────────────────────────────────────────────────────────────
class DetailScreenShimmer extends StatelessWidget {
  const DetailScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Poster Backdrop
            Container(
              height: 380,
              width: double.infinity,
              color: AppShimmerConfig.baseColor,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const ShimmerBox(width: 220, height: 24, borderRadius: 6),
                  const SizedBox(height: 12),
                  // Meta Tags Row (Rating, Year, Duration, Genre)
                  Row(
                    children: const [
                      ShimmerBox(width: 45, height: 18, borderRadius: 4),
                      SizedBox(width: 8),
                      ShimmerBox(width: 50, height: 18, borderRadius: 4),
                      SizedBox(width: 8),
                      ShimmerBox(width: 60, height: 18, borderRadius: 4),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Primary Action Buttons (Play Now, Watchlist, Share)
                  Row(
                    children: const [
                      Expanded(child: ShimmerBox(height: 48, borderRadius: 24)),
                      SizedBox(width: 12),
                      ShimmerBox(width: 48, height: 48, borderRadius: 24),
                      SizedBox(width: 12),
                      ShimmerBox(width: 48, height: 48, borderRadius: 24),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Synopsis Header & Lines
                  const ShimmerBox(width: 100, height: 18, borderRadius: 4),
                  const SizedBox(height: 10),
                  const ShimmerBox(
                    width: double.infinity,
                    height: 12,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 6),
                  const ShimmerBox(
                    width: double.infinity,
                    height: 12,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 6),
                  const ShimmerBox(width: 200, height: 12, borderRadius: 4),
                  const SizedBox(height: 24),
                  // Episodes / More Like This Row
                  const ShimmerBox(width: 130, height: 18, borderRadius: 4),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, _) => const ShimmerBox(
                        width: 100,
                        height: 130,
                        borderRadius: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 4. Dedicated Micro Drama Detail Screen Shimmer Skeleton
/// ─────────────────────────────────────────────────────────────────────────────
class MicroDramaDetailShimmer extends StatelessWidget {
  const MicroDramaDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 280px Vertical Hero Cover with Top Bar & Bottom Title
            Container(
              height: 280,
              width: double.infinity,
              color: AppShimmerConfig.baseColor,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top bar buttons (Back & Share)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          ShimmerBox(width: 34, height: 34, borderRadius: 17),
                          ShimmerBox(width: 34, height: 34, borderRadius: 17),
                        ],
                      ),
                      // Bottom Title and Premium badge
                      Row(
                        children: const [
                          Expanded(
                            child: ShimmerBox(height: 24, borderRadius: 4),
                          ),
                          SizedBox(width: 12),
                          ShimmerBox(width: 70, height: 20, borderRadius: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Rating & Tags Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  ShimmerBox(width: 70, height: 24, borderRadius: 4),
                  ShimmerBox(width: 60, height: 24, borderRadius: 4),
                  ShimmerBox(width: 80, height: 24, borderRadius: 4),
                  ShimmerBox(width: 65, height: 24, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Story Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 60, height: 16, borderRadius: 4),
                  SizedBox(height: 8),
                  ShimmerBox(
                    width: double.infinity,
                    height: 12,
                    borderRadius: 4,
                  ),
                  SizedBox(height: 6),
                  ShimmerBox(
                    width: double.infinity,
                    height: 12,
                    borderRadius: 4,
                  ),
                  SizedBox(height: 6),
                  ShimmerBox(width: 180, height: 12, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Start Watching Button + Action Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const ShimmerBox(
                    width: double.infinity,
                    height: 48,
                    borderRadius: 12,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(3, (index) {
                      return Column(
                        children: const [
                          ShimmerBox(width: 35, height: 35, borderRadius: 18),
                          SizedBox(height: 6),
                          ShimmerBox(width: 45, height: 10, borderRadius: 2),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Episodes Section (Chips / Grid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: 110, height: 18, borderRadius: 4),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 6,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, _) => const ShimmerBox(
                        width: 44,
                        height: 44,
                        borderRadius: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Similar Dramas Header & 2-column Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: 160, height: 18, borderRadius: 4),
                  const SizedBox(height: 12),
                  const MicroDramaGridShimmer(itemCount: 2, shrinkWrap: true),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 5. Dedicated Micro Drama 2-Column Grid Shimmer Skeleton (For Listing Screen)
/// ─────────────────────────────────────────────────────────────────────────────
class MicroDramaGridShimmer extends StatelessWidget {
  final int itemCount;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;

  const MicroDramaGridShimmer({
    super.key,
    this.itemCount = 6,
    this.shrinkWrap = false,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.62,
        ),
        itemCount: itemCount,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: AppShimmerConfig.baseColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Premium Badge Placeholder
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 50,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppShimmerConfig.highlightColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Bottom gradient / title line placeholder
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppShimmerConfig.highlightColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppShimmerConfig.highlightColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 4. Subscription Screen Shimmer Skeleton
/// ─────────────────────────────────────────────────────────────────────────────
class SubscriptionPlansShimmer extends StatelessWidget {
  const SubscriptionPlansShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            const ShimmerBox(width: 160, height: 22, borderRadius: 6),
            const SizedBox(height: 8),
            const ShimmerBox(width: 240, height: 14, borderRadius: 4),
            const SizedBox(height: 24),
            // Plan Card 1
            const ShimmerBox(
              width: double.infinity,
              height: 220,
              borderRadius: 20,
            ),
            const SizedBox(height: 16),
            // Plan Card 2
            const ShimmerBox(
              width: double.infinity,
              height: 160,
              borderRadius: 20,
            ),
            const SizedBox(height: 24),
            const ShimmerBox(
              width: double.infinity,
              height: 50,
              borderRadius: 25,
            ),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 5. Policy & FAQ Text Shimmer Skeleton
/// ─────────────────────────────────────────────────────────────────────────────
class TextContentShimmer extends StatelessWidget {
  final int paragraphCount;

  const TextContentShimmer({super.key, this.paragraphCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(paragraphCount, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 160, height: 18, borderRadius: 4),
                  SizedBox(height: 10),
                  ShimmerBox(
                    width: double.infinity,
                    height: 12,
                    borderRadius: 4,
                  ),
                  SizedBox(height: 6),
                  ShimmerBox(
                    width: double.infinity,
                    height: 12,
                    borderRadius: 4,
                  ),
                  SizedBox(height: 6),
                  ShimmerBox(
                    width: double.infinity,
                    height: 12,
                    borderRadius: 4,
                  ),
                  SizedBox(height: 6),
                  ShimmerBox(width: 220, height: 12, borderRadius: 4),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 6. Audio Stories Feed Shimmer Skeleton (For Audio Stories Main Screen)
/// ─────────────────────────────────────────────────────────────────────────────
class AudioStoriesFeedShimmer extends StatelessWidget {
  const AudioStoriesFeedShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Pills
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, _) =>
                  const ShimmerBox(width: 75, height: 34, borderRadius: 20),
            ),
          ),
          const SizedBox(height: 16),

          // Continue Listening Shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 150, height: 16, borderRadius: 4),
                SizedBox(height: 10),
                ShimmerBox(
                  width: double.infinity,
                  height: 80,
                  borderRadius: 14,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Audio Hero Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 170,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppShimmerConfig.baseColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    ShimmerBox(width: 90, height: 18, borderRadius: 4),
                    SizedBox(height: 8),
                    ShimmerBox(width: 180, height: 20, borderRadius: 4),
                    SizedBox(height: 8),
                    ShimmerBox(width: 120, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Top Audio Stories Section
          _buildAudioSectionShimmer('Top Audio Stories'),
          const SizedBox(height: 20),

          // Recently Added Section
          _buildAudioSectionShimmer('Recently Added'),
        ],
      ),
    );
  }

  Widget _buildAudioSectionShimmer(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBox(width: 140, height: 18, borderRadius: 4),
              ShimmerBox(width: 50, height: 14, borderRadius: 4),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) => const _AudioCardShimmer(),
          ),
        ),
      ],
    );
  }
}

class _AudioCardShimmer extends StatelessWidget {
  const _AudioCardShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerBox(width: 120, height: 120, borderRadius: 14),
          SizedBox(height: 8),
          ShimmerBox(width: 100, height: 12, borderRadius: 4),
          SizedBox(height: 4),
          ShimmerBox(width: 60, height: 10, borderRadius: 4),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 7. Audio Story Grid Shimmer (For Search Results)
/// ─────────────────────────────────────────────────────────────────────────────
class AudioStoryGridShimmer extends StatelessWidget {
  final int itemCount;

  const AudioStoryGridShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemCount: itemCount,
        itemBuilder: (_, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              child: ShimmerBox(width: double.infinity, borderRadius: 14),
            ),
            SizedBox(height: 8),
            ShimmerBox(width: 120, height: 12, borderRadius: 4),
            SizedBox(height: 4),
            ShimmerBox(width: 70, height: 10, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// 8. Dedicated Audio Story Detail Screen Shimmer Skeleton
/// ─────────────────────────────────────────────────────────────────────────────
class AudioDetailShimmer extends StatelessWidget {
  const AudioDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Cover Image (height 260)
            Container(
              height: 260,
              width: double.infinity,
              color: AppShimmerConfig.baseColor,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 34, height: 34, borderRadius: 17),
                      ShimmerBox(width: 34, height: 34, borderRadius: 17),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title & Meta Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: 220, height: 22, borderRadius: 4),
                  const SizedBox(height: 10),
                  // Author & Stats Row
                  Row(
                    children: const [
                      ShimmerBox(width: 90, height: 14, borderRadius: 4),
                      SizedBox(width: 12),
                      ShimmerBox(width: 70, height: 14, borderRadius: 4),
                      SizedBox(width: 12),
                      ShimmerBox(width: 80, height: 14, borderRadius: 4),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Genre Tags
                  Row(
                    children: const [
                      ShimmerBox(width: 65, height: 22, borderRadius: 12),
                      SizedBox(width: 8),
                      ShimmerBox(width: 65, height: 22, borderRadius: 12),
                      SizedBox(width: 8),
                      ShimmerBox(width: 80, height: 22, borderRadius: 12),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Large "Play All" Button
                  const ShimmerBox(
                    width: double.infinity,
                    height: 48,
                    borderRadius: 24,
                  ),
                  const SizedBox(height: 24),

                  // Synopsis
                  const ShimmerBox(width: 100, height: 16, borderRadius: 4),
                  const SizedBox(height: 8),
                  const ShimmerBox(
                    width: double.infinity,
                    height: 12,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 6),
                  const ShimmerBox(
                    width: double.infinity,
                    height: 12,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 6),
                  const ShimmerBox(width: 200, height: 12, borderRadius: 4),
                  const SizedBox(height: 24),

                  // Episodes Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerBox(width: 120, height: 18, borderRadius: 4),
                      ShimmerBox(width: 60, height: 14, borderRadius: 4),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Episodes List Skeletons
                  ...List.generate(4, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppShimmerConfig.baseColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const ShimmerBox(
                              width: 38,
                              height: 38,
                              borderRadius: 19,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  ShimmerBox(
                                    width: double.infinity,
                                    height: 13,
                                    borderRadius: 4,
                                  ),
                                  SizedBox(height: 6),
                                  ShimmerBox(
                                    width: 80,
                                    height: 10,
                                    borderRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const ShimmerBox(
                              width: 32,
                              height: 32,
                              borderRadius: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
