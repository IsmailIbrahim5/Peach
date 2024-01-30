import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:peach/Classes/main_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Classes/design_constants.dart';
import '../Classes/user_classes.dart';
import '../Widgets/sequence_animation_builder.dart';
import 'home.dart';
import '../main.dart';
import 'register.dart';

class Welcome extends StatefulWidget {
  const Welcome({super.key});

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  bool registered = false;

  SequenceAnimationController controller = SequenceAnimationController();

  late MainProvider provider;
  @override
  void initState() {
    super.initState();
    initCurrentUser();
  }

  void initCurrentUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    String? id = prefs.getString('user_id');

    if (id == null) {
      await Future.delayed(
        const Duration(seconds: 2),
        () => Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const Register(),
          ),
        ),
      );
    } else {
      Map? userData =
          (await FirebaseDatabase.instance.ref('users/$id').get()).value
              as Map?;
      if (userData != null) {
        provider.currentUser = CurrentUser.fromJson(userData, id);
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          provider.currentUser?.messagingToken = fcmToken;
          FirebaseDatabase.instance
              .ref('users/${provider.currentUser!.id}')
              .update({'messagingToken': fcmToken});
          await Future.delayed(
              const Duration(seconds: 1), () => controller.reverse!());
        }
      } else {
        prefs.remove('user_id');
        await Future.delayed(
          const Duration(seconds: 2),
          () => Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 600),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const Register(),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    provider = Provider.of<MainProvider>(context);
    provider.screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const BackgroundGradient(),
            SequenceAnimationBuilder(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              controller: controller,
              animations: 1,
              repeat: false,
              endCallback: () {
                Navigator.of(context).pushReplacement(PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const Home(),
                    transitionDuration: Duration.zero));
              },
              builder: (values, [child]) => UpwardCrossFade(
                value: values[0],
                child: Transform.scale(
                  scale: .7,
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
            )
          ],
        ),
      ),
    );
  }
}
