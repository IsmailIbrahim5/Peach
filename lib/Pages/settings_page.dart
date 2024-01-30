import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peach/Classes/main_provider.dart';
import 'package:provider/provider.dart';
import '../Classes/design_constants.dart';
import '../main.dart';
import '../Screens/register.dart';
import '../Widgets/cross_fade_switcher.dart';
import '../Widgets/sequence_animation_builder.dart';
import '../Widgets/icon_switcher.dart';
import '../Widgets/loading_widget.dart';
import '../Widgets/switcher.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import 'chat_rooms_page.dart';

class SettingsPage extends StatefulWidget {
  final SequenceAnimationController controller;

  const SettingsPage({super.key, required this.controller});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool editMode = false;
  late TextEditingController nameController;
  late TextEditingController statusController;
  ImageProvider? currentImage;
  File? currentImageFile;

  bool isUploading = false;

  SequenceAnimationController builderController = SequenceAnimationController();


  late MainProvider provider;
  @override
  void initState() {
    super.initState();
    provider =  Provider.of<MainProvider>(context , listen: false);
    nameController =
        TextEditingController(text: provider.currentUser?.name);
    statusController =
        TextEditingController(text: provider.currentUser?.status);

  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SequenceAnimationBuilder(
          repeat: false,
          animations: 7,
          duration: const Duration(milliseconds: 600),
          endCallback: () {
            Navigator.of(context).pushReplacement(PageRouteBuilder(
              transitionDuration: Duration.zero,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const Register(
                logOut: true,
              ),
            ));
          },
          controller: builderController,
          curve: Curves.easeOutBack,
          builder: (values, [child]) => Column(
            children: [
              Expanded(
                flex: 2,
                child: UpwardCrossFade(
                  value: values[0],
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'SETTINGS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 52.0,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Inter'),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 15,
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: provider.screenSize.height * 0.35 - 44.0,
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white,
                              Colors.white,
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.0, 0.2, 0.9, 1.0]).createShader(bounds),
                        blendMode: BlendMode.dstIn,
                        child: ListView(
                          scrollDirection: Axis.vertical,
                          padding: EdgeInsets.only(
                              bottom: provider.screenSize.height * 0.085 + 32.0 + 8.0,
                              top: 44.0 + 32.0),
                          children: [
                            UpwardCrossFade(
                              value: values[2],
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(32.0),
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: AnimatedContainer(
                                        width: 20.0,
                                        height: 20.0,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: provider.currentUser!
                                                    .settings.activeStatus
                                                ? Design.activeColor
                                                : Design.mainColor),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 5,
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        child: const FittedBox(
                                          child: Text(
                                            'Active Status',
                                            style: TextStyle(
                                                color: Design.mainColor,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inter',
                                                fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 46,
                                      padding: const EdgeInsets.all(4.0),
                                      child: Switcher(
                                        defaultVal:
                                        provider.currentUser!.settings.activeStatus,
                                        callback: (bool val) {
                                          setState(() {
                                            provider.currentUser!.settings.activeStatus =
                                                val;
                                          });
                                          FirebaseDatabase.instance
                                              .ref(
                                                  'users/${provider.currentUser?.id}/settings/active_status')
                                              .set(val);
                                          FirebaseDatabase.instance
                                              .ref(
                                                  'users/${provider.currentUser?.id}/active')
                                              .set(val);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            UpwardCrossFade(
                              value: values[3],
                              child: Container(
                                margin: const EdgeInsets.only(top: 24.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(32.0),
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Image.asset(
                                        'images/eye_shown.png',
                                        color: Design.mainColor,
                                        height: 32.0,
                                        width: 32.0,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 5,
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        child: const FittedBox(
                                          child: Text(
                                            'Read Recipients',
                                            style: TextStyle(
                                                color: Design.mainColor,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inter',
                                                fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 46,
                                      padding: const EdgeInsets.all(4.0),
                                      child: Switcher(
                                        defaultVal: provider.currentUser!
                                            .settings.readRecipients,
                                        callback: (bool val) {
                                          setState(() {
                                            provider.currentUser!
                                                .settings.readRecipients = val;
                                          });
                                          FirebaseDatabase.instance
                                              .ref(
                                                  'users/${provider.currentUser?.id}/settings/read_recipients')
                                              .set(val);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            UpwardCrossFade(
                              value: values[4],
                              child: Container(
                                margin: const EdgeInsets.only(top: 24.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(32.0),
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Image.asset(
                                        'images/notification.png',
                                        color: Design.mainColor,
                                        height: 32.0,
                                        width: 32.0,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 5,
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        child: const FittedBox(
                                          child: Text(
                                            'Allow Notifications',
                                            style: TextStyle(
                                                color: Design.mainColor,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inter',
                                                fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 46,
                                      padding: const EdgeInsets.all(4.0),
                                      child: Switcher(
                                        defaultVal:
                                        provider.currentUser!.settings.notifications,
                                        callback: (bool val) {
                                          setState(() {
                                            provider.currentUser!
                                                .settings.notifications = val;
                                          });
                                          FirebaseDatabase.instance
                                              .ref(
                                                  'users/${provider.currentUser?.id}/settings/notifications_allowed')
                                              .set(val);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            UpwardCrossFade(
                              value: values[5],
                              child: GestureDetector(
                                onTap: () async {
                                  DatabaseReference userRef = FirebaseDatabase
                                      .instance
                                      .ref('users/${provider.currentUser!.id}');
                                  await userRef.child('active').set(false);
                                  await userRef.child('messagingToken').set('');
                                  (await SharedPreferences.getInstance())
                                      .remove('user_id');
                                  widget.controller.reverse!();
                                  builderController.reverse!();
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(top: 24.0),
                                  decoration: BoxDecoration(
                                    color: Design.mainColor,
                                    borderRadius: BorderRadius.circular(32.0),
                                  ),
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Image.asset(
                                          'images/log_out.png',
                                          color: Colors.white,
                                          height: 36.0,
                                          width: 36.0,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 5,
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          child: const FittedBox(
                                            child: Text(
                                              'Log Out',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Inter',
                                                  fontSize: 16),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 46 * 2,
                                        height: 46.0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    UpwardCrossFade(
                      value: values[1],
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(44.0),
                            boxShadow: [Design.shadow1]),
                        width: provider.screenSize.width,
                        height: provider.screenSize.height * 0.35,
                        clipBehavior: Clip.antiAlias,

                        child: Stack(
                          children: [
                            BackgroundPainter(count: 8, size: 48 , color: Design.mainColor.withOpacity(.5),),

                           Padding(
                             padding: const EdgeInsets.symmetric(
                                 horizontal: 16.0, vertical: 36.0),
                             child: Stack(
                               children: [
                                 Align(
                                   alignment: Alignment.topCenter,
                                   child: Container(
                                     decoration: BoxDecoration(
                                         shape: BoxShape.circle,
                                         color: Colors.white,
                                         border: Border.all(
                                             color: Design.mainColor
                                                 .withOpacity(.75),
                                             width: 2.0)),
                                     height: provider.screenSize.width * 0.35,
                                     width: provider.screenSize.width * 0.35,
                                     clipBehavior: Clip.antiAlias,
                                     child: Container(
                                       decoration: const BoxDecoration(
                                           shape: BoxShape.circle),
                                       clipBehavior: Clip.antiAlias,
                                       child: currentImage == null
                                           ? CachedNetworkImage(
                                         imageUrl: provider.currentUser!.pfpLink,
                                         imageBuilder:
                                             (context, imageProvider) {
                                           return Image(
                                             image: imageProvider,
                                             fit: BoxFit.cover,
                                           );
                                         },
                                         placeholder: (context, url) =>
                                             FittedBox(
                                               fit: BoxFit.fitWidth,
                                               child: Transform.scale(
                                                 scale: 0.3,
                                                 child: Text(
                                                   provider.currentUser!.name[0],
                                                   style: const TextStyle(
                                                       color:
                                                       Design.mainColor,
                                                       fontSize: 100.0,
                                                       fontWeight:
                                                       FontWeight.w900),
                                                 ),
                                               ),
                                             ),
                                         errorWidget:
                                             (context, url, error) =>
                                             FittedBox(
                                               fit: BoxFit.fitWidth,
                                               child: Transform.scale(
                                                 scale: 0.3,
                                                 child: Text(
                                                   provider.currentUser!.name[0],
                                                   style: const TextStyle(
                                                       color:
                                                       Design.mainColor,
                                                       fontSize: 100.0,
                                                       fontWeight:
                                                       FontWeight.w900),
                                                 ),
                                               ),
                                             ),
                                         fit: BoxFit.cover,
                                       )
                                           : Image(
                                         image: currentImage!,
                                         fit: BoxFit.cover,
                                       ),
                                     ),
                                   ),
                                 ),
                                 Transform.translate(
                                   offset: Offset(
                                     provider.screenSize.width * 0.35 * 1.35,
                                     provider.screenSize.width * 0.35 * 0.73,
                                   ),
                                   child: AnimatedScale(
                                     scale: editMode ? 1.0 : 0.0,
                                     duration:
                                     const Duration(milliseconds: 400),
                                     curve: editMode
                                         ? Curves.easeOutBack
                                         : Curves.easeOutQuad,
                                     alignment: Alignment.center,
                                     child: GestureDetector(
                                       onTap: () async {
                                         final ImagePicker picker =
                                         ImagePicker();
                                         XFile? ximage =
                                         await picker.pickImage(
                                             source:
                                             ImageSource.gallery);
                                         if (ximage != null) {
                                           currentImageFile =
                                               File(ximage.path);
                                           currentImage = Image.memory(
                                               await currentImageFile!
                                                   .readAsBytes())
                                               .image;
                                           setState(() {});
                                         }
                                       },
                                       child: Container(
                                           height:
                                           provider.screenSize.width * 0.35 * .25,
                                           width:
                                           provider.screenSize.width * 0.35 * .25,
                                           decoration: BoxDecoration(
                                               shape: BoxShape.circle,
                                               gradient:
                                               Design.mainGradient),
                                           child: Transform.scale(
                                             scale: .7,
                                             child: Image.asset(
                                               'images/add.png',
                                               color: Colors.white,
                                             ),
                                           )),
                                     ),
                                   ),
                                 ),
                                 Positioned(
                                   bottom: 0.0,
                                   right: 0,
                                   left: 0,
                                   child: editMode
                                       ? Column(
                                     children: [
                                       TextFormField(
                                         decoration:
                                         const InputDecoration(
                                           border: InputBorder.none,
                                           contentPadding:
                                           EdgeInsets.zero,
                                           isDense: true,
                                         ),
                                         controller: nameController,
                                         textAlign: TextAlign.center,
                                         style: const TextStyle(
                                           color: Design.mainColor,
                                           fontFamily: 'Inter',
                                           fontSize: 26.0,
                                           decoration: TextDecoration
                                               .underline,
                                           decorationColor:
                                           Design.mainColor,
                                           fontWeight: FontWeight.bold,
                                         ),
                                       ),
                                       TextFormField(
                                         decoration:
                                         const InputDecoration(
                                           border: InputBorder.none,
                                           contentPadding:
                                           EdgeInsets.zero,
                                           isDense: true,
                                         ),
                                         textAlign: TextAlign.center,
                                         controller: statusController,
                                         style: const TextStyle(
                                           color: Design.mainColor,
                                           fontFamily: 'Inter',
                                           fontSize: 14.0,
                                           decorationColor:
                                           Design.mainColor,
                                           decoration: TextDecoration
                                               .underline,
                                           fontWeight: FontWeight.w300,
                                         ),
                                       ),
                                     ],
                                   )
                                       : Column(
                                     children: [
                                       Text(
                                         provider.currentUser!.name,
                                         style: const TextStyle(
                                           color: Design.mainColor,
                                           fontFamily: 'Inter',
                                           fontSize: 26.0,
                                           fontWeight: FontWeight.bold,
                                         ),
                                       ),
                                       FittedBox(
                                         child: Text(
                                           provider.currentUser!.status,
                                           textAlign: TextAlign.center,
                                           style: const TextStyle(
                                             color: Design.mainColor,
                                             fontFamily: 'Inter',
                                             fontSize: 14.0,
                                             fontWeight:
                                             FontWeight.w300,
                                           ),
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                                 Align(
                                   alignment: Alignment.centerRight,
                                   child: GestureDetector(
                                     onTap: () async {
                                       if (editMode) {
                                         setState(() {
                                           isUploading = true;
                                         });
                                         if (provider.currentUser?.name !=
                                             nameController.text) {
                                           FirebaseDatabase.instance
                                               .ref('users/${provider.currentUser!.id}/name')
                                               .set(nameController.text);
                                           provider.currentUser!.name = nameController.text;
                                         }
                                         if (provider.currentUser?.status !=
                                             statusController.text) {
                                           FirebaseDatabase.instance
                                               .ref('users/${provider.currentUser!.id}/status')
                                               .set(statusController.text);
                                           provider.currentUser!.status =
                                               statusController.text;
                                         }

                                         if (currentImage != null &&
                                             currentImageFile != null &&
                                             path.basename(provider.currentUser!.pfpLink) !=
                                                 path.basename(currentImageFile!.path)) {
                                           Random random = Random();
                                           String pfpLink = '';
                                           final pfpLinkRef =
                                           FirebaseStorage.instance.ref(
                                               'user_profile_pictures/user_${provider.currentUser!.id}_pfp${random.nextInt(100000)}${path.extension(currentImageFile!.path)}');

                                           await pfpLinkRef.putFile(
                                               currentImageFile!,
                                               SettableMetadata(
                                                   contentType:
                                                   'image/${path.extension(currentImageFile!.path).substring(1)}'));
                                           pfpLink =
                                           await pfpLinkRef.getDownloadURL();
                                           FirebaseDatabase.instance
                                               .ref('users/${provider.currentUser!.id}/pfpLink')
                                               .set(pfpLink);
                                           provider.currentUser!.pfpLink = pfpLink;
                                         }
                                         currentImage = null;
                                         currentImageFile = null;
                                       }
                                       setState(() {
                                         editMode = !editMode;
                                         if (isUploading) isUploading = false;
                                       });
                                     },
                                     child: Container(
                                       decoration: BoxDecoration(
                                           color: Colors.white,
                                           shape: BoxShape.circle,
                                           boxShadow: [Design.shadow3]),
                                       clipBehavior: Clip.antiAlias,
                                       height: provider.screenSize.width * .125,
                                       width: provider.screenSize.width * .125,
                                       alignment: Alignment.center,
                                       child: CrossFadeSwitcher(
                                         next: isUploading,
                                         child: isUploading
                                             ? const LoadingWidget(
                                           size: 8.0,
                                           color: Design.mainColor,
                                           number: 3,
                                         )
                                             : Transform.scale(
                                           scale: .7,
                                           child: IconSwitcher(
                                             icon: editMode
                                                 ? Image.asset(
                                               'images/done.png',
                                               key: const ValueKey(
                                                   'done'),
                                               color: Design.mainColor,
                                               height: 24.0,
                                               width: 28.0,
                                             )
                                                 : Image.asset(
                                               'images/pen.png',
                                               key:
                                               const ValueKey('pen'),
                                               color: Design.mainColor,
                                               height: 24.0,
                                               width: 24.0,
                                             ),
                                           ),
                                         ),
                                       ),
                                     ),
                                   ),
                                 )
                               ],
                             ),
                           )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CustomDecoration extends CustomPainter {
  Random random = Random();
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.redAccent.withOpacity(.5)
      ..strokeCap = StrokeCap.round;
    Paint paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.redAccent.withOpacity(.5)
      ..strokeCap = StrokeCap.round;

    double widthStart = .25;
    double heightEnd = .25;
    double startingPoint = size.width * .25 * 1.1;
    double endingPoint = size.height * .25 * 1.1;

    double rand1 = 1.1;

    Path path = Path()
      ..moveTo(startingPoint, 0)
      ..cubicTo(
          startingPoint * rand1,
          endingPoint * .5 * rand1,
          startingPoint * .25 * rand1,
          endingPoint * .5 * rand1,
          0,
          endingPoint);
    Path path1 = Path()
      ..moveTo(startingPoint * 1.25, 0)
      ..cubicTo(
          startingPoint * rand1 * 1.25,
          endingPoint * .5 * rand1 * 1.25,
          startingPoint * .25 * rand1 * 1.25,
          endingPoint * .5 * rand1 * 1.25,
          0,
          endingPoint * 1.25);

    //
    canvas.drawPath(path, paint);
    canvas.drawPath(path1, paint1);

    // Vertices vertices = Vertices(VertexMode.triangles, [Offset(0, 0 ) , Offset(0, 100) , Offset(100, 0)]);

    // canvas.drawVertices(vertices, BlendMode.color, paint);

    List<Rect> occupiedSpaces = [];
    Paint paint3 = Paint()..color = Colors.redAccent.withOpacity(.5);
    // for(int i = 0 ; i<5 ; i++) {
    //
    //   while(true) {
    //     Offset randomOffset1 = Offset(size.width *
    //         random.nextDouble(), size.height *
    //         random.nextDouble());
    //
    //     Rect space = Rect.fromCenter(
    //         center: randomOffset1, width: 10, height: 10);
    //     if (occupiedSpaces
    //         .where((element) => element.overlaps(space))
    //         .firstOrNull == null) {
    //       occupiedSpaces.add(
    //           Rect.fromCenter(center: randomOffset1, width: 10, height: 10));
    //       canvas.drawCircle(randomOffset1, 10, paint3);
    //       break;
    //     }
    //   }
    // }
    // canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
