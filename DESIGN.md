# yeahBuddy design

A local-first iPhone workout tracker. SwiftUI + SwiftData, iOS 26.

## Principles

- **A Philosophy of Software Design.** Deep modules behind small, obvious, reusable interfaces. No pass-through layers; a protocol only where there is a real seam.
- **Define errors out of existence.** e.g. logging a set with no workout running starts one; finishing an empty workout discards it.
- **Files stay at or under 300 lines**, except UI-heavy views. Split an oversized module's implementation with extensions, never into shallow modules.
- **Test-driven.** Logic modules are built red → green, one behavior at a time, tested only through their public interface. UI is checked in previews and the simulator.
- **Reusable UI.** Views use `DesignSystem` tokens, styles and components; no raw colors, fonts or spacing in feature code.
- **Local-first.** No network, no accounts. The only planned exception (voice logging) runs on-device too.

## Workflow

- **Nothing is committed until the owner has tested the feature.** Passing tests and a simulator check are not enough on their own: the change is built, then handed over to try, and committed only after the owner confirms it works.
- **Pushing is a separate step** that also waits for the owner's go-ahead.

## Look

Inspired by Apple Sports: dark scoreboard canvas, bold tiles, big monospaced numbers, a color per muscle group (like team colors), and a LIVE tile for the workout in progress. Dark mode only in v1.

## Modules

| Module | Interface | Hides |
|---|---|---|
| `WorkoutLog` | `active`, `history`, `start()`, `add(_:)`, `logSet(weightKg:reps:of:)`, `remove(_:)`, `finish()`, `delete(_:)` | SwiftData, ordering, persistence, starting workouts implicitly |
| `ExerciseCatalog` | `all`, `search(_:)`, `addCustom(name:muscle:)` | Built-in seeding, duplicate handling |
| `RestTimer` | `remaining`, `isRunning`, `start(seconds:)`, `extend(by:)`, `skip()` | End-time math that survives backgrounding |
| `WeightUnit` | `kilograms(from:)`, `value(fromKilograms:)`, `format(kilograms:)`, `step` | Storage is always kg |

Views never touch SwiftData directly; they go through these modules, injected with `.environment`.

## Layout

```
yeahBuddy/
  Model/          SwiftData models, WeightUnit, built-in exercises
  Modules/        WorkoutLog, ExerciseCatalog, RestTimer
  DesignSystem/   Theme tokens, Styles, Components/
  Features/       Home, Workout, Exercises, History, Shared
yeahBuddyTests/   Swift Testing suites, one per module
scripts/test.sh   Runs tests on the simulator: scripts/test.sh [SuiteName]
```

## Scope

**v1:** live logging (exercises, weight × reps, rest timer), history tiles and detail, built-in + custom exercises, kg/lb.

**Later:** voice logging (SpeechAnalyzer + Foundation Models tool calling, on-device, behind a `WorkoutParser` protocol), routines/templates, progress charts, Apple Health, Live Activity, cardio.
