import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peach/Classes/chat_room.dart';
import 'package:peach/Classes/main_provider.dart';
import 'package:peach/Classes/message.dart';
import 'package:provider/provider.dart';
import '../Classes/design_constants.dart';
import '../Classes/user_classes.dart';
import '../Screens/home.dart';
import '../main.dart';
import '../Widgets/cross_fade_switcher.dart';
import '../Widgets/sequence_animation_builder.dart';
import '../Widgets/icon_switcher.dart';
import '../Widgets/loading_widget.dart';
import '../Classes/user_classes.dart' as peach_user;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';


class Register extends StatefulWidget {
  final bool logOut;
  const Register({super.key,  this.logOut = false});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register>
    with SingleTickerProviderStateMixin {

  double scale = 1.0;

  bool isSignInPage = true;
  bool passwordObscure = true;
  bool registered = false;
  bool isLoading = false;

  File? currentImageFile;
  ImageProvider? currentImage;

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  SequenceAnimationController builderController = SequenceAnimationController();
  PageController pageController = PageController();

  late AnimationController controller;
  late Animation<double> animation;

  late MainProvider provider;

  final creatorId = 'VD1K2usGu8M97nC7jmvsY4ShPGn1';

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    animation = CurvedAnimation(parent: controller, curve: Curves.easeOutBack);
  }

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<MainProvider>(context);
    scale = (provider.screenSize.height - MediaQuery.of(context).viewInsets.bottom) /
        provider.screenSize.height;
    return Scaffold(
      body: SequenceAnimationBuilder(
          animations: isSignInPage ? (registered ? 6 : 7) : (registered ? 8 : 9),
          delay: 0.4,
          repeat: false,
          duration: const Duration(milliseconds: 500),
          curve: Curves.linear,
          controller: builderController,
          endCallback: (){
            Navigator.of(context).pushReplacement(PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation) => const Home(), transitionDuration: Duration.zero));
          },
          builder: (values , [child]) => Stack(
          children: [
            const BackgroundGradient(),
             Column(
                children: [
                  Transform.scale(
                    scale: registered || widget.logOut ? values[0] : 1.0,

                    child: Opacity(
                      opacity: registered || widget.logOut ? values[0] : 1.0,
                      child: AnimatedBuilder(
                        builder: (context, child) => SizedBox(
                          height: provider.screenSize.height *
                              (.25 - (animation.value * .15)) *
                              scale,
                          child: child,
                        ),
                        animation: animation,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 600),
                          alignment: Alignment.center,
                          curve: Curves.easeOutBack,
                          scale: isSignInPage ?1.0 : 0.0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutBack,
                            opacity: isSignInPage ? 1.0 : 0.0,
                            child: Padding(
                              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top  + 12.0, bottom: 24.0),
                              child: Hero(
                                tag: 'logo',
                                child: Stack(
                                  children: [
                                    ImageFiltered(
                                      imageFilter: ImageFilter.blur(
                                          sigmaY: 5.0,
                                          sigmaX: 5.0,
                                          tileMode: TileMode.decal),
                                      child: Opacity(
                                        opacity: .5,
                                        child: Image.asset(
                                          'images/top_logo.png',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Image.asset(
                                      'images/top_logo.png',
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                UpwardCrossFade(
                      value:Curves.easeOutQuad.transform(values[1 - (registered ? 1 : 0)]),
                      child: AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) => SizedBox(
                          height: provider.screenSize.height *
                              (1 - (.25 - (animation.value * .15))) *
                              scale,
                          child: child,
                        ),
                        child: CustomPaint(
                          painter: BackdropPainter(),
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: provider.screenSize.height * .12 * scale, bottom: 16.0),
                            child: PageView(
                                physics: const NeverScrollableScrollPhysics(),
                                controller: pageController,
                                clipBehavior: Clip.none,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        UpwardCrossFade(
                                          value: Curves.easeOutBack.transform(values[3- (registered ? 1 : 0)]),
                                          child: Column(
                                            children: [
                                              Text(
                                                'Hello',
                                                style: TextStyle(
                                                    height: 1.0,
                                                    color: Design.mainColor,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 80.0 * scale,
                                                    fontFamily: 'Inter'),
                                              ),
                                              Text(
                                                'Sign in to your account',
                                                style: TextStyle(
                                                    color:
                                                    Design.mainColor.withOpacity(.7),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18.0 * scale,
                                                    fontFamily: 'Inter'),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(flex: 4,),
                                        UpwardCrossFade(
                                          value: Curves.easeOutBack.transform(values[4- (registered ? 1 : 0)]),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(24.0),
                                                boxShadow: [Design.shadow3]),
                                            child: TextFormField(
                                              controller: emailController,
                                              autofillHints: const [
                                                AutofillHints.username,
                                                AutofillHints.email
                                              ],
                                              textInputAction: TextInputAction.next,
                                              cursorOpacityAnimates: true,
                                              onChanged: (value) => setState(() {}),
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              decoration: InputDecoration(
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          vertical: 24.0 * scale,
                                                          horizontal: 32.0 * scale),
                                                  border: InputBorder.none,
                                                  hintText: 'E-mail Address',
                                                  hintStyle: TextStyle(
                                                    color: Design.mainColor
                                                        .withOpacity(.7),
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18.0 * scale,
                                                  )),
                                              style: TextStyle(
                                                  color: Design.mainColor,
                                                  fontFamily: 'Inter',
                                                  fontSize: 18.0 * scale,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        const Spacer(
                                          flex: 2,
                                        ),
                                        UpwardCrossFade(
                                          value: Curves.easeOutBack.transform(values[4- (registered ? 1 : 0)]),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(24.0),
                                                boxShadow: [Design.shadow3]),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextFormField(
                                                    controller: passwordController,
                                                    textInputAction:
                                                        TextInputAction.done,
                                                    onEditingComplete: () async{
                                                      setState(() {
                                                        isLoading = true;
                                                      });
                                                      if(await signIn(context)) {
                                                        setState(() {
                                                          registered = true;
                                                        });
                                                        builderController.reverse!.call();
                                                      }
                                                      setState(() {
                                                        isLoading = false;
                                                      });
                                                    },
                                                    autofillHints: const [
                                                      AutofillHints.password
                                                    ],
                                                    obscureText: passwordObscure,
                                                    cursorOpacityAnimates: true,
                                                    onChanged: (value) =>
                                                        setState(() {}),
                                                    decoration: InputDecoration(
                                                        border: InputBorder.none,
                                                        hintText: 'Password',
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                                vertical:
                                                                    24.0 * scale,
                                                                horizontal:
                                                                    32.0 * scale),
                                                        hintStyle: TextStyle(
                                                            color: Design.mainColor
                                                                .withOpacity(.7),
                                                            fontFamily: 'Inter',
                                                            fontSize: 18.0 * scale,
                                                            fontWeight:
                                                                FontWeight.bold)),
                                                    style: TextStyle(
                                                        color: Design.mainColor,
                                                        fontFamily: 'Inter',
                                                        fontSize: 18.0 * scale,
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 24.0),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        passwordObscure =
                                                            !passwordObscure;
                                                      });
                                                    },
                                                    child: SizedBox(
                                                      height: 28.0 * scale,
                                                      width: 28.0 * scale,
                                                      child: IconSwitcher(

                                                        icon: passwordObscure ? Image.asset(
                                                            'images/eye_hidden.png',
                                                            key: const ValueKey('eye_hidden'),
                                                            color: Design.mainColor ):Image.asset(
                                                            'images/eye_shown.png',
                                                          key: const ValueKey('eye_shown'),
                                                            color: Design.mainColor),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        const Spacer(
                                          flex: 1,
                                        ),
                                        UpwardCrossFade(
                                          value: Curves.easeOutBack.transform(values[5- (registered ? 1 : 0)]),
                                          child: GestureDetector(
                                            onTap: () {
                                              SnackBar snackBar = const SnackBar(
                                                  content: Text(
                                                    'Well opsie fucking daisy, try to remember it then',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontFamily: 'Inter',
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                  backgroundColor: Design.mainColor);

                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(snackBar);
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 8.0),
                                              child: Align(
                                                alignment: Alignment.bottomRight,
                                                child: Text(
                                                  'Forgot Your Password?',
                                                  style: TextStyle(
                                                      color: Design.mainColor
                                                          .withOpacity(.3),
                                                      fontSize: 14.0 * scale,
                                                      fontFamily: 'Inter'),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Spacer(
                                          flex: 4,
                                        ),
                                        UpwardCrossFade(
                                          value: Curves.easeOutBack.transform(values[5- (registered ? 1 : 0)]),
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: AnimatedOpacity(
                                              duration:
                                                  const Duration(milliseconds: 400),
                                              opacity:  isButtonEnabled() ? 1.0 : .5,
                                              child: GestureDetector(
                                                onTap: () async{
                                                  setState(() {
                                                    isLoading = true;
                                                  });
                                                  if(await signIn(context)) {
                                                    setState(() {
                                                      registered = true;
                                                    });
                                                    builderController.reverse!.call();
                                                  }
                                                  setState(() {
                                                    isLoading = false;
                                                  });
                                                },
                                                child: Container(
                                                  clipBehavior: Clip.antiAlias,
                                                  decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      gradient: Design.mainGradient,
                                                      borderRadius:
                                                          BorderRadius.circular(24.0),
                                                      boxShadow: [Design.shadow3]),
                                                  height: provider.screenSize.height * .07 * scale,
                                                  width: provider.screenSize.width * .5* scale,
                                                  alignment: Alignment.center,

                                                  child: CrossFadeSwitcher(
                                                    next: isLoading,
                                                    child: isLoading ? LoadingWidget(size: 15 * scale,) :Text(
                                                      'SIGN IN',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontFamily: 'Inter',
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 20 * scale,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Spacer(
                                          flex: 1,
                                        ),
                                        UpwardCrossFade(
                                          value: Curves.easeOutBack.transform(values[6- (registered ? 1 : 0)]),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0),
                                            child: Align(
                                              alignment: Alignment.center,
                                              child: RichText(
                                                text: TextSpan(children: [
                                                  TextSpan(
                                                    text: 'Don\'t have an account? ',
                                                    style: TextStyle(
                                                        color: Design.mainColor
                                                            .withOpacity(.5),
                                                        fontSize: 14.0 * scale,
                                                        fontFamily: 'Inter',
                                                        fontWeight: FontWeight.w700),
                                                  ),
                                                  TextSpan(
                                                      text: 'Create',
                                                      style: TextStyle(
                                                          color: Design.mainColor,
                                                          fontSize: 14.0 * scale,
                                                          fontFamily: 'Inter',
                                                          fontWeight:
                                                              FontWeight.w900),
                                                      recognizer:
                                                          TapGestureRecognizer()
                                                            ..onTap = () {
                                                              setState(() {
                                                                isSignInPage = false;
                                                              });
                                                              animation = Tween(
                                                                      begin: 0.0,
                                                                      end: 1.0)
                                                                  .animate(CurvedAnimation(
                                                                      parent:
                                                                          controller,
                                                                      curve: Curves
                                                                          .easeOutBack));
                                                              controller.forward(
                                                                  from: 0.0);
                                                              pageController.animateToPage(
                                                                  1,
                                                                  duration: const Duration(
                                                                      milliseconds:
                                                                          400),
                                                                  curve: Curves
                                                                      .easeOutBack);
                                                            })
                                                ]),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Spacer(
                                          flex: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Spacer(
                                          flex: 4,
                                        ),
                                        UpwardCrossFade(
                                          value: Curves.easeOutBack.transform(values[isSignInPage ? 0 : 3- (registered ? 1 : 0)]),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(24.0),
                                                boxShadow: [Design.shadow3]),
                                            child: TextFormField(
                                              controller: firstNameController,
                                              textInputAction: TextInputAction.next,
                                              cursorOpacityAnimates: true,
                                              onChanged: (value) => setState(() {}),
                                              decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          vertical: 24.0 * scale,
                                                          horizontal: 32.0 * scale),
                                                  hintText: 'First Name',
                                                  hintStyle: TextStyle(
                                                    color: Design.mainColor
                                                        .withOpacity(.7),
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18.0 * scale,
                                                  )),
                                              style: TextStyle(
                                                  color: Design.mainColor,
                                                  fontFamily: 'Inter',
                                                  fontSize: 18.0 * scale,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        const Spacer(
                                          flex: 2,
                                        ),
                                        UpwardCrossFade(
                                          value: Curves.easeOutBack.transform(values[isSignInPage ? 0 : 4- (registered ? 1 : 0)]),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(24.0),
                                                boxShadow: [Design.shadow3]),
                                            child: TextFormField(
                                              controller: lastNameController,
                                              textInputAction: TextInputAction.next,
                                              onChanged: (value) => setState(() {}),
                                              cursorOpacityAnimates: true,
                                              decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          vertical: 24.0 * scale,
                                                          horizontal: 32.0 * scale),
                                                  hintText: 'Last Name',
                                                  hintStyle: TextStyle(
                                                    color: Design.mainColor
                                                        .withOpacity(.7),
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18.0 * scale,
                                                  )),
                                              style: TextStyle(
                                                  color: Design.mainColor,
                                                  fontFamily: 'Inter',
                                                  fontSize: 18.0 * scale,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        const Spacer(
                                          flex: 2,
                                        ),
                                        UpwardCrossFade(
                                          value: Curves.easeOutBack.transform(values[isSignInPage ? 0 : 5- (registered ? 1 : 0)]),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(24.0),
                                                boxShadow: [Design.shadow3]),
                                            child: TextFormField(
                                              controller: emailController,
                                              autofillHints:const [
                                                AutofillHints.username,
                                                AutofillHints.email
                                              ],
                                              textInputAction: TextInputAction.next,
                                              onChanged: (value) => setState(() {}),
                                              cursorOpacityAnimates: true,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          vertical: 24.0 * scale,
                                                          horizontal: 32.0 * scale),
                                                  hintText: 'E-mail Address',
                                                  hintStyle: TextStyle(
                                                    color: Design.mainColor
                                                        .withOpacity(.7),
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18.0 * scale,
                                                  )),
                                              style: TextStyle(
                                                  color: Design.mainColor,
                                                  fontFamily: 'Inter',
                                                  fontSize: 18.0 * scale,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        const Spacer(
                                          flex: 2,
                                        ),
                                        UpwardCrossFade(
                                          value: Curves.easeOutBack.transform(values[isSignInPage ? 0 : 6- (registered ? 1 : 0)]),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(24.0),
                                                boxShadow: [Design.shadow3]),
                                            child: TextFormField(
                                              controller: passwordController,
                                              textInputAction: TextInputAction.done,
                                              onChanged: (value) => setState(() {}),
                                              onEditingComplete: () async{
                                                setState(() {
                                                  isLoading = true;
                                                });
                                                if(await signUp(context)){
                                                  setState(() {
                                                    registered = true;
                                                  });
                                                  builderController.reverse!.call();
                                                }
                                                setState(() {
                                                  isLoading = false;
                                                });
                                              },
                                              cursorOpacityAnimates: true,
                                              autofillHints: const [
                                                AutofillHints.newPassword
                                              ],
                                              decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                          vertical: 24.0 * scale,
                                                          horizontal: 32.0 * scale),
                                                  hintText: 'Password',
                                                  hintStyle: TextStyle(
                                                      color: Design.mainColor
                                                          .withOpacity(.7),
                                                      fontFamily: 'Inter',
                                                      fontSize: 18.0 * scale,
                                                      fontWeight: FontWeight.bold)),
                                              style: TextStyle(
                                                  color: Design.mainColor,
                                                  fontFamily: 'Inter',
                                                  fontSize: 18.0 * scale,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        const Spacer(
                                          flex: 4,
                                        ),
                                        UpwardCrossFade(
                                          value: Curves.easeOutBack.transform(values[isSignInPage ? 0 : 7- (registered ? 1 : 0)]),

                                          child: Align(
                                            alignment: Alignment.center,
                                            child: AnimatedOpacity(
                                              duration:
                                                  const Duration(milliseconds: 400),
                                              opacity: isButtonEnabled() ? 1.0 : .5,
                                              child: GestureDetector(
                                                onTap: () async{
                                                  setState(() {
                                                    isLoading = true;
                                                  });
                                                  if(await signUp(context)){
                                                    setState(() {
                                                      registered = true;
                                                    });
                                                    builderController.reverse!.call();
                                                  }
                                                  setState(() {
                                                    isLoading = false;
                                                  });
                                                },
                                                child: Container(
                                                  clipBehavior: Clip.antiAlias,
                                                  decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      gradient: Design.mainGradient,
                                                      borderRadius:
                                                      BorderRadius.circular(24.0),
                                                      boxShadow: [Design.shadow3]),
                                                  height: provider.screenSize.height * .07 * scale,
                                                  width: provider.screenSize.width * .5* scale,
                                                  alignment: Alignment.center,

                                                  child: CrossFadeSwitcher(
                                                    next: isLoading,
                                                    child: isLoading ? LoadingWidget(size: 15 * scale,) :Text(
                                                      'SIGN UP',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontFamily: 'Inter',
                                                        fontWeight: FontWeight.w900,
                                                        fontSize: 20 * scale,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Spacer(
                                          flex: 1,
                                        ),
                                        UpwardCrossFade(
                                          value: Curves.easeOutBack.transform(values[isSignInPage ? 0 : 8- (registered ? 1 : 0)]),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0),
                                            child: Align(
                                              alignment: Alignment.center,
                                              child: RichText(
                                                text: TextSpan(children: [
                                                  TextSpan(
                                                    text: 'Already have an account? ',
                                                    style: TextStyle(
                                                        color: Design.mainColor
                                                            .withOpacity(.5),
                                                        fontSize: 14.0 * scale,
                                                        fontFamily: 'Inter',
                                                        fontWeight: FontWeight.w700),
                                                  ),
                                                  TextSpan(
                                                      text: 'Login',
                                                      style: TextStyle(
                                                          color: Design.mainColor,
                                                          fontSize: 14.0 * scale,
                                                          fontFamily: 'Inter',
                                                          fontWeight:
                                                              FontWeight.w900),
                                                      recognizer:
                                                          TapGestureRecognizer()
                                                            ..onTap = () {
                                                              setState(() {
                                                                isSignInPage = true;
                                                              });
                                                              animation = Tween(
                                                                      begin: 1.0,
                                                                      end: 0.0)
                                                                  .animate(CurvedAnimation(
                                                                      parent:
                                                                          controller,
                                                                      curve: Curves
                                                                          .easeOutBack));
                                                              controller.forward(
                                                                  from: 0);
                                                              pageController.animateToPage(
                                                                  0,
                                                                  duration: const Duration(
                                                                      milliseconds:
                                                                          400),
                                                                  curve: Curves
                                                                      .easeOutBack);
                                                            })
                                                ]),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Spacer(
                                          flex: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: provider.screenSize.height * .05),
                child: Stack(
                  children: [
                    Transform.scale(
                      scale: registered || widget.logOut ? values[0] : 1.0,
                      alignment: Alignment.center,

                      child: Opacity(
                        opacity: registered || widget.logOut ? values[0] : 1.0,
                        child: AnimatedOpacity(
                          opacity: isSignInPage ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutQuad,
                          child: AnimatedScale(
                            scale: isSignInPage ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 400),
                            curve: isSignInPage ? Curves.easeOutQuad : Curves.easeOutBack,
                            alignment: Alignment.center,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [Design.shadow3]),
                              height: provider.screenSize.width * .4 * scale,
                              width: provider.screenSize.width * .4 * scale,
                              child: currentImage == null
                                  ? Padding(
                                      padding:
                                          EdgeInsets.all(provider.screenSize.width * 0.4 * .15),
                                      child: FittedBox(
                                        fit: BoxFit.fitWidth,
                                        child: ShaderMask(
                                          shaderCallback: (bounds) => Design
                                              .mainGradient
                                              .createShader(bounds),
                                          child: Image.asset('images/person_filled.png',
                                              color: Colors.white),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      decoration:
                                          const BoxDecoration(shape: BoxShape.circle),
                                      clipBehavior: Clip.antiAlias,
                                      child: Image(image:currentImage! , fit: BoxFit.cover,)
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(provider.screenSize.width * .3 * scale,
                          provider.screenSize.width * .3 * scale),
                      child: GestureDetector(
                        onTap: () async {
                          XFile? ximage = await ImagePicker().pickImage(
                              source: ImageSource.gallery);
                          if (ximage != null) {
                            currentImageFile = File(ximage.path);
                            currentImage = Image.memory(await currentImageFile!.readAsBytes()).image;

                            setState(() {});
                          }
                        },
                        child: Opacity(
                          opacity: registered ? values[0] : 1.0,
                          child: Transform.scale(
                            scale: registered || widget.logOut ? values[0] : 1.0,
                            alignment: Alignment.center,
                            child: AnimatedOpacity(
                              opacity: isSignInPage ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutQuad,
                              child: AnimatedScale(
                                scale: isSignInPage ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 400),
                                curve: isSignInPage ? Curves.easeOutQuad : Curves.easeOutBack,
                                alignment: Alignment.center,
                                child: Container(
                                    height: provider.screenSize.width * .4 * .25 * scale,
                                    width: provider.screenSize.width * .4 * .25 * scale,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: Design.mainGradient,
                                        boxShadow: [Design.shadow3]),
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
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool isButtonEnabled() {
    const pattern = r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
        r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
        r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
        r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
        r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
        r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
        r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])';
    final regex = RegExp(pattern);

    if (!regex.hasMatch(emailController.text) ||
        emailController.text.isEmpty ||
        passwordController.text.length < 8) return false;

    if (!isSignInPage &&
        (firstNameController.text.length < 3 ||
            lastNameController.text.length < 3)) return false;

    return true;
  }

  Future<bool> signIn(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (isButtonEnabled()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: emailController.text, password: passwordController.text);
        if (userCredential.user != null) {
          (await SharedPreferences.getInstance()).setString('user_id', userCredential.user!.uid);
          Map? userData =
          (await FirebaseDatabase.instance.ref('users/${userCredential.user!.uid}').get()).value
          as Map?;
          if (userData != null) {
            provider.currentUser = CurrentUser.fromJson(userData, userCredential.user!.uid);
            final fcmToken = await FirebaseMessaging.instance.getToken();
            if (fcmToken != null) {
              provider.currentUser?.messagingToken = fcmToken;
              await FirebaseDatabase.instance
                  .ref('users/${provider.currentUser!.id}')
                  .update({'messagingToken': fcmToken});
              return true;
            }
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Error: $e',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter'),
          ),
          backgroundColor: Design.mainColor,
        ),
        );
      }
    }
    return false;
  }

  Future<bool> signUp(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (isButtonEnabled()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: emailController.text, password: passwordController.text);
        if (userCredential.user != null) {
          String pfpLink = '';
          if (currentImage != null) {
            Random random = Random();

            final pfpLinkRef = FirebaseStorage
                .instance.ref(
                'user_profile_pictures/user_${userCredential.user!.uid}_pfp${random.nextInt(100000)}${path.extension(currentImageFile!.path)}');

            await pfpLinkRef.putFile(currentImageFile! , SettableMetadata(contentType: 'image/${path.extension(currentImageFile!.path).substring(1)}'));
            pfpLink = await pfpLinkRef.getDownloadURL();
          }

          final fcmToken = await FirebaseMessaging.instance.getToken();

          (await SharedPreferences.getInstance()).setString('user_id', userCredential.user!.uid);


          provider.currentUser = peach_user.CurrentUser(
              '${firstNameController.text} ${lastNameController.text}',
              userCredential.user!.uid,
              pfpLink,
              fcmToken??'',
              true,
              'Hello everyone!',
              peach_user.UserSettings(true, true, true), [], []);
          await FirebaseDatabase.instance
              .ref('users/${provider.currentUser!.id}')
              .set(provider.currentUser!.toJson());

          DatabaseReference chatRoomRef = FirebaseDatabase.instance.ref('chat_rooms/').push();

          await chatRoomRef.set({
            'typing': {userCredential.user!.uid: false, creatorId: false},
            'user_ids': {
              userCredential.user!.uid: userCredential.user!.uid,
              creatorId: creatorId
            }
          });

          await FirebaseDatabase.instance
              .ref('users/${userCredential.user!.uid}/friends/$creatorId')
              .set({'friend_id': creatorId, 'friend_chat_room_id': chatRoomRef.key});
          await FirebaseDatabase.instance
              .ref('users/$creatorId/friends/${userCredential.user!.uid}')
              .set({
            'friend_id': userCredential.user!.uid,
            'friend_chat_room_id': chatRoomRef.key
          });


          List<Message> messages = [
            Message(userId: creatorId, content: 'Welcome friend!', seen: false, date: DateTime.now(), messageType: 'text', liked: false),
            Message(userId: creatorId, content: 'My name is Ismail Ibrahim and I\'m the creator of this app', seen: false, date: DateTime.now(), messageType: 'text', liked: false),
            Message(userId: creatorId, content: 'I\'m glad that my application has caught your attention, and I hope you will like it!', seen: false, date: DateTime.now(), messageType: 'text', liked: false),
            Message(userId: creatorId, content: 'I\'d also gladly assist you through anything you would like to know about this application, that\'s why I made it so new comers would me add me automatically so you\'d be able to send me message at any time', seen: false, date: DateTime.now(), messageType: 'text', liked: false),
            Message(userId: creatorId, content: 'And don\'t worry this is not just a bot that\'s the real me, so try to send me anything and I\'ll respond as soon as possible!', seen: false, date: DateTime.now(), messageType: 'text', liked: false),
          ];
          for(Message m in messages) {
            await FirebaseDatabase.instance.ref('messages/${chatRoomRef.key}/${DateTime.now().microsecondsSinceEpoch}')
                .set(m.toJson());
          }

          await FirebaseDatabase.instance
              .ref(
              'users/${userCredential.user!.uid}/chat_rooms/${messages.last.date.microsecondsSinceEpoch}')
              .set({
            'chat_room_id': chatRoomRef.key,
          });

          await FirebaseDatabase.instance
              .ref(
              'users/$creatorId/chat_rooms/${messages.last.date.microsecondsSinceEpoch}')
              .set({
            'chat_room_id': chatRoomRef.key,
          });

          return true;

        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Error: $e',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter'),
          ),
          backgroundColor: Design.mainColor,
        ));
      }
    }
    return false;
  }
}


class BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Path path1 = Path();
    path1.moveTo(0, 0);
    path1.cubicTo(
        size.width * .2, 50, size.width * .4, 50, size.width * 0.6, 25);
    path1.cubicTo(size.width * .8, 10, size.width, 10, size.width * 1.2, 50);
    path1.lineTo(size.width, size.height * 2);
    path1.lineTo(0, size.height * 2);
    path1.close();

    Path path2 = Path();
    path2.moveTo(-size.width * .2, 40);
    path2.cubicTo(0, 0, size.width * .2, 00, size.width * 0.6, 40);
    path2.lineTo(size.width * .6, size.height * .2);
    path2.close();

    Path path3 = Path();
    path3.moveTo(size.width * .2, 45);
    path3.cubicTo(
        size.width * .4, 0, size.width * .6, 00, size.width * 0.8, 40);
    path3.close();

    Path path4 = Path();
    path4.moveTo(size.width * .5, 40);
    path4.cubicTo(
        size.width * .8, -40, size.width * 1, -40, size.width * 1.8, 40);
    path4.close();

    Paint paint1 = Paint()..color = Colors.white;
    Paint paint2 = Paint()..color = Colors.white24;

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
    canvas.drawPath(path3, paint2);
    canvas.drawPath(path4, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
