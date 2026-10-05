import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/utils/helpers.dart';
import 'package:masti_adda_app/web/routes/web_routes.dart';
import 'package:masti_adda_app/web/utils/web_auth_guard.dart';
import 'package:masti_adda_app/web/utils/web_responsive.dart';

class WebContentCard extends StatefulWidget {
  final String id;
  final String title;
  final String? posterUrl;
  final String? category;
  final String? type; // 'drama', 'movie', 'series'
  final double? rating;
  final String? duration;
  final int? releaseYear;
  final bool isPremium;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const WebContentCard({
    super.key,
    required this.id,
    required this.title,
    this.posterUrl,
    this.category,
    this.type = 'movie',
    this.rating,
    this.duration,
    this.releaseYear,
    this.isPremium = false,
    this.width = 190,
    this.height = 280,
    this.onTap,
  });

  @override
  State<WebContentCard> createState() => _WebContentCardState();
}

class _WebContentCardState extends State<WebContentCard> {
  bool _isHovered = false;

  void _navigateToDetail() {
    WebAuthGuard.requireAuth(
      context: context,
      message: 'Please sign in to view details and watch on Masti Adda.',
      onSuccess: () {
        if (widget.onTap != null) {
          widget.onTap!();
          return;
        }
        Get.toNamed(
          '${WebRoutes.details}?id=${widget.id}&type=${widget.type ?? "movie"}',
          arguments: {'id': widget.id, 'type': widget.type ?? 'movie'},
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = WebResponsive.isMobile(context);
    final formattedPoster = formatMediaUrl(widget.posterUrl);
    final effectiveWidth = (isMobile && widget.width == 190) ? 140.0 : widget.width;
    final effectiveHeight = (isMobile && widget.height == 280) ? 210.0 : widget.height;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _navigateToDetail,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: effectiveWidth,
          height: effectiveHeight,
          transform: Matrix4.identity()
            ..scale(_isHovered ? 1.05 : 1.0)
            ..translate(0.0, _isHovered ? -6.0 : 0.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppColors.primaryPink.withOpacity(0.35)
                    : Colors.black.withOpacity(0.4),
                blurRadius: _isHovered ? 18 : 8,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
            border: Border.all(
              color: _isHovered
                  ? AppColors.primaryPink.withOpacity(0.8)
                  : AppColors.borderColor.withOpacity(0.2),
              width: _isHovered ? 1.5 : 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Poster Image (BoxFit.contain to ensure full poster is shown without cuts)
                if (formattedPoster.isNotEmpty)
                  Container(
                    color: AppColors.surfaceColor,
                    child: CachedNetworkImage(
                      imageUrl: formattedPoster,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      placeholder: (context, url) => Container(
                        color: AppColors.surfaceColor,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryPink,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.surfaceColor,
                        child: const Center(
                          child: Icon(
                            Icons.movie_creation_outlined,
                            color: AppColors.secondaryTextColor,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    color: AppColors.surfaceColor,
                    child: const Center(
                      child: Icon(
                        Icons.movie_creation_outlined,
                        color: AppColors.secondaryTextColor,
                        size: 40,
                      ),
                    ),
                  ),

                // 2. Gradient Overlay for readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.95),
                        ],
                        stops: const [0.0, 0.45, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),

                // Premium Badge (Uncomment if needed in future):
                /*
                if (widget.isPremium)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                */

                // 3. Top Type Tag
                if (widget.type != null)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.type!.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                // 4. Hover Play Button in Center
                if (_isHovered)
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPink.withOpacity(0.6),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                // 5. Bottom Info (Title, Rating, Category)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (widget.rating != null && widget.rating! > 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFC107),
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              widget.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (widget.releaseYear != null) ...[
                            Text(
                              widget.releaseYear.toString(),
                              style: TextStyle(
                                color: AppColors.white.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (widget.duration != null &&
                              widget.duration!.isNotEmpty) ...[
                            Flexible(
                              child: Text(
                                widget.duration!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.white.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
