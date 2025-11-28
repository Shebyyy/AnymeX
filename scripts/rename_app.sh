#!/usr/bin/env bash
set -e

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
# ANDROID — rename package + app label
###############################################
echo "➡ ANDROID: Updating Gradle + Manifest + Kotlin..."

# Update applicationId + namespace
sed -i "s|applicationId = \".*\"|applicationId = \"$NEW_PKG\"|g" android/app/build.gradle
sed -i "s|namespace = \".*\"|namespace = \"$NEW_PKG\"|g" android/app/build.gradle

# Update manifest
sed -i "s|package=\"$OLD_PKG\"|package=\"$NEW_PKG\"|g" "$MANIFEST_FILE"
sed -i "s|android:label=\"AnymeX\"|android:label=\"$NEW_APP_NAME\"|g" "$MANIFEST_FILE"

# Move Kotlin folders
mkdir -p "$ANDROID_SRC/$NEW_DIR"
mv "$ANDROID_SRC/$OLD_DIR"/* "$ANDROID_SRC/$NEW_DIR"/
rm -rf "$ANDROID_SRC/com/ryan/anymex"

# Update Kotlin package import
sed -i "s|package $OLD_PKG|package $NEW_PKG|g" "$ANDROID_SRC/$NEW_DIR/MainActivity.kt"


###############################################
# iOS — bundle ID + display name
###############################################
echo "➡ iOS: Updating CFBundle IDs + display name..."

# bundle identifiers
sed -i "s|PRODUCT_BUNDLE_IDENTIFIER = $OLD_PKG|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PKG|g" ios/Runner.xcodeproj/project.pbxproj
sed -i "s|PRODUCT_BUNDLE_IDENTIFIER = ${OLD_PKG}.RunnerTests|PRODUCT_BUNDLE_IDENTIFIER = ${NEW_PKG}.RunnerTests|g" ios/Runner.xcodeproj/project.pbxproj

# CFBundleDisplayName
sed -i '' 's|\(<key>CFBundleDisplayName</key>[[:space:]]*<string>\)AnymeX\(</string>\)|\1AnymeX β\2|' "$IOS_PLIST"


###############################################
# macOS — PRODUCT_NAME + display name
###############################################
echo "➡ macOS: Updating AppInfo.xcconfig + Info.plist..."

# App name + bundle identifier in xcconfig
if [ -f "$MACOS_CONFIG" ]; then
  sed -i '' "s|PRODUCT_NAME = anymex|PRODUCT_NAME = $NEW_FLUTTER_NAME|g" "$MACOS_CONFIG"
  sed -i '' "s|PRODUCT_BUNDLE_IDENTIFIER = $OLD_PKG|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PKG|g" "$MACOS_CONFIG"
fi

# Update macOS display name
if [ -f "$MACOS_INFO" ]; then
  sed -i '' 's|\(<key>CFBundleDisplayName</key>[[:space:]]*<string>\)AnymeX\(</string>\)|\1AnymeX β\2|' "$MACOS_INFO"
fi


###############################################
# Linux — window title + app name
###############################################
echo "➡ Linux: Updating window title + CMake metadata..."

# Update window title in my_application.cc
if [ -f "$LINUX_MAIN" ]; then
  sed -i 's|"AnymeX"|"AnymeX β"|g' "$LINUX_MAIN"
fi

# Update CMakeLists.txt app name
if [ -f "$LINUX_CMAKE" ]; then
  sed -i "s|AnymeX|AnymeX β|g" "$LINUX_CMAKE"
fi


###############################################
# Windows — RC metadata (lowercase style)
###############################################
echo "➡ Windows: Updating .rc metadata..."

if [ -f "$WINDOWS_RC" ]; then
  # Any occurrence of "anymex" → "anymex_beta"
  sed -i "s|\"anymex\"|\"anymex_beta\"|g" "$WINDOWS_RC"
  sed -i "s|\"anymex.exe\"|\"anymex_beta.exe\"|g" "$WINDOWS_RC"
fi


###############################################
# Flutter pubspec — name + version
###############################################
echo "➡ Flutter: Updating pubspec.yaml..."

sed -i "s|name: anymex|name: $NEW_FLUTTER_NAME|g" pubspec.yaml
sed -i "s|version: .*|version: $NEW_VERSION|g" pubspec.yaml


echo "🎉 FULL CROSS-PLATFORM RENAME COMPLETE!"
