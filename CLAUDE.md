# yeahBuddy

A local-first iPhone workout tracker: SwiftUI + SwiftData, iOS 26, Xcode 26.1, no third-party dependencies.

Read [DESIGN.md](DESIGN.md) before changing anything. It holds the principles, the Sumeria-inspired look, the module map and the scope. This file covers how to work in the repo.

## Working rules

- **Never commit until the owner has tested the change** in the simulator and said it works. My own tests and screenshots are not sign-off. Pushing needs a separate go-ahead.
- **Outline a plan and wait for approval** before any change touching more than a few files.
- **Test-driven for logic.** For anything in `Modules/` or `Model/`: write one failing Swift Testing test through the public interface, see it fail, make it pass, repeat. UI is checked in the simulator instead.
- **A Philosophy of Software Design.** Deep modules with small, reusable interfaces; no pass-through layers. Views go through `WorkoutLog` / `ExerciseCatalog` / `RestTimer` and never touch SwiftData directly.
- **Every function, initializer, computed property and view `body` gets a `///` doc comment.** The owner likes generous comments: explain the why and anything non-obvious.
- **No file over 300 lines**, except UI-heavy views.
- **Reusable UI only.** Colors, fonts, spacing and radii come from `DesignSystem/Theme.swift`; shared looks are styles or components in `DesignSystem/`. Check both light and dark mode.
- **Explicit branching** (`switch` / `if`) over clever one-liners.
- **No network calls, accounts or new dependencies** without asking.

## Layout

```
yeahBuddy/
  Model/          SwiftData models, WeightUnit, WeekSummary, built-in exercises
  Modules/        WorkoutLog, ExerciseCatalog, RestTimer (the logic; fully tested)
  DesignSystem/   Theme tokens, Styles, Components/
  Features/       Root (tab bar), Home, History, Exercises, Workout, Shared
  Shared/         Compiled into the app and the widget extension (Live Activity attributes, intents)
yeahBuddyWidgets/ Widget extension: the workout Live Activity UI only
yeahBuddyTests/   One Swift Testing suite per module, in-memory store + TestClock
scripts/          test.sh, testflight.sh, make_icon.swift
```

The project uses Xcode's synchronized folders: new files in `yeahBuddy/` or `yeahBuddyTests/` are picked up automatically, with no project-file edits needed.

## Commands

```bash
scripts/test.sh                    # all tests on the iPhone 17 Pro simulator
scripts/test.sh WorkoutLogTests    # one suite
scripts/testflight.sh --check      # archive + export locally; confirms signing, uploads nothing
scripts/testflight.sh              # bump build number, archive, upload to TestFlight
swift scripts/make_icon.swift yeahBuddy/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

`CoreData: error: Failed to stat path … default.store` in test output on first launch is harmless noise.

## Gotchas

- **Never build into the Desktop folder** (e.g. `-derivedDataPath build`). Files there get extended attributes that make code signing fail. Use the default DerivedData or a temp folder.
- **Simulator screenshots lag behind taps.** If a tap seems ignored, take another screenshot before tapping again, or you'll double-tap.
- **Exercise names are the key** linking stored built-ins to `BuiltInExercises`; renaming one there won't update existing installs.
- **The rest timer is in memory only** and resets if the app is killed; the Live Activity is ended on the next launch.
- **Files the widget extension needs** (`Shared/*`, `DesignSystem/Theme.swift`) are added to its target through the `yeahBuddy` folder's membership exceptions in the project file. A new shared file must be added there too.
- **Live Activity buttons run in the app's process** through `LiveActivityActions` closures set in `yeahBuddyApp.init`; the widget target never imports app modules.

## Releasing to TestFlight

- **App Store Connect:** app record exists; bundle ID `com.sajalgupta.yeahBuddy`, team `C26JUM6SS4`. Xcode on this Mac is signed in to that account.
- **To release:** after the owner has tested and approved, run `scripts/testflight.sh`. Uploading sends the build to Apple, so get the owner's go-ahead first. Then commit the build-number bump and push when asked.
- **Already uploaded:** builds 1 and 2 of version 1.0.

## Reference

UI references are Sumeria screens on Mobbin (the owner has Mobbin Pro and the Mobbin MCP is connected).
