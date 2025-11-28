#!/usr/bin/env bash
set -e

echo "🧹 Running flutter clean..."
flutter clean
flutter pub get

###############################################
# Detect macOS BSD sed vs Linux GNU sed
###############################################
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED="sed -i ''"
else
  SED="sed -i"
fi

###############################################
# Package & Directory Variables
###############################################
OLD_PKG="com.ryan.anymex"
NEW_PKG="com.ryan.anymexbeta"

OLD_DIR="com/ryan/anymex"
NEW_DIR="com/ryan/anymexbeta"

ANDROID_SRC="android/app/src/main/kotlin"

MANIFEST_FILE="android/app/src/main/AndroidManifest.xml"
IOS_PLIST="ios/Runner/Info.plist"
MACOS_CONFIG="macos/Runner/Configs/AppInfo.xcconfig"
MACOS_INFO="macos/Runner/Info.plist"
LINUX_MAIN="linux/my_application.cc"
LINUX_CMAKE="linux/CMakeLists.txt"
WINDOWS_RC="windows/runner/Runner.rc"

NEW_VERSION="$1"
NEW_APP_NAME="AnymeX β"

echo "🔄 Starting FULL Cross-Platform Beta Rename..."

###############################################
# 0. SKIP IF ALREADY BETA
###############################################
if [ -d "$ANDROID_SRC/$NEW_DIR" ]; then
  echo "✔ Already beta — skipping rename."
  exit 0
fi


###############################################
# ANDROID — ID + Manifest + Kotlin
###############################################
echo "➡ ANDROID: Updating Gradle, Manifest & Kotlin..."

$SED "s|applicationId = \".*\"|applicationId = \"$NEW_PKG\"|g" android/app/build.gradle
$SED "s|namespace = \".*\"|namespace = \"$NEW_PKG\"|g" android/app/build.gradle

$SED "s|package=\"$OLD_PKG\"|package=\"$NEW_PKG\"|g" "$MANIFEST_FILE"
$SED "s|android:label=\"AnymeX\"|android:label=\"$NEW_APP_NAME\"|g" "$MANIFEST_FILE"

mkdir -p "$ANDROID_SRC/$NEW_DIR"
mv "$ANDROID_SRC/$OLD_DIR"/* "$ANDROID_SRC/$NEW_DIR"/
rm -rf "$ANDROID_SRC/com/ryan/anymex"

$SED "s|package $OLD_PKG|package $NEW_PKG|g" "$ANDROID_SRC/$NEW_DIR/MainActivity.kt"


###############################################
# iOS — Bundle ID + App Name
###############################################
echo "➡ iOS: Updating bundle ID & app name..."

# 1. Update PRODUCT_BUNDLE_IDENTIFIER everywhere
$SED "s|PRODUCT_BUNDLE_IDENTIFIER = $OLD_PKG|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PKG|g" ios/Runner.xcodeproj/project.pbxproj
$SED "s|PRODUCT_BUNDLE_IDENTIFIER = ${OLD_PKG}.RunnerTests|PRODUCT_BUNDLE_IDENTIFIER = ${NEW_PKG}.RunnerTests|g" ios/Runner.xcodeproj/project.pbxproj

# 2. Update PRODUCT_NAME
$SED "s|PRODUCT_NAME = \"\\\$(TARGET_NAME)\"|PRODUCT_NAME = \"$NEW_APP_NAME\"|g" ios/Runner.xcodeproj/project.pbxproj

# 3. Update TARGET_NAME → not strictly required but makes naming correct
$SED "s|name = Runner;|name = \"$NEW_APP_NAME\";|g" ios/Runner.xcodeproj/project.pbxproj
$SED "s|productName = Runner;|productName = \"$NEW_APP_NAME\";|g" ios/Runner.xcodeproj/project.pbxproj

# 4. Update CFBundleName (always present)
$SED 's|\(<key>CFBundleName</key>[[:space:]]*<string>\)[^<]*\(</string>\)|\1'"$NEW_APP_NAME"'\2|' ios/Runner/Info.plist

# 5. Update CFBundleDisplayName (if present)
$SED 's|\(<key>CFBundleDisplayName</key>[[:space:]]*<string>\)[^<]*\(</string>\)|\1'"$NEW_APP_NAME"'\2|' ios/Runner/Info.plist


###############################################
# macOS — Bundle ID + PRODUCT_NAME + Display
###############################################
echo "➡ macOS: Updating xcconfig & Info.plist..."

if [ -f "$MACOS_CONFIG" ]; then
  $SED "s|PRODUCT_NAME = anymex|PRODUCT_NAME = anymex_beta|g" "$MACOS_CONFIG"
  $SED "s|PRODUCT_BUNDLE_IDENTIFIER = $OLD_PKG|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PKG|g" "$MACOS_CONFIG"
fi

if [ -f "$MACOS_INFO" ]; then
  $SED 's|\(<key>CFBundleDisplayName</key>[[:space:]]*<string>\)AnymeX\(</string>\)|\1AnymeX β\2|' "$MACOS_INFO"
fi


###############################################
# Linux — Window Title + CMake project name
###############################################
echo "➡ Linux: Updating GTK window title & metadata..."

if [ -f "$LINUX_MAIN" ]; then
  $SED 's|"AnymeX"|"AnymeX β"|g' "$LINUX_MAIN"
fi

if [ -f "$LINUX_CMAKE" ]; then
  $SED "s|AnymeX|AnymeX β|g" "$LINUX_CMAKE"
fi


###############################################
# Windows — .rc exe metadata
###############################################
echo "➡ Windows: Updating .rc metadata..."

if [ -f "$WINDOWS_RC" ]; then
  $SED 's|"anymex"|"anymex_beta"|g' "$WINDOWS_RC"
  $SED 's|"anymex.exe"|"anymex_beta.exe"|g' "$WINDOWS_RC"
fi


###############################################
# Flutter — Update version ONLY
###############################################
echo "➡ Flutter: Updating version in pubspec.yaml (keep name same)…"

$SED "s|version: .*|version: $NEW_VERSION|g" pubspec.yaml


echo "🎉 FULL CROSS-PLATFORM BETA RENAME COMPLETE!"
