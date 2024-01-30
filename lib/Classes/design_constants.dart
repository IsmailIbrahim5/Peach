import 'package:flutter/material.dart';

class Design{
  static const Color mainColor = Color(0xFFFE8896);
  static const Color peachColor = Color(0xFFFE9688);
  static const Color activeColor = Color(0xFF56E375);
  static Gradient mainGradient = LinearGradient(
      begin:  Alignment.topLeft,
      end: Alignment.bottomRight,
      colors:[
        const Color(0xFFF99C7E).withOpacity(.75),
        const Color(0xFFF97E96).withOpacity(.75)
      ]
  );

  static BoxShadow shadow1 =  BoxShadow(
      color: const Color(0xFF652222).withOpacity(.25),
      blurRadius: 18,
      offset: const Offset(0 , 13.0)
  );


  static BoxShadow shadow2 =  const BoxShadow(
      color: Color(0xFF50F675),
      blurRadius: 20,
      offset: Offset(0 , 8.0)
  );

  static BoxShadow shadow3 =  BoxShadow(
      color: mainColor.withOpacity(.25),
      blurRadius: 20,
      spreadRadius: 4,
      offset: const Offset(0 , 4.0)
  );
}

class BackgroundGradient extends StatelessWidget {
  const BackgroundGradient({super.key});

  @override
  Widget build(BuildContext context) {
    // return Stack(
    //   children: [
    //     Positioned(
    //       width: math.sqrt(math.pow(screenSize.width, 2) +
    //           math.pow(screenSize.height, 2)),
    //       height: math.sqrt(math.pow(screenSize.width, 2) +
    //           math.pow(screenSize.height, 2)),
    //       left: -screenSize.width,
    //       top:  - screenSize.height * 0.15,
    //       child: ImageFiltered(
    //         imageFilter:
    //         ImageFilter.blur(sigmaX: 100.0, sigmaY: 100.0),
    //         child: Container(
    //           decoration: BoxDecoration(
    //               color: Color(0xFFD33535).withOpacity(.75),
    //               shape: BoxShape.circle),
    //         ),
    //       ),
    //     ),
    //     Positioned(
    //       width: math.sqrt(math.pow(screenSize.width, 2) +
    //           math.pow(screenSize.height, 2)),
    //       height: math.sqrt(math.pow(screenSize.width, 2) +
    //           math.pow(screenSize.height, 2)),
    //       left: -screenSize.width / 2,
    //       top: screenSize.height / 2,
    //       child: ImageFiltered(
    //         imageFilter:
    //         ImageFilter.blur(sigmaX: 500.0, sigmaY: 500.0),
    //         child: Container(
    //           decoration: BoxDecoration(
    //               color: Color(0xFFD39435).withOpacity(.75),
    //               shape: BoxShape.circle),
    //         ),
    //       ),
    //     ),
    //     Positioned(
    //       width: math.sqrt(math.pow(screenSize.width, 2) +
    //           math.pow(screenSize.height, 2)),
    //       height: math.sqrt(math.pow(screenSize.width, 2) +
    //           math.pow(screenSize.height, 2)),
    //       left: screenSize.width * 0.5,
    //       top:  - screenSize.height * 0.25,
    //       child: ImageFiltered(
    //         imageFilter:
    //         ImageFilter.blur(sigmaX: 500.0, sigmaY: 500.0),
    //         child: Container(
    //           decoration: BoxDecoration(
    //               color: Color(0xFF9735D3).withOpacity(.75),
    //               shape: BoxShape.circle),
    //         ),
    //       ),
    //     ),
    //   ],
    // );
    return Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin:  Alignment.topLeft,
                end: Alignment.bottomRight,
                colors:[
                  const Color(0xFFF99C7E).withOpacity(.75),
                  const Color(0xFFF97E96).withOpacity(.75)
                ]
            )
        )
    );
  }
}