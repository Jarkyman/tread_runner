# TreadRunner

Internal notes for running and testing the treadmill companion app.

## Requirements
- Flutter 3.24 / Dart 3.9 SDK (see `environment.sdk` in `pubspec.yaml`)
- Xcode 15 / Android Studio for device targets
- Firebase CLI configured for analytics if you want real metrics

## Setup
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs # when data models change
```
`build_runner` stays on 2.4.13 until Isar ships a generator that supports `build` 4.x.

## Run against hardware
```bash
flutter run
```
Connect to a BLE treadmill first so the Ftms service can discover it. Analytics consent + seed data happen automatically on first launch.

## Mock treadmill mode
Use the mock when you do not have a treadmill nearby or want predictable data:
```bash
flutter run --dart-define USE_MOCK_TREADMILL=true
```
- BLE permissions are skipped and the mock broadcasts a fake FTMS device.
- Preloaded demo workouts sync instantly so you can test dashboards + summaries.
- Set `--dart-define USE_REAL_TREADMILL=true` if you ever need to override and force the real BLE service even when another flag is on.

## Misc
- `TODO.md` tracks the current roadmap.
- App icon assets live in `assets/app_icon.png` and are wired through `flutter_launcher_icons`.
