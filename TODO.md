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
- [ ] Parse FTMS treadmill metrics data instead of emitting placeholders
- [ ] Encode FTMS incline control command
- [ ] Encode FTMS speed control command

## 4. Health integration (platform channels)
- [x] Define `HealthService` interface in Dart:
  - [x] requestAuthorization()
  - [x] writeWorkout(session)
  - [x] readLatestHeartRate()
- [x] Create iOS method channel skeleton for HealthKit
- [x] Create Android method channel skeleton for Google Fit
- [x] Make calls non-blocking and optional (app must work without permissions)
- [ ] Implement HealthKit requests on iOS:
  - [ ] Request authorization in `AppDelegate`
  - [ ] Persist finished workouts to HealthKit
  - [ ] Query latest heart rate samples from HealthKit
- [ ] Implement Google Fit bridge on Android:
  - [ ] Request Google Fit permissions
  - [ ] Write workout sessions to Google Fit
  - [ ] Read heart rate data via Google Fit

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
- [ ] Wire “Add Program” card to the create program screen

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
- [x] Screen with:
  - [x] time elapsed (big)
  - [x] distance + heart rate cards
  - [x] speed control
  - [x] incline control
  - [x] program timeline (blocks, highlight current)
  - [x] current step description
  - [x] bottom: Pause, Hold-to-end
- [x] Connect to `WorkoutBloc` stream for live values
- [x] If connection lost → show warning banner
- [ ] Re-add workout header sync indicator once watch/health sync is implemented

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
- [x] Screen with:
  - [x] Device connections (current device, add new)
  - [x] App preferences (units, audio cues)
  - [x] Support (contact, about, privacy)
  - [x] App version footer
- [x] Hook device list to BLE scan
- [ ] Persist push notification preference and connect it to scheduled reminders
- [ ] Enable workout audio cues toggle once audio prompts are implemented
- [ ] Build privacy settings / data export surface instead of placeholder toast
- [ ] Show connected device details panel when tapping the device tile
- [ ] Implement Support links (contact form, about screen, privacy policy)

## 11.5. App Icon
- [x] create Appicon to IOS
- [x] create Appicon to Android
- [x] Add Appicon to IOS
- [x] Add Appicon to Android

## 12. Permissions flow
- [x] On first BLE scan → request BT + (Android) location
- [ ] On first health sync → request HealthKit/Google Fit
- [ ] Show graceful fallback UIs when denied

## 13. Testing / mocks
- [x] Add a mock device in debug mode that sends:
  - [x] speed 8 km/h
  - [x] incline 1%
  - [x] distance += every second
  - [x] hr 140
- [x] Use mock device to test Workout screen without real treadmill
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
- [ ] Apply units preference across all speed/distance labels (km ↔ mi, km/h ↔ mph)
- [ ] Set final Android `applicationId` in `android/app/build.gradle.kts`
- [ ] Configure Android release signing in `android/app/build.gradle.kts`

## 16. Out of scope (later)
- [ ] Strava export
- [ ] Watch companion
- [ ] AI workout summary
- [ ] Program marketplace
- [ ] Remove temporary “Timeline Demo” debug workout plan once live UI is finalized
