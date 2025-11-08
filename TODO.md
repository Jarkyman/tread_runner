# TODO – TreadRunner

## 0. Project setup
- [x] Create Flutter project `treadrunner`
- [x] Add core packages:
  - [x] `flutter_bloc`
  - [x] `equatable`
  - [x] `isar` (+ isar generator, build_runner)
  - [x] `flutter_reactive_ble`
  - [x] `shared_preferences`
- [x] Create folder structure:
  - [x] `lib/core/`
  - [x] `lib/core/ble/`
  - [x] `lib/core/health/`
  - [x] `lib/data/`
  - [x] `lib/domain/`
  - [x] `lib/features/`
  - [x] `lib/features/dashboard/`
  - [x] `lib/features/pre_workout/`
  - [x] `lib/features/workout/`
  - [x] `lib/features/workout_summary/`
  - [x] `lib/features/programs/`
  - [x] `lib/features/settings/`
- [x] Add `docs/ai-context.md` with project rules (Bloc, local storage, FTMS, no server)

## 0.b Analytics
- [x] Add Firebase / Google Analytics to the Flutter project
- [x] Create `lib/core/analytics/analytics_service.dart`
  - [x] method: `logScreenView(String name)`
  - [x] method: `logWorkoutStarted({String? programId})`
  - [x] method: `logWorkoutCompleted({Duration? duration, double? distanceKm})`
  - [x] method: `logDeviceConnected({String? vendor})`
- [x] Call `logScreenView(...)` from each screen’s init/build
- [x] Add setting toggle “Share usage data” under Settings → App Preferences
- [x] Wrap all analytics calls so they only fire if user has consented

## 1. Domain models
- [x] Create `WorkoutStep` model (type, duration, distanceMeters, targetSpeedKmh, inclinePercent, repeatCount?)
- [x] Create `WorkoutPlan` model (id, name, color, steps[])
- [x] Create `WorkoutSession` model (id, planId, startedAt, endedAt, deviceId, metrics/time-series placeholder)
- [x] Create `TreadmillDevice` model (id, name, connectionState, supportedFeatures)
- [x] Make them all serializable for Isar

## 2. Local storage (Isar)
- [x] Configure Isar in `main.dart`
- [x] Create Isar collections:
  - [x] `WorkoutPlanCollection`
  - [x] `WorkoutSessionCollection`
  - [x] `DeviceCollection`
- [x] Seed predefined programs on first run (20 min run, intervals, hill)
- [x] Add repository classes:
  - [x] `ProgramsRepository`
  - [x] `WorkoutHistoryRepository`
  - [x] `DeviceRepository`

## 3. BLE layer
- [x] Implement `TreadmillService` abstract class:
  - [x] scan()
  - [x] connect(deviceId)
  - [x] disconnect()
  - [x] listenToMetrics() → speed, incline, distance, time, hr
  - [x] setSpeed(value)
  - [x] setIncline(value)
- [x] Implement FTMS-based service (`FtmsTreadmillService`)
- [x] Implement a mock treadmill service for simulator/testing
- [x] Add feature detection: mark unsupported controls so UI can disable buttons

## 4. Health integration (platform channels)
- [x] Define `HealthService` interface in Dart:
  - [x] requestAuthorization()
  - [x] writeWorkout(session)
  - [x] readLatestHeartRate()
- [x] Create iOS method channel skeleton for HealthKit
- [x] Create Android method channel skeleton for Google Fit
- [x] Make calls non-blocking and optional (app must work without permissions)

## 5. App state (Bloc)
- [ ] Create global `AppBloc` or `ConnectionCubit` for treadmill connection state
- [ ] Create `ProgramsBloc` for listing/creating programs
- [ ] Create `PreWorkoutBloc` for selected program, speed, incline, goal (duration/distance)
- [ ] Create `WorkoutBloc` for running workout:
  - [ ] tick every second
  - [ ] advance steps
  - [ ] dispatch new targets to treadmill
  - [ ] collect metrics
- [ ] Create `WorkoutSummaryCubit` to show finished session
- [ ] Wire blocs in `main.dart` with `MultiBlocProvider`

## 6. UI – Dashboard
- [x] Screen with:
  - [x] connection status (top)
  - [x] programs grid (2x2, horizontal scroll, add-program skeleton)
  - [x] history list (or “No trainings recorded”)
  - [x] FAB → Pre Workout
- [x] Load programs from `ProgramsRepository`
- [x] Load history from `WorkoutHistoryRepository`

## 7. UI – Pre Workout
- [x] Screen with:
  - [x] connection status in top bar
  - [x] selected program card + dropdown
  - [x] speed control (+/-)
  - [x] incline control (+/-)
  - [x] goal selector (Duration / Distance)
  - [x] time/distance picker
  - [x] bottom buttons: Cancel (25%), primary (75%)
- [x] If not connected → primary says “Connect treadmill” and opens device list
- [x] If connected → primary says “Begin Workout” and starts `WorkoutBloc`

## 8. UI – Workout (live)
- [ ] Screen with:
  - [ ] time elapsed (big)
  - [ ] distance + heart rate cards
  - [ ] speed control
  - [ ] incline control
  - [ ] program timeline (blocks, highlight current)
  - [ ] current step description
  - [ ] bottom: Pause, Hold-to-end
- [ ] Connect to `WorkoutBloc` stream for live values
- [ ] If connection lost → show warning banner

## 9. UI – Workout Summary (Info)
- [ ] Screen with:
  - [ ] program title
  - [ ] date/time (start–end)
  - [ ] main stats: time, distance, avg speed, calories
  - [ ] chart placeholder (speed/incline/HR)
  - [ ] splits list
  - [ ] notes field
  - [ ] bottom: Share / Done
- [ ] On Done → save to history

## 10. UI – Create Program
- [ ] Screen with:
  - [ ] name field
  - [ ] color picker
  - [ ] 1..N section cards
  - [ ] each card: speed, incline, duration/distance toggle, picker
  - [ ] repeat button + delete button
  - [ ] “Add new section” skeleton
- [ ] Save → store in Isar → return to dashboard

## 11. UI – Settings
- [ ] Screen with:
  - [ ] Device connections (current device, add new)
  - [ ] App preferences (units, audio cues)
  - [ ] Support (contact, about, privacy)
  - [ ] App version footer
- [ ] Hook device list to BLE scan

## 11.5. App Icon
- [x] create Appicon to IOS
- [x] create Appicon to Android
- [ ] Add Appicon to IOS
- [ ] Add Appicon to Android

## 12. Permissions flow
- [ ] On first BLE scan → request BT + (Android) location
- [ ] On first health sync → request HealthKit/Google Fit
- [ ] Show graceful fallback UIs when denied

## 13. Testing / mocks
- [ ] Add a mock device in debug mode that sends:
  - [ ] speed 8 km/h
  - [ ] incline 1%
  - [ ] distance += every second
  - [ ] hr 140
- [ ] Use mock device to test Workout screen without real treadmill
- [ ] Add unit tests for:
  - [ ] workout step progression
  - [ ] repeat blocks
  - [ ] timeline rendering model

## 14. Analytics validation
- [ ] Test analytics on Android
- [ ] Test analytics on iOS
- [ ] Verify events show up in GA dashboard

## 15. Polish
- [ ] Add light/dark theme
- [ ] Add app name: “TreadRunner”
- [ ] Add icons for program types (Run, Intervals, Hill)
- [ ] Add empty states (no history, no device)
- [ ] Add error toasts/snackbars for BLE errors
- [ ] Make dashboard greeting dynamic (time of day + user name)
- [ ] Allow editing presets for non-run programs on Pre Workout screen

## 16. Out of scope (later)
- [ ] Strava export
- [ ] Watch companion
- [ ] AI workout summary
- [ ] Program marketplace
