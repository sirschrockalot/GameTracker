import 'package:go_router/go_router.dart';

import '../features/team_setup/team_setup_screen.dart';
import '../features/game/game_dashboard_screen.dart';
import '../features/awards/awards_screen.dart';
import '../features/history/history_screen.dart';
import '../features/history/game_summary_screen.dart';

enum AppRoute {
  teamSetup('/'),
  gameDashboard('/game'),
  awards('/awards'),
  history('/history'),
  gameSummary('/history/:gameUuid'),
  ;

  const AppRoute(this.path);
  final String path;
}

final goRouter = GoRouter(
  initialLocation: AppRoute.teamSetup.path,
  routes: [
    GoRoute(
      path: AppRoute.teamSetup.path,
      name: 'teamSetup',
      builder: (_, __) => const TeamSetupScreen(),
    ),
    GoRoute(
      path: AppRoute.gameDashboard.path,
      name: 'gameDashboard',
      builder: (_, __) => const GameDashboardScreen(),
    ),
    GoRoute(
      path: AppRoute.awards.path,
      name: 'awards',
      builder: (_, __) => const AwardsScreen(),
    ),
    GoRoute(
      path: AppRoute.history.path,
      name: 'history',
      builder: (_, __) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/history/:gameUuid',
      name: 'gameSummary',
      builder: (context, state) {
        final gameUuid = state.pathParameters['gameUuid'] ?? '';
        return GameSummaryScreen(gameUuid: gameUuid);
      },
    ),
  ],
);
