import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/web/utils/web_responsive.dart';
import 'package:masti_adda_app/web/widgets/web_shimmer.dart';

class WebContentSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? viewAllRoute;
  final VoidCallback? onViewAll;
  final List<Widget> items;
  final bool isLoading;
  final double cardWidth;
  final double cardHeight;

  const WebContentSection({
    super.key,
    required this.title,
    this.subtitle,
    this.viewAllRoute,
    this.onViewAll,
    required this.items,
    this.isLoading = false,
    this.cardWidth = 190,
    this.cardHeight = 280,
  });

  @override
  State<WebContentSection> createState() => _WebContentSectionState();
}

class _WebContentSectionState extends State<WebContentSection> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;
  DateTime? _lastKeyEventTime;
  LogicalKeyboardKey? _lastKeyEventKey;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollPosition);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScrollPosition);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _checkScrollPosition() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    final canLeft = currentScroll > 10;
    final canRight = currentScroll < maxScroll - 10;

    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  void _scrollLeft() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      (_scrollController.offset - 400).clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollRight() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      (_scrollController.offset + 400).clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    if (!_scrollController.hasClients) return;

    final now = DateTime.now();
    final bool isRapidOrRepeat = event is KeyRepeatEvent ||
        (_lastKeyEventKey == event.logicalKey &&
            _lastKeyEventTime != null &&
            now.difference(_lastKeyEventTime!).inMilliseconds < 150);

    _lastKeyEventTime = now;
    _lastKeyEventKey = event.logicalKey;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (isRapidOrRepeat) {
        _scrollController.jumpTo((current - 35.0).clamp(0.0, maxScroll));
      } else {
        _scrollLeft();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (isRapidOrRepeat) {
        _scrollController.jumpTo((current + 35.0).clamp(0.0, maxScroll));
      } else {
        _scrollRight();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: WebShimmerSection(),
      );
    }

    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      onEnter: (_) {
        if (_focusNode.canRequestFocus) {
          _focusNode.requestFocus();
        }
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.primaryPink,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Text(
                            widget.subtitle!,
                            style: const TextStyle(
                              color: AppColors.secondaryTextColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // View All Button
                  if (widget.onViewAll != null)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: widget.onViewAll,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(
                                color: AppColors.primaryPink,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: AppColors.primaryPink,
                              size: 13,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Content Row with scroll buttons
              SizedBox(
                height: (WebResponsive.isMobile(context) && widget.cardHeight == 280) ? 226.0 : (widget.cardHeight + 16.0),
                child: Stack(
                  children: [
                    ListView.separated(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: widget.items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 18),
                      itemBuilder: (context, index) => widget.items[index],
                    ),

                    // Left Scroll Arrow (Desktop)
                    if (_canScrollLeft)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.borderColor.withOpacity(0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.chevron_left_rounded,
                                  color: Colors.white, size: 28),
                              onPressed: _scrollLeft,
                            ),
                          ),
                        ),
                      ),

                    // Right Scroll Arrow (Desktop)
                    if (_canScrollRight)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.borderColor.withOpacity(0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.chevron_right_rounded,
                                  color: Colors.white, size: 28),
                              onPressed: _scrollRight,
                            ),
                          ),
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
