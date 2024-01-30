
import 'package:flutter/material.dart';
import 'package:peach/Screens/opened_chat_room.dart';

import '../main.dart';

class AnimatedListItem{
  final Widget widget;
  final Key key;

  AnimatedListItem(this.widget, this.key);
}

class AnimatedListBgd extends StatefulWidget {
  final List<AnimatedListItem> children;
  final double childrenHeight;
  final ScrollController? scrollController;
  final EdgeInsets padding;
  final Duration startingDelay;
  const AnimatedListBgd({super.key, required this.children, required this.childrenHeight, this.scrollController, this.padding  = const EdgeInsets.symmetric(vertical: 16.0), this.startingDelay =  Duration.zero});

  @override
  State<AnimatedListBgd> createState() => _AnimatedListBgdState();
}

class _AnimatedListBgdState extends State<AnimatedListBgd> {
  late List<AnimatedListItem> children;
  int buildTime = 0;

  List<AnimatedListItem> removedChildren = [];
  List<AnimatedListItem> addedChildren = [];

  double childHeight = 0.0;
  double skippers = 0.0;

  @override
  void initState() {
    super.initState();
    children = widget.children;
    childHeight = widget.childrenHeight;
  }

  void checkForDifferences(){
    removedChildren = children.where((oldChild) => widget.children.where((newChild) => newChild.key == oldChild.key).firstOrNull == null).toList();
    addedChildren = widget.children.where((newChild) => children.where((oldChild) => newChild.key == oldChild.key).firstOrNull == null).toList();

    children.sort((a, b)  {
      int index1 = widget.children
          .indexWhere((element) => element.key == a.key);
      if(index1 == -1){
        index1 = children.indexOf(a);
      }
      int index2 = widget.children
          .indexWhere((element) => element.key == b.key);
      if(index2 == -1){
        index2 = children.indexOf(b);
      }
      return index1.compareTo(index2);
        });
    for(AnimatedListItem item in addedChildren){
      children.insert(widget.children.indexOf(item), item);
    }
  }


  @override
  Widget build(BuildContext context) {
    checkForDifferences();
    skippers = 0.0;
    buildTime ++;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      controller: widget.scrollController,
      padding: widget.padding,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        height: (children.length - removedChildren.length) * (childHeight)   ,
        onEnd: (){
          children.removeWhere((original) => removedChildren.where((removed) => removed.key == original.key).firstOrNull != null);
        },
        child: Stack(
          children: List.generate(
              children.length  ,
                  (index)
              {
                int animationType = -1;
                if(removedChildren.contains(children[index])){
                  skippers += childHeight;
                  animationType = 2;
                }
                if(addedChildren.contains(children[index])){
                  animationType = 0;
                }
                if(buildTime == 1 && index < 5){
                  animationType = 1;
                }

                return AnimatedPositioned(
                  key: children[index].key,
                  height: childHeight,
                  top: childHeight * index - (removedChildren.contains(children[index]) ? 0.0 : skippers),
                  left: 24.0,
                  right: 24.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  child: ShowAnimation( animation: animationType, delay: Duration(milliseconds: 200 * index) + widget.startingDelay,child: children[index].widget),
                );
              }
          ),
        ),
      ),
    );
  }
}



class ShowAnimation extends StatefulWidget {
  final Widget child;
  final int animation;
  final Duration delay;
  const ShowAnimation({
    required this.child,
    required this.animation,
    required this.delay,
    super.key,
  });

  @override
  State<ShowAnimation> createState() => _ShowAnimationState();
}

class _ShowAnimationState extends State<ShowAnimation> with SingleTickerProviderStateMixin{
  late AnimationController controller;
  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }


  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void startAnimation()async {

    if(widget.animation == 1) {
      await Future.delayed(widget.delay);
    }
    if(mounted) {
      controller.forward(from: 0);
    }
  }


  @override
  Widget build(BuildContext context) {
    Curve easeOutBack = Curves.easeOutBack;
    Curve easeOut = Curves.easeOut;
    startAnimation();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Opacity(
          opacity: widget.animation == -1 ? 1.0:(widget.animation == 2 ? 1 - easeOut.transform(controller.value) : easeOut
              .transform(controller.value)),
          child: Transform.translate(
              offset: widget.animation == -1 ? Offset.zero :(widget.animation == 1
                  ? Offset(0, (1 - easeOutBack.transform(controller.value)) * 100)
                  : Offset((widget.animation == 0
                  ? (1 - easeOut.transform(controller.value))
                  :  easeOut.transform(controller.value)) * MediaQuery.sizeOf(context).width, 0)) ,
              child:child),
        );
      },
      child:  widget.child,
    );
  }
}


