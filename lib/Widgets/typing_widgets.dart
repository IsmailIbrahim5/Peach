import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter/scheduler.dart';

import '../Classes/design_constants.dart';



class ChatTyping extends StatefulWidget {
  final int shapeType;
  const ChatTyping({super.key, required this.shapeType});

  @override
  State<ChatTyping> createState() => _ChatTypingState();
}

class _ChatTypingState extends State<ChatTyping>
    with TickerProviderStateMixin {
  static const Radius hardEdge = Radius.circular(8.0);
  static const Radius softEdge = Radius.circular(48.0);
  late AnimationController controller;
  late AnimationController cursorController;
  late Animation<double> cursorAnimation;

  String content = '';
  String emoji = '';

  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890 ';
  final _rnd = Random();

  final _emojis =
      '😀 😃 😄 😁 😆 😅 😂 🤣 ☺️ 😊 😇 🙂 🙃 😉 😌 😍 🥰 😘 😗 😙 😚 😋 😛 😝 😜 🤪 🤨 🧐 🤓 😎 🤩 🥳 😏 😒 😞 😔 😟 😕 🙁 ☹️ 😣 😖 😫 😩 🥺 😢 😭 😮‍💨 😤 😠 😡 🤬 🤯 😳 🥵 🥶 😱 😨 😰 😥 😓 🤗 🤔 🤭 🤫 🤥 😶 😶‍🌫️ 😐 😑 😬 🙄 😯 😦 😧 😮 😲 🥱 😴 🤤 😪 😵 😵‍💫 🤐 🥴 🤢 🤮 🤧 😷 🤒 🤕 🤑 🤠 😈 👿 👹 👺 🤡 💩 👻 💀 ☠️ 👽 👾 🤖 🎃 😺 😸 😹 😻 😼 😽 🙀 😿 😾';

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String getRandomEmoji() =>
      _emojis.split(' ').elementAt(_rnd.nextInt(_emojis.split(' ').length));

  @override
  void dispose() {
    controller.dispose();
    cursorController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
        reverseDuration: const Duration(milliseconds: 500));
    cursorController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    cursorAnimation = CurvedAnimation(
        parent: cursorController,
        curve: Curves.easeOutQuad,
        reverseCurve: Curves.easeInQuad);
    cursorController.repeat(reverse: true);
    triggerAnimation();
  }

  void triggerAnimation() async {
    while (mounted) {
      try {
        content = getRandomString(_rnd.nextInt(10) + 10);
        emoji = getRandomEmoji();
        await controller.forward();
        await Future.delayed(const Duration(seconds: 2));
        await controller.reverse();
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        //
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    BorderRadius shape0 = const BorderRadius.only(
        topLeft: softEdge,
        topRight: softEdge,
        bottomLeft: hardEdge,
        bottomRight: softEdge);
    BorderRadius shape1 = const BorderRadius.only(
        topLeft: hardEdge,
        topRight: softEdge,
        bottomLeft: softEdge,
        bottomRight: softEdge);

    BorderRadius shape = widget.shapeType == 0 ? shape0 : shape1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: shape,
                    boxShadow: [Design.shadow3]
                  ),
                  padding: const EdgeInsets.all(18.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: controller,
                        builder: (context, child) {
                          List<String> separated = content
                              .substring(0,
                                  (controller.value * content.length).toInt())
                              .split(' ');
                          return Row(
                            children: [
                              ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                    Design.mainColor.withOpacity(.5), BlendMode.srcIn),
                                child: Row(
                                  children: List.generate(
                                    separated.length,
                                    (index) => Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4.0),
                                      child: Text(
                                        separated[index],
                                        style: const TextStyle(
                                          color: Color(0xFF28355b),
                                          fontSize: 12.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                child: AnimatedDefaultTextStyle(
                                  duration: controller.value == 1
                                      ? const Duration(milliseconds: 500)
                                      : const Duration(milliseconds: 250),
                                  curve: controller.value == 1
                                      ? Curves.easeOutBack
                                      : Curves.easeOut,
                                  style: TextStyle(
                                    fontSize:
                                        controller.value == 1 ? 18.0 : 0.0,
                                      fontFamily: 'NotoColorEmoji'
                                  ),
                                  child: Text(
                                    emoji,
                                  ),
                                ),
                              )
                            ],
                          );
                        },
                      ),
                      Transform.translate(
                          offset: const Offset(-2.0, 0.0),
                          child: FadeTransition(
                            opacity: cursorAnimation,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white54,
                                  borderRadius: BorderRadius.circular(3)),
                              height: 20,
                              width: 3.0,
                            ),
                          ))
                    ],
                  )),
            ),
          ),
          const Spacer(
            flex: 1,
          )
        ],
      ),
    );
  }


}

class Typing extends StatefulWidget {
  const Typing({super.key});

  @override
  State<Typing> createState() => _TypingState();
}

class _TypingState extends State<Typing>{
  late Ticker ticker;

  double t = 0.0;
  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    ticker = Ticker((elapsed) {
      setState(() {
        setState(() {
          t = elapsed.inMilliseconds / const Duration(milliseconds: 400).inMilliseconds;
        });
      });
    });
    ticker.start();
  }


  double _curve(double t ){
    if(t.toInt() % 2 == 0){
      t %= 1;
      return (t-1)*(0.5-t)*2+1;
    }else{
      t %= 1;
      return (t-1)*(t-0.5)*2;
    }
  }


  List<Color> colors = [
    const Color(0xFFFF7339),
    const Color(0xFF009CFF),
    const Color(0xFFFFB500)
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return FractionalTranslation(
          translation: Offset(0.0, -_curve(t + 0.3 * index) ),
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
              height: 8.0,
              width: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[(((t + .1 * index).toInt() /  2) % 3).toInt()])),
        );
      }).reversed.toList(),
    );
  }
}

