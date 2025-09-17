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
    super.initState();
    initializePlayer();
  }

  void initializePlayer() async {
    controller = VideoPlayerController.asset(
      'asset/display-rotate_key_no_audio.mp4',
    );
    await controller!.initialize();

    setState(() {
      videoDuration = controller!.value.duration;
      print('[bobby] ${videoDuration.inMilliseconds}');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        VideoPlayer(controller!),
        GestureDetector(
          onTapDown: (details) async {
            if (controller == null) return;

            final downTime = DateTime.now();
            await controller!.seekTo(Duration(milliseconds: 2200)).then((_) {
              print('haha bobby');
            });
            print(
              '[Bobby] seekTo took ${DateTime.now().difference(downTime).inMilliseconds}ms',
            );
          },
          onTapUp: (details) {
            controller?.seekTo(Duration(milliseconds: 0));
          },
          // onHorizontalDragUpdate: (details) async {
          //   distance += details.delta.dx;
          //   distance = distance.clamp(0, 200);

          //   final sensitivity = videoDuration.inMilliseconds / 200;
          //   final currentTime = sensitivity * distance;

          //   if (!shouldSkipFrame()) {
          //     if (currentTime == videoDuration.inMilliseconds.toDouble()) {
          //       print('[BOBBY] $currentTime');
          //       // return;
          //     }
          //     controller?.seekTo(Duration(milliseconds: currentTime.toInt())).then((
          //       _,
          //     ) {
          //       print(
          //         'BOBBY ${currentTime == videoDuration.inMilliseconds.toDouble()}',
          //       );
          //       if (currentTime == videoDuration.inMilliseconds.toDouble()) {
          //         print('[BOBBY] SeekTo Complete');
          //         return;
          //       }
          //     });
          //   }
          // },
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
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
