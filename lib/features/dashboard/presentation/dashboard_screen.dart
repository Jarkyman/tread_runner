import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/ble/connection_cubit.dart' as connection;
import '../../../core/ble/treadmill_service.dart';
import '../../../domain/models/workout_plan.dart';
import '../../../domain/models/workout_session.dart';
import '../../dashboard/cubit/dashboard_cubit.dart';
import '../../pre_workout/presentation/pre_workout_screen.dart';
import '../../programs/bloc/programs_bloc.dart';
import '../../settings/presentation/settings_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('TreadRunner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed(SettingsScreen.routeName);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pushNamed(PreWorkoutScreen.routeName);
        },
        label: const Text('Pre Workout'),
        icon: const Icon(Icons.directions_run),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ConnectionStatusCard(isWide: isWide),
                const SizedBox(height: 24),
                _ProgramsSection(isWide: isWide),
                const SizedBox(height: 24),
                const _HistorySection(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConnectionStatusCard extends StatelessWidget {
  const _ConnectionStatusCard({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<connection.ConnectionCubit, connection.ConnectionState>(
      builder: (context, state) {
        final statusText = _statusText(state.status);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: isWide
              ? Row(
                  children: [
                    Expanded(
                      child: _ConnectionInfo(
                        statusText: statusText,
                        deviceId: state.connectedDeviceId,
                        isScanning: state.isScanning,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _ConnectionActions(state: state),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConnectionInfo(
                      statusText: statusText,
                      deviceId: state.connectedDeviceId,
                      isScanning: state.isScanning,
                    ),
                    const SizedBox(height: 16),
                    _ConnectionActions(state: state),
                  ],
                ),
        );
      },
    );
  }

  String _statusText(TreadmillConnectionState status) {
    switch (status) {
      case TreadmillConnectionState.scanning:
        return 'Searching for treadmills...';
      case TreadmillConnectionState.connecting:
        return 'Connecting to treadmill...';
      case TreadmillConnectionState.connected:
        return 'Connected';
      case TreadmillConnectionState.error:
        return 'Connection error';
      case TreadmillConnectionState.disconnected:
        return 'No treadmill connected';
    }
  }
}

class _ConnectionInfo extends StatelessWidget {
  const _ConnectionInfo({
    required this.statusText,
    required this.deviceId,
    required this.isScanning,
  });

  final String statusText;
  final String? deviceId;
  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          statusText,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (deviceId != null && !isScanning) ...[
          const SizedBox(height: 4),
          Text(
            'Device: $deviceId',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _ConnectionActions extends StatelessWidget {
  const _ConnectionActions({required this.state});

  final connection.ConnectionState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<connection.ConnectionCubit>();
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: state.isScanning ? null : cubit.startScan,
          icon: const Icon(Icons.search),
          label: Text(state.isScanning ? 'Scanning...' : 'Scan devices'),
        ),
        if (state.status == TreadmillConnectionState.connected)
          OutlinedButton.icon(
            onPressed: cubit.disconnect,
            icon: const Icon(Icons.link_off),
            label: const Text('Disconnect'),
          ),
      ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Programs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Navigate to create program flow.
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.status == ProgramsStatus.loading)
              const Center(child: CircularProgressIndicator())
            else if (programs.isEmpty)
              const _EmptyProgramsCard()
            else
              _ProgramsGrid(
                programs: programs,
                isWide: isWide,
              ),
          ],
        );
      },
    );
  }
}

class _ProgramsGrid extends StatelessWidget {
  const _ProgramsGrid({
    required this.programs,
    required this.isWide,
  });

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
      mainAxisExtent: 160,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
    );

    return SizedBox(
      height: isWide ? 320 : 340,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
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
          colors: [color.withAlpha((0.8 * 255).round()), color],
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white),
          ),
          const Spacer(),
          Text(
            '${plan.steps.length} steps',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white70),
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
    return _DottedBorderCard(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Add Program',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
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
          color: Theme.of(context)
              .colorScheme
              .primary
              .withAlpha((0.4 * 255).round()),
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
              'Recent Sessions',
              style: Theme.of(context).textTheme.titleLarge,
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
      children: sessions
          .map(
            (session) => Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                title: Text('Program #${session.planId ?? '-'}'),
                subtitle: Text(
                  '${session.startedAt.toLocal()}',
                ),
                trailing: Text(
                  _formatDuration(
                    (session.endedAt ?? DateTime.now())
                        .difference(session.startedAt),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No trainings recorded',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Start a workout to see your progress here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
