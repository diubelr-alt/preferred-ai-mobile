import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } catch (e) {
    cameras = [];
    debugPrint("Camera error: $e");
  }

  runApp(const PreferredAIApp());
}

class PreferredAIApp extends StatelessWidget {
  const PreferredAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CameraScreen(),
    );
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;

  Offset? A;
  Offset? B;
  Offset? C;

  double lengthFeet = 0;
  double widthFeet = 0;

  bool cameraError = false;
  String errorText = "";

  @override
  void initState() {
    super.initState();

    initCamera();
  }

  Future<void> initCamera() async {
    try {
      if (cameras.isEmpty) {
        cameraError = true;
        errorText = "No camera detected";
        setState(() {});
        return;
      }

      controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller!.initialize();

      if (!mounted) return;

      setState(() {});
    } catch (e) {
      cameraError = true;
      errorText = e.toString();

      debugPrint("Init camera error: $e");

      if (mounted) {
        setState(() {});
      }
    }
  }

  void tapPoint(TapDownDetails tap) {
    final p = tap.localPosition;

    setState(() {
      if (A == null) {
        A = p;
      } else if (B == null) {
        B = p;

        lengthFeet =
            ((B! - A!).distance) * 0.1;
      } else if (C == null) {
        C = p;

        widthFeet =
            ((C! - B!).distance) * 0.1;
      } else {
        A = p;
        B = null;
        C = null;
        lengthFeet = 0;
        widthFeet = 0;
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (cameraError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            errorText,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (controller == null ||
        !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: tapPoint,
        child: Stack(
          children: [
            SizedBox.expand(
              child: CameraPreview(controller!),
            ),

            CustomPaint(
              painter: LinePainter(A, B, C),
              child: Container(),
            ),

            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black.withOpacity(0.7),
                child: Text(
                  "Length: ${lengthFeet.toStringAsFixed(2)} ft\n"
                  "Width: ${widthFeet.toStringAsFixed(2)} ft\n"
                  "Area: ${(lengthFeet * widthFeet).toStringAsFixed(2)} sq.ft",
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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

class LinePainter extends CustomPainter {
  final Offset? A;
  final Offset? B;
  final Offset? C;

  LinePainter(this.A, this.B, this.C);

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.red
      ..strokeWidth = 4;

    final paintPoint = Paint()
      ..color = Colors.green;

    if (A != null) {
      canvas.drawCircle(A!, 8, paintPoint);
    }

    if (A != null && B != null) {
      canvas.drawLine(A!, B!, paintLine);
      canvas.drawCircle(B!, 8, paintPoint);
    }

    if (B != null && C != null) {
      canvas.drawLine(B!, C!, paintLine);
      canvas.drawCircle(C!, 8, paintPoint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}