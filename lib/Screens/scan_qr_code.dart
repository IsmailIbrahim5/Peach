
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:peach/Classes/design_constants.dart';
import 'dart:math' as math;

import '../main.dart';

class ScanQRCode extends StatefulWidget {
  final Function(String id) callback;
  const ScanQRCode({super.key, required this.callback});

  @override
  State<ScanQRCode> createState() => _ScanQRCodeState();
}

class _ScanQRCodeState extends State<ScanQRCode>
    with SingleTickerProviderStateMixin {
  String data = '';

  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
  late CameraDescription camera;

  @override
  void initState() {
    super.initState();

    init();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  CameraController? _controller;

  void init() async {
    final cameras = await availableCameras(); // your camera instance
    for (CameraDescription c in cameras) {
      if (c.lensDirection == CameraLensDirection.back) {
        camera = c;
      }
    }
    _controller = CameraController(camera, ResolutionPreset.max,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.nv21 ,);

    _controller?.initialize().then((value) {
      _controller?.startImageStream(_inputImageFromCameraImage);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {

    final screenSize = MediaQuery.sizeOf(context);
    double scale = (1 / screenSize.aspectRatio) / (_controller?.value.aspectRatio ?? 1);
    return Scaffold(
      body: Stack(
        children: [
            if(_controller != null)
              Transform.scale(
                scale: scale,
                alignment: Alignment.topCenter,
                child: CameraPreview(
                  _controller!,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedOpacity(
                        opacity: data.isNotEmpty ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        child: SizedBox(
                          width: screenSize.width * .5,
                          height: screenSize.width * .5,
                          child: CustomPaint(
                            painter: QrScannerPainter(),
                          ),
                        ),
                      ),
                    ],
                  ),

                ),
              ),
          AnimatedOpacity(
            opacity: _controller == null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            child: Container(
              color: Design.activeColor,
              child: Center(
                child: Transform.scale(
                  scale: .5 ,
                  child: Image.asset(
                    'images/camera.png',
                    color: Colors.white,
                    width: screenSize.width,
                  ),
                ),
              ),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                width: math.sqrt(((screenSize.height) * (screenSize.height)) +
                        (screenSize.width * screenSize.width)) *
                    (data.isEmpty ? 0 : 1.0),
                height: math.sqrt(((screenSize.height) * (screenSize.height)) +
                        (screenSize.width * screenSize.width)) *
                    (data.isEmpty ? 0 : 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Design.activeColor),
                ),
              ),
              AnimatedScale(
                scale: data.isEmpty ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                onEnd: () => Future.delayed(
                  const Duration(milliseconds: 400),
                      () {
                    // scannerController.stop();
                    widget.callback(data);
                    Navigator.of(context).pop();
                  },
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 200,
                ),
              )
            ],
          ),

        ],
      ),
    );
  }

  void _inputImageFromCameraImage(CameraImage image) async{
    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/android/src/main/java/com/google_mlkit_commons/InputImageConverter.java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/ios/Classes/MLKVisionImage%2BFlutterPlugin.m
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/example/lib/vision_detector_views/painters/coordinates_translator.dart
    final sensorOrientation = camera.sensorOrientation;
    // print(
    //     'lensDirection: ${camera.lensDirection}, sensorOrientation: $sensorOrientation, ${_controller?.value.deviceOrientation} ${_controller?.value.lockedCaptureOrientation} ${_controller?.value.isCaptureOrientationLocked}');
    InputImageRotation? rotation;

    var rotationCompensation =
        _orientations[_controller?.value.deviceOrientation];
    if (rotationCompensation == null) return null;
    if (camera.lensDirection == CameraLensDirection.front) {
      // front-facing
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      // back-facing
      rotationCompensation =
          (sensorOrientation - rotationCompensation + 360) % 360;
    }
    rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    // print('rotationCompensation: $rotationCompensation');
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    final inputImage = InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
    final barcodes = await _barcodeScanner.processImage(inputImage);

    if(barcodes.isNotEmpty) {
      if (barcodes.firstOrNull?.rawValue != null) {
        print('found barcode: ${barcodes.firstOrNull?.rawValue}');
        _controller?.pausePreview();
        setState(() {
          data = barcodes.firstOrNull!.rawValue!;
        });
      }
    }
  }
}

class QrScannerPainter extends CustomPainter {
  final double gap = .25;
  final double width = 12.0;
  final double curve = .75;

  QrScannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    Path path = Path()
      ..moveTo(0, (size.height * (1 - gap)) / 2)
      ..lineTo(0, ((size.height * (1 - gap)) / 2) * curve)
      ..cubicTo(0, 0, 0, 0, ((size.width * (1 - gap)) / 2) * curve, 0)
      ..lineTo(((size.width * (1 - gap)) / 2), 0)
      ..moveTo(0, (size.height * (1 + gap)) / 2)
      ..lineTo(0, ((size.height * (1 + gap)) / 2) * (2 - curve))
      ..cubicTo(0, size.height, 0, size.height,
          ((size.width * (1 - gap)) / 2) * curve, size.height)
      ..lineTo(((size.width * (1 - gap)) / 2), size.height)
      ..moveTo(((size.width * (1 + gap)) / 2), size.height)
      ..lineTo(((size.width * (1 + gap)) / 2) * (2 - curve), size.height)
      ..cubicTo(size.width, size.height, size.width, size.height, size.width,
          ((size.height * (1 + gap)) / 2) * (2 - curve))
      ..lineTo(size.width, ((size.height * (1 + gap)) / 2))
      ..moveTo(size.width, ((size.width * (1 - gap)) / 2))
      ..lineTo(size.width, ((size.width * (1 - gap)) / 2) * curve)
      ..cubicTo(size.width, 0, size.width, 0,
          ((size.width * (1 + gap)) / 2) * (2 - curve), 0)
      ..lineTo(((size.width * (1 + gap)) / 2), 0);
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = Colors.red;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
