import 'package:flutter/material.dart';

/// Reusable widget for scrollable dialog content with auto-hiding scrollbar
/// 
/// The scrollbar is only visible when content is scrollable and the user is scrolling.
/// This provides a clean UI while still indicating scrollability when needed.
class ScrollableDialogContent extends StatefulWidget {
  final Widget child;

  const ScrollableDialogContent({
    super.key,
    required this.child,
  });

  @override
  State<ScrollableDialogContent> createState() => _ScrollableDialogContentState();
}

class _ScrollableDialogContentState extends State<ScrollableDialogContent> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      // thumbVisibility: false means scrollbar only appears when scrolling
      // This provides the best UX - visible when needed, hidden when not
      thumbVisibility: false,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: widget.child,
      ),
    );
  }
}

