import 'package:flutter/material.dart';

/// Animation constants for consistent motion design.
class AppAnimations {
  // Durations
  static const Duration instant = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration pageTransition = Duration(milliseconds: 300);

  // Curves
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve emphasis = Curves.easeInOutCubic;
  static const Curve overshoot = Curves.easeOutBack;
  static const Curve bounce = Curves.elasticOut;
  static const Curve sharp = Curves.easeInOutQuart;
  static const Curve decelerate = Curves.decelerate;

  /// Standard fade + slide up animation for list items.
  static Widget fadeSlideIn({
    required Widget child,
    required Animation<double> animation,
    double offsetY = 20,
  }) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: defaultCurve,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, offsetY / 100),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: defaultCurve,
        )),
        child: child,
      ),
    );
  }

  /// Scale animation for buttons and interactive elements.
  static Widget scaleOnTap({
    required Widget child,
    required bool isPressed,
    double scale = 0.95,
  }) {
    return AnimatedScale(
      scale: isPressed ? scale : 1.0,
      duration: fast,
      curve: defaultCurve,
      child: child,
    );
  }
}

/// Mixin for staggered list animations.
mixin StaggeredAnimationMixin<T extends StatefulWidget> on State<T>
    implements TickerProvider {
  late AnimationController _staggerController;
  final List<Animation<double>> _itemAnimations = [];

  void initStaggeredAnimation({
    required int itemCount,
    Duration itemDelay = const Duration(milliseconds: 50),
    Duration itemDuration = const Duration(milliseconds: 300),
  }) {
    final totalDuration = itemDuration +
        Duration(milliseconds: itemDelay.inMilliseconds * itemCount);

    _staggerController = AnimationController(
      vsync: this,
      duration: totalDuration,
    );

    _itemAnimations.clear();
    for (int i = 0; i < itemCount; i++) {
      final startTime = itemDelay.inMilliseconds * i / totalDuration.inMilliseconds;
      final endTime = startTime +
          itemDuration.inMilliseconds / totalDuration.inMilliseconds;

      _itemAnimations.add(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            startTime.clamp(0.0, 1.0),
            endTime.clamp(0.0, 1.0),
            curve: AppAnimations.defaultCurve,
          ),
        ),
      );
    }

    _staggerController.forward();
  }

  Animation<double> getItemAnimation(int index) {
    if (index >= 0 && index < _itemAnimations.length) {
      return _itemAnimations[index];
    }
    return const AlwaysStoppedAnimation(1.0);
  }

  void disposeStaggeredAnimation() {
    _staggerController.dispose();
  }
}

/// Implicit animation wrapper for common transitions.
class AnimatedAppear extends StatelessWidget {
  const AnimatedAppear({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppAnimations.normal,
    this.curve = AppAnimations.defaultCurve,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: curve,
      builder: (context, value, child) {
        // Account for delay
        final adjustedValue = delay.inMilliseconds > 0
            ? ((value - delay.inMilliseconds / (duration + delay).inMilliseconds) /
                    (duration.inMilliseconds / (duration + delay).inMilliseconds))
                .clamp(0.0, 1.0)
            : value;

        return Opacity(
          opacity: adjustedValue,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - adjustedValue)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Page route with custom transition.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required Widget page,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: AppAnimations.pageTransition,
          reverseTransitionDuration: AppAnimations.pageTransition,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: AppAnimations.defaultCurve,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}
