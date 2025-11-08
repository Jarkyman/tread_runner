# AI Context – TreadRunner

## Project
- Name: TreadRunner
- Description: Flutter app for treadmill and indoor running, with local storage and programmable workouts.
- Package name: `com.hartvig_solutions.tread_runner`

## Tech stack
- Flutter (iOS + Android)
- State management: Bloc (`flutter_bloc`)
- Local DB: Isar (all user data is stored locally, no backend)
- BLE: `flutter_reactive_ble`
- Health integrations:
  - iOS: HealthKit via method channel
  - Android: Google Fit via method channel

## Hard rules
1. **No remote/backend calls** – data must stay on device.
2. **Prefer FTMS** if treadmill supports it, but code must be layered so we can add vendor-specific adapters.
3. **Use Bloc** for screens and feature logic.
4. **Use existing models** if they exist; do not invent random class names.
5. **Target screens are fixed**: Dashboard, Pre Workout, Workout, Workout Summary (Info), Create Program, Settings.

## App structure (intended)
- `lib/core/` → shared utilities, theme, constants
- `lib/core/ble/` → treadmill service abstraction and FTMS implementation
- `lib/core/health/` → HealthService abstraction + platform calls
- `lib/data/` → repositories (programs, devices, history)
- `lib/domain/` → entities/models (WorkoutPlan, WorkoutStep, WorkoutSession, TreadmillDevice)
- `lib/features/dashboard/` → dashboard UI + bloc
- `lib/features/pre_workout/` → pre workout UI + bloc
- `lib/features/workout/` → live workout UI + bloc (ticks every second)
- `lib/features/workout_summary/` → info screen UI
- `lib/features/programs/` → create/edit programs
- `lib/features/settings/` → device management, units, prefs

## Analytics
- We use Google/Firebase Analytics ONLY for usage metrics.
- Allowed events: screen views, workout started/completed, device connected, program created.
- Do NOT send raw sensor/workout time series to analytics.
- Respect a user setting: if analytics is disabled, the service must no-op.
- This is the only allowed remote call; all functional app data remains local (Isar).

## Screens (short spec)
- **Dashboard**: connection status, scrollable program grid, history list, FAB → Pre Workout.
- **Pre Workout**: show selected program, speed/incline controls, goal (duration/distance), connect-or-begin button.
- **Workout**: live metrics (time, distance, HR), speed/incline +/-, program timeline, pause, hold-to-end.
- **Workout Summary**: program title, date/time, main stats, chart (speed/incline/HR), splits, notes.
- **Create Program**: name, color, 1..N sections (speed, incline, duration/distance), repeat, add new.
- **Settings**: devices, app prefs, support.

## Data models (expected shape)
- `WorkoutStep`:
  - `type` (warmup, run, recovery, cooldown, hill)
  - `duration` OR `distanceMeters`
  - `targetSpeedKmh`
  - `inclinePercent`
  - optional `repeatCount`
- `WorkoutPlan`:
  - `id`
  - `name`
  - `color`
  - `steps: List<WorkoutStep>`
- `WorkoutSession`:
  - `id`
  - `planId`
  - `startedAt`
  - `endedAt`
  - `deviceId`
  - `metrics` (time-series placeholder)
- `TreadmillDevice`:
  - `id`
  - `name`
  - `connectionState`
  - `supportsSpeed`
  - `supportsIncline`
  - `supportsHeartRate`

## BLE layer expectations
- Must expose:
  - `scanForTreadmills()`
  - `connect(deviceId)`
  - `disconnect()`
  - `onMetrics()` stream → { speed, incline, distance, elapsedTime, heartRate }
  - `setSpeed(double kmh)`
  - `setIncline(double percent)`
- If a feature is not supported, return a flag so UI can disable the button.

## Permissions flow
- Ask for Bluetooth (and Android location if needed) right before scanning or connecting.
- Ask for HealthKit / Google Fit only when the user tries to sync a workout or when first workout finishes.
- If permissions are denied, app continues but marks workout as “not synced”.

## Styling
- Dark and light theme.
- Sporty, high-contrast, large numbers on workout screen.
- Program cards use gradient based on program color.

## Testing / mock
- There should be a mock treadmill service that emits fake metrics so UI can be developed without hardware.
- When AI writes code for BLE, it should first target the mock service.

## DO NOT
- Do not add HTTP clients or remote APIs.
- Do not rename the package.
- Do not change state management away from Bloc.
