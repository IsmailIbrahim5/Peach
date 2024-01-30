import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:ui' ;

import 'package:flutter/material.dart';
import 'package:peach/Classes/main_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../Classes/chat_room.dart';
import '../Classes/design_constants.dart';
import '../main.dart';
import '../Screens/opened_chat_room.dart';
import '../Widgets/contacts_widgets.dart';
import '../Widgets/sequence_animation_builder.dart';

class ContactsPage extends StatefulWidget {
  final SequenceAnimationController controller;

  const ContactsPage({super.key, required this.controller});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  bool expanded = false;
  ValueNotifier<ui.Image?> qrImage = ValueNotifier(null);


  late MainProvider provider;
  @override
  void initState() {
    super.initState();

    provider =  Provider.of<MainProvider>(context , listen: false);

    QrPainter.withQr(qr: QrCode.fromData(data: provider.currentUser!.id, errorCorrectLevel: QrErrorCorrectLevel.L ) , dataModuleStyle: const QrDataModuleStyle(color: Colors.white , dataModuleShape: QrDataModuleShape.circle) , eyeStyle: const QrEyeStyle(color: Colors.white , eyeShape: QrEyeShape.circle)).toImage(provider.screenSize.width).then((value) => qrImage.value = value);
  }

  SequenceAnimationController builderController = SequenceAnimationController();

  ChatRoom? clickedChatRoom;
  int buildTime = 0;

  @override
  Widget build(BuildContext context) {
    buildTime++;
    return SafeArea(
      child: SequenceAnimationBuilder(
        animations: 6,
        repeat: false,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        endCallback: (){
          Navigator.of(context).push(PageRouteBuilder(
              transitionDuration: Duration.zero,
              pageBuilder: (context, animation, secondaryAnimation) => OpenedChatRoom(chatRoom: clickedChatRoom!, key: const ValueKey('openedChatRoom'),)
          ));
        },
        controller: builderController,
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
          }; return Column(
            children: [
              Expanded(
                flex: 2,
                child: UpwardCrossFade(
                  value: values[0],
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'CONTACTS',
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
                        value:buildTime == 1?  1.0:values[3],
                        limit: .5,
                        child: child!),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          UpwardCrossFade(
                            value: values[1],
                            child: Container(
                              height: provider.screenSize.height * .07,
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
                                          hintText: 'Search in conversations...',
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
                          const SizedBox(height: 16.0,),
                          UpwardCrossFade(
                            value: values[2],
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  expanded = !expanded;
                                });
                              },
                              child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 2000),
                                  curve: Curves.elasticOut,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(36.0),
                                      boxShadow: [Design.shadow1]
                                  ),
                                  alignment: Alignment.center,
                                  //Theme.of(context).scaffoldBackgroundColor,
                                  height: (provider.screenSize.width * (expanded ?  7: 2.5) / 10) + 40.0,
                                  child: ValueListenableBuilder(
                                    valueListenable: qrImage,
                                    builder: (context, value, child) => Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        AnimatedPositioned(
                                          duration: const Duration(milliseconds: 2000),
                                          curve: Curves.elasticOut,
                                          top: 0,
                                          left: expanded ?(provider.screenSize.width / 2) - (provider.screenSize.width * 5 / 10 / 2) - 24: 0,
                                          child: Padding(
                                            padding: expanded ? const EdgeInsets.symmetric(vertical: 20.0): const EdgeInsets.all(20.0),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 2000),
                                              width:  provider.screenSize.width * (expanded ? 5 /10 : 2.5 / 10),
                                              height:  provider.screenSize.width * (expanded ? 5 /10 : 2.5 / 10),
                                              curve: Curves.elasticOut,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(provider.screenSize.width * (expanded ? 5 /10 : 3 / 10) / 4),
                                                  color: Colors.white,
                                                  boxShadow: [Design.shadow3]
                                              ),
                                              padding: EdgeInsets.all(provider.screenSize.width * (expanded ? 5 /10 : 3 / 10) / 8),
                                              child: qrImage.value == null ? const SizedBox(): ShaderMask(
                                                shaderCallback: (bounds) => Design.mainGradient.createShader(bounds),
                                                child: RawImage(
                                                  image: qrImage.value,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top:  (provider.screenSize.width * 0.5 + 20.0) / 2 - 15.0,
                                          left: provider.screenSize.width * .025,

                                          child: AnimatedScale(
                                            scale: expanded ? 1.0 : 0.0,
                                            curve: expanded ? Curves.elasticOut : Curves.easeOutQuart,
                                            duration: expanded ? const Duration(seconds: 2) : const Duration(milliseconds: 400),
                                            child: IconButton(icon: Icon(Icons.share_rounded , size: 36.0, color: Design.mainColor.withOpacity(.75), ),
                                              highlightColor: Design.mainColor,
                                              onPressed: () async{
                                              PictureRecorder recorder = PictureRecorder();
                                              final canvas = Canvas(recorder , Rect.fromPoints(Offset.zero, Offset(provider.screenSize.width,provider.screenSize.width)));
                                              final path = Path()
                                                ..moveTo(provider.screenSize.width * .25, 0)
                                                ..lineTo(provider.screenSize.width * .75, 0)
                                                ..quadraticBezierTo(provider.screenSize.width, 0, provider.screenSize.width, provider.screenSize.width * .25)
                                                ..lineTo(provider.screenSize.width, provider.screenSize.width* .75)
                                                ..quadraticBezierTo(provider.screenSize.width, provider.screenSize.width, provider.screenSize.width * .75, provider.screenSize.width)
                                                ..lineTo(provider.screenSize.width * .25, provider.screenSize.width)
                                                ..quadraticBezierTo(0, provider.screenSize.width, 0, provider.screenSize.width * .75)
                                                ..lineTo(0, provider.screenSize.width * .25)
                                                ..quadraticBezierTo(0, 0, provider.screenSize.width *.25, 0);

                                              canvas.clipPath(path);

                                              canvas.drawRect(Rect.fromLTRB(0, 0, provider.screenSize.width, provider.screenSize.width), Paint()..color= Colors.white);


                                              QrPainter painter = QrPainter.withQr(qr: QrCode.fromData(data: provider.currentUser!.id, errorCorrectLevel: QrErrorCorrectLevel.L ) , dataModuleStyle: const QrDataModuleStyle(color: Design.mainColor , dataModuleShape: QrDataModuleShape.circle) , eyeStyle: const QrEyeStyle(color: Design.mainColor , eyeShape: QrEyeShape.circle) , gapless: true);

                                              canvas.drawImage(await painter.toImage(provider.screenSize.width * .8), Offset(provider.screenSize.width * .1 , provider.screenSize.width * .1), Paint());

                                              final picture = recorder.endRecording();
                                              final img = await picture.toImage(provider.screenSize.width.toInt(), provider.screenSize.width.toInt());
                                              final pngBytes = await img.toByteData(format:ui.ImageByteFormat.png);

                                              final list = pngBytes?.buffer.asUint8List(pngBytes.offsetInBytes , pngBytes.lengthInBytes);
                                              if(list != null) {
                                                Share.shareXFiles([XFile.fromData(list , name: 'Image' , mimeType: 'image/png')] , text: 'Hey add me xoxo' , );
                                              }
                                            },
                                            ),
                                          ),
                                        ),
                                        AnimatedPositioned(
                                          duration: const Duration(milliseconds: 2000
                                          ),
                                          top: expanded ? (provider.screenSize.width * 5 / 10):0.0,
                                          left: expanded ? null : 0 ,
                                          curve: Curves.elasticOut,
                                          child: Container(
                                            height: (provider.screenSize.width *  2.5 / 10) + 40.0,
                                            width: provider.screenSize.width ,
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(horizontal: 42.0 , vertical: 16.0),
                                            child: AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 400),
                                              child: expanded ? const FittedBox(
                                                fit: BoxFit.fitWidth,
                                                child:  Text(
                                                  key: ValueKey('1'),
                                                  'Scan This QR Code From Someone\'s\n Phone To Make Them Add You' ,
                                                  textAlign: TextAlign.center,
                                                  style:  TextStyle(
                                                      color:  Design.mainColor,
                                                      fontSize: 20.0,
                                                      fontWeight: FontWeight.w900),),
                                              ) : const Padding(
                                                padding: EdgeInsets.only(left: 20.0),
                                                child: Text(
                                                  key: ValueKey('2'),
                                                  'Show QR Invitation' , style:  TextStyle(
                                                    color:  Design.mainColor,
                                                    fontSize: 16.0,
                                                    fontWeight: FontWeight.w900),),
                                              ),
                                            ),
                                          ),
                                        ),
                                        AnimatedPositioned(
                                          duration: const Duration(milliseconds: 2000),
                                          right: 0.0,
                                          top:  (provider.screenSize.width * (expanded ? 5 /10 : 2.5 / 10) + 20.0) / 2 - 10,
                                          width: provider.screenSize.width * 2 / 10,
                                          curve: Curves.elasticOut,
                                          child: AnimatedRotation(
                                            duration: const Duration(milliseconds: 2000
                                            ),
                                            curve: Curves.elasticOut,
                                            turns: expanded ? .5 : 0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white,
                                                  boxShadow: [Design.shadow3]
                                              ),
                                              child:  const Icon(
                                                Icons.arrow_drop_down_rounded,
                                                size: 30.0,
                                                color: Design.mainColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            ],
          );
        },
        child: ContactsList(expanded: expanded,   onClick: (ChatRoom chatRoom){
         openChatAnimation!(chatRoom);
        }),
      ),
    );
  }
}
