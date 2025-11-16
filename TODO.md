# TODO – TreadRunner

## Done
- **Foundation & Setup**
  - [x] Project created with folders, packages, analytics, Firebase integration
  - [x] Domain models, Isar storage, BLE layer, Health channel scaffolding
  - [x] App scaffold with Dashboard, Pre Workout, Workout, Workout Summary, Settings
  - [x] Mock treadmill, permissions flow scaffolding, seed programs including Timeline Demo
- **UI Completed**
  - [x] Dashboard with programs/history, Pre Workout adjustments, live Workout screen
  - [x] Workout Summary screen with charts, splits, notes, share/done flow
  - [x] Create Program screen (name, color, icon picker, sections/repeat, saves to Isar)
  - [x] Settings, Analytics consent, Device management, App icons, Theme foundation
- **Testing & Mocking**
  - [x] Debug mock treadmill service + workout screen integration
  - [x] Timeline demo program for testing timeline UI
- **Recent Polish**
  - [x] Pre-workout goal handling widgets aligned with create program
  - [x] Shared widget kit for toggles, pickers, and cards
  - [x] AppStatusCubit + connection telemetry surfaced globally
  - [x] ProgramsBloc hooked up for create/edit/duplicate/delete
  - [x] Analytics validated across Android/iOS DebugView

## MVP (to ship)
- **App State & Blocs**
  - [x] WorkoutBloc step progression, repeat blocks, treadmill commands
  - [x] WorkoutSummaryCubit history integrations
- **Permissions Flow**
  - [x] Request health permissions on first sync
  - [x] Show fallbacks when denied
- **Testing / QA**
  - [x] Add unit tests for workout step progression
  - [ ] Add unit tests for repeat blocks
  - [ ] Add unit tests for timeline rendering model

## Improvements
- **UI / UX Polish**
  - [ ] App state refinements (toasts, error handling)
  - [ ] Permissions cues, sync badge reintroduction
  - [ ] Workout Summary chart & table styling tweaks
  - [ ] History list display program names/colors/icons
- **Packages & Tooling**
  - [x] Update all packages (Flutter/Dart dependencies)

## Out of Scope (later)
- [ ] Strava export
- [ ] Watch companion
- [ ] AI workout summary
- [ ] Program marketplace
