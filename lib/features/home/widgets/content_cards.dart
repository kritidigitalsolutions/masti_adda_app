import 'package:flutter/material.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/features/home/models/content_item.dart';
import 'package:masti_adda_app/utils/text_style.dart';

class PosterCard extends StatelessWidget {
  final ContentItem item;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const PosterCard({
    super.key,
    required this.item,
    this.width = 108,
    this.height = 148,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accentColor.withOpacity(0.55)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [item.primaryColor, item.secondaryColor],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -18,
              top: -12,
              child: Icon(
                Icons.movie_filter_rounded,
                size: 84,
                color: Colors.white.withOpacity(0.09),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.82),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text12(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text10(color: AppColors.secondaryTextColor),
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

class HomeSection extends StatelessWidget {
  final String title;
  final List<ContentItem> items;
  final ValueChanged<ContentItem> onItemTap;
  final double cardWidth;
  final double cardHeight;

  const HomeSection({
    super.key,
    required this.title,
    required this.items,
    required this.onItemTap,
    this.cardWidth = 112,
    this.cardHeight = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: text15(fontWeight: FontWeight.w700)),
            Text(
              'View All >',
              style: text10(color: AppColors.secondaryTextColor),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, index) => PosterCard(
              item: items[index],
              width: cardWidth,
              height: cardHeight,
              onTap: () => onItemTap(items[index]),
            ),
          ),
        ),
      ],
    );
  }
}
