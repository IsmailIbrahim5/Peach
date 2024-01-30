import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';




class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // home: Scaffold(body: SuperCoolColumn(children: [], controller: SuperCoolColumnController(),)),
      home: RecordDemo()
    );
  }
}

//
class RecordDemo extends StatefulWidget {
  const RecordDemo({super.key});

  @override
  State<RecordDemo> createState() => _RecordDemoState();
}

class _RecordDemoState extends State<RecordDemo> {

  RecorderController controller = RecorderController();


  @override
  void initState() {
    super.initState();
    controller.sampleRate = 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [

            AnimatedBuilder(animation: controller
                , builder: (context, child) {
                  return Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withOpacity(controller.waveData.lastOrNull ?? 0)
                    ),
                  );
                },),
            AnimatedBuilder(
              animation: controller,
              builder:(context, child) => Container(
                width: MediaQuery.of(context).size.width,
                height: 200,
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(.5 + (controller.waveData.lastOrNull ?? 0) / 2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child:child,
              ),
              child:  AudioWaveforms(
                size: Size(MediaQuery.of(context).size.width, 200.0),
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                recorderController: controller,
                waveStyle: const WaveStyle(
                    waveColor: Colors.white,
                    spacing: 12.0,
                    extendWaveform: true,
                    showMiddleLine: false,
                    waveThickness: 8.0
                  //   gradient: ui.Gradient.linear(
                  //   const Offset(70, 50),
                  //   Offset(MediaQuery.of(context).size.width / 2, 0),
                  //   [Colors.red, Colors.green],
                  // ),
                ),
              ),
            ),

            SizedBox(height: 24,),
            GestureDetector(
              onTap: () async{
                print('??/');
                final hasPermission = await controller.checkPermission();

                print('start');
                if(hasPermission){
                  print('recording');
                  await controller.record();
                }else{
                }
              },
              child: Container(
                height: 100,
                width: 100,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 24,),
            GestureDetector(
              onTap: () async{
                if(controller.isRecording){
                  final path = await controller.stop();
                }
              },
              child: Container(
                height: 100,
                width: 100,
                color: Colors.black,
              ),
            )
          ],
        ),
      ),
    );
  }
}


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _offsetAnimation = List.generate(
      2,
          (index) => Tween<Offset>(
        begin: const Offset(0.0, 0.0),
        end: Offset(index == 0 ? 1 : -1, 0.0),
      ).animate(_controller),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  void _animate() {
    _controller.status == AnimationStatus.completed
        ? _controller.reverse()
        : _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flutter Demo Row Animation")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                BoxWidget(
                  callBack: _animate,
                  text: "1",
                  color: Colors.red,
                  position: _offsetAnimation[0],key: UniqueKey(),
                ),
                BoxWidget(
                  callBack: _animate,
                  text: "2",
                  color: Colors.blue,
                  position: _offsetAnimation[1], key: UniqueKey(),
                )
              ],
            ),
            MaterialButton(
              onPressed: _animate,
              child: const Text("Swap"),
            )
          ],
        ),
      ),
    );
  }
}

class BoxWidget extends StatelessWidget {
  final Animation<Offset> position;
  final Function callBack;
  final String text;
  final Color color;

  const BoxWidget(
      {required Key key, required this.position, required this.callBack, required this.text, required this.color})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: position,
      child: GestureDetector(
        onTap: () => callBack(),
        child: Container(
          margin: const EdgeInsets.all(10),
          height: 50,
          width: 50,
          color: color,
          child: Center(
            child: Container(
              height: 20,
              width: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Center(child: Text(text)),
            ),
          ),
        ),
      ),
    );
  }
}

class Test extends StatefulWidget {
  const Test({super.key});

  @override
  State<Test> createState() => _TestState();
}

class _TestState extends State<Test> {


  @override
  Widget build(BuildContext context) {
    return  const MaterialApp(
      home: OverlayTest()
    );
  }
}

class LTRB {
  double left;
  double top;
  double right;
  double bottom;

  LTRB(this.left, this.top, this.right, this.bottom);

  Offset readjust (Offset position , Size size){
    if(position.dx + (size.width / 2) > right){
      double diff = position.dx + (size.width / 2) - right;
      position = Offset(position.dx - diff, position.dy);
    }
    else if(position.dx - (size.width / 2) < left){
      double diff = left - position.dx - (size.width / 2);
      position = Offset(position.dx + diff, position.dy);
    }

    if(position.dy + size.height > bottom){
      position= Offset(position.dx, position.dy - size.height);
    }
    if(position.dy - size.height < top){
      position= Offset(position.dx, position.dy + size.height);
    }
    return position;
  }
}
class OverlayTest extends StatefulWidget {
  const OverlayTest({super.key});

  @override
  State<OverlayTest> createState() => _OverlayTestState();
}

class _OverlayTestState extends State<OverlayTest> {
  late OverlayEntry overlayEntry;



  Offset position = Offset.zero;
  Size size = const Size(175, 200);
  @override
  void initState() {
    super.initState();
    overlayEntry = OverlayEntry(builder: (context) {
      LTRB ltrb = LTRB(0, MediaQuery.of(context).padding.top, MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
      return Stack(
        children: [
          Positioned(
              left: position.dx - size.width / 2,
              top: position.dy - size.height,
              child: Container(color: Colors.yellow, height: size.height,  width: size.width,)),

        ],
      );
    },);
  }

  void removeHighlightOverlay() {
    overlayEntry.remove();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: GestureDetector(
            onTapUp: (details) {
              position = details.globalPosition;
              Overlay.of(context).insert(overlayEntry);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Helllo World!',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 40,
                      fontWeight: FontWeight.w900
                  ),
                ),
                const SizedBox(height: 50,),
                GestureDetector(
                  onTap: () => print('tf bro'),
                  child: const Text(
                    'Click Me!',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 40,
                        fontWeight: FontWeight.w900
                    ),
                  ),
                ),
              ],
            ),
          )
      ),
    );
  }
}
