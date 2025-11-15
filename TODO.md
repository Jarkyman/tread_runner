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

## MVP (to ship)
- **App State & Blocs**
  - [ ] Global AppBloc / ConnectionCubit enhancements
  - [ ] ProgramsBloc for CRUD (beyond create)
  - [ ] PreWorkoutBloc goal handling improvements
  - [ ] WorkoutBloc step progression, repeat blocks, treadmill commands (partially done)
  - [ ] WorkoutSummaryCubit history integrations (future features)
- **Permissions Flow**
  - [ ] Request health permissions on first sync
  - [ ] Show fallbacks when denied
- **Testing / QA**
  - [ ] Add unit tests for workout step progression
  - [ ] Add unit tests for repeat blocks
  - [ ] Add unit tests for timeline rendering model
- **Analytics & Config**
  - [ ] Provide real Firebase config for Web, macOS, Windows, Linux
  - [ ] Validate analytics on Android & iOS
  - [ ] Verify GA dashboard events

## Improvements
- **UI / UX Polish**
  - [ ] App state refinements (toasts, error handling)
  - [ ] Permissions cues, sync badge reintroduction
  - [ ] Workout Summary chart & table styling tweaks
  - [ ] History list display program names/colors/icons
- **Widget/Code Quality**
  - [ ] Refactor widgets for improved usability and reuse
- **Packages & Tooling**
  - [x] Update all packages (Flutter/Dart dependencies)

## Out of Scope (later)
- [ ] Strava export
- [ ] Watch companion
- [ ] AI workout summary
- [ ] Program marketplace
