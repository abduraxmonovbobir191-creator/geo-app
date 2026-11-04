#!/usr/bin/env bash
# Adds what Nex Map needs to the Android project that `flutter create` generates:
# app name, location/network permissions, and plain-HTTP access for a local dev server.
set -euo pipefail

manifest="android/app/src/main/AndroidManifest.xml"
[ -f "$manifest" ] || { echo "Run 'flutter create . --platforms=android' first" >&2; exit 1; }

if ! grep -q 'ACCESS_FINE_LOCATION' "$manifest"; then
  perms='    <uses-permission android:name="android.permission.INTERNET"/>\
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>\
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>\
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>\
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>\
    <uses-permission android:name="android.permission.WAKE_LOCK"/>\
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>'
  sed -i "s#<application#${perms}\n    <application#" "$manifest"
fi

sed -i 's#android:label="[^"]*"#android:label="Nex Map"#' "$manifest"

if ! grep -q 'usesCleartextTraffic' "$manifest"; then
  sed -i 's#<application#<application android:usesCleartextTraffic="true"#' "$manifest"
fi

echo "Configured $manifest"
