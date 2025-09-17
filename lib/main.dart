import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: PlayerTestSelector());
  }
}

class PlayerTestSelector extends StatefulWidget {
  const PlayerTestSelector({super.key});

  @override
  State<PlayerTestSelector> createState() => _PlayerTestSelectorState();
}

class _PlayerTestSelectorState extends State<PlayerTestSelector> {
  bool useMediaKit = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          useMediaKit ? 'media_kit (libmpv)' : 'video_player (ExoPlayer)',
        ),
        backgroundColor: useMediaKit ? Colors.green : Colors.blue,
        actions: [
          Switch(
            value: useMediaKit,
            onChanged: (value) {
              setState(() {
                useMediaKit = value;
              });
            },
            activeColor: Colors.white,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: useMediaKit ? const MediaKitTest() : const VideoPlayerTest(),
    );
  }
}

// MediaKit Test Widget
class MediaKitTest extends StatefulWidget {
  const MediaKitTest({super.key});

  @override
  State<MediaKitTest> createState() => _MediaKitTestState();
}

class _MediaKitTestState extends State<MediaKitTest> {
  Player? player;
  VideoController? videoController;
  late Duration videoDuration;
  double distance = 0;
  double lastFrameTime = 0;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  void initializePlayer() async {
    player = Player(configuration: PlayerConfiguration());
    videoController = VideoController(
      player!,
      configuration: VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );

    player!.stream.duration.listen((duration) {
      if (duration != Duration.zero) {
        setState(() {
          videoDuration = duration;
          print('[bobby] ${videoDuration.inMilliseconds} - media_kit libmpv');
        });
      }
    });

    await player!.open(Media('asset:///asset/screw.mp4'));
    await player!.pause(); // 자동 재생 중지
  }

  @override
  Widget build(BuildContext context) {
    if (videoController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Video(
          controller: videoController!,
          controls: NoVideoControls, // UI 제거
        ),
        GestureDetector(
          onTapDown: (details) async {
            if (player == null) return;

            final downTime = DateTime.now();
            await player!.seek(Duration(milliseconds: 1100)).then((_) {
              print('🟢 media_kit seek completed');
            });
            print(
              '🟢 [media_kit] seekTo took ${DateTime.now().difference(downTime).inMilliseconds}ms',
            );
          },
          onTapUp: (details) {
            player?.seek(Duration(milliseconds: 0));
          },
          onHorizontalDragUpdate: (details) async {
            distance += details.delta.dx;
            distance = distance.clamp(0, 200);

            final sensitivity = videoDuration.inMilliseconds / 200;
            final currentTime = sensitivity * distance;

            if (!shouldSkipFrame()) {
              if (currentTime == videoDuration.inMilliseconds.toDouble()) {
                print('[MEDIA_KIT] $currentTime');
                // return;
              }
              player?.seek(Duration(milliseconds: currentTime.toInt())).then((
                _,
              ) {
                print(
                  'MEDIA_KIT ${currentTime == videoDuration.inMilliseconds.toDouble()}',
                );
                if (currentTime == videoDuration.inMilliseconds.toDouble()) {
                  print('[MEDIA_KIT] SeekTo Complete');
                  return;
                }
              });
            }
          },
          child: Container(
            color: Colors.transparent,
            child: const Center(
              child: Text(
                'TAP: media_kit seek test\n(libmpv engine)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10.0, color: Colors.black)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    player?.dispose();
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
}

// VideoPlayer Test Widget
class VideoPlayerTest extends StatefulWidget {
  const VideoPlayerTest({super.key});

  @override
  State<VideoPlayerTest> createState() => _VideoPlayerTestState();
}

class _VideoPlayerTestState extends State<VideoPlayerTest> {
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
    controller = VideoPlayerController.asset('asset/screw.mp4');
    await controller!.initialize();

    setState(() {
      videoDuration = controller!.value.duration;
      print('[bobby] ${videoDuration.inMilliseconds} - video_player ExoPlayer');
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
            await controller!.seekTo(Duration(milliseconds: 1100)).then((_) {
              print('🔵 video_player seek completed');
            });
            print(
              '🔵 [video_player] seekTo took ${DateTime.now().difference(downTime).inMilliseconds}ms',
            );
          },
          onTapUp: (details) {
            controller?.seekTo(Duration(milliseconds: 0));
          },
          onHorizontalDragUpdate: (details) async {
            distance += details.delta.dx;
            distance = distance.clamp(0, 200);

            final sensitivity = videoDuration.inMilliseconds / 200;
            final currentTime = sensitivity * distance;

            if (!shouldSkipFrame()) {
              if (currentTime == videoDuration.inMilliseconds.toDouble()) {
                print('[VIDEO_PLAYER] $currentTime');
                // return;
              }
              controller?.seekTo(Duration(milliseconds: currentTime.toInt())).then((
                _,
              ) {
                print(
                  'VIDEO_PLAYER ${currentTime == videoDuration.inMilliseconds.toDouble()}',
                );
                if (currentTime == videoDuration.inMilliseconds.toDouble()) {
                  print('[VIDEO_PLAYER] SeekTo Complete');
                  return;
                }
              });
            }
          },
          child: Container(
            color: Colors.transparent,
            child: const Center(
              child: Text(
                'TAP: video_player seek test\n(ExoPlayer engine)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10.0, color: Colors.black)],
                ),
              ),
            ),
          ),
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
}
