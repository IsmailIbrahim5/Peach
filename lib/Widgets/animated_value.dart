
import 'package:flutter/material.dart';

class AnimatedValue extends StatefulWidget {
  final dynamic val;
  final Widget Function(dynamic val) builder;
  final Duration duration;
  final Curve curve;
  const AnimatedValue({super.key, required this.val, required this.builder, required this.duration, this.curve = Curves.linear});

  @override
  State<AnimatedValue> createState() => _AnimatedValueState();
}

class _AnimatedValueState extends State<AnimatedValue> with SingleTickerProviderStateMixin{
  late dynamic val;
  late AnimationController controller;
  late Animation<dynamic> animation;


  @override
  void initState() {
    super.initState();
    val = widget.val;
    controller = AnimationController(vsync: this, duration: widget.duration);

    if(widget.val is Color) {
      animation = ColorTween(begin:val , end: val).animate(CurvedAnimation(parent: controller, curve: widget.curve));
    } else {
      animation = Tween<dynamic>(begin:val , end: val).animate(CurvedAnimation(parent: controller, curve: widget.curve));
    }
  }


  @override
  Widget build(BuildContext context) {
    if(val != widget.val){
      if(widget.val is Color){
        animation = ColorTween(begin: val , end: widget.val).animate(CurvedAnimation(parent: controller, curve: widget.curve));
      }else {
        animation = Tween<dynamic>(begin: val, end: widget.val).animate(
            CurvedAnimation(parent: controller, curve: widget.curve));
      }
      val = widget.val;
      controller.forward(from: 0);
    }
    return AnimatedBuilder(
        animation: animation,
        builder: (context, child) =>  widget.builder(animation.value));
  }
}
