import 'package:flutter/material.dart';

class CrossFadeSwitcher extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool next;
  final Axis direction;
  final double factor;
  const CrossFadeSwitcher(
      {super.key,
        required this.child,
        this.duration = const Duration(milliseconds: 400),
        required this.next, this.direction = Axis.horizontal, this.factor = 1.0});

  @override
  State<CrossFadeSwitcher> createState() => _CrossFadeSwitcherState();
}

class _CrossFadeSwitcherState extends State<CrossFadeSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;
  late Widget child;

  @override
  void initState() {
    super.initState();
    child = widget.child;
    controller = AnimationController(vsync: this, duration: widget.duration)..value = 1.0;
    animation = CurvedAnimation(parent: controller, curve: Curves.ease);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void animate() async {
    await controller.forward(from: 0);
    setState(() {
      child = widget.child;
    });
  }


  @override
  Widget build(BuildContext context) {

    if (widget.child.key != child.key) {
      animate();
    } else {
      child = widget.child;
    }
    return Stack(
      children: [
        if(child != widget.child)
          SlideTransition(
            key: const ValueKey('old_widget'),
            position: Tween<Offset>(
              begin: Offset.zero,
              end: Offset(widget.direction == Axis.horizontal ? (widget.next ? 1.0 : -1.0)* widget.factor : 0.0, widget.direction == Axis.vertical ? (widget.next ? 1.0 : -1.0)* widget.factor : 0.0),
            ).animate(animation),
            child: FadeTransition(
                opacity: Tween<double>(begin: 1.0 , end: 0.0).animate(animation),
                child: child),
          ),
        SlideTransition(
          key: const ValueKey('new_widget'),
          position: Tween<Offset>(
            begin: Offset(widget.direction == Axis.horizontal ? (widget.next ? -1.0 : 1.0) * widget.factor : 0.0, widget.direction == Axis.vertical ? (widget.next ? -1.0 : 1.0)* widget.factor : 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: widget.child),
        ),
      ],
    );
  }
}