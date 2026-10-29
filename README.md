# yeahBuddy

A fast, offline workout tracker for iPhone, styled like a sports scoreboard.

Log your sets between lifts with big, thumb-friendly controls, rest with a built-in timer, and look back on past workouts as bold, color-coded tiles. Everything stays on your phone: no account, no sign-in, no network.

## What it does

- **Log a workout live.** Start a workout, add exercises, and log each set as weight × reps. The steppers start from your last set, so repeating it is one tap.
- **Rest timer.** Logging a set starts a 90-second countdown, with +15s and Skip buttons.
- **Live tile.** While you train, the home screen shows a LIVE tile with a running clock. Close the app mid-workout and it picks up where you left off.
- **History.** Finished workouts show up as tiles with total volume, sets and exercises. Tap one to see every set.
- **Exercise library.** More than 30 built-in exercises grouped by muscle, plus your own. Type a name that doesn't exist in search to create it.
- **kg or lb.** Switch units at any time from the settings menu. Your saved data never changes.
- **Color by muscle group.** Chest is red, back blue, legs green, and so on, like team colors on a scoreboard.

## Requirements

- Xcode 26.1 or newer
- iOS 26 or newer (simulator or device)

## Run it

1. Open `yeahBuddy.xcodeproj` in Xcode.
2. Pick an iPhone simulator, e.g. iPhone 17 Pro.
3. Press ⌘R.

## Run the tests

```bash
scripts/test.sh
```

Run one suite with `scripts/test.sh WorkoutLogTests`. The tests use Swift Testing and an in-memory store, so they never touch your real data.

## How it's built

SwiftUI + SwiftData, with no third-party dependencies. The app is split into a few deep modules (`WorkoutLog`, `ExerciseCatalog`, `RestTimer`), and the screens are built from a shared design system. The logic modules were written test-first.

To ship a TestFlight build, run `scripts/testflight.sh` (or `--check` for a dry run). [CLAUDE.md](CLAUDE.md) has the working rules and release steps.

See [DESIGN.md](DESIGN.md) for the principles, the module map, and what's planned next (voice logging, routines, progress charts, Apple Health).
