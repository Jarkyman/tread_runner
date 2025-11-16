import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app/app_status_cubit.dart';

enum ConnectionBadgeStyle { compact, expanded }

class ConnectionStatusBadge extends StatelessWidget {
  const ConnectionStatusBadge({
    super.key,
    this.style = ConnectionBadgeStyle.expanded,
  });

  final ConnectionBadgeStyle style;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppStatusCubit, AppStatusState>(
      builder: (context, state) {
        final iconData = _iconForStage(state.stage);
        final color = _colorForStage(state.stage);
        final textStyle = style == ConnectionBadgeStyle.compact
            ? const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              )
            : Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white);
        final label = style == ConnectionBadgeStyle.compact
            ? _compactLabel(state)
            : state.headline;

        final detail = style == ConnectionBadgeStyle.expanded
            ? state.detail
            : null;

        return Row(
          mainAxisSize: style == ConnectionBadgeStyle.compact
              ? MainAxisSize.min
              : MainAxisSize.max,
          crossAxisAlignment: detail != null
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Icon(
              iconData,
              color: color,
              size: style == ConnectionBadgeStyle.compact ? 18 : 24,
            ),
            const SizedBox(width: 8),
            if (detail == null)
              Text(label, style: textStyle)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textStyle),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }

  static IconData _iconForStage(AppLifecycleStage stage) {
    switch (stage) {
      case AppLifecycleStage.connected:
        return Icons.link;
      case AppLifecycleStage.connecting:
      case AppLifecycleStage.scanning:
        return Icons.sync;
      case AppLifecycleStage.permissionsRequired:
        return Icons.bluetooth_disabled;
      case AppLifecycleStage.error:
        return Icons.error_outline;
      case AppLifecycleStage.ready:
      case AppLifecycleStage.initializing:
        return Icons.link_off;
    }
  }

  static Color _colorForStage(AppLifecycleStage stage) {
    switch (stage) {
      case AppLifecycleStage.connected:
        return Colors.lightGreenAccent;
      case AppLifecycleStage.connecting:
      case AppLifecycleStage.scanning:
        return Colors.amberAccent;
      case AppLifecycleStage.permissionsRequired:
      case AppLifecycleStage.error:
        return Colors.orangeAccent;
      case AppLifecycleStage.ready:
      case AppLifecycleStage.initializing:
        return Colors.white70;
    }
  }

  static String _compactLabel(AppStatusState state) {
    switch (state.stage) {
      case AppLifecycleStage.connected:
        final name = state.activeDevice?.name ?? '';
        final trimmed = name.trim();
        return trimmed.isNotEmpty ? trimmed : 'Connected';
      case AppLifecycleStage.connecting:
        return 'Connecting…';
      case AppLifecycleStage.scanning:
        return 'Scanning…';
      case AppLifecycleStage.permissionsRequired:
        return 'Enable Bluetooth';
      case AppLifecycleStage.error:
        return 'Connection issue';
      case AppLifecycleStage.ready:
        return 'Idle';
      case AppLifecycleStage.initializing:
        return 'Starting...';
    }
  }
}
