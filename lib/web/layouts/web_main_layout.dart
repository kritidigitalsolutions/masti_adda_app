import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masti_adda_app/constants/app_colors.dart';
import 'package:masti_adda_app/web/layouts/web_footer.dart';
import 'package:masti_adda_app/web/layouts/web_header.dart';
import 'package:masti_adda_app/web/layouts/web_nav_drawer.dart';

class WebMainLayout extends StatefulWidget {
  final String activeRoute;
  final Widget body;
  final bool showFooter;
  final bool isScrollable;

  const WebMainLayout({
    super.key,
    required this.activeRoute,
    required this.body,
    this.showFooter = true,
    this.isScrollable = true,
  });

  @override
  State<WebMainLayout> createState() => _WebMainLayoutState();
}

class _WebMainLayoutState extends State<WebMainLayout> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _keyboardFocusNode = FocusNode();
  DateTime? _lastKeyEventTime;
  LogicalKeyboardKey? _lastKeyEventKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _keyboardFocusNode.canRequestFocus) {
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    if (!_scrollController.hasClients) return;

    // Do not intercept if user is typing in a text field / input
    final focusedWidget = FocusManager.instance.primaryFocus?.context?.widget;
    if (focusedWidget is EditableText) return;

    final now = DateTime.now();
    final bool isRapidOrRepeat = event is KeyRepeatEvent ||
        (_lastKeyEventKey == event.logicalKey &&
            _lastKeyEventTime != null &&
            now.difference(_lastKeyEventTime!).inMilliseconds < 150);

    _lastKeyEventTime = now;
    _lastKeyEventKey = event.logicalKey;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final minScroll = _scrollController.position.minScrollExtent;
    final current = _scrollController.offset;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (isRapidOrRepeat) {
        _scrollController.jumpTo((current + 35.0).clamp(minScroll, maxScroll));
      } else {
        _scrollController.animateTo(
          (current + 160.0).clamp(minScroll, maxScroll),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
        );
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (isRapidOrRepeat) {
        _scrollController.jumpTo((current - 35.0).clamp(minScroll, maxScroll));
      } else {
        _scrollController.animateTo(
          (current - 160.0).clamp(minScroll, maxScroll),
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
        );
      }
    } else if (event.logicalKey == LogicalKeyboardKey.pageDown ||
        (event.logicalKey == LogicalKeyboardKey.space &&
            !HardwareKeyboard.instance.isShiftPressed)) {
      if (isRapidOrRepeat) {
        _scrollController.jumpTo((current + 60.0).clamp(minScroll, maxScroll));
      } else {
        _scrollController.animateTo(
          (current + 550.0).clamp(minScroll, maxScroll),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    } else if (event.logicalKey == LogicalKeyboardKey.pageUp ||
        (event.logicalKey == LogicalKeyboardKey.space &&
            HardwareKeyboard.instance.isShiftPressed)) {
      if (isRapidOrRepeat) {
        _scrollController.jumpTo((current - 60.0).clamp(minScroll, maxScroll));
      } else {
        _scrollController.animateTo(
          (current - 550.0).clamp(minScroll, maxScroll),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    } else if (event.logicalKey == LogicalKeyboardKey.home) {
      _scrollController.animateTo(
        minScroll,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    } else if (event.logicalKey == LogicalKeyboardKey.end) {
      _scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        drawer: WebNavDrawer(activeRoute: widget.activeRoute),
        body: Column(
          children: [
            WebHeader(activeRoute: widget.activeRoute),
            Expanded(
              child: widget.isScrollable
                  ? SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          widget.body,
                          if (widget.showFooter) const WebFooter(),
                        ],
                      ),
                    )
                  : widget.body,
            ),
          ],
        ),
      ),
    );
  }
}
