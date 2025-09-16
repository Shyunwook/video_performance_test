import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Scaffold(body: VideoPlayerTest()));
  }
}

class VideoPlayerTest extends StatefulWidget {
  const VideoPlayerTest({super.key});

  @override
  State<VideoPlayerTest> createState() => VvideoPlayerTestState();
}

class VvideoPlayerTestState extends State<VideoPlayerTest> {
  VideoPlayerController? controller;
  late Duration videoDuration;
  double distance = 0;
  double lastFrameTime = 0;

  @override
  void initState() {
    controller = VideoPlayerController.asset('asset/screw.mp4');
    controller?.initialize().then((_) {
      setState(() {
        videoDuration = controller!.value.duration;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) SizedBox.shrink();

    return Stack(
      children: [
        VideoPlayer(controller!),
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            distance += details.delta.dx;
            distance = distance.clamp(0, 200);

            final sensitivity = videoDuration.inMilliseconds / 200;
            final currentTime = sensitivity * distance;

            if (!shouldSkipFrame()) {
              print('[BOBBY] $currentTime');
              controller?.seekTo(Duration(milliseconds: currentTime.toInt()));
            }
          },
          child: Container(color: Colors.red.withAlpha(50)),
        ),
      ],
    );
  }

  bool shouldSkipFrame() {
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    final timeSinceLastFrame = now - lastFrameTime;

    if (timeSinceLastFrame < 33) {
      return true;
    }

    lastFrameTime = now;
    return false;
  }

  //   shouldSkipFrame() {
  //   // 60fps 제한 (16ms 간격)
  //   const now = performance.now();
  //   const timeSinceLastFrame = now - this.lastFrameTime;

  //   if (timeSinceLastFrame < 16) {
  //     return true; // 프레임 스킵
  //   }

  //   this.lastFrameTime = now;
  //   this.frameCount++;
  //   return false;
  // }
}
