import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/preferences/units_preference.dart';
import '../../../core/preferences/user_preferences_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/workout_metric_sample.dart';
import '../../../domain/models/workout_plan.dart';
import '../../../domain/models/workout_session.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../cubit/workout_summary_cubit.dart';

class WorkoutSummaryArgs {
  const WorkoutSummaryArgs({
    this.session,
    this.plan,
    this.sessionId,
  });

  final WorkoutSession? session;
  final WorkoutPlan? plan;
  final int? sessionId;
}

class WorkoutSummaryScreen extends StatefulWidget {
  const WorkoutSummaryScreen({super.key});

  static const routeName = '/workout-summary';

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _noteFocus = FocusNode();
  Timer? _noteDebounce;
  UnitsPreference _unitsPreference = UnitsPreference.metric;
  bool _isLoadingUnits = true;
  bool _handledArgs = false;

  @override
  void initState() {
    super.initState();
    _loadUnitsPreference();
  }

  Future<void> _loadUnitsPreference() async {
    final pref =
        await context.read<UserPreferencesRepository>().getUnitsPreference();
    if (!mounted) return;
    setState(() {
      _unitsPreference = pref;
      _isLoadingUnits = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledArgs) return;
    final args =
        ModalRoute.of(context)?.settings.arguments as WorkoutSummaryArgs?;
    if (args != null) {
      final cubit = context.read<WorkoutSummaryCubit>();
      if (args.session != null) {
        cubit.showSession(args.session!, plan: args.plan);
      } else if (args.sessionId != null) {
        cubit.loadSession(args.sessionId!);
      }
      _handledArgs = true;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _noteFocus.dispose();
    _noteDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _noteFocus.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocConsumer<WorkoutSummaryCubit, WorkoutSummaryState>(
            listener: (context, state) {
              final note = state.session?.note ?? '';
              if (note != _noteController.text) {
                _noteController.text = note;
                _noteController.selection = TextSelection.fromPosition(
                  TextPosition(offset: note.length),
                );
              }
              final error = state.errorMessage;
              if (error != null && error.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              }
            },
            builder: (context, state) {
              if (state.isLoading || _isLoadingUnits) {
                return const Center(child: CircularProgressIndicator());
              }
              final session = state.session;
              if (session == null) {
                return const Center(
                  child: Text(
                    'No workout summary available.',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }
              return Column(
                children: [
                  _SummaryHero(
                    plan: state.plan,
                    session: session,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: _SummaryBody(
                        session: session,
                        plan: state.plan,
                        unitsPreference: _unitsPreference,
                        noteController: _noteController,
                        noteFocusNode: _noteFocus,
                        onNoteChanged: _handleNoteChanged,
                        recentSessions: state.recentSessions,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleNoteChanged(String value) {
    _noteDebounce?.cancel();
    _noteDebounce = Timer(const Duration(milliseconds: 500), () {
      context.read<WorkoutSummaryCubit>().updateNote(value.trim());
    });
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({required this.plan, required this.session});

  final WorkoutPlan? plan;
  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final planName = plan?.name ?? 'Custom Run';
    final formatter = DateFormat.yMMMMd();
    final timeFormatter = DateFormat.jm();
    final endedAt = session.endedAt ?? session.startedAt.add(
      session.metrics.isNotEmpty
          ? Duration(seconds: session.metrics.last.elapsedSeconds)
          : const Duration(minutes: 1),
    );
    final dateText =
        '${formatter.format(session.startedAt)} • '
        '${timeFormatter.format(session.startedAt)} – '
        '${timeFormatter.format(endedAt)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
        colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.31),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            planName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateText,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({
    required this.session,
    required this.plan,
    required this.unitsPreference,
    required this.noteController,
    required this.noteFocusNode,
    required this.onNoteChanged,
    required this.recentSessions,
  });

  final WorkoutSession session;
  final WorkoutPlan? plan;
  final UnitsPreference unitsPreference;
  final TextEditingController noteController;
  final FocusNode noteFocusNode;
  final ValueChanged<String> onNoteChanged;
  final List<WorkoutSession> recentSessions;

  @override
  Widget build(BuildContext context) {
    final metrics = session.metrics;
    final derivedEnd = session.endedAt ??
        session.startedAt.add(
          metrics.isNotEmpty
              ? Duration(seconds: metrics.last.elapsedSeconds)
              : Duration.zero,
        );
    final duration = derivedEnd.difference(session.startedAt);
    final totalDistanceMeters =
        metrics.isNotEmpty ? (metrics.last.distanceMeters ?? 0.0) : 0.0;
    final distanceDisplay = _formatDistance(
      totalDistanceMeters,
      unitsPreference,
    );
    final distanceUnit = unitsPreference == UnitsPreference.metric ? 'km' : 'mi';
    final avgSpeed = totalDistanceMeters == 0 || duration.inSeconds == 0
        ? 0.0
        : (totalDistanceMeters / 1000) /
            (duration.inSeconds / 3600);
    final calories = _estimateCalories(totalDistanceMeters);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _KeyMetricsRow(
          duration: duration,
          distanceText: distanceDisplay,
          distanceUnit: distanceUnit,
          avgSpeed: _formatSpeed(avgSpeed, unitsPreference),
          calories: calories,
        ),
        const SizedBox(height: 24),
        _MetricsChartSection(
          samples: metrics,
        ),
        const SizedBox(height: 24),
        _SplitsSection(
          session: session,
          unitsPreference: unitsPreference,
        ),
        const SizedBox(height: 24),
        _NotesSection(
          controller: noteController,
          focusNode: noteFocusNode,
          onChanged: onNoteChanged,
        ),
        const SizedBox(height: 24),
        _SummaryActions(
          session: session,
          plan: plan,
        ),
        if (_otherSessions.isNotEmpty) ...[
          const SizedBox(height: 24),
          _RecentSessionsList(
            currentSessionId: session.id,
            sessions: _otherSessions,
          ),
        ],
      ],
    );
  }

  double _estimateCalories(double distanceMeters) {
    final distanceKm = distanceMeters / 1000;
    return (distanceKm * 60).clamp(0, 9999);
  }

  List<WorkoutSession> get _otherSessions =>
      recentSessions.where((it) => it.id != session.id).toList();
}

class _RecentSessionsList extends StatelessWidget {
  const _RecentSessionsList({
    required this.currentSessionId,
    required this.sessions,
  });

  final int currentSessionId;
  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent workouts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...sessions.map(
          (session) => InkWell(
            onTap: () => context.read<WorkoutSummaryCubit>().showSession(session),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: session.id == currentSessionId ? 0.2 : 0.08,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white70),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      DateFormat.yMMMd().add_jm().format(session.startedAt),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KeyMetricsRow extends StatelessWidget {
  const _KeyMetricsRow({
    required this.duration,
    required this.distanceText,
    required this.distanceUnit,
    required this.avgSpeed,
    required this.calories,
  });

  final Duration duration;
  final String distanceText;
  final String distanceUnit;
  final String avgSpeed;
  final double calories;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricCard(
          label: 'Time',
          value: _formatElapsed(duration),
          unit: '',
        ),
        _MetricCard(
          label: 'Distance',
          value: distanceText,
          unit: distanceUnit.toUpperCase(),
        ),
        _MetricCard(
          label: 'Avg Speed',
          value: avgSpeed,
          unit: ' ${distanceUnit.toUpperCase()}/h',
        ),
        _MetricCard(
          label: 'Calories',
          value: calories.toStringAsFixed(0),
          unit: ' kcal',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(color: Colors.white54)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricsChartSection extends StatefulWidget {
  const _MetricsChartSection({required this.samples});

  final List<WorkoutMetricSample> samples;

  @override
  State<_MetricsChartSection> createState() => _MetricsChartSectionState();
}

class _MetricsChartSectionState extends State<_MetricsChartSection> {
  double? _hoverFraction;

  @override
  Widget build(BuildContext context) {
    if (widget.samples.length < 2) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Not enough data points for chart.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onPanStart: (details) => _handleHover(details.localPosition, context),
            onPanUpdate: (details) =>
                _handleHover(details.localPosition, context),
            onPanEnd: (_) => setState(() => _hoverFraction = null),
            onTapDown: (details) => _handleHover(details.localPosition, context),
            onTapUp: (_) => setState(() => _hoverFraction = null),
            child: SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _MetricsChartPainter(
                  samples: widget.samples,
                  hoverFraction: _hoverFraction,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              _LegendDot(color: AppColors.primary, label: 'Speed'),
              SizedBox(width: 12),
              _LegendDot(color: Colors.purpleAccent, label: 'Incline'),
              SizedBox(width: 12),
              _LegendDot(color: Colors.redAccent, label: 'BPM'),
            ],
          ),
        ],
      ),
    );
  }

  void _handleHover(Offset offset, BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final fraction = offset.dx / box.size.width;
    setState(() => _hoverFraction = fraction.clamp(0, 1));
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _MetricsChartPainter extends CustomPainter {
  _MetricsChartPainter({
    required this.samples,
    required this.hoverFraction,
  });

  final List<WorkoutMetricSample> samples;
  final double? hoverFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.fill;
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      backgroundPaint,
    );

    if (samples.length < 2) return;

    final speedPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final inclinePaint = Paint()
      ..color = Colors.purpleAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final hrPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final elapsedValues = samples.map((s) => s.elapsedSeconds).toList();
    _drawLine(
      canvas,
      size,
      samples.map((s) => s.speedKmh ?? 0).toList(),
      elapsedValues,
      speedPaint,
    );
    _drawLine(
      canvas,
      size,
      samples.map((s) => s.inclinePercent ?? 0).toList(),
      elapsedValues,
      inclinePaint,
    );
    _drawLine(
      canvas,
      size,
      samples.map((s) => (s.heartRate ?? 0).toDouble()).toList(),
      elapsedValues,
      hrPaint,
    );

    if (hoverFraction != null) {
      final x = hoverFraction!.clamp(0, 1) * size.width;
      final hoverPaint = Paint()
        ..color = Colors.white30
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        hoverPaint,
      );
    }
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    List<double> data,
    List<int> elapsed,
    Paint paint,
  ) {
    final minValue = data.reduce(min);
    final maxValue = data.reduce(max);
    final range = max(maxValue - minValue, 0.01);
    final startTime = elapsed.first;
    final totalTime = max(elapsed.last - startTime, 1);
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      double fraction;
      if (totalTime == 0) {
        fraction = i / max(data.length - 1, 1);
      } else {
        fraction = (elapsed[i] - startTime) / totalTime;
      }
      final x = fraction.clamp(0, 1) * size.width;
      double normalized = (data[i] - minValue) / range;
      if (maxValue - minValue < 0.01) {
        normalized = 0.5;
      }
      final y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MetricsChartPainter oldDelegate) {
    return oldDelegate.samples != samples ||
        oldDelegate.hoverFraction != hoverFraction;
  }
}

class _SplitsSection extends StatelessWidget {
  const _SplitsSection({
    required this.session,
    required this.unitsPreference,
  });

  final WorkoutSession session;
  final UnitsPreference unitsPreference;

  @override
  Widget build(BuildContext context) {
    final splits = _computeSplits(
      session.metrics,
      unitsPreference,
    );
    if (splits.isEmpty) {
      return const SizedBox.shrink();
    }
    final unitLabel = unitsPreference == UnitsPreference.metric ? 'Km' : 'Mi';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Splits',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: AppColors.secondary,
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(56),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
                3: FixedColumnWidth(72),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Colors.white10),
                children: [
                  _tableHeader(unitLabel),
                  _tableHeader('Time'),
                  _tableHeader('Pace'),
                  _tableHeader('Speed'),
                ],
              ),
              ...splits.map(
                (split) => TableRow(
                  children: [
                    _tableCell(split.index.toString()),
                    _tableCell(_formatElapsed(split.duration)),
                    _tableCell(_formatElapsed(split.pace)),
                    _tableCell(split.speed.toStringAsFixed(1)),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ],
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

class _SplitData {
  _SplitData({
    required this.index,
    required this.duration,
    required this.pace,
    required this.speed,
  });

  final int index;
  final Duration duration;
  final Duration pace;
  final double speed;
}

List<_SplitData> _computeSplits(
  List<WorkoutMetricSample> samples,
  UnitsPreference preference,
) {
  if (samples.length < 2) return [];
  final targetMeters =
      preference == UnitsPreference.metric ? 1000.0 : 1609.34;
  final splits = <_SplitData>[];
  double nextTarget = targetMeters;
  Duration lastTime = Duration(seconds: samples.first.elapsedSeconds);
  double lastDistance = samples.first.distanceMeters ?? 0;
  int splitIndex = 1;

  for (final sample in samples.skip(1)) {
    final currentDistance = sample.distanceMeters ?? lastDistance;
    if (currentDistance >= nextTarget) {
      final currentTime = Duration(seconds: sample.elapsedSeconds);
      final segmentDistance = currentDistance - lastDistance;
      if (segmentDistance <= 0) continue;
      final segmentTime = currentTime - lastTime;
      final paceSeconds = segmentTime.inSeconds /
          (segmentDistance / targetMeters).clamp(0.01, double.infinity);
      final paceDuration = Duration(seconds: paceSeconds.round());
      final speedKmh = (segmentDistance / 1000) /
          (segmentTime.inSeconds / 3600);

      splits.add(
        _SplitData(
          index: splitIndex,
          duration: segmentTime,
          pace: paceDuration,
          speed: speedKmh,
        ),
      );

      splitIndex += 1;
      nextTarget += targetMeters;
      lastTime = currentTime;
      lastDistance = currentDistance;
    }
  }
  return splits;
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: null,
          minLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'How did you feel? Add a note…',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: AppColors.secondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: onChanged,
          textInputAction: TextInputAction.newline,
        ),
      ],
    );
  }
}

class _SummaryActions extends StatelessWidget {
  const _SummaryActions({required this.session, required this.plan});

  final WorkoutSession session;
  final WorkoutPlan? plan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share coming soon.')),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.of(context).popUntil((route) {
                final name = route.settings.name;
                if (name == DashboardScreen.routeName) {
                  return true;
                }
                return route.isFirst;
              });
            },
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

String _formatDistance(double meters, UnitsPreference preference) {
  final value = preference == UnitsPreference.metric
      ? meters / 1000
      : meters * 0.000621371;
  return value.toStringAsFixed(2);
}

String _formatSpeed(double kmh, UnitsPreference preference) {
  return preference == UnitsPreference.metric
      ? kmh.toStringAsFixed(1)
      : (kmh * 0.621371).toStringAsFixed(1);
}

String _formatElapsed(Duration value) {
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60);
  final seconds = value.inSeconds.remainder(60);
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
