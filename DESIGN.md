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

Inspired by Sumeria (references pulled from Mobbin):

- **Calm surfaces:** soft gray canvas with white cards in light mode, true black with charcoal cards in dark; large continuous corners and a soft shadow.
- **Black and white, no brand color:** primary buttons are black (white in dark mode), secondary ones a light gray wash. The only color in the app is muscle groups.
- **Big left-aligned screen titles** with a summary line under them, instead of navigation bars on tab roots.
- **Numbers with small decimals and units**, e.g. "82" big then ".5 kg" small (`Text.amount`).
- **Muscle colors are small accents, except on live exercise cards:** elsewhere a colored dot and label. In the workout in progress, each exercise card is lit by a soft glow of its muscle color from the top-left (after Ultrahuman's cycle-tracking card), with the muscle as a small uppercase pill, so exercises are told apart at a glance. These cards always use their dark look, in light mode too, so they read the same in both.
- **Floating pill tab bar:** Home, History, Exercises. The system iOS 26 tab bar (Liquid Glass), tinted with the brand color.
- **Light and dark**, following the system or the saved appearance setting.

## Modules

| Module | Interface | Hides |
|---|---|---|
| `WorkoutLog` | `active`, `history`, `start()`, `add(_:)`, `logSet(weightKg:reps:of:)`, `remove(_:)`, `finish()`, `delete(_:)`, `thisWeek()` | SwiftData, ordering, persistence, starting workouts implicitly, week boundaries |
| `ExerciseCatalog` | `all`, `search(_:)`, `addCustom(name:muscle:summary:)` | Built-in seeding and description backfill, duplicate handling |
| `RestTimer` | `remaining`, `isRunning`, `start(seconds:)`, `extend(by:)`, `skip()` | End-time math that survives backgrounding |
| `WorkoutActivity` | `sync()`, `content(log:rest:unit:)` | ActivityKit: starting, updating and ending the Lock Screen / Dynamic Island activity |
| `WeightUnit` | `kilograms(from:)`, `value(fromKilograms:)`, `format(kilograms:)`, `step` | Storage is always kg |

Views never touch SwiftData directly; they go through these modules, injected with `.environment`.

## Layout

```
yeahBuddy/
  Model/          SwiftData models, WeightUnit, built-in exercises
  Modules/        WorkoutLog, ExerciseCatalog, RestTimer
  DesignSystem/   Theme tokens, Styles, Components/
  Features/       Root (tabs), Home, Workout, Exercises, History, Shared
yeahBuddyTests/   Swift Testing suites, one per module
scripts/test.sh   Runs tests on the simulator: scripts/test.sh [SuiteName]
```

## Scope

**v1:** live logging (exercises, weight × reps, rest timer), history tiles and detail, built-in + custom exercises, kg/lb, a silent workout Live Activity (exercise and set, workout clock, rest countdown, +15s / Skip / Add Set).

**Later:** voice logging (SpeechAnalyzer + Foundation Models tool calling, on-device, behind a `WorkoutParser` protocol), routines/templates, progress charts, Apple Health, cardio.
