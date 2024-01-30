
import 'package:flutter/material.dart';

import '../Classes/design_constants.dart';

class Switcher extends StatefulWidget {
  final bool defaultVal;
  final Function(bool val) callback;
  const Switcher({super.key, this.defaultVal = false, required this.callback});

  @override
  State<Switcher> createState() => _SwitcherState();
}

class _SwitcherState extends State<Switcher>with SingleTickerProviderStateMixin {
  late bool active;
  late AnimationController controller;
  late Animation hanyakaAnimation;

  @override
  void initState() {
    super.initState();
    active = widget.defaultVal;
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    hanyakaAnimation = CurvedAnimation(parent: controller, curve: Curves.easeOut , reverseCurve: Curves.easeIn);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void runAnimations()async{
    await controller.forward();
    await controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        runAnimations();
        setState(() {
          active = !active;
        });
        widget.callback.call(active);
      },
      child: LayoutBuilder(
        builder: (context, constraints) => AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuad,
          decoration: BoxDecoration(
            color:active? Design.activeColor : Design.mainColor,
            borderRadius: BorderRadius.circular(constraints.maxHeight),
          ),
          width:  constraints.maxHeight * 1.75,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: AnimatedAlign(
              alignment: active ? Alignment.centerRight : Alignment.centerLeft,
              curve: Curves.easeOutBack,
              duration: const Duration(milliseconds: 400),
              child: AnimatedBuilder(
                animation: hanyakaAnimation,
                builder: (context, child) => Transform.scale(
                  scale: 1.0 - (hanyakaAnimation.value * .25),
                  child: child,
                ),
                child: Container(
                  height: constraints.maxHeight ,
                  width: constraints.maxHeight,
                  decoration:
                  const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}