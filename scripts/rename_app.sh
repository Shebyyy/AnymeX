#!/usr/bin/env bash
set -e

# Detect macOS vs Linux sed
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED="sed -i ''"
else
  SED="sed -i"
fi

# PACKAGE IDs
OLD_PKG="com.ryan.anymex"
NEW_PKG="com.ryan.anymexbeta"

# ANDROID FOLDER PATHS
OLD_DIR="com/ryan/anymex"
NEW_DIR="com/ryan/anymexbeta"
ANDROID_SRC="android/app/src/main/kotlin"

# FILE PATHS
MANIFEST_FILE="android/app/src/main/AndroidManifest.xml"
IOS_PLIST="ios/Runner/Info.plist"
MACOS_CONFIG="macos/Runner/Configs/AppInfo.xcconfig"
MACOS_INFO="macos/Runner/Info.plist"
LINUX_CMAKE="linux/CMakeLists.txt"
LINUX_MAIN="linux/my_application.cc"
WINDOWS_RC="windows/runner/Runner.rc"

# VERSION & NAMES
NEW_VERSION="$1"
NEW_APP_NAME="AnymeX β"
NEW_FLUTTER_NAME="anymex_beta"

echo "🔄 Starting FULL Cross-Platform Beta Rename..."

###############################################
# 0. SKIP IF ALREADY BETA
###############################################
if [ -d "$ANDROID_SRC/$NEW_DIR" ]; then
  echo "✔ Already beta — skipping rename."
  exit 0
fi

###############################################
# ANDROID
###############################################
echo "➡ ANDROID: Updating Gradle + Manifest + Kotlin..."

$SED "s|applicationId = \".*\"|applicationId = \"$NEW_PKG\"|g" android/app/build.gradle
$SED "s|namespace = \".*\"|namespace = \"$NEW_PKG\"|g" android/app/build.gradle

$SED "s|package=\"$OLD_PKG\"|package=\"$NEW_PKG\"|g" "$MANIFEST_FILE"
$SED "s|android:label=\"AnymeX\"|android:label=\"$NEW_APP_NAME\"|g" "$MANIFEST_FILE"

mkdir -p "$ANDROID_SRC/$NEW_DIR"
mv "$ANDROID_SRC/$OLD_DIR"/* "$ANDROID_SRC/$NEW_DIR"/
rm -rf "$ANDROID_SRC/com/ryan/anymex"

$SED "s|package $OLD_PKG|package $NEW_PKG|g" "$ANDROID_SRC/$NEW_DIR/MainActivity.kt"

###############################################
# iOS
###############################################
echo "➡ iOS: Updating CFBundle IDs + display name..."

$SED "s|PRODUCT_BUNDLE_IDENTIFIER = $OLD_PKG|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PKG|g" ios/Runner.xcodeproj/project.pbxproj
$SED "s|PRODUCT_BUNDLE_IDENTIFIER = ${OLD_PKG}.RunnerTests|PRODUCT_BUNDLE_IDENTIFIER = ${NEW_PKG}.RunnerTests|g" ios/Runner.xcodeproj/project.pbxproj

$SED 's|\(<key>CFBundleDisplayName</key>[[:space:]]*<string>\)AnymeX\(</string>\)|\1AnymeX β\2|' "$IOS_PLIST"

###############################################
# macOS
###############################################
echo "➡ macOS: Updating AppInfo.xcconfig + Info.plist..."

if [ -f "$MACOS_CONFIG" ]; then
  $SED "s|PRODUCT_NAME = anymex|PRODUCT_NAME = $NEW_FLUTTER_NAME|g" "$MACOS_CONFIG"
  $SED "s|PRODUCT_BUNDLE_IDENTIFIER = $OLD_PKG|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PKG|g" "$MACOS_CONFIG"
fi

if [ -f "$MACOS_INFO" ]; then
  $SED 's|\(<key>CFBundleDisplayName</key>[[:space:]]*<string>\)AnymeX\(</string>\)|\1AnymeX β\2|' "$MACOS_INFO"
fi

###############################################
# LINUX
###############################################
echo "➡ Linux: Updating window title + CMake metadata..."

if [ -f "$LINUX_MAIN" ]; then
  $SED 's|"AnymeX"|"AnymeX β"|g' "$LINUX_MAIN"
fi

if [ -f "$LINUX_CMAKE" ]; then
  $SED "s|AnymeX|AnymeX β|g" "$LINUX_CMAKE"
fi

###############################################
# WINDOWS
###############################################
echo "➡ Windows: Updating .rc metadata..."

if [ -f "$WINDOWS_RC" ]; then
  $SED 's|"anymex"|"anymex_beta"|g' "$WINDOWS_RC"
  $SED 's|"anymex.exe"|"anymex_beta.exe"|g' "$WINDOWS_RC"
fi

###############################################
# Flutter pubspec — name + version
###############################################
echo "➡ Flutter: Updating pubspec.yaml..."

$SED "s|name: anymex|name: $NEW_FLUTTER_NAME|g" pubspec.yaml
$SED "s|version: .*|version: $NEW_VERSION|g" pubspec.yaml

echo "🎉 FULL CROSS-PLATFORM RENAME COMPLETE!"
