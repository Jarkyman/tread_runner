import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/health/health_permission_cubit.dart';
import 'app_card.dart';

class HealthPermissionBanner extends StatelessWidget {
  const HealthPermissionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HealthPermissionCubit, HealthPermissionState>(
      builder: (context, state) {
        if (!state.shouldShowFallback) return const SizedBox.shrink();
        return Column(
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Health sync unavailable',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'We could not access Apple Health / Google Fit. Workouts will '
                    'still save locally, but health metrics will not sync.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: state.isRequestInProgress
                        ? null
                        : () => context
                            .read<HealthPermissionCubit>()
                            .retryRequest(),
                    child: state.isRequestInProgress
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Try again'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
