import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/achievements_screen.dart';
import '../../features/cards/cards_review_screen.dart';
import '../../features/cards/cards_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/mindmap/mindmap_screen.dart';
import '../../features/notes/note_detail_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/ocr/ocr_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/quiz/quiz_setup_screen.dart';
import '../../features/settings/about_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../animations/page_transitions.dart';
import 'route_paths.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        pageBuilder: (context, state) =>
            ZinkPageTransition.fade(const SplashScreen()),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        pageBuilder: (context, state) =>
            ZinkPageTransition.fadeUp(const OnboardingScreen()),
      ),

      // Shell с табами
      ShellRoute(
        builder: (context, state, child) {
          return HomeShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: RoutePaths.home,
            pageBuilder: (context, state) =>
                ZinkPageTransition.fade(const HomeScreen()),
          ),
          GoRoute(
            path: RoutePaths.notes,
            pageBuilder: (context, state) =>
                ZinkPageTransition.fade(const NotesScreen()),
          ),
          GoRoute(
            path: RoutePaths.achievements,
            pageBuilder: (context, state) =>
                ZinkPageTransition.fade(const AchievementsScreen()),
          ),
          GoRoute(
            path: RoutePaths.settings,
            pageBuilder: (context, state) =>
                ZinkPageTransition.fade(const SettingsScreen()),
          ),
        ],
      ),

      // Детальные экраны (без таб-бара)
      GoRoute(
        path: '/notes/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return ZinkPageTransition.fadeUp(NoteDetailScreen(noteId: id));
        },
      ),
      GoRoute(
        path: RoutePaths.chat,
        pageBuilder: (context, state) =>
            ZinkPageTransition.fadeUp(const ChatScreen()),
      ),
      GoRoute(
        path: '/chat/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return ZinkPageTransition.fadeUp(ChatScreen(sessionId: id));
        },
      ),
      GoRoute(
        path: RoutePaths.chatHistory,
        pageBuilder: (context, state) =>
            ZinkPageTransition.fadeUp(const HistoryScreen()),
      ),
      GoRoute(
        path: RoutePaths.cards,
        pageBuilder: (context, state) =>
            ZinkPageTransition.fadeUp(const CardsScreen()),
      ),
      GoRoute(
        path: RoutePaths.cardsReview,
        pageBuilder: (context, state) =>
            ZinkPageTransition.fadeUp(const CardsReviewScreen()),
      ),
      GoRoute(
        path: RoutePaths.quiz,
        pageBuilder: (context, state) =>
            ZinkPageTransition.fadeUp(const QuizSetupScreen()),
      ),
      GoRoute(
        path: RoutePaths.mindmap,
        pageBuilder: (context, state) =>
            ZinkPageTransition.fadeUp(const MindMapScreen()),
      ),
      GoRoute(
        path: RoutePaths.ocr,
        pageBuilder: (context, state) =>
            ZinkPageTransition.fadeUp(const OcrScreen()),
      ),
      GoRoute(
        path: RoutePaths.about,
        pageBuilder: (context, state) =>
            ZinkPageTransition.fadeUp(const AboutScreen()),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Маршрут не найден: ${state.uri.path}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );
});
