import 'package:flutter/material.dart';

class BreathingDot extends StatefulWidget {
  final Color color;
  final double minSize;
  final double maxSize;
  final Duration duration;

  const BreathingDot({
    super.key,
    this.color = Colors.blue,
    this.minSize = 8.0,
    this.maxSize = 16.0,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  BreathingDotState createState() => BreathingDotState();
}

class BreathingDotState extends State<BreathingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();

    // Create an animation controller with the given duration.
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Tween for size: animate from minSize to maxSize.
    _sizeAnimation = Tween<double>(
      begin: widget.minSize,
      end: widget.maxSize,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Loop the animation: reverse when complete, then forward again.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });

    // Start the animation.
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sizeAnimation,
      builder: (context, child) {
        return Container(
          width: _sizeAnimation.value,
          height: _sizeAnimation.value,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
