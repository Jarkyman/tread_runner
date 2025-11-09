enum UnitsPreference {
  metric(distanceLabel: 'km', speedLabel: 'km/h'),
  imperial(distanceLabel: 'mi', speedLabel: 'mph');

  const UnitsPreference({
    required this.distanceLabel,
    required this.speedLabel,
  });

  final String distanceLabel;
  final String speedLabel;

  String get displayLabel => switch (this) {
    UnitsPreference.metric => 'Metric',
    UnitsPreference.imperial => 'Imperial',
  };

  String get longDescription => switch (this) {
    UnitsPreference.metric => 'Kilometers (km) & kilometers per hour',
    UnitsPreference.imperial => 'Miles (mi) & miles per hour',
  };

  static UnitsPreference fromStorage(String? value) {
    if (value == UnitsPreference.imperial.name) {
      return UnitsPreference.imperial;
    }
    return UnitsPreference.metric;
  }
}
