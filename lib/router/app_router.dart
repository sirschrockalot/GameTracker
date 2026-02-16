import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/isar/models/join_request.dart';
import '../features/teams/teams_list_screen.dart';
import '../features/teams/team_detail_screen.dart';
import '../features/teams/team_access_blocked_screen.dart';
import '../features/teams/create_team_screen.dart';
import '../features/teams/join_team_screen.dart';
import '../features/parent/parent_home_screen.dart';
import '../features/game/game_dashboard_screen.dart';
import '../features/game/whos_here_screen.dart';
import '../features/awards/awards_screen.dart';
import '../features/history/history_screen.dart';
import '../features/history/game_summary_screen.dart';
import '../features/history/season_totals_screen.dart';
import '../features/schedule/coach_schedule_screen.dart';
import '../providers/join_request_provider.dart';

enum AppRoute {
  teams('/teams'),
  gameDashboard('/game'),
  schedule('/schedule'),
  awards('/awards'),
  history('/history'),
  gameSummary('/history/:gameUuid'),
  teamDetail('/teams/:teamUuid'),
  parentHome('/parent/:teamUuid'),
  ;

  const AppRoute(this.path);
  final String path;
}

/// Platform-adaptive page: iOS uses CupertinoPage (slide + back gesture),
/// Android uses MaterialPage.
Page<void> platformPageRoute(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return CupertinoPage(key: state.pageKey, child: child);
  }
  return MaterialPage(key: state.pageKey, child: child);
}

final goRouter = GoRouter(
  initialLocation: AppRoute.teams.path,
  redirect: (context, state) async {
    final container = ProviderScope.containerOf(context);
    final loc = state.matchedLocation;

    // Coach-only routes: redirect parent to teams list
    if (loc == '/game' || loc.startsWith('/game/') ||
        loc == '/schedule' || loc == '/awards' ||
        loc == '/history' || loc.startsWith('/history/')) {
      final canAccess = await container.read(canAccessCoachNavProvider.future);
      if (!canAccess) return '/teams';
    }

    // Team detail: redirect by role to parent home or blocked screen
    final teamDetailMatch = state.pathParameters['teamUuid'];
    if (loc.startsWith('/teams/') && teamDetailMatch != null &&
        !loc.endsWith('/pending') && !loc.endsWith('/blocked') &&
        loc != '/teams/join' && loc != '/teams/new') {
      final teamUuid = state.uri.pathSegments.length >= 2
          ? state.uri.pathSegments[1]
          : teamDetailMatch;
      if (teamUuid.isNotEmpty && teamUuid != 'join' && teamUuid != 'new') {
        final membership = await container.read(
          userTeamMembershipProvider(teamUuid).future,
        );
        if (membership.team == null) return null;
        if (membership.isOwner) return null; // owner -> team detail
        final m = membership.membership;
        if (m == null) return null; // no request -> team detail (e.g. owner only)
        if (m.status == JoinRequestStatus.approved) {
          if (m.role == TeamMemberRole.parent) return '/parent/$teamUuid';
          return null; // coach -> team detail
        }
        if (m.status == JoinRequestStatus.pending) return '/teams/$teamUuid/pending';
        if (m.status == JoinRequestStatus.rejected ||
            m.status == JoinRequestStatus.revoked) {
          return '/teams/$teamUuid/blocked';
        }
      }
    }

    return null;
  },
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
      pageBuilder: (context, state) =>
          platformPageRoute(context, state, const TeamsListScreen()),
      routes: [
        GoRoute(
          path: 'new',
          name: 'createTeam',
          pageBuilder: (context, state) =>
              platformPageRoute(context, state, const CreateTeamScreen()),
        ),
        GoRoute(
          path: 'join',
          name: 'joinTeam',
          pageBuilder: (context, state) =>
              platformPageRoute(context, state, const JoinTeamScreen()),
        ),
        GoRoute(
          path: ':teamUuid',
          name: 'teamDetail',
          pageBuilder: (context, state) {
            final teamUuid = state.pathParameters['teamUuid'] ?? '';
            return platformPageRoute(
              context,
              state,
              TeamDetailScreen(teamUuid: teamUuid),
            );
          },
          routes: [
            GoRoute(
              path: 'pending',
              name: 'teamPending',
              pageBuilder: (context, state) {
                final teamUuid = state.pathParameters['teamUuid'] ?? '';
                return platformPageRoute(
                  context,
                  state,
                  TeamAccessBlockedScreen(
                    teamUuid: teamUuid,
                    status: JoinRequestStatus.pending,
                  ),
                );
              },
            ),
            GoRoute(
              path: 'blocked',
              name: 'teamBlocked',
              pageBuilder: (context, state) {
                final teamUuid = state.pathParameters['teamUuid'] ?? '';
                return platformPageRoute(
                  context,
                  state,
                  TeamBlockedScreen(teamUuid: teamUuid),
                );
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/parent/:teamUuid',
      name: 'parentHome',
      pageBuilder: (context, state) {
        final teamUuid = state.pathParameters['teamUuid'] ?? '';
        return platformPageRoute(
          context,
          state,
          ParentHomeScreen(teamUuid: teamUuid),
        );
      },
    ),
    GoRoute(
      path: AppRoute.gameDashboard.path,
      name: 'gameDashboard',
      pageBuilder: (context, state) =>
          platformPageRoute(context, state, const GameDashboardScreen()),
      routes: [
        GoRoute(
          path: 'whos-here/:teamUuid',
          name: 'whosHere',
          pageBuilder: (context, state) {
            final teamUuid = state.pathParameters['teamUuid'] ?? '';
            return platformPageRoute(
              context,
              state,
              WhosHereScreen(teamUuid: teamUuid),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRoute.schedule.path,
      name: 'schedule',
      pageBuilder: (context, state) =>
          platformPageRoute(context, state, const CoachScheduleScreen()),
    ),
    GoRoute(
      path: AppRoute.awards.path,
      name: 'awards',
      pageBuilder: (context, state) =>
          platformPageRoute(context, state, const AwardsScreen()),
    ),
    GoRoute(
      path: AppRoute.history.path,
      name: 'history',
      pageBuilder: (context, state) =>
          platformPageRoute(context, state, const HistoryScreen()),
      routes: [
        GoRoute(
          path: 'season-totals',
          name: 'seasonTotals',
          pageBuilder: (context, state) =>
              platformPageRoute(context, state, const SeasonTotalsScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/history/:gameUuid',
      name: 'gameSummary',
      pageBuilder: (context, state) {
        final gameUuid = state.pathParameters['gameUuid'] ?? '';
        return platformPageRoute(
          context,
          state,
          GameSummaryScreen(gameUuid: gameUuid),
        );
      },
    ),
  ],
);
