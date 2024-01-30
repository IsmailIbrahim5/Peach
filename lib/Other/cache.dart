/*
class GradientBack extends StatefulWidget {
  final Widget child;
  final Listenable controller;
  const GradientBack(
      {super.key, required this.child, required this.controller});

  @override
  State<GradientBack> createState() => _GradientBackState();
}

class _GradientBackState extends State<GradientBack> {
  GlobalKey key = GlobalKey();
  Offset offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {});
    });
  }

  Offset getOffset() {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;
    return renderBox.localToGlobal(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        offset = getOffset();
        return ShaderMask(
            key: key,
            shaderCallback: (bounds) => chatGradient.createShader(
                Rect.fromLTRB(0, 0, screenSize.width, screenSize.height)
                    .translate(-offset.dx, -offset.dy)),
            child: child);
      },
      child: widget.child,
    );
  }
}

class CrazyColumn extends StatefulWidget {
  final List<CrazyColumnChild> children;
  const CrazyColumn({super.key, required this.children});

  @override
  State<CrazyColumn> createState() => _CrazyColumnState();
}

class _CrazyColumnState extends State<CrazyColumn> {
  @override
  Widget build(BuildContext context) {
    int totalFlex = 0;
    int topFlexes = 0;
    for (CrazyColumnChild child in widget.children) {
      totalFlex += child.flex;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        Size size = constraints.biggest;
        return Stack(
          children: List.generate(
            widget.children.length,
                (index) {
              topFlexes += widget.children[index].flex;
              return
                AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    width: size.width,
                    height: size.height * widget.children[index].flex / totalFlex,
                    top: ((topFlexes - widget.children[index].flex)  / totalFlex) * size.height,
                    child: widget.children[index].child);
            },
          ),
        );
      },
    );
  }
}

class CrazyColumnChild {
  final int flex;
  final Widget child;

  CrazyColumnChild({required this.flex, required this.child});
}



LinearGradient chatGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF6CAB),
      Color(0xFF7366FF),
    ]);

class EnterExitRoute extends PageRouteBuilder {
  final Widget enterPage;
  final Widget exitPage;
  EnterExitRoute({required this.exitPage, required this.enterPage})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              enterPage,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              Stack(
            children: <Widget>[
              SlideTransition(
                position: new Tween<Offset>(
                  begin: const Offset(0.0, 0.0),
                  end: const Offset(-1.0, 0.0),
                ).animate(animation),
                child: exitPage,
              ),
              SlideTransition(
                position: new Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: enterPage,
              )
            ],
          ),
        );
}

class LogoClipper extends CustomClipper<Path> {
  final double scale;
  final Offset translation;

  LogoClipper({
    required this.scale,
    this.translation = Offset.zero,
  });

  @override
  getClip(Size size) {
    double pivotX = size.width / 2 - (size.width / 2 * scale) + translation.dx;
    double pivotY = size.height / 2 - (size.width / 2 * scale) + translation.dy;
    size = Size(size.width, size.width) * scale;
    Path path_0 = Path();
    path_0.moveTo(size.width * 0.1443333, size.height * 0.7011667);
    path_0.cubicTo(
        size.width * 0.08333333,
        size.height * 0.6523333,
        size.width * 0.08333333,
        size.height * 0.6154167,
        size.width * 0.08333333,
        size.height * 0.4583333);
    path_0.cubicTo(
        size.width * 0.08333333,
        size.height * 0.3012500,
        size.width * 0.08333333,
        size.height * 0.2226667,
        size.width * 0.1443333,
        size.height * 0.1738333);
    path_0.cubicTo(
        size.width * 0.2054167,
        size.height * 0.1250000,
        size.width * 0.3035833,
        size.height * 0.1250000,
        size.width * 0.5000000,
        size.height * 0.1250000);
    path_0.cubicTo(
        size.width * 0.6964167,
        size.height * 0.1250000,
        size.width * 0.7945833,
        size.height * 0.1250000,
        size.width * 0.8555833,
        size.height * 0.1738333);
    path_0.cubicTo(
        size.width * 0.9166667,
        size.height * 0.2226667,
        size.width * 0.9166667,
        size.height * 0.3012500,
        size.width * 0.9166667,
        size.height * 0.4583333);
    path_0.cubicTo(
        size.width * 0.9166667,
        size.height * 0.6154167,
        size.width * 0.9166667,
        size.height * 0.6523333,
        size.width * 0.8555833,
        size.height * 0.7011667);
    path_0.cubicTo(
        size.width * 0.7946667,
        size.height * 0.7500000,
        size.width * 0.6964167,
        size.height * 0.7500000,
        size.width * 0.5000000,
        size.height * 0.7500000);
    path_0.cubicTo(
        size.width * 0.4496667,
        size.height * 0.7500000,
        size.width * 0.3827500,
        size.height * 0.7962500,
        size.width * 0.3178333,
        size.height * 0.8295833);
    path_0.cubicTo(
        size.width * 0.2787500,
        size.height * 0.8496667,
        size.width * 0.2582500,
        size.height * 0.8226667,
        size.width * 0.2549167,
        size.height * 0.8082500);
    path_0.cubicTo(
        size.width * 0.2510833,
        size.height * 0.7919167,
        size.width * 0.2579167,
        size.height * 0.7522500,
        size.width * 0.2500000,
        size.height * 0.7411667);
    path_0.cubicTo(
        size.width * 0.2429167,
        size.height * 0.7313333,
        size.width * 0.1708333,
        size.height * 0.7224167,
        size.width * 0.1443333,
        size.height * 0.7011667);

    final translateM = Float64List.fromList(
        [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, pivotX, pivotY, 0, 1]);

    return path_0.transform(translateM);
  }

  @override
  bool shouldReclip(covariant CustomClipper<dynamic> oldClipper) => true;
}

//Copy this CustomPainter code to the Bottom of the File
class RPSCustomPainter extends CustomPainter {
  final double scale;

  RPSCustomPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    Path path_0 = Path();
    path_0.moveTo(size.width * 0.1443333, size.height * 0.7011667);
    path_0.cubicTo(
        size.width * 0.08333333,
        size.height * 0.6523333,
        size.width * 0.08333333,
        size.height * 0.6154167,
        size.width * 0.08333333,
        size.height * 0.4583333);
    path_0.cubicTo(
        size.width * 0.08333333,
        size.height * 0.3012500,
        size.width * 0.08333333,
        size.height * 0.2226667,
        size.width * 0.1443333,
        size.height * 0.1738333);
    path_0.cubicTo(
        size.width * 0.2054167,
        size.height * 0.1250000,
        size.width * 0.3035833,
        size.height * 0.1250000,
        size.width * 0.5000000,
        size.height * 0.1250000);
    path_0.cubicTo(
        size.width * 0.6964167,
        size.height * 0.1250000,
        size.width * 0.7945833,
        size.height * 0.1250000,
        size.width * 0.8555833,
        size.height * 0.1738333);
    path_0.cubicTo(
        size.width * 0.9166667,
        size.height * 0.2226667,
        size.width * 0.9166667,
        size.height * 0.3012500,
        size.width * 0.9166667,
        size.height * 0.4583333);
    path_0.cubicTo(
        size.width * 0.9166667,
        size.height * 0.6154167,
        size.width * 0.9166667,
        size.height * 0.6523333,
        size.width * 0.8555833,
        size.height * 0.7011667);
    path_0.cubicTo(
        size.width * 0.7946667,
        size.height * 0.7500000,
        size.width * 0.6964167,
        size.height * 0.7500000,
        size.width * 0.5000000,
        size.height * 0.7500000);
    path_0.cubicTo(
        size.width * 0.4496667,
        size.height * 0.7500000,
        size.width * 0.3827500,
        size.height * 0.7962500,
        size.width * 0.3178333,
        size.height * 0.8295833);
    path_0.cubicTo(
        size.width * 0.2787500,
        size.height * 0.8496667,
        size.width * 0.2582500,
        size.height * 0.8226667,
        size.width * 0.2549167,
        size.height * 0.8082500);
    path_0.cubicTo(
        size.width * 0.2510833,
        size.height * 0.7919167,
        size.width * 0.2579167,
        size.height * 0.7522500,
        size.width * 0.2500000,
        size.height * 0.7411667);
    path_0.cubicTo(
        size.width * 0.2429167,
        size.height * 0.7313333,
        size.width * 0.1708333,
        size.height * 0.7224167,
        size.width * 0.1443333,
        size.height * 0.7011667);

    Paint paint_0_fill = Paint()..style = PaintingStyle.fill;
    paint_0_fill.color = const Color(0xff000000).withOpacity(1.0);
    canvas.drawPath(path_0, paint_0_fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}


class AnimatedTranslate extends StatefulWidget {
  final Offset offset;
  final Widget child;
  const AnimatedTranslate(
      {super.key, required this.offset, required this.child});

  @override
  State<AnimatedTranslate> createState() => _AnimatedTranslateState();
}

class _AnimatedTranslateState extends State<AnimatedTranslate>
    with SingleTickerProviderStateMixin {
  late Offset offset;
  late AnimationController controller;
  late Animation<Offset> animation;
  @override
  void initState() {
    super.initState();
    offset = widget.offset;
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    animation =
        Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(controller);
    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (offset != widget.offset) {
      animation = Tween<Offset>(begin: animation.value, end: widget.offset)
          .animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutQuad));
      controller.forward(from: 0);
      offset = widget.offset;
    }
    return Transform.translate(
      offset: animation.value,
      child: widget.child,
    );
  }
}
 */