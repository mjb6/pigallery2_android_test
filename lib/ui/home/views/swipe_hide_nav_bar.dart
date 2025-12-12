import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Hide/Show the bottom nav bar when a vertical swipe gesture is performed on the main content.
class SwipeHideNavBarWrapper extends StatefulWidget {
  final Widget screenContent;

  final Widget navBar;

  final double navBarHeight;

  final Duration animationDuration;

  final double swipeThreshold;

  const SwipeHideNavBarWrapper({
    super.key,
    required this.screenContent,
    required this.navBar,
    required this.navBarHeight,
    this.animationDuration = const Duration(milliseconds: 300),
    this.swipeThreshold = -1,
  });

  @override
  State<SwipeHideNavBarWrapper> createState() => _SwipeHideNavBarWrapperState();
}

class _SwipeHideNavBarWrapperState extends State<SwipeHideNavBarWrapper> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  bool _isNavBarVisible = true;
  Offset _lastDragStart = Offset.zero;
  Offset _lastScrollStart = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _offsetAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, 1), // Move down by full height
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _lastScrollStart = notification.dragDetails?.globalPosition ?? Offset.zero;
      return false;
    }
    if (notification is OverscrollNotification) {
      if (notification.dragDetails == null) return false;
      double xDiff = notification.dragDetails!.globalPosition.dx - _lastScrollStart.dx;
      double yDiff = notification.dragDetails!.globalPosition.dy - _lastScrollStart.dy;
      if (xDiff.abs() > yDiff.abs()) {
        return false;
      }

      final double scrollDelta = yDiff;

      if (scrollDelta.abs() > widget.swipeThreshold) {
        if (scrollDelta > 0) {
          _hideNavBar();
          _lastScrollStart = notification.dragDetails?.globalPosition ?? Offset.zero;
        } else {
          _showNavBar();
          _lastScrollStart = notification.dragDetails?.globalPosition ?? Offset.zero;
        }
      }
    }
    if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails == null) return false;
      double xDiff = notification.dragDetails!.globalPosition.dx - _lastScrollStart.dx;
      double yDiff = notification.dragDetails!.globalPosition.dy - _lastScrollStart.dy;
      if (xDiff.abs() > yDiff.abs()) {
        return false;
      }

      final double scrollDelta = yDiff;

      if (scrollDelta != 0) {
        if (scrollDelta.abs() > widget.swipeThreshold) {
          if (scrollDelta > 0) {
            _hideNavBar();
            _lastScrollStart = notification.dragDetails?.globalPosition ?? Offset.zero;
          } else {
            _showNavBar();
            _lastScrollStart = notification.dragDetails?.globalPosition ?? Offset.zero;
          }
        }
      }
    }
    return false;
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _lastDragStart = details.globalPosition;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final double dragDistance = details.globalPosition.dy - _lastDragStart.dy;

    if (dragDistance.abs() > widget.swipeThreshold) {
      if (dragDistance > 0) {
        _hideNavBar();
        _lastDragStart = details.globalPosition;
      } else {
        _showNavBar();
        _lastDragStart = details.globalPosition;
      }
    }
  }

  void _hideNavBar() {
    if (!_isNavBarVisible) {
      _isNavBarVisible = true;
      _animationController.reverse();
    }
  }

  void _showNavBar() {
    if (_isNavBarVisible) {
      _isNavBarVisible = false;
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        VerticalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
          () => VerticalDragGestureRecognizer(),
          (VerticalDragGestureRecognizer instance) {
            instance.onStart = _onVerticalDragStart;
            instance.onUpdate = _onVerticalDragUpdate;
          },
        ),
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: widget.screenContent,
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: widget.navBarHeight,
            child: SlideTransition(
              position: _offsetAnimation,
              child: widget.navBar,
            ),
          ),
        ],
      ),
    );
  }
}
