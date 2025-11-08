import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/ble/connection_cubit.dart' as connection;
import '../../../core/ble/treadmill_service.dart';

enum ConnectionBadgeStyle { compact, expanded }

class ConnectionStatusBadge extends StatelessWidget {
  const ConnectionStatusBadge({super.key, this.style = ConnectionBadgeStyle.expanded});

  final ConnectionBadgeStyle style;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<connection.ConnectionCubit, connection.ConnectionState>(
      builder: (context, state) {
        final icon = state.status == TreadmillConnectionState.connected
            ? Icons.link
            : Icons.link_off;
        final textStyle = style == ConnectionBadgeStyle.compact
            ? const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)
            : Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white);
        return Row(
          mainAxisSize: style == ConnectionBadgeStyle.compact
              ? MainAxisSize.min
              : MainAxisSize.max,
          children: [
            Icon(
              icon,
              color: style == ConnectionBadgeStyle.compact
                  ? Colors.white70
                  : Colors.white,
              size: style == ConnectionBadgeStyle.compact ? 18 : 24,
            ),
            const SizedBox(width: 8),
            Text(_statusText(state.status), style: textStyle),
          ],
        );
      },
    );
  }

  static String _statusText(TreadmillConnectionState status) {
    switch (status) {
      case TreadmillConnectionState.connected:
        return 'Connected';
      case TreadmillConnectionState.connecting:
        return 'Connecting...';
      case TreadmillConnectionState.scanning:
        return 'Scanning...';
      case TreadmillConnectionState.error:
        return 'Connection error';
      case TreadmillConnectionState.disconnected:
        return 'Not Connected';
    }
  }
}
