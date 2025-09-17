import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';

class MultiChannelTestScreen extends StatefulWidget {
  const MultiChannelTestScreen({super.key});

  @override
  State<MultiChannelTestScreen> createState() => _MultiChannelTestScreenState();
}

class _MultiChannelTestScreenState extends State<MultiChannelTestScreen>
    with WidgetsBindingObserver {
  bool _useMediaKit = true;
  late final AudioPlayer _audioPlayer;
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() async {
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer.setAsset('asset/chapa.mp3');
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isAudioPlaying = state.playing;
          });
        }
      });
    } catch (e) {
      debugPrint('Audio setup error: $e');
    }
  }

  void _toggleAudio() async {
    if (_isAudioPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  void _toggleVideoPlayer() {
    setState(() {
      _useMediaKit = !_useMediaKit;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        // 앱이 백그라운드로 이동 시 오디오 일시정지
        if (_isAudioPlaying) {
          _audioPlayer.pause();
        }
        break;
      case AppLifecycleState.resumed:
        // 앱이 포그라운드로 복귀 시 - 사용자가 수동으로 재생해야 함
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          _useMediaKit ? 'media_kit (libmpv)' : 'video_player (ExoPlayer)',
        ),
        backgroundColor: _useMediaKit ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Switch(
            value: _useMediaKit,
            onChanged: (value) => _toggleVideoPlayer(),
            activeColor: Colors.white,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _useMediaKit
                ? const MediaKitVideoTest()
                : const VideoPlayerVideoTest(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  _useMediaKit
                      ? '🟢 Testing media_kit + just_audio'
                      : '🔵 Testing video_player + just_audio',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _toggleAudio,
                  child: Text(_isAudioPlaying ? 'Stop Audio (chapa.mp3)' : 'Play Audio (chapa.mp3)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// MediaKit Video Test Widget
class MediaKitVideoTest extends StatefulWidget {
  const MediaKitVideoTest({super.key});

  @override
  State<MediaKitVideoTest> createState() => _MediaKitVideoTestState();
}

class _MediaKitVideoTestState extends State<MediaKitVideoTest> {
  Player? _player;
  VideoController? _videoController;
  bool _isVideoLoading = true;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      MediaKit.ensureInitialized();

      _player = Player();
      _videoController = VideoController(_player!);

      _player!.stream.buffering.listen((isBuffering) {
        if (mounted) {
          setState(() {
            _isVideoLoading = isBuffering;
          });
        }
      });

      _player!.stream.error.listen((error) {
        if (mounted) {
          setState(() {
            _videoError = error.toString();
            _isVideoLoading = false;
          });
        }
      });

      _player!.stream.playing.listen((isPlaying) {
        if (mounted && !isPlaying && !_isVideoLoading) {
          setState(() {
            _isVideoLoading = false;
          });
        }
      });

      await _player!.open(Media('asset:///asset/poop_explorers.mp4'));
      await _player!.pause();
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoError = e.toString();
          _isVideoLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Media Kit Error: $_videoError'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _videoError = null;
                  _isVideoLoading = true;
                });
                _initializeVideo();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isVideoLoading || _videoController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text('Loading media_kit video...'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Video(controller: _videoController!),
        GestureDetector(
          onTap: () {
            if (_player!.state.playing) {
              _player!.pause();
            } else {
              _player!.play();
            }
          },
          child: Container(
            color: Colors.transparent,
            child: const Center(
              child: Text(
                'TAP: Play/Pause media_kit video\n(poop_explorers.mp4)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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
}

// VideoPlayer Video Test Widget
class VideoPlayerVideoTest extends StatefulWidget {
  const VideoPlayerVideoTest({super.key});

  @override
  State<VideoPlayerVideoTest> createState() => _VideoPlayerVideoTestState();
}

class _VideoPlayerVideoTestState extends State<VideoPlayerVideoTest> {
  VideoPlayerController? _controller;
  bool _isVideoLoading = true;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('asset/poop_explorers.mp4');
      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isVideoLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoError = e.toString();
          _isVideoLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Video Player Error: $_videoError'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _videoError = null;
                  _isVideoLoading = true;
                });
                _initializeVideo();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isVideoLoading || _controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text('Loading video_player video...'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        VideoPlayer(_controller!),
        GestureDetector(
          onTap: () {
            if (_controller!.value.isPlaying) {
              _controller!.pause();
            } else {
              _controller!.play();
            }
          },
          child: Container(
            color: Colors.transparent,
            child: const Center(
              child: Text(
                'TAP: Play/Pause video_player video\n(poop_explorers.mp4)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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
}
