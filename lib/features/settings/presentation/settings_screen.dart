import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/analytics/analytics_consent_cubit.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/ble/connection_cubit.dart' as connection;
import '../../../core/ble/treadmill_service.dart';
import '../../../core/preferences/units_preference.dart';
import '../../../core/preferences/user_preferences_repository.dart';
import '../../../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  final bool _audioCues = false;
  UnitsPreference _unitsPreference = UnitsPreference.metric;
  bool _isUnitsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnitsPreference();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AnalyticsService>().logScreenView('settings');
    });
  }

  Future<void> _loadUnitsPreference() async {
    final storedPreference = await context
        .read<UserPreferencesRepository>()
        .getUnitsPreference();
    if (!mounted) return;
    setState(() {
      _unitsPreference = storedPreference;
      _isUnitsLoading = false;
    });
  }

  void _handleUnitsChanged(UnitsPreference value) {
    if (_isUnitsLoading || _unitsPreference == value) return;
    setState(() {
      _unitsPreference = value;
    });
    unawaited(
      context.read<UserPreferencesRepository>().setUnitsPreference(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _SectionCard(
            title: 'Device Connections',
            icon: Icons.bluetooth,
            actionLabel: 'Add New',
            onActionTap: () =>
                context.read<connection.ConnectionCubit>().startScan(),
            child: const _DevicesCard(),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'App Preferences',
            icon: Icons.tune,
            child: _PreferencesCard(
              pushNotifications: _pushNotifications,
              audioCues: _audioCues,
              unitsPreference: _unitsPreference,
              isUnitsLoading: _isUnitsLoading,
              onNotificationsChanged: (value) =>
                  setState(() => _pushNotifications = value),
              onAudioCuesTapped: () =>
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Workout audio cues are coming soon.'),
                    ),
                  ),
              onUnitsChanged: _handleUnitsChanged,
            ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'Support',
            icon: Icons.headset_mic_outlined,
            child: _SupportCard(),
          ),
          const SizedBox(height: 32),
          _AppVersionFooter(),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(24),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white70, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: onActionTap,
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DevicesCard extends StatelessWidget {
  const _DevicesCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<connection.ConnectionCubit, connection.ConnectionState>(
      builder: (context, state) {
        final connectedId = state.connectedDeviceId;
        final devices = state.devices;
        TreadmillDeviceInfo? currentDevice;
        if (connectedId != null) {
          for (final device in devices) {
            if (device.id == connectedId) {
              currentDevice = device;
              break;
            }
          }
        }
        currentDevice ??= devices.isNotEmpty ? devices.first : null;

        return Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Device details coming soon.')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.black.withAlpha(40),
                      ),
                      child: const Icon(
                        Icons.directions_run,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentDevice?.name ?? 'No treadmill connected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: currentDevice != null
                                      ? AppColors.primary
                                      : Colors.white38,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                currentDevice != null
                                    ? 'Connected'
                                    : 'Tap Add New to pair',
                                style: const TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white54),
                  ],
                ),
              ),
            ),
            if (state.isScanning)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        );
      },
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.pushNotifications,
    required this.audioCues,
    required this.unitsPreference,
    required this.isUnitsLoading,
    required this.onNotificationsChanged,
    required this.onAudioCuesTapped,
    required this.onUnitsChanged,
  });

  final bool pushNotifications;
  final bool audioCues;
  final UnitsPreference unitsPreference;
  final bool isUnitsLoading;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onAudioCuesTapped;
  final ValueChanged<UnitsPreference> onUnitsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<AnalyticsConsentCubit, AnalyticsConsentState>(
          builder: (context, state) {
            return SwitchListTile.adaptive(
              title: const Text(
                'Share usage data',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Help improve TreadRunner by sharing anonymous metrics.',
                style: TextStyle(color: Colors.white54),
              ),
              activeTrackColor: AppColors.primary.withAlpha(120),
              activeThumbColor: AppColors.primary,
              value: state.shareUsageData,
              onChanged: state.isSaving
                  ? null
                  : (value) async {
                      if (!value) {
                        final confirmed =
                            await showDialog<bool>(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                backgroundColor: AppColors.secondary,
                                title: const Text('Turn off usage sharing?'),
                                content: const Text(
                                  'We only collect anonymous usage data to improve TreadRunner. Are you sure you want to disable it?',
                                ),
                                titleTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                contentTextStyle: const TextStyle(
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                                actions: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(dialogCtx).pop(false),
                                    child: const Text('Keep on'),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(dialogCtx).pop(true),
                                    child: const Text('Turn off'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                        if (!confirmed || !context.mounted) return;
                      }
                      if (!context.mounted) return;
                      context.read<AnalyticsConsentCubit>().setShareUsageData(
                        value,
                      );
                    },
            );
          },
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          title: const Text(
            'Push notifications',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Get reminders for scheduled runs and updates.',
            style: TextStyle(color: Colors.white54),
          ),
          activeTrackColor: AppColors.primary.withAlpha(120),
          activeThumbColor: AppColors.primary,
          value: pushNotifications,
          onChanged: onNotificationsChanged,
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onAudioCuesTapped,
          child: AbsorbPointer(
            child: SwitchListTile.adaptive(
              title: const Text(
                'Workout audio cues',
                style: TextStyle(color: Colors.white54),
              ),
              subtitle: const Text(
                'Voice prompts are coming soon.',
                style: TextStyle(color: Colors.white30),
              ),
              value: audioCues,
              onChanged: null,
              inactiveThumbColor: Colors.white24,
              inactiveTrackColor: Colors.white12,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.white10),
        const SizedBox(height: 16),
        _UnitsSelector(
          unitsPreference: unitsPreference,
          isLoading: isUnitsLoading,
          onChanged: onUnitsChanged,
        ),
        const SizedBox(height: 16),
        _PreferencesRow(
          title: 'Privacy Settings',
          subtitle: 'Manage data exports and deletion requests.',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy settings coming soon.')),
            );
          },
        ),
      ],
    );
  }
}

class _UnitsSelector extends StatelessWidget {
  const _UnitsSelector({
    required this.unitsPreference,
    required this.isLoading,
    required this.onChanged,
  });

  final UnitsPreference unitsPreference;
  final bool isLoading;
  final ValueChanged<UnitsPreference> onChanged;

  @override
  Widget build(BuildContext context) {
    final isMetric = unitsPreference == UnitsPreference.metric;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Units of measurement',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const LinearProgressIndicator()
        else
          ToggleButtons(
            isSelected: UnitsPreference.values
                .map((pref) => pref == unitsPreference)
                .toList(),
            onPressed: (index) {
              final pref = UnitsPreference.values[index];
              onChanged(pref);
            },
            borderRadius: BorderRadius.circular(14),
            fillColor: AppColors.primary.withOpacity(0.2),
            selectedColor: Colors.white,
            color: Colors.white54,
            borderColor: Colors.white24,
            selectedBorderColor: AppColors.primary,
            constraints: const BoxConstraints(minHeight: 44, minWidth: 120),
            children: UnitsPreference.values.map((pref) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${pref.displayLabel}\n(${pref.distanceLabel} • ${pref.speedLabel})',
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 6),
        Text(
          isMetric
              ? 'Shows km & km/h across the app.'
              : 'Shows mi & mph across the app.',
          style: const TextStyle(color: Colors.white54),
        ),
      ],
    );
  }
}

class _PreferencesRow extends StatelessWidget {
  const _PreferencesRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }
}

class _SupportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SupportRow(
          icon: Icons.mail_outline,
          title: 'Contact Us',
          subtitle: 'Questions or feedback',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contact form coming soon.')),
            );
          },
        ),
        const Divider(color: Colors.white10),
        _SupportRow(
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'Learn about TreadRunner',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('About screen coming soon.')),
            );
          },
        ),
        const Divider(color: Colors.white10),
        _SupportRow(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'Read how we handle data',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy policy link coming soon.')),
            );
          },
        ),
      ],
    );
  }
}

class _SupportRow extends StatelessWidget {
  const _SupportRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.08),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }
}

class _AppVersionFooter extends StatelessWidget {
  _AppVersionFooter();

  static final Future<PackageInfo> _packageInfoFuture =
      PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return FutureBuilder<PackageInfo>(
      future: _packageInfoFuture,
      builder: (context, snapshot) {
        final versionText = snapshot.hasData
            ? 'TreadRunner v${snapshot.data!.version}'
            : 'TreadRunner';
        return Column(
          children: [
            Text(versionText, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 6),
            Text(
              '© $year Hartvig Solutions',
              style: const TextStyle(color: Colors.white38),
            ),
          ],
        );
      },
    );
  }
}
