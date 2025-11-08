import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_consent_cubit.dart';
import '../../../core/analytics/analytics_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AnalyticsService>().logScreenView('settings');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'App Preferences',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          BlocBuilder<AnalyticsConsentCubit, AnalyticsConsentState>(
            builder: (context, state) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Share usage data'),
                subtitle: const Text(
                  'Help improve TreadRunner by sharing anonymous usage metrics.',
                ),
                value: state.shareUsageData,
                onChanged: state.isSaving
                    ? null
                    : (value) => context
                        .read<AnalyticsConsentCubit>()
                        .setShareUsageData(value),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'TODO: Complete settings layout per design specs.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
