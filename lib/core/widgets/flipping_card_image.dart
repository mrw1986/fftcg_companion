// lib/core/widgets/flipping_card_image.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

class FlippingCardImage extends StatefulWidget {
  final Widget frontWidget;
  final Widget backWidget;
  static const defaultDuration = Duration(milliseconds: 300);
  final Duration duration;
  final VoidCallback? onAnimationComplete;

  const FlippingCardImage({
    super.key,
    required this.frontWidget,
    required this.backWidget,
    this.duration = defaultDuration,
    this.onAnimationComplete,
  });

  @override
  State<FlippingCardImage> createState() => _FlippingCardImageState();
}

class _FlippingCardImageState extends State<FlippingCardImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFrontSide = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ))
      ..addListener(() {
        if (_animation.value >= math.pi / 2) {
          setState(() => _showFrontSide = false);
        }
      });

    _controller.forward().then((_) {
      widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(_animation.value);

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: _showFrontSide ? widget.frontWidget : widget.backWidget,
        );
      },
    );
  }
}
