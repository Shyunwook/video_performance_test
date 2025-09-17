import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:video_performance_test/router_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Video Performance Test',
      routerConfig: router,
    );
  }
}
