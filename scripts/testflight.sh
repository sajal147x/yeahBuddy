#!/bin/zsh
# Builds yeahBuddy for the App Store and uploads it to TestFlight.
#
# Usage:
#   scripts/testflight.sh           Bump the build number, archive, and upload.
#   scripts/testflight.sh --check   Archive and export locally only: no bump, no upload.
#                                   Use it to confirm signing works before a real upload.
#
# Every upload needs a build number higher than the last one, so a real run bumps
# CURRENT_PROJECT_VERSION in the project file. Commit that change afterwards.
# Signing is automatic with team C26JUM6SS4; Xcode must be signed in to that account.
set -euo pipefail
cd "$(dirname "$0")/.."

project=yeahBuddy.xcodeproj/project.pbxproj
check_only=false
[[ "${1:-}" == "--check" ]] && check_only=true

# Build outside the Desktop: files there get extended attributes that break code signing.
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

if [[ $check_only == false ]]; then
    current=$(grep -m1 -o 'CURRENT_PROJECT_VERSION = [0-9]*' "$project" | grep -o '[0-9]*$')
    next=$((current + 1))
    sed -i '' "s/CURRENT_PROJECT_VERSION = $current;/CURRENT_PROJECT_VERSION = $next;/" "$project"
    echo "Build number: $current -> $next"
fi

echo "Archiving..."
xcodebuild archive -scheme yeahBuddy -destination 'generic/platform=iOS' \
    -archivePath "$work/yeahBuddy.xcarchive" -allowProvisioningUpdates -quiet

export_options=scripts/ExportOptions.plist
if [[ $check_only == true ]]; then
    # Same settings, but export to a local folder instead of uploading.
    sed 's|<string>upload</string>|<string>export</string>|' "$export_options" > "$work/ExportOptions.plist"
    export_options="$work/ExportOptions.plist"
fi

echo "Exporting..."
xcodebuild -exportArchive -archivePath "$work/yeahBuddy.xcarchive" \
    -exportOptionsPlist "$export_options" -exportPath "$work/export" -allowProvisioningUpdates \
    2>&1 | grep -E "error|Upload succeeded|EXPORT (SUCCEEDED|FAILED)"

if [[ $check_only == true ]]; then
    echo "Check passed: signing and export work. Nothing was uploaded."
else
    echo "Uploaded build $next. It appears in TestFlight after Apple processes it (10-30 min)."
fi
