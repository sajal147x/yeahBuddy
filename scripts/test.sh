#!/bin/zsh
# Runs the unit tests on the iPhone simulator and prints only results and errors.
# Usage: scripts/test.sh [TestSuiteName]   e.g. scripts/test.sh WorkoutLogTests
cd "$(dirname "$0")/.."
only=()
[[ -n "$1" ]] && only=(-only-testing:"yeahBuddyTests/$1")
xcodebuild test -scheme yeahBuddy -destination 'platform=iOS Simulator,name=iPhone 17 Pro' "${only[@]}" 2>&1 \
  | grep -E "error:|✔|✘|passed|failed|TEST (SUCCEEDED|FAILED)" \
  | grep -v "IDETestOperationsObserverDebug"
