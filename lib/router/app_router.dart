import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/teams/teams_list_screen.dart';
import '../features/teams/team_detail_screen.dart';
import '../features/teams/create_team_screen.dart';
import '../features/game/game_dashboard_screen.dart';
import '../features/game/whos_here_screen.dart';
import '../features/awards/awards_screen.dart';
import '../features/history/history_screen.dart';
import '../features/history/game_summary_screen.dart';

enum AppRoute {
  teams('/teams'),
  gameDashboard('/game'),
  awards('/awards'),
  history('/history'),
  gameSummary('/history/:gameUuid'),
  teamDetail('/teams/:teamUuid'),
  ;

  const AppRoute(this.path);
  final String path;
}

final goRouter = GoRouter(
  initialLocation: AppRoute.teams.path,
  errorBuilder: (context, state) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Text(
                state.error!.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    ),
  ),
  routes: [
    GoRoute(
      path: AppRoute.teams.path,
      name: 'teams',
      builder: (_, __) => const TeamsListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          name: 'createTeam',
          builder: (_, __) => const CreateTeamScreen(),
        ),
        GoRoute(
          path: ':teamUuid',
          name: 'teamDetail',
          builder: (context, state) {
            final teamUuid = state.pathParameters['teamUuid'] ?? '';
            return TeamDetailScreen(teamUuid: teamUuid);
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRoute.gameDashboard.path,
      name: 'gameDashboard',
      builder: (_, __) => const GameDashboardScreen(),
      routes: [
        GoRoute(
          path: 'whos-here/:teamUuid',
          name: 'whosHere',
          builder: (context, state) {
            final teamUuid = state.pathParameters['teamUuid'] ?? '';
            return WhosHereScreen(teamUuid: teamUuid);
          },
        ),
      ],
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
