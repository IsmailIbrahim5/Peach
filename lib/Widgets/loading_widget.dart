
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../Classes/design_constants.dart';

class LoadingWidget extends StatefulWidget {
  final Color color;
  final double size;
  final int number;
  const LoadingWidget({super.key, this.color = Colors.white, this.size = 32.0, this.number = 4});

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>{
  late Ticker ticker;
  double t = 0.0;


  @override
  void initState() {
    super.initState();
    ticker = Ticker(
          (elapsed) {
        setState(() {
          t = elapsed.inMilliseconds / const Duration(seconds: 2).inMilliseconds;
        });
      },
    );
    ticker.start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  double correctedValue(double val) {
    val %= 1;
    if (val > 1.0) return 1 - (val - 1);
    if (val < 0.0) return -val;
    return val;
  }

  @override
  Widget build(BuildContext context) {
    Curve easeOutBack = Curves.bounceOut;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.number, (index) {
        double val = correctedValue(t + 0.05 * index);

        return FractionalTranslation(
          translation:
          Offset(0.0, easeOutBack.transform(val) >= .5 ? -10.0 : 0.0),
          child: FractionalTranslation(
            translation: Offset(0.0, (easeOutBack.transform(val)) * 10),
            child: Opacity(
              opacity: _alpha(_bounce(val).clamp(0, 1)),
              child: Container(
                  height: widget.size,
                  width: widget.size,
                  margin:  EdgeInsets.symmetric(horizontal: widget.size / 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [Design.shadow1],
                    color: widget.color,
                    // border: Border.all(color: Colors.white , width: 1.0),
                  )),
            ),
          ),
        );
      }).reversed.toList(),
    );
  }

  double _bounce(double t) {
    return 7.5625 * t * t;
  }

  double _alpha(double t){
    return (-2 * t + 1).abs();
  }
}


