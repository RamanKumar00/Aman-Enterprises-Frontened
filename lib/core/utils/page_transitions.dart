import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

/// Custom page route with fade through transition
class FadeThroughPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeThroughPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// Custom page route with shared axis transition (horizontal)
class SharedAxisHorizontalPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SharedAxisHorizontalPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// Custom page route with shared axis transition (vertical)
class SharedAxisVerticalPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SharedAxisVerticalPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.vertical,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// Custom page route with shared axis transition (scaled)
class SharedAxisScaledPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SharedAxisScaledPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.scaled,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// Custom page route with slide transition
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  SlidePageRoute({
    required this.page,
    this.direction = SlideDirection.right,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset begin;
            switch (direction) {
              case SlideDirection.right:
                begin = const Offset(1.0, 0.0);
                break;
              case SlideDirection.left:
                begin = const Offset(-1.0, 0.0);
                break;
              case SlideDirection.up:
                begin = const Offset(0.0, 1.0);
                break;
              case SlideDirection.down:
                begin = const Offset(0.0, -1.0);
                break;
            }
            
            return SlideTransition(
              position: Tween<Offset>(
                begin: begin,
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

enum SlideDirection { right, left, up, down }

/// Custom page route with scale transition
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Alignment alignment;

  ScalePageRoute({
    required this.page,
    this.alignment = Alignment.center,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
              ),
              alignment: alignment,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// Custom page route with rotate transition
class RotatePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  RotatePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return RotationTransition(
              turns: Tween<double>(begin: 0.5, end: 0.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// Open container transition wrapper for smooth expansion animations
class ExpandableTile extends StatelessWidget {
  final Widget closedChild;
  final Widget Function(BuildContext context) openBuilder;
  final Color? closedColor;
  final BorderRadius? borderRadius;
  final double closedElevation;
  final VoidCallback? onClosed;

  const ExpandableTile({
    super.key,
    required this.closedChild,
    required this.openBuilder,
    this.closedColor,
    this.borderRadius,
    this.closedElevation = 0,
    this.onClosed,
  });

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      closedColor: closedColor ?? Theme.of(context).scaffoldBackgroundColor,
      closedShape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      closedElevation: closedElevation,
      openColor: Theme.of(context).scaffoldBackgroundColor,
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 400),
      onClosed: (_) => onClosed?.call(),
      closedBuilder: (context, openContainer) => GestureDetector(
        onTap: openContainer,
        child: closedChild,
      ),
      openBuilder: (context, _) => openBuilder(context),
    );
  }
}

/// Navigation helper with custom transitions
class AppNavigator {
  static void push(BuildContext context, Widget page, {PageTransitionType type = PageTransitionType.fadeThrough}) {
    Route route;
    switch (type) {
      case PageTransitionType.fadeThrough:
        route = FadeThroughPageRoute(page: page);
        break;
      case PageTransitionType.sharedAxisHorizontal:
        route = SharedAxisHorizontalPageRoute(page: page);
        break;
      case PageTransitionType.sharedAxisVertical:
        route = SharedAxisVerticalPageRoute(page: page);
        break;
      case PageTransitionType.sharedAxisScaled:
        route = SharedAxisScaledPageRoute(page: page);
        break;
      case PageTransitionType.slideRight:
        route = SlidePageRoute(page: page, direction: SlideDirection.right);
        break;
      case PageTransitionType.slideUp:
        route = SlidePageRoute(page: page, direction: SlideDirection.up);
        break;
      case PageTransitionType.scale:
        route = ScalePageRoute(page: page);
        break;
      case PageTransitionType.material:
        route = MaterialPageRoute(builder: (_) => page);
        break;
    }
    Navigator.push(context, route);
  }

  static void pushReplacement(BuildContext context, Widget page, {PageTransitionType type = PageTransitionType.fadeThrough}) {
    Route route;
    switch (type) {
      case PageTransitionType.fadeThrough:
        route = FadeThroughPageRoute(page: page);
        break;
      case PageTransitionType.sharedAxisHorizontal:
        route = SharedAxisHorizontalPageRoute(page: page);
        break;
      case PageTransitionType.sharedAxisVertical:
        route = SharedAxisVerticalPageRoute(page: page);
        break;
      case PageTransitionType.sharedAxisScaled:
        route = SharedAxisScaledPageRoute(page: page);
        break;
      case PageTransitionType.slideRight:
        route = SlidePageRoute(page: page, direction: SlideDirection.right);
        break;
      case PageTransitionType.slideUp:
        route = SlidePageRoute(page: page, direction: SlideDirection.up);
        break;
      case PageTransitionType.scale:
        route = ScalePageRoute(page: page);
        break;
      case PageTransitionType.material:
        route = MaterialPageRoute(builder: (_) => page);
        break;
    }
    Navigator.pushReplacement(context, route);
  }

  static void pushAndRemoveUntil(BuildContext context, Widget page, {PageTransitionType type = PageTransitionType.fadeThrough}) {
    Route route;
    switch (type) {
      case PageTransitionType.fadeThrough:
        route = FadeThroughPageRoute(page: page);
        break;
      case PageTransitionType.sharedAxisHorizontal:
        route = SharedAxisHorizontalPageRoute(page: page);
        break;
      case PageTransitionType.sharedAxisVertical:
        route = SharedAxisVerticalPageRoute(page: page);
        break;
      case PageTransitionType.sharedAxisScaled:
        route = SharedAxisScaledPageRoute(page: page);
        break;
      case PageTransitionType.slideRight:
        route = SlidePageRoute(page: page, direction: SlideDirection.right);
        break;
      case PageTransitionType.slideUp:
        route = SlidePageRoute(page: page, direction: SlideDirection.up);
        break;
      case PageTransitionType.scale:
        route = ScalePageRoute(page: page);
        break;
      case PageTransitionType.material:
        route = MaterialPageRoute(builder: (_) => page);
        break;
    }
    Navigator.pushAndRemoveUntil(context, route, (route) => false);
  }
}

enum PageTransitionType {
  fadeThrough,
  sharedAxisHorizontal,
  sharedAxisVertical,
  sharedAxisScaled,
  slideRight,
  slideUp,
  scale,
  material,
}
