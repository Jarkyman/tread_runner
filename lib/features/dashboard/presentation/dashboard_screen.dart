import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/workout_plan.dart';
import '../../../domain/models/workout_session.dart';
import '../../dashboard/cubit/dashboard_cubit.dart';
import '../../pre_workout/presentation/pre_workout_screen.dart';
import '../../programs/bloc/programs_bloc.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../shared/widgets/connection_status_badge.dart';
import '../../workout_summary/cubit/workout_summary_cubit.dart';
import '../../workout_summary/presentation/workout_summary_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AnalyticsService>().logScreenView('dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 180,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: ConnectionStatusBadge(style: ConnectionBadgeStyle.compact),
        ),
        titleSpacing: 0,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: Colors.white70,
            onPressed: () {
              Navigator.of(context).pushNamed(SettingsScreen.routeName);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.of(context).pushNamed(PreWorkoutScreen.routeName);
        },
        child: const Icon(Icons.play_arrow_rounded, size: 32),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Programs',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _ProgramsSection(isWide: isWide),
                const SizedBox(height: 32),
                const _HistorySection(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProgramsSection extends StatelessWidget {
  const _ProgramsSection({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgramsBloc, ProgramsState>(
      builder: (context, state) {
        final programs = state.programs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.status == ProgramsStatus.loading)
              const Center(child: CircularProgressIndicator())
            else if (programs.isEmpty)
              const _EmptyProgramsCard()
            else
              _ProgramsGrid(programs: programs, isWide: isWide),
          ],
        );
      },
    );
  }
}

class _ProgramsGrid extends StatelessWidget {
  const _ProgramsGrid({required this.programs, required this.isWide});

  final List<WorkoutPlan> programs;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final cards = [
      ...programs.map((plan) => _ProgramCard(plan: plan)),
      const _AddProgramCard(),
    ];
    final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisExtent: isWide ? 220 : 200,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
    );

    return SizedBox(
      height: isWide ? 360 : 420,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        gridDelegate: gridDelegate,
        itemCount: cards.length,
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.plan});

  final WorkoutPlan plan;

  @override
  Widget build(BuildContext context) {
    final color = Color(plan.colorValue);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [AppColors.gradientOverlay(color), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const Spacer(),
          Text(
            '${plan.steps.length} steps',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _AddProgramCard extends StatelessWidget {
  const _AddProgramCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to create program screen.
      },
      child: _DottedBorderCard(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 32,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Add Program',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DottedBorderCard extends StatelessWidget {
  const _DottedBorderCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.primary.withAlpha((0.4 * 255).round()),
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}

class _EmptyProgramsCard extends StatelessWidget {
  const _EmptyProgramsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No programs yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first treadmill workout to get started.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (state.status == DashboardStatus.loading)
              const Center(child: CircularProgressIndicator())
            else if (state.recentSessions.isEmpty)
              const _EmptyHistoryCard()
            else
              _HistoryList(sessions: state.recentSessions),
          ],
        );
      },
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.sessions});

  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: sessions.map((session) {
        final duration = _formatDuration(
          (session.endedAt ?? DateTime.now()).difference(session.startedAt),
        );
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            context.read<WorkoutSummaryCubit>().showSession(session);
            Navigator.of(context).pushNamed(
              WorkoutSummaryScreen.routeName,
              arguments: WorkoutSummaryArgs(session: session),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha((0.1 * 255).round()),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Program #${session.planId ?? '-'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(session.startedAt),
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDistance(session),
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    if (difference == 0) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final minutes = date.minute.toString().padLeft(2, '0');
      return 'Today, $hour:$minutes $period';
    } else if (difference == 1) {
      return 'Yesterday';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDistance(WorkoutSession session) {
    final distanceMeters = session.metrics.isNotEmpty
        ? session.metrics.last.distanceMeters ?? 0
        : 0;
    final miles = (distanceMeters / 1609.34);
    return '${miles.toStringAsFixed(1)} mi';
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF242426),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No trainings recorded',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a workout to see your progress here.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
