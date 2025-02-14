// lib/core/widgets/flipping_card_image.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

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
  bool _hasAnimated = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: math.pi,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _animation.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        _isAnimating = true;
      } else if (status == AnimationStatus.completed) {
        _isAnimating = false;
        _hasAnimated = true;
        widget.onAnimationComplete?.call();
      }
    });

    _animation.addListener(() {
      if (_animation.value <= math.pi / 2 && _showFrontSide && _isAnimating) {
        setState(() {
          _showFrontSide = false;
        });
      }
    });

    // Only start animation if we haven't animated before
    if (!_hasAnimated) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FlippingCardImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the key changed but we're already animated, don't animate again
    if (widget.key != oldWidget.key && !_hasAnimated && !_isAnimating) {
      _controller.forward();
    }
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
          ..setEntry(3, 2, 0.001) // Perspective
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
