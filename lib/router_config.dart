import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_performance_test/main_menu_screen.dart';
import 'package:video_performance_test/multi_channel_test.dart';
import 'package:video_performance_test/player_compare_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const MainMenuScreen();
      },
    ),
    GoRoute(
      path: '/multichannel',
      name: 'multichannel',
      builder: (BuildContext context, GoRouterState state) {
        return const MultiChannelTestScreen();
      },
    ),
    GoRoute(
      path: '/player-compare',
      name: 'player-compare',
      builder: (BuildContext context, GoRouterState state) {
        return const PlayerCompareScreen();
      },
    ),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  },
);