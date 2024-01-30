import 'dart:math';

import 'package:flutter/material.dart';
import 'package:peach/Classes/main_provider.dart';
import 'package:provider/provider.dart';
import '../Classes/chat_room.dart';
import '../Classes/design_constants.dart';
import '../Screens/opened_chat_room.dart';
import '../Widgets/chat_room_widgets.dart';
import '../main.dart';
import '../Widgets/sequence_animation_builder.dart';
import 'dart:math' as math;


class MessagesPage extends StatefulWidget {
  final SequenceAnimationController controller;

  const MessagesPage({super.key, required this.controller});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {

  SequenceAnimationController builderController = SequenceAnimationController();

  ChatRoom? clickedChatRoom;

  int buildTime = 0;

  @override
  Widget build(BuildContext context) {
    buildTime++;

    final provider =  Provider.of<MainProvider>(context , listen: false);
    return SafeArea(
      child:
      SequenceAnimationBuilder(
        animations: 6,
        repeat: false,
        duration: const Duration(milliseconds: 600),
        controller: builderController,
        curve: Curves.easeOutBack,
        endCallback: (){
          Navigator.of(context).push(PageRouteBuilder(
              transitionDuration: Duration.zero,

              pageBuilder: (context, animation, secondaryAnimation) => OpenedChatRoom(chatRoom: clickedChatRoom!,key: const ValueKey('openedChatRoom'),)
          ));
        },
        builder: (values, [child]) {
         provider.refreshMain = (){
            widget.controller.forward!();
            builderController.forward!();
          };
          openChatAnimation = (ChatRoom chatRoom){
            setState(() {
              clickedChatRoom = chatRoom;
            });
            widget.controller.reverse!();
            builderController.reverse!();
          };
          return Column(
            children: [
              Expanded(
                flex: 2,
                child: UpwardCrossFade(
                  value: values[0],
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child:  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'MESSAGES',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 52.0,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Inter'),
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                flex: 15,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                   UpwardCrossFade(
                       value: buildTime == 1 ? 1.0 : values[2] ,
                       limit: .5,
                       child: child!),

                    UpwardCrossFade(
                      value: values[1],
                      child: Container(
                        height: provider.screenSize.height * .07,
                        margin: const EdgeInsets.symmetric(horizontal: 24.0),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24.0),
                            boxShadow: [
                              Design.shadow1
                            ]
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Search In Conversations...',
                                    hintStyle: TextStyle(
                                        color: Design.mainColor.withOpacity(.75),
                                        fontFamily: 'Inter',
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w500
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 20.0),
                                  ),
                                  style: TextStyle(
                                      color: Design.mainColor.withOpacity(.75),
                                      fontFamily: 'Inter',
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w400
                                  ),
                                ),
                              ),
                            ),
                            Image.asset('images/search.png' , color: Design.mainColor.withOpacity(.75), width: 28.0 , height: 28.0,)
                          ],
                        ),
                      ),
                    ),


                  ],
                ),
              ),


            ],
          );
        },
        child:  ChatRoomsList(
          onClick: (ChatRoom chatRoom){
            openChatAnimation!(chatRoom);
          },
        ),
      ),
    );
  }
}

class BackgroundPainter extends StatefulWidget {
  final int count;
  final double size;
  final Color color;
  const BackgroundPainter({super.key, required this.count, required this.size, required this.color});

  @override
  State<BackgroundPainter> createState() => _BackgroundPainterState();
}

class _BackgroundPainterState extends State<BackgroundPainter> {
  List<Rect> positions= [];
  List<double> rotations= [];
  Random rnd = Random();


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if(positions.isEmpty) {
          for (int i = 0; i < widget.count; i++) {
            bool notValid = true;
            Rect position = Rect.zero;
            while (notValid) {
              notValid = false;
              position = Rect.fromCenter(center: Offset(
                  rnd.nextDouble() * constraints.maxWidth,
                  rnd.nextDouble() * constraints.maxHeight),
                  width: widget.size,
                  height: widget.size * 1.2094972271671687);
              for (int x = 0; x < positions.length; x++) {
                if (position.overlaps(positions[x])) {
                  notValid = true;
                  break;
                }
              }
            }
            positions.add(position);
            rotations.add( math.pi * 2 * rnd.nextDouble());
          }
        }
        return Stack(
          children: List.generate(positions.length, (index) {
            return Positioned.fromRect(
              rect: positions[index],
              child: Transform.rotate(
                angle: rotations[index],
                child:  CustomPaint(
                  size: Size(widget.size, (widget.size*1.2094972271671687).toDouble()), //You can Replace [WIDTH] with your desired width for Custom Paint and height will be calculated automatically
                  painter: PeachPainter(color: widget.color),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}



class PeachPainter extends CustomPainter {

  final Color color;

  PeachPainter({required this.color});

  @override
void paint(Canvas canvas, Size size) {

Path path_0 = Path();
path_0.moveTo(0,0);
path_0.lineTo(size.width*0.05713281,size.height*0.009583283);
path_0.lineTo(size.width*0.1150934,size.height*0.01300606);
path_0.lineTo(size.width*0.2003787,size.height*0.01095276);
path_0.cubicTo(size.width*0.2691955,size.height*0.002379164,size.width*0.3588280,size.height*0.01212780,size.width*0.3999289,size.height*0.03217323);
path_0.cubicTo(size.width*0.4630777,size.height*0.06297093,size.width*0.4856032,size.height*0.1152556,size.width*0.5117104,size.height*0.1772974);
path_0.cubicTo(size.width*0.3986726,size.height*0.1783016,size.width*0.3034812,size.height*0.1492835,size.width*0.2227350,size.height*0.1204833);
path_0.lineTo(size.width*0.1523542,size.height*0.09241732);
path_0.lineTo(size.width*0.1523542,size.height*0.09310176);
path_0.cubicTo(size.width*0.1715933,size.height*0.1113174,size.width*0.2051808,size.height*0.1229503,size.width*0.2310147,size.height*0.1355427);
path_0.cubicTo(size.width*0.3032080,size.height*0.1707335,size.width*0.3910595,size.height*0.1993489,size.width*0.4959781,size.height*0.2060503);
path_0.cubicTo(size.width*0.4880955,size.height*0.2144785,size.width*0.4748262,size.height*0.2201339,size.width*0.4636858,size.height*0.2259019);
path_0.cubicTo(size.width*0.4056893,size.height*0.2559243,size.width*0.3165205,size.height*0.2740157,size.width*0.2351553,size.height*0.2478019);
path_0.cubicTo(size.width*0.1316411,size.height*0.2144518,size.width*0.06586449,size.height*0.1501987,size.width*0.02401266,size.height*0.06571775);
path_0.cubicTo(size.width*0.01446928,size.height*0.04645185,size.width*0.003030703,size.height*0.02354270,0,0);
path_0.close();
path_0.moveTo(size.width*0.6864208,size.height*0.03080436);
path_0.cubicTo(size.width*0.7054490,size.height*0.03129921,size.width*0.7394783,size.height*0.06078922,size.width*0.7269935,size.height*0.07735251);
path_0.cubicTo(size.width*0.7163784,size.height*0.09143852,size.width*0.6768848,size.height*0.1153295,size.width*0.6599247,size.height*0.1266390);
path_0.cubicTo(size.width*0.6045713,size.height*0.1635530,size.width*0.5613921,size.height*0.2265045,size.width*0.5589071,size.height*0.3059849);
path_0.cubicTo(size.width*0.5414672,size.height*0.3098613,size.width*0.5383090,size.height*0.3085288,size.width*0.5208186,size.height*0.3059849);
path_0.cubicTo(size.width*0.5183124,size.height*0.1977832,size.width*0.5702761,size.height*0.1381157,size.width*0.6268038,size.height*0.07940642);
path_0.cubicTo(size.width*0.6437631,size.height*0.06179285,size.width*0.6632821,size.height*0.04321623,size.width*0.6864208,size.height*0.03080436);
path_0.close();
path_0.moveTo(size.width*0.3982733,size.height*0.3203628);
path_0.cubicTo(size.width*0.4223416,size.height*0.3200981,size.width*0.4484832,size.height*0.3185778,size.width*0.4694805,size.height*0.3224161);
path_0.cubicTo(size.width*0.5808876,size.height*0.3427832,size.width*0.6568815,size.height*0.4285942,size.width*0.6955276,size.height*0.5106657);
path_0.cubicTo(size.width*0.7069215,size.height*0.5348619,size.width*0.7110188,size.height*0.5620285,size.width*0.7170560,size.height*0.5907565);
path_0.cubicTo(size.width*0.7270653,size.height*0.6383907,size.width*0.7090745,size.height*0.6840721,size.width*0.7038072,size.height*0.7221884);
path_0.lineTo(size.width*0.7046358,size.height*0.7221884);
path_0.cubicTo(size.width*0.7049112,size.height*0.7217280,size.width*0.7051874,size.height*0.7212738,size.width*0.7054636,size.height*0.7208195);
path_0.cubicTo(size.width*0.7196904,size.height*0.7017341,size.width*0.7218003,size.height*0.6731514,size.width*0.7278199,size.height*0.6482574);
path_0.cubicTo(size.width*0.7551394,size.height*0.5352302,size.width*0.6958265,size.height*0.4311090,size.width*0.6408790,size.height*0.3710200);
path_0.cubicTo(size.width*0.6254016,size.height*0.3540951,size.width*0.6049589,size.height*0.3413374,size.width*0.5878860,size.height*0.3258407);
path_0.cubicTo(size.width*0.7894845,size.height*0.3012635,size.width*0.9150348,size.height*0.3806784,size.width*0.9712534,size.height*0.4942350);
path_0.cubicTo(size.width*0.9923298,size.height*0.5367977,size.width*1.009150,size.height*0.6057844,size.width*0.9944397,size.height*0.6660509);
path_0.cubicTo(size.width*0.9879563,size.height*0.6926287,size.width*0.9821835,size.height*0.7181769,size.width*0.9712534,size.height*0.7413507);
path_0.cubicTo(size.width*0.9071376,size.height*0.8773592,size.width*0.7394563,size.height*0.9707208,size.width*0.5456591,size.height*0.9994246);
path_0.cubicTo(size.width*0.5272712,size.height*1.002144,size.width*0.5044409,size.height*0.9947184,size.width*0.4901819,size.height*0.9912053);
path_0.cubicTo(size.width*0.4409258,size.height*0.9790915,size.width*0.3978850,size.height*0.9670745,size.width*0.3568727,size.height*0.9494488);
path_0.cubicTo(size.width*0.2354446,size.height*0.8972683,size.width*0.1433822,size.height*0.8319746,size.width*0.1001890,size.height*0.7146578);
path_0.cubicTo(size.width*0.08663619,size.height*0.6778498,size.width*0.07402328,size.height*0.6224833,size.width*0.08445675,size.height*0.5743259);
path_0.cubicTo(size.width*0.08906617,size.height*0.5530491,size.width*0.09239577,size.height*0.5322950,size.width*0.1001890,size.height*0.5134022);
path_0.cubicTo(size.width*0.1331414,size.height*0.4335179,size.width*0.1966155,size.height*0.3714973,size.width*0.2889761,size.height*0.3409007);
path_0.cubicTo(size.width*0.3115565,size.height*0.3334204,size.width*0.3359347,size.height*0.3285227,size.width*0.3618411,size.height*0.3237874);
path_0.close();


Paint paint_0_fill = Paint()..style=PaintingStyle.fill;
paint_0_fill.color = color;
canvas.drawPath(path_0,paint_0_fill);

}


@override
bool shouldRepaint(covariant CustomPainter oldDelegate) {
return true;
}
}