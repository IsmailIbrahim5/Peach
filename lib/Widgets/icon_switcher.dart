import 'package:flutter/material.dart';
import 'dart:math' as math;

class IconSwitcher extends StatefulWidget {
  final Widget icon;
  const IconSwitcher({super.key, required this.icon});

  @override
  State<IconSwitcher> createState() => _IconSwitcherState();
}

class _IconSwitcherState extends State<IconSwitcher> with SingleTickerProviderStateMixin{

  late AnimationController controller;
  late Animation<double> animation;

  late Widget icon;

  @override
  void initState() {
    super.initState();
    icon  = widget.icon;
    controller = AnimationController(vsync: this , duration: const Duration(milliseconds: 400));
    animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(icon.key != widget.icon.key){
      controller.forward(from: 0);
    }
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        if(animation.value >= .5) icon = widget.icon;
        double alpha = ((.5 - animation.value) * 2).abs();
        double rotation = animation.value * math.pi * 2;
        return Opacity(opacity: alpha , child: Transform.rotate(angle: rotation, child: icon,));
      },
    );
  }
}